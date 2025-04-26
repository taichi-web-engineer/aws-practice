# 現役エンジニアの実務レベルAWS Webアプリ環境構築
![WebアプリのAWS構成](images/app_aws_architecture.png)

本記事のゴールは上記AWS構成のWebアプリを作成することです。技術スタックは
- Kotlin
- Spring Boot
- PostgreSQL
- Go(DBマイグレーションでのみ使用)
- Next.js
- Docker
- Terraform

です。

アプリのGithubリポジトリはこちら。Next.jsとTerraformのリポジトリは今後追記します。

https://github.com/taichi-web-engineer/aws-practice

実務レベルのAWS Webアプリ環境構築が目的なので、アプリの機能は最低限しか実装しません。具体的にはKotlin、Spring BootでDBからデータを取得して返すAPIを用意し、Next.jsでAPIから取得したデータを画面表示するのみです。
SQSによる非同期処理、SESによるメール配信も動作確認ができる最低限の機能のみ実装します。

## Gitの準備
自身のGithubでaws-practiceという名前でリポジトリを作成します。

![Githubでaws-practiceのリポジトリ作成](create_aws_practice_repository.png)

ローカルにチェックアウト