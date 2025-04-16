-- Create user if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_user WHERE usename = 'aws_practice') THEN
        CREATE USER aws_practice WITH PASSWORD 'password';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Grant privileges
-- データベースへの接続権限
GRANT CONNECT ON DATABASE aws_practice TO aws_practice;

-- スキーマへのアクセス権限
GRANT USAGE ON SCHEMA public TO aws_practice;

-- 既存のテーブルへの権限
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO aws_practice;

-- 既存のシーケンスへの権限（INSERTで必要）
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO aws_practice;

-- 今後作成されるテーブルに対する権限を自動付与
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT ALL PRIVILEGES ON TABLES TO aws_practice;

-- 今後作成されるテーブルに対するシーケンスの権限を自動付与
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE ON SEQUENCES TO aws_practice;
