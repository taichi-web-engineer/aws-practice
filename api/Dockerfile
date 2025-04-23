# ビルドステージ
FROM gradle:8.13.0-jdk21-alpine AS builder
WORKDIR /app
# Gradleキャッシュ最適化
# 依存関係は変更頻度が低いため、ソースコード以外を先にビルドすることで変更がないときはキャッシュが使われる
COPY build.gradle.kts settings.gradle.kts ./
COPY gradle ./gradle
# 一度の実行で良いので --no-daemon
RUN gradle dependencies --no-daemon

# ソースコードのコピーとビルド
COPY src ./src
# テスト実行不要なので -x test
RUN gradle bootJar --no-daemon -x test

# レイヤー抽出ステージ
FROM eclipse-temurin:21-jdk-alpine AS extractor
WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar
# extractedディレクトリへのSpring Boot JARレイヤー抽出コマンド
# Spring Boot 2.3で導入された機能で、JARファイルを論理的なレイヤーに分解
# 依存関係(dependencies)、Spring Boot自体(spring-boot-loader)、
# 開発中の依存関係(snapshot-dependencies)、アプリケーションコード(application)の
# 4つの論理レイヤーに分け、Dockerのキャッシュを活用
RUN mkdir -p extracted && \
    java -Djarmode=tools -jar app.jar extract --layers --destination extracted --launcher

# 実行ステージ
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# 脆弱性があるパッケージを修正バージョン以上にアップデート
RUN apk update && \
    apk upgrade && \
    apk add --no-cache libexpat>=2.7.0-r0 sqlite-libs>=3.48.0-r1

# タイムゾーン設定
ENV TZ=Asia/Tokyo

# 機密性、環境差分がない環境変数のみデフォルト値設定
ENV DB_PORT=5432 \
    DB_NAME=aws_practice

# セキュリティ向上のための非rootユーザー作成
RUN addgroup -S spring && adduser -S spring -G spring

# アプリケーションディレクトリの権限設定
RUN mkdir -p /app && chown -R spring:spring /app
USER spring:spring

# レイヤー最適化されたアプリケーションのコピー
# 変更頻度の低いものから高いものへ順にコピー（キャッシュ効率化）
COPY --from=extractor --chown=spring:spring /app/extracted/dependencies/ ./
COPY --from=extractor --chown=spring:spring /app/extracted/spring-boot-loader/ ./
COPY --from=extractor --chown=spring:spring /app/extracted/snapshot-dependencies/ ./
COPY --from=extractor --chown=spring:spring /app/extracted/application/ ./

# コンテナポート公開
EXPOSE 8080

# ヘルスチェック追加
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -q -O /dev/null http://localhost:8080/actuator/health || exit 1

# コンテナ環境に最適化されたJVM設定
ENTRYPOINT ["java", \
            "-XX:+UseContainerSupport", \
            "-XX:MaxRAMPercentage=75.0", \
            "-Djava.security.egd=file:/dev/./urandom", \
            "org.springframework.boot.loader.launch.JarLauncher"]
