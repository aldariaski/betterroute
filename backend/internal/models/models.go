package models

type Merchant struct {
	ID int64 `json:"id"`
	Name string `json:"name"`
	Address string `json:"address"`
	Latitude float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

type RouteResponse struct {
	DistanceKM float64 `json:"distance_km"`
	DurationMinutes float64 `json:"duration_minutes"`
	Geometry any `json:"geometry"`
}
