-- Revoke privileges
-- テーブルへの権限を取り消し
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM aws_practice;

-- シーケンスへの権限を取り消し
REVOKE USAGE ON ALL SEQUENCES IN SCHEMA public FROM aws_practice;

-- スキーマへのアクセス権限を取り消し
REVOKE USAGE ON SCHEMA public FROM aws_practice;

-- データベースへの接続権限を取り消し
REVOKE CONNECT ON DATABASE aws_practice FROM aws_practice;

-- 今後作成されるテーブルに対するデフォルト権限を取り消し
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES FROM aws_practice;

-- Drop user if exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_user WHERE usename = 'aws_practice') THEN
        DROP USER aws_practice;
    END IF;
END;
$$ LANGUAGE plpgsql;
