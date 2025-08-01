package database

import (
	"fmt"

	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"

	"github.com/hafizd-kurniawan/pos-baru/internal/config"
)

type Database struct {
	*sqlx.DB
}

func NewConnection(cfg *config.Config) (*Database, error) {
	db, err := sqlx.Connect("postgres", cfg.GetDatabaseURL())
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	// Test the connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	// Set connection pool settings
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(10)

	return &Database{DB: db}, nil
}