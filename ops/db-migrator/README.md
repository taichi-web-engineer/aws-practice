# db-migrator

データベースマイグレーションを管理・実行するためのツールです。
マルチデータベース対応を行っています。

## 前提条件

- Docker
- Docker Compose
- golang-migrate (ローカル環境用)

## セットアップ

### ローカル環境への golang-migrate のインストール

マイグレーションファイルの生成はローカル環境で行います。以下のコマンドで golang-migrate をインストールしてください：

```bash
brew install golang-migrate
```

### postgres コンテナを起動

postgres のコンテナをデーモン起動します。

```bash
docker compose up -d
```

### db-migrator を実行

db-migrator を実行します。

```bash
go run main.go

>
2025/01/19 20:55:47 INFO start db-migrator
2025/01/19 20:55:47 INFO mode !BADKEY=up
2025/01/19 20:55:47 INFO dbName !BADKEY=aws_practice
2025/01/19 20:55:47 INFO connected to default db
2025/01/19 20:55:47 INFO Migrations applied successfully
```

※ `TARGET_DB` を指定することで、指定した DB に対してマイグレーションを実行できます。指定しない場合は全ての DB に対してマイグレーションを実行します。
※ `MODE` を `up` にするとマイグレーションを実行します。`down` にするとマイグレーションをロールバックします。

### テーブルが作成されているか確認

Table Plus などの DB クライアントツールで DB に接続し、`public`スキーマにテーブルが作成されているか確認します。

### seed データの作成

seed データの作成は、dump ファイルを復元することで行います。

```bash
make restore DB=[DB名]
```

## 運用

### マイグレーションファイルの作成

新しいマイグレーションファイルを生成する場合は、以下のコマンドを実行します：

```bash
make new DB=[DB名] NAME=[マイグレーションファイル名]
```

例：

```bash
make new DB=aws_practice NAME=create_users
```

これにより、`migrations/[DB名]`ディレクトリに以下の 2 つのファイルが生成されます：

- `YYYYMMDDHHMMSS_create_users.up.sql`
- `YYYYMMDDHHMMSS_create_users.down.sql`

マイグレーションファイル内には SQL 文を記述してください。

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);
```

### マイグレーションファイルの実行(最新バージョンまで)

マイグレーションファイルを実行する場合は、以下のコマンドを実行します：

```bash
make up DB=[DB名]
```

例：

```bash
make up DB=aws_practice
```

### マイグレーションのロールバック(1 つのバージョンのみ)

マイグレーションファイルをロールバックする場合は、以下のコマンドを実行します：

```bash
make down DB=[DB名]
```

### dump ファイルの作成

seed データのメンテナンスを行う場合は、DB を dump する必要があります。
DB を dump する場合は以下のコマンドを実行します:

```bash
make dump DB=[DB名]
```

### dump ファイルから seed データを復元する

dump ファイルから seed データを復元する場合は以下のコマンドを実行します:

```bash
make restore DB=[DB名]
```

## 環境変数について

環境変数で以下の項目を設定できます：

- `DB_HOST` : DB インスタンスのホスト名
- `DB_PORT` : DB インスタンスのポート番号
- `DB_USER` : migration を実行するユーザー名
- `DB_PASSWORD` : migration を実行するユーザのパスワード
- `TARGET_DB`: マイグレーションを実行する DB 名を指定します。指定しない場合は全ての DB に対して実行します。

## リモート環境へのデプロイについて

GitHub の差分を検知して、自動で Docker イメージの build、ECR への push が行われます。
内部では、以下のコマンドを実行しています。

```bash
make release-image ENV=[環境名]
```

ECS タスク定義にて、Docker イメージを参照し、マイグレーションを実行します。

## 注意事項

1. マイグレーションファイルの作成、実行は必ずローカル環境で行ってください（Docker 内ではありません）

2. マイグレーションファイルは一度実行すると変更できません。新しい変更が必要な場合は、新しいマイグレーションファイルを作成してください。

## 開発着手から、リモート DB のマイグレーションを実行するまでの全体の流れ

1. [local] postgres コンテナを起動 docker compose up -d
1. [local] 最新のバージョンまでマイグレーションを実行 make up DB=[DB 名]
1. [local] restore して dump ファイルからスナップショットを復元 make restore DB=[DB 名]
1. [local] マイグレーションファイルを作成 make new DB=[DB 名] NAME=[マイグレーションファイル名]
1. [local] マイグレーションファイルを実行してローカル DB に反映の上、動作確認 make up DB=[DB 名]
1. [local] 必要であれば、TablePlus から GUI でデータの中身をメンテナンス
1. [local] スキーマ変更後の dump ファイルを作成 make dump DB=[DB 名]
1. [github] PR を作成 (差分はマイグレーションファイルのみ)
1. [github] develop ブランチにマージ
1. [CD パイプライン] aws ecs run-task [db-migrator 用のタスク定義] にて、stg DB に対してマイグレーションを実行
1. [github] main ブランチにマージ
1. [CD パイプライン] aws ecs run-task [db-migrator 用のタスク定義] にて、prd DB に対してマイグレーションを実行
