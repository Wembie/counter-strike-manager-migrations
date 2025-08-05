package main

import (
	"embed"

	"counter-strike-manager-migrations/src/config"
	"counter-strike-manager-migrations/src/db"
	"go.uber.org/zap"
)

//go:embed migrations/*.sql
var embedMigrations embed.FS

func main() {
	config.Logger.Info("Starting migration")

	config.InitEnv()

	instance := db.GetConnection()

	db.Migrate(instance.DB, embedMigrations)

	if err := instance.DB.Close(); err != nil {
		config.Logger.Error("Error closing connection", zap.Error(err))
		panic(err)
	}

	config.Logger.Info("Migration finished")
}