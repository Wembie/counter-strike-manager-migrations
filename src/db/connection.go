package db

import (
	"context"
	"database/sql"
	"embed"
	"strconv"
	"time"

	"counter-strike-manager-migrations/src/config"

	"github.com/pressly/goose/v3"
	"github.com/uptrace/bun"
	"github.com/uptrace/bun/dialect/pgdialect"
	"github.com/uptrace/bun/driver/pgdriver"
	"github.com/uptrace/bun/extra/bundebug"
	"go.uber.org/zap"
)

func GetConnection() *bun.DB {
	addr := config.Config.DBHost + ":" + config.Config.DBPort

	pgconn := pgdriver.NewConnector(
		pgdriver.WithAddr(addr),
		pgdriver.WithUser(config.Config.DBUser),
		pgdriver.WithPassword(config.Config.DBPassword),
		pgdriver.WithDatabase(config.Config.DBName),
		pgdriver.WithApplicationName("counter-strike-manager-migrations"),
		pgdriver.WithInsecure(config.Config.DBInsecure),
	)

	sqldb := sql.OpenDB(pgconn)
	db := bun.NewDB(sqldb, pgdialect.New())
	db.AddQueryHook(bundebug.NewQueryHook(bundebug.WithVerbose(true)))

	maxIdle, err := strconv.Atoi(config.Config.MaxConnection)
	if err != nil {
		config.Logger.Warn("Invalid MAX_IDLE_CONN, defaulting to 1", zap.Error(err))
		maxIdle = 1
	}

	maxOpen, err := strconv.Atoi(config.Config.MaxOpenConnection)
	if err != nil {
		config.Logger.Warn("Invalid MAX_OPEN_CONN, defaulting to 1", zap.Error(err))
		maxOpen = 1
	}

	db.SetMaxOpenConns(maxOpen)
	db.SetMaxIdleConns(maxIdle)
	db.SetConnMaxIdleTime(30 * time.Minute)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		config.Logger.Fatal("Cannot connect to database", zap.Error(err))
	}

	config.Logger.Info("Database connection established successfully")
	return db
}

func Migrate(sqlDB *sql.DB, fs embed.FS) {
	goose.SetBaseFS(fs)

	if err := goose.SetDialect("postgres"); err != nil {
		config.Logger.Fatal("Error setting dialect", zap.Error(err))
	}

	if err := goose.Up(sqlDB, "migrations"); err != nil {
		config.Logger.Fatal("Error running migrations", zap.Error(err))
	}

	config.Logger.Info("Database migration completed successfully")
}