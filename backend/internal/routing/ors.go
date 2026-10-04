package routing

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"time"
)

type Service struct {
	APIKey string
	Client *http.Client
}

type Step struct {
	Instruction string  `json:"instruction"`
	Name        string  `json:"name"`
	DistanceM   float64 `json:"distance_m"`
	DurationS   float64 `json:"duration_s"`
	Type        int     `json:"type"`
}

type Route struct {
	DistanceKM      float64 `json:"distance_km"`
	DurationMinutes float64 `json:"duration_minutes"`
	Geometry        any     `json:"geometry"`
	Steps           []Step  `json:"steps"`
}

type Place struct {
	Name      string  `json:"name"`
	Address   string  `json:"address"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

func New(apiKey string) *Service {
	return &Service{APIKey: apiKey, Client: &http.Client{Timeout: 20 * time.Second}}
}

func (s *Service) request(ctx context.Context, method, endpoint string, body any) ([]byte, error) {
	if s.APIKey == "" {
		return nil, fmt.Errorf("ORS_API_KEY is not configured")
	}
	var payload io.Reader
	if body != nil {
		data, err := json.Marshal(body)
		if err != nil {
			return nil, err
		}
		payload = bytes.NewReader(data)
	}
	req, err := http.NewRequestWithContext(ctx, method, endpoint, payload)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", s.APIKey)
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	resp, err := s.Client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	data, err := io.ReadAll(io.LimitReader(resp.Body, 4<<20))
	if err != nil {
		return nil, err
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("routing service returned %d: %s", resp.StatusCode, string(data))
	}
	return data, nil
}

func (s *Service) DrivingRoutes(ctx context.Context, lon1, lat1, lon2, lat2 float64) ([]Route, error) {
	data, err := s.request(ctx, http.MethodPost, "https://api.openrouteservice.org/v2/directions/driving-car/geojson", map[string]any{
		"coordinates":        [][]float64{{lon1, lat1}, {lon2, lat2}},
		"units":              "km",
		"instructions":       true,
		"alternative_routes": map[string]any{"target_count": 2, "weight_factor": 1.6, "share_factor": 0.6},
	})
	if err != nil {
		return nil, err
	}
	var geo struct {
		Features []struct {
			Properties struct {
				Summary struct {
					Distance float64 `json:"distance"`
					Duration float64 `json:"duration"`
				} `json:"summary"`
				Segments []struct {
					Steps []struct {
						Instruction string  `json:"instruction"`
						Name        string  `json:"name"`
						Distance    float64 `json:"distance"`
						Duration    float64 `json:"duration"`
						Type        int     `json:"type"`
					} `json:"steps"`
				} `json:"segments"`
			} `json:"properties"`
			Geometry any `json:"geometry"`
		} `json:"features"`
	}
	if err := json.Unmarshal(data, &geo); err != nil {
		return nil, err
	}
	if len(geo.Features) == 0 {
		return nil, fmt.Errorf("routing service returned no route")
	}
	routes := make([]Route, 0, len(geo.Features))
	for _, f := range geo.Features {
		r := Route{DistanceKM: f.Properties.Summary.Distance, DurationMinutes: f.Properties.Summary.Duration / 60, Geometry: f.Geometry, Steps: []Step{}}
		for _, segment := range f.Properties.Segments {
			for _, step := range segment.Steps {
				r.Steps = append(r.Steps, Step{Instruction: step.Instruction, Name: step.Name, DistanceM: step.Distance, DurationS: step.Duration, Type: step.Type})
			}
		}
		routes = append(routes, r)
	}
	return routes, nil
}

func (s *Service) SearchPlaces(ctx context.Context, query string) ([]Place, error) {
	endpoint := "https://api.openrouteservice.org/geocode/search?text=" + url.QueryEscape(query) + "&size=6&boundary.country=ID"
	data, err := s.request(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, err
	}
	var response struct {
		Features []struct {
			Geometry struct {
				Coordinates []float64 `json:"coordinates"`
			} `json:"geometry"`
			Properties struct {
				Name  string `json:"name"`
				Label string `json:"label"`
			} `json:"properties"`
		} `json:"features"`
	}
	if err := json.Unmarshal(data, &response); err != nil {
		return nil, err
	}
	places := make([]Place, 0, len(response.Features))
	for _, feature := range response.Features {
		if len(feature.Geometry.Coordinates) < 2 {
			continue
		}
		name := feature.Properties.Name
		if name == "" {
			name = feature.Properties.Label
		}
		places = append(places, Place{Name: name, Address: feature.Properties.Label, Longitude: feature.Geometry.Coordinates[0], Latitude: feature.Geometry.Coordinates[1]})
	}
	return places, nil
}
