package app

import (
	"context"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"

	"betterroute/backend/internal/handlers"
	"betterroute/backend/internal/routing"
)

// ServeHTTP adapts the existing API to Vercel's request-scoped Go Functions.
func ServeHTTP(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
	defer cancel()

	db, err := pgx.Connect(ctx, os.Getenv("DATABASE_URL"))
	if err != nil {
		http.Error(w, `{"error":"database connection failed"}`, http.StatusServiceUnavailable)
		return
	}
	defer db.Close(context.Background())

	api := handlers.New(db, routing.New(os.Getenv("ORS_API_KEY")))
	gin.SetMode(gin.ReleaseMode)
	g := gin.New()
	g.Use(gin.Recovery(), cors())
	g.GET("/health", api.Health)
	g.GET("/api/merchants", api.ListMerchants)
	g.GET("/api/merchants/:id", api.GetMerchant)
	g.POST("/api/merchants", api.CreateMerchant)
	g.GET("/api/route", api.Route)
	g.GET("/api/places/search", api.SearchPlaces)
	g.ServeHTTP(w, r)
}

func cors() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	}
}
