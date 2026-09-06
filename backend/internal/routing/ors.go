package routing

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

type Service struct { APIKey string; Client *http.Client }

func New(apiKey string) *Service {
	return &Service{APIKey: apiKey, Client: &http.Client{Timeout: 20 * time.Second}}
}

func (s *Service) DrivingRoute(lon1, lat1, lon2, lat2 float64) (float64, float64, any, error) {
	if s.APIKey == "" { return 0, 0, nil, fmt.Errorf("ORS_API_KEY is not configured") }
	body, _ := json.Marshal(map[string]any{
		"coordinates": [][]float64{{lon1, lat1}, {lon2, lat2}},
		"units": "km",
		"instructions": false,
	})
	req, err := http.NewRequest(http.MethodPost, "https://api.openrouteservice.org/v2/directions/driving-car/geojson", bytes.NewReader(body))
	if err != nil { return 0,0,nil,err }
	req.Header.Set("Authorization", s.APIKey)
	req.Header.Set("Content-Type", "application/json")
	resp, err := s.Client.Do(req)
	if err != nil { return 0,0,nil,err }
	defer resp.Body.Close()
	data, _ := io.ReadAll(resp.Body)
	if resp.StatusCode < 200 || resp.StatusCode >= 300 { return 0,0,nil,fmt.Errorf("routing service returned %d: %s", resp.StatusCode, string(data)) }
	var geo struct { Features []struct { Properties struct { Summary struct { Distance float64 `json:"distance"`; Duration float64 `json:"duration"` } `json:"summary"` } `json:"properties"`; Geometry any `json:"geometry"` } `json:"features"` }
	if err := json.Unmarshal(data, &geo); err != nil { return 0,0,nil,err }
	if len(geo.Features) == 0 { return 0,0,nil,fmt.Errorf("routing service returned no route") }
	f := geo.Features[0]
	return f.Properties.Summary.Distance, f.Properties.Summary.Duration / 60, f.Geometry, nil
}
