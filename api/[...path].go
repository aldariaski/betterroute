package handler

import (
	"net/http"

	"betterroute/backend/app"
)

func Handler(w http.ResponseWriter, r *http.Request) {
	app.ServeHTTP(w, r)
}
