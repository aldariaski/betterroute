package handlers

import (
	"context"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"

	"betterroute/backend/internal/models"
	"betterroute/backend/internal/routing"
)

type Handler struct { db *pgx.Conn; router *routing.Service }
func New(db *pgx.Conn, router *routing.Service) *Handler { return &Handler{db:db, router:router} }

func (h *Handler) Health(c *gin.Context) { c.JSON(http.StatusOK, gin.H{"status":"ok"}) }

func (h *Handler) ListMerchants(c *gin.Context) {
	rows, err := h.db.Query(context.Background(), `SELECT id,name,address,ST_Y(location::geometry),ST_X(location::geometry) FROM merchants ORDER BY id`)
	if err != nil { c.JSON(500, gin.H{"error":err.Error()}); return }
	defer rows.Close()
	out := []models.Merchant{}
	for rows.Next() {
		var m models.Merchant
		if err := rows.Scan(&m.ID,&m.Name,&m.Address,&m.Latitude,&m.Longitude); err != nil { c.JSON(500, gin.H{"error":err.Error()}); return }
		out = append(out,m)
	}
	c.JSON(200,out)
}

func (h *Handler) GetMerchant(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"),10,64); if err != nil { c.JSON(400,gin.H{"error":"invalid id"}); return }
	var m models.Merchant
	err = h.db.QueryRow(context.Background(), `SELECT id,name,address,ST_Y(location::geometry),ST_X(location::geometry) FROM merchants WHERE id=$1`, id).Scan(&m.ID,&m.Name,&m.Address,&m.Latitude,&m.Longitude)
	if err == pgx.ErrNoRows { c.JSON(404,gin.H{"error":"merchant not found"}); return }
	if err != nil { c.JSON(500,gin.H{"error":err.Error()}); return }
	c.JSON(200,m)
}

type createMerchant struct { Name string `json:"name" binding:"required"`; Address string `json:"address"`; Latitude float64 `json:"latitude" binding:"required"`; Longitude float64 `json:"longitude" binding:"required"` }
func (h *Handler) CreateMerchant(c *gin.Context) {
	var req createMerchant
	if err:=c.ShouldBindJSON(&req); err!=nil { c.JSON(400,gin.H{"error":err.Error()}); return }
	var m models.Merchant
	err:=h.db.QueryRow(context.Background(), `INSERT INTO merchants(name,address,location) VALUES($1,$2,ST_SetSRID(ST_MakePoint($3,$4),4326)::geography) RETURNING id,name,address,ST_Y(location::geometry),ST_X(location::geometry)`, req.Name,req.Address,req.Longitude,req.Latitude).Scan(&m.ID,&m.Name,&m.Address,&m.Latitude,&m.Longitude)
	if err!=nil { c.JSON(500,gin.H{"error":err.Error()}); return }
	c.JSON(201,m)
}

func (h *Handler) Route(c *gin.Context) {
	buyerLat,err1:=strconv.ParseFloat(c.Query("buyer_lat"),64); buyerLon,err2:=strconv.ParseFloat(c.Query("buyer_lng"),64)
	merchantLat,err3:=strconv.ParseFloat(c.Query("merchant_lat"),64); merchantLon,err4:=strconv.ParseFloat(c.Query("merchant_lng"),64)
	if err1!=nil||err2!=nil||err3!=nil||err4!=nil { c.JSON(400,gin.H{"error":"buyer_lat, buyer_lng, merchant_lat and merchant_lng are required numbers"}); return }
	d,mins,geometry,err:=h.router.DrivingRoute(buyerLon,buyerLat,merchantLon,merchantLat)
	if err!=nil { c.JSON(502,gin.H{"error":err.Error()}); return }
	c.JSON(200,models.RouteResponse{DistanceKM:d,DurationMinutes:mins,Geometry:geometry})
}
