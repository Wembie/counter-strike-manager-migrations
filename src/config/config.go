package config

import (
	"os"
	"strconv"
)

type Conf struct {
	DBHost            string
	DBUser            string
	DBPassword        string
	DBName            string
	MaxConnection     string
	MaxOpenConnection string
	DBPort            string
	DBInsecure        bool
}

var Config *Conf

func InitEnv() *Conf {
	Config = new(Conf)
	Config.DBHost = os.Getenv("DB_HOST")
	Config.DBUser = os.Getenv("DB_USER")
	Config.DBPassword = os.Getenv("DB_PASSWORD")
	Config.DBName = os.Getenv("DB_NAME")
	Config.MaxConnection = os.Getenv("MAX_IDLE_CONN")
	Config.MaxOpenConnection = os.Getenv("MAX_OPEN_CONN")
	Config.DBPort = GetEnvOrDefault("DB_PORT", "5432")
	Config.DBInsecure, _ = strconv.ParseBool(os.Getenv("DB_INSECURE"))

	return Config
}

func GetEnvOrDefault(key string, defaultValue string) string {
	value, ok := os.LookupEnv(key)
	if !ok || len(value) == 0 {
		return defaultValue
	}

	return value
}
