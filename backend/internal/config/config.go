package config

import "os"

type Config struct {
	Port string
	DatabaseURL string
	ORSAPIKey string
}

func Load() Config {
	port := os.Getenv("PORT")
	if port == "" { port = "8080" }
	return Config{
		Port: port,
		DatabaseURL: os.Getenv("DATABASE_URL"),
		ORSAPIKey: os.Getenv("ORS_API_KEY"),
	}
}
