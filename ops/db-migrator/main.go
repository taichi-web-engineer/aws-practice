package main

import (
	"fmt"
	"log"
	"os"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"golang.org/x/exp/slog"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	slog.Info("start db-migrator")

	// Get the mode from command-line arguments or default to "up"
	mode := getEnvWithDefault("MODE", "up")
	slog.Info("mode", "mode", mode)

	// get environment variables with default values
	host := getEnvWithDefault("DB_HOST", "localhost")
	user := getEnvWithDefault("DB_USER", "postgres")
	password := getEnvWithDefault("DB_PASSWORD", "postgres")
	port := getEnvWithDefault("DB_PORT", "5432")
	targetDB := getEnvWithDefault("TARGET_DB", "all")
	sslMode := getEnvWithDefault("SSL_MODE", "disable")

	slog.Info("connecting to db", "host", host, "user", user, "port", port, "targetDB", targetDB, "sslMode", sslMode)

	dsn := fmt.Sprintf("host=%s user=%s password=%s port=%s sslmode=%s", host, user, password, port, sslMode)
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("failed to connect to postgres: %v", err)
	}
	operator := &operator{
		db:       db,
		mode:     mode,
		host:     host,
		user:     user,
		password: password,
		port:     port,
		sslMode:  sslMode,
	}
	// ターゲットDBが指定されている場合はそのDBに対して実行する
	if targetDB != "" && targetDB != "all" {
		if err := operator.execute(targetDB); err != nil {
			log.Fatalf("failed to execute migrations: %v", err)
		}
		return
	}

	// 以降は、全てのDBに対して実行する処理 ----------------------------

	// 全てのDBに対してrollbackは禁止
	if mode == "down" {
		log.Fatalf("rollback is not allowed for all databases")
	}

	// ターゲットDBが指定されていない場合はすべてのDBに対して実行
	dirs, err := os.ReadDir("db")
	if err != nil {
		log.Fatalf("failed to read db directory: %v", err)
	}
	for _, dir := range dirs {
		if dir.IsDir() {
			dbName := dir.Name()
			if err := operator.execute(dbName); err != nil {
				log.Fatalf("failed to execute migrations: %v", err)
			}
		}
	}
	slog.Info("connected to default db")
}

type operator struct {
	db       *gorm.DB
	mode     string
	host     string
	user     string
	password string
	port     string
	sslMode  string
}

func (o *operator) execute(dbName string) error {
	// データベースが存在するか確認
	var exists bool
	err := o.db.Raw("SELECT EXISTS(SELECT 1 FROM pg_database WHERE datname = ?)", dbName).Scan(&exists).Error
	if err != nil {
		return fmt.Errorf("failed to check if database exists: %v", err)
	}

	// データベースが存在しない場合は作成
	if !exists {
		if err := o.db.Exec(fmt.Sprintf("CREATE DATABASE %s", dbName)).Error; err != nil {
			return fmt.Errorf("failed to create database: %v", err)
		}
	}

	m, err := migrate.New(
		fmt.Sprintf("file://db/%s/migrations", dbName),
		fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=%s", o.user, o.password, o.host, o.port, dbName, o.sslMode))
	if err != nil {
		return fmt.Errorf("failed to create migrate instance: %v", err)
	}

	// DBマイグレーションを実行
	switch o.mode {
	case "up":
		slog.Info("start to apply migrations", "dbName", dbName)
		if err := m.Up(); err != nil && err != migrate.ErrNoChange {
			return fmt.Errorf("failed to apply migrations: %v", err)
		}
		slog.Info("finish to apply migrations")
	case "down":
		slog.Info("start to rollback migrations", "dbName", dbName)
		if err := m.Steps(-1); err != nil {
			return fmt.Errorf("failed to rollback migrations: %v", err)
		}
		slog.Info("finish to rollback migrations", "dbName", dbName)
	default:
		return fmt.Errorf("unknown mode: %s", o.mode)
	}
	return nil
}

// 環境変数をデフォルト値込みで取得
func getEnvWithDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
