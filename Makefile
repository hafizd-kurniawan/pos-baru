# ====== Config ======
include .env

DB_URL=$(DATABASE_URL)
MIGRATIONS_DIR=./migrations

# ====== Docker Commands ======

up:
	docker compose up -d

down:
	docker compose down

ps:
	docker compose ps

logs:
	docker compose logs -f

# ====== DB Migrate Commands ======

migrate-up:
	migrate -path $(MIGRATIONS_DIR) -database "$(DB_URL)" up

migrate-down:
	migrate -path $(MIGRATIONS_DIR) -database "$(DB_URL)" down

migrate-drop:
	migrate -path $(MIGRATIONS_DIR) -database "$(DB_URL)" drop -f

migrate-force:
	migrate -path $(MIGRATIONS_DIR) -database "$(DB_URL)" force $(version)

migrate-new:
	@if [ -z "$(name)" ]; then \
		echo "Usage: make migrate-new name=create_users_table"; \
		exit 1; \
	fi
	migrate create -ext sql -dir $(MIGRATIONS_DIR) -seq $(name)

# ====== Run App ======

run:
	fuser -k 8080/tcp
	go run cmd/server/main.go

build:
	go build -o app main.go

