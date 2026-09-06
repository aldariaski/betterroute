package database

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
)

func New(ctx context.Context, url string) (*pgx.Conn, error) {
	if url == "" { return nil, fmt.Errorf("DATABASE_URL is not set") }
	return pgx.Connect(ctx, url)
}
