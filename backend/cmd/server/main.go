package main

import (
	"context"
	"log"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"

	"betterroute/backend/internal/config"
	"betterroute/backend/internal/database"
	"betterroute/backend/internal/handlers"
	"betterroute/backend/internal/routing"
)

func main() {
	_ = godotenv.Load()
	cfg := config.Load()

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	db, err := database.New(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Fatal("database connection failed: ", err)
	}

	defer db.Close(context.Background())

	router := routing.New(cfg.ORSAPIKey)
	h := handlers.New(db, router)

	g := gin.Default()
	g.Use(cors())
	g.GET("/health", h.Health)
	g.GET("/api/merchants", h.ListMerchants)
	g.GET("/api/merchants/:id", h.GetMerchant)
	g.POST("/api/merchants", h.CreateMerchant)
	g.GET("/api/route", h.Route)
	g.GET("/api/places/search", h.SearchPlaces)

	port := cfg.Port
	log.Printf("BetterRoute API listening on http://localhost:%s", port)
	if err := g.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

func cors() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	}
}

var _ = os.Getenv
