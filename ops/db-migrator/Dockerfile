# ビルドステージ
FROM golang:1.24.2-alpine AS builder

WORKDIR /app

# 必要なビルドツールをインストール
RUN apk add --no-cache git

# 依存関係のコピーとダウンロード
COPY go.mod go.sum ./
RUN go mod download

# ソースコードのコピーとビルド
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

# 実行ステージ
FROM alpine:3.18

WORKDIR /app

# 必要なランタイム依存関係をインストール
RUN apk add --no-cache ca-certificates

# bashのインストール
RUN apk add --no-cache bash

# golang-migrateのインストール
RUN apk add --no-cache curl \
    && curl -L https://github.com/golang-migrate/migrate/releases/download/v4.15.2/migrate.linux-amd64.tar.gz | tar xvz \
    && mv migrate /usr/local/bin/migrate \
    && apk del curl

# ビルドステージから実行可能ファイルをコピー
COPY --from=builder /app/main .
COPY --from=builder /app/db ./db

# 非rootユーザーで実行
RUN adduser -D nonroot
USER nonroot

CMD ["./main"]
