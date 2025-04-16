ROOT_DIR = ../../

include $(ROOT_DIR)/Makefile

# migrationファイルを生成する。
# e.g.
# make new DB=slack_metrics NAME=create_workspaces
# make new DB=slack_metrics NAME=add_column_xxxx_to_workspaces
new: .check-db .check-name
	migrate create -ext sql -dir db/$(DB)/migrations $(NAME)

# マイグレーションを適用する。
# e.g.
# make up DB=slack_metrics
up: .check-db
	MODE=up TARGET_DB=$(DB) go run main.go

# マイグレーションをロールバックする
# e.g.
# make down DB=slack_metrics
down: .check-db
	MODE=down TARGET_DB=$(DB) go run main.go

# Makefile

# ダンプファイルを作成する。
# e.g.
# make dump DB=slack_metrics
dump: .check-db
	docker compose exec db pg_dump --create -U postgres -d $(DB) > db/$(DB)/dump.sql

# dumpファイルからseedデータを復元する。
# e.g.
# make restore DB=slack_metrics
restore: .check-db
	docker compose exec -T db psql -U postgres -d $(DB) -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
	docker compose exec -T db psql -U postgres -d $(DB) < db/$(DB)/dump.sql

# ローカル環境でマイグレーションを実行する。
# e.g.
# make run-local
run-local:
	docker compose up -d
	sleep 5
	go run main.go TARGET_DB=$(DB)

# リモート環境でDBマイグレーションを実行する
# e.g.
# make run-remote ENV=stg PRIVATE_SUBNET_ID=subnet-XXXXXX SECURITY_GROUP_ID=sg-XXXXXX
run-remote: .check-env .check-run-remote-envs
	aws ecs run-task --cluster cloud-pratica-backend-$(ENV) \
		--launch-type FARGATE \
		--task-definition db-migrator-$(ENV) \
		--count 1 \
		--network-configuration "awsvpcConfiguration={subnets=[\"$(PRIVATE_SUBNET_ID)\"],securityGroups=[\"$(SECURITY_GROUP_ID)\"]}"

PHONY: new up down dump restore run-local run-remote

.check-name:
	@if [ -z "$(NAME)" ]; then \
		echo "NAME is required"; \
		exit 1; \
	fi

.check-db:
	@if [ -z "$(DB)" ]; then \
		echo "DB_NAME is required"; \
		exit 1; \
	fi

.check-run-remote-envs:
	@if [ -z "$(PRIVATE_SUBNET_ID)" ]; then \
		echo "PRIVATE_SUBNET_ID is required"; \
		exit 1; \
	fi
	@if [ -z "$(SECURITY_GROUP_ID)" ]; then \
		echo "SECURITY_GROUP_ID is required"; \
		exit 1; \
	fi
