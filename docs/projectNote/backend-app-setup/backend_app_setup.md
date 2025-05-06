![実務レベル環境構築ハンズオン](https://storage.googleapis.com/zenn-user-upload/6db148f9e68d-20250507.png)

こんにちは、フリーランスエンジニアのたいち（[@taichi_hack_we](https://x.com/taichi_hack_we)）です。
この記事では**Kotlin** / **Spring Boot** / **PostgreSQL**によるシンプルなバックエンドAPIを作成し、**Docker**でコンテナ化するまでの手順をまとめました。

[続編](https://zenn.dev/taichi_hack_we/articles/b2e94844c6b08d)では、ここで作ったAPIを**AWS**にデプロイします。

Githubリポジトリは以下です。

https://github.com/taichi-web-engineer/aws-practice

# Git、Githubの設定
## aws-practiceリポジトリ作成
[Github](https://github.com/)でaws-practiceという名前でリポジトリを作成します。

![Githubでaws-practiceのリポジトリ作成](https://storage.googleapis.com/zenn-user-upload/06f7d623a811-20250507.png)

リポジトリを作成したら`git clone`でローカルリポジトリを作成しましょう。
```bash
git clone git@github.com:taichi-web-engineer/aws-practice.git
```

以降、`aws-practice`ディレクトリを**ルート**と呼びます。

##  不要ファイルをcommit対象から除外する`.gitignore`
### グローバルな`gitignore`
macOSの一時ファイルなどを全リポジトリのcommit対象から除外するため、`~/.config/git/ignore`を作成します。
ベースは[GitHub公式macOS用テンプレート](https://github.com/github/gitignore/blob/main/Global/macOS.gitignore)です。
さらに環境変数管理ツールdirenv(詳細は後で解説)の設定ファイル`.envrc`を`ignore`に追加します。

```bash:~/.config/git/ignore
# General
.DS_Store
.AppleDouble
.LSOverride
Icon[]

# Thumbnails
._*

# Files that might appear in the root of a volume
.DocumentRevisions-V100
.fseventsd
.Spotlight-V100
.TemporaryItems
.Trashes
.VolumeIcon.icns
.com.apple.timemachine.donotpresent

# Directories potentially created on remote AFP share
.AppleDB
.AppleDesktop
Network Trash Folder
Temporary Items
.apdisk

.envrc
```

### リポジトリ用`.gitignore`
ルート直下に`.gitignore`置きます。
`.gitignore`の内容はChatGPT o3に以下のプロンプトで考えてもらいました。

```
kotlin、spring bootのwebアプリ用の.gitignoreのベストプラクティスを教えて
```

[ChatGPTとの会話内容](https://chatgpt.com/share/680cc02e-36bc-8009-a7c5-9cdb609d75dd)

o3の回答を調整した最終版が以下です。グローバルなgitignoreで設定しているもの、不要なものは削除しています。

https://github.com/taichi-web-engineer/aws-practice/blob/main/.gitignore

# Kotlin、Spring Boot環境構築
## Spring Initializrでプロジェクト作成
[Spring Initializr](https://start.spring.io/#!type=gradle-project-kotlin&language=kotlin&platformVersion=3.4.5&packaging=jar&jvmVersion=21&groupId=com.awsPracticeTaichi&artifactId=api&name=api&description=API%20project%20with%20Spring%20Boot&packageName=com.awsPracticeTaichi.api&dependencies=web,data-jpa,postgresql)にアクセスし、以下設定でZIPをダウンロードしてルートに展開します。

![Spring Initializrの設定](https://storage.googleapis.com/zenn-user-upload/0d9710801301-20250507.png)

`Gradle - Kotlin`を選ぶ理由は私が他のGroovyやMavenを使ったことがないためです。実務でもGradleがよく使われている印象です。

Spring Boot、Javaのバージョンは最新のLTS(安定)バージョンを選びます。

Project Metadataの概要は以下のとおりです。

- Group：ドメインを逆にしたものを設定する。パッケージ名などで使われる
- Artifact：プロジェクト自体のディレクトリ名などで使われる

GroupはAWSで取得するドメインをもとに設定します。私は`aws-practice-taichi.com`というドメインを取得するので、`com.awsPracticeTaichi`としました。パッケージ名に「-」は使えないのでキャメルケースにしています。

DependenciesにはAPI、DB設定に必要なツールを追加しました。

## 依存ライブラリを最新のLTS(安定版)に更新
Kotlin、Spring Bootなど、各ライブラリのバージョンは`api/build.gradle.kts`で以下のように定義されています。
```kotlin
plugins {
	kotlin("jvm") version "1.9.25"
	kotlin("plugin.spring") version "1.9.25"
	id("org.springframework.boot") version "3.4.5"
	id("io.spring.dependency-management") version "1.1.7"
	kotlin("plugin.jpa") version "1.9.25"
}

group = "com.awsPracticeTaichi"
version = "0.0.1-SNAPSHOT"

java {
	toolchain {
		languageVersion = JavaLanguageVersion.of(21)
	}
}

repositories {
	mavenCentral()
}

dependencies {
	implementation("org.springframework.boot:spring-boot-starter-data-jpa")
	implementation("org.springframework.boot:spring-boot-starter-web")
	implementation("com.fasterxml.jackson.module:jackson-module-kotlin")
	implementation("org.jetbrains.kotlin:kotlin-reflect")
	runtimeOnly("org.postgresql:postgresql")
	testImplementation("org.springframework.boot:spring-boot-starter-test")
	testImplementation("org.jetbrains.kotlin:kotlin-test-junit5")
	testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

kotlin {
	compilerOptions {
		freeCompilerArgs.addAll("-Xjsr305=strict")
	}
}

allOpen {
	annotation("jakarta.persistence.Entity")
	annotation("jakarta.persistence.MappedSuperclass")
	annotation("jakarta.persistence.Embeddable")
}

tasks.withType<Test> {
	useJUnitPlatform()
}
```

依存ライブラリのバージョンは最新のLTSを使いたいので、Gensparkのスーパーエージェントに以下のプロンプトで修正してもらいましょう。

:::message
ChatGPTとGensparkは両方に同じプロンプトを投げ、より良い回答を採用しています
:::

```
以下のbuild.gradle.ktsの設定内容を最新のLTSバージョンに更新したいです

{build.gradle.ktsの全文をコピペ}
```

[Gensparkとのやりとり](https://www.genspark.ai/agents?id=7101cdc5-e583-4460-a838-3dcf928f6c5b)

`build.gradle.kts`の完成版は以下です。

https://github.com/taichi-web-engineer/aws-practice/blob/main/api/build.gradle.kts

[detekt](https://detekt.dev/)という静的解析ツールを使いたいので、jvmのバージョン変更や関連ライブラリ追加をしています。(詳細は後ほど解説)

`build.gradle.kts`を完成版と同じ内容に更新したら「すべてのGradle プロジェクトを同期」ボタンで`build.gradle.kts`のライブラリやプラグインを反映できます。

![すべてのGradle プロジェクトを同期](https://storage.googleapis.com/zenn-user-upload/4629d774771a-20250504.png)

Gradle同期時に`The detekt plugin found some problems`という警告が出ますが、これはdetektの設定が未完了なため。あとで設定するので無視してOKです。

![detektの警告](https://storage.googleapis.com/zenn-user-upload/a1acb381de79-20250504.png)

## Docker & DB環境構築
### Docker環境構築
Dockerを使うため、[Docker Desktop](https://www.docker.com/ja-jp/products/docker-desktop/)か[OrbStack](https://orbstack.dev/)をインストールします。Appleシリコン製のMacユーザーはOrbStackを圧倒的におすすめします。OrbStackはDocker Desktopと同じ機能で動作が軽くて速いからです。詳細は以下の記事を参照してください。

https://qiita.com/shota0616/items/5b5b74d72272627e0f5a

`docker help`コマンドが使えればDocker環境構築完了です。

```bash
docker help

Usage:  docker [OPTIONS] COMMAND

A self-sufficient runtime for containers

Common Commands:
  run         Create and run a new container from an image
  exec        Execute a command in a running container
  ps          List containers
  build       Build an image from a Dockerfile
  pull        Download an image from a registry
  ...
```

Docker Desktopを使っている方は以降のOrbStackをDocker Desktopに読み替えてください。

### データベース環境構築
[私のaws-practiceのGithubリポジトリ](https://github.com/taichi-web-engineer/aws-practice)から`aws-practice/ops`、`aws-practice/Makefile`を取得して自身の`aws-practice`の同じパスに配置してください。

`aws-practice/ops/db-migrator/README.md`をもとにDB環境構築をします。知り合いのエンジニアが作成したGoのDBマイグレーションツールが使いやすいので活用しています。

https://github.com/taichi-web-engineer/aws-practice/blob/main/ops/db-migrator/README.md

`README.md`に書いてあるとおり`brew install golang-migrate`で`golang-migrate`をインストールします。あとは`ops/db-migrator`ディレクトリで以下コマンドを順に実行すればDBにテーブルが作成されます。

```bash
docker compose up -d
go run main.go
```

テーブルを作成したら以下コマンドでテーブルにデータを入れます。

```bash
make restore DB=aws_practice
```

`make restore`コマンドの実態は[ops/db-migrator/Makefile](https://github.com/taichi-web-engineer/aws-practice/blob/9824a750e1d08516d84459d495eaecc733cb1e6d/ops/db-migrator/Makefile#L32)で定義している以下です。

```makefile
# dumpファイルからseedデータを復元する。
# e.g.
# make restore DB=aws_practice
restore: .check-db
	docker compose exec -T db psql -U postgres -d $(DB) -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
	docker compose exec -T db psql -U postgres -d $(DB) < db/$(DB)/dump.sql
```

Makefileは複数のコマンドや変数を使ってコマンドを簡略化するコマンド集のようなものです。`make restore`コマンドの実態は引数のチェックをしたあと2つの`docker compose exec`コマンドでDBに`dump.sql`のseedデータを登録するコマンドというわけです。

データを入れたら、[TablePlus](https://tableplus.com/)などのDBクライアントツールで`aws_test`テーブルのテストデータを確認できればOKです。

![テストデータ](https://storage.googleapis.com/zenn-user-upload/8ca4cb81d0b4-20250507.png)

DBのDockerコンテナはマウントによるデータ永続化をしていません。Dockerコンテナを停止するとテストデータは削除されます。

永続化をしない理由はDBマイグレーションでDB環境をすぐ復元できるためです。復元のためのテストデータは以下のディレクトリで管理しています。

https://github.com/taichi-web-engineer/aws-practice/tree/main/ops/db-migrator/db/aws_practice

### DBの立ち上げ & データ復元手順
DBを使うときは以下手順でDBを立ち上げてデータを復元できます。

 1. Docker Desktop or OrbStackの起動
 2. ops/db-migratorへcd
 3. docker compose up -d
 4. go run main.go
 5. make restore DB=aws_practice

## direnvで環境変数の設定
DBのパスワードなど、Gitにコミットしたくないセキュアな情報は環境変数で管理しましょう。[direnv](https://direnv.net/)というディレクトリごとに環境変数を設定できるツールを使います。

https://zenn.dev/masuda1112/articles/2024-11-29-direnv

direnvをインストールしたらルートから`api`ディレクトリに移動します。

```bash
cd api
```

環境変数を管理するファイルである`.envrc`を作成してエディタで開きます。私はVSCodeを使っています。

```bash
code .envrc
```

`.envrc`に以下のDB接続情報を追記して保存しましょう。ローカルのDocker環境のDBなので、接続情報は[aws-practice/ops/db-migrator/compose.yaml](https://github.com/taichi-web-engineer/aws-practice/blob/main/ops/db-migrator/compose.yaml)で設定しているデフォルト値を使います。

```
export DB_HOST=localhost
export DB_NAME=aws_practice
export DB_PASSWORD=postgres
export DB_PORT=5432
export DB_USERNAME=postgres
```

`.envrc`を保存したら`direnv allow .`を実行すれば`direnv`で環境変数を使う準備完了です。

## Spring BootアプリのDB接続設定
Spring BootアプリのDB接続情報は`api/src/main/resources/application.properties`で設定します。ただ、`application.properties`よりもyaml形式の`application.yml`の方が階層構造で設定がわかりやすいのでリネームしてください。

リネーム後、`application.yml`に以下の内容をコピペします。

https://github.com/taichi-web-engineer/aws-practice/blob/main/api/src/main/resources/application.yml

`application.yml`の以下の部分で`.envrc`の環境変数を利用しています。

```yml
  datasource:
    url: jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
    driver-class-name: org.postgresql.Driver
```

次に、IntelliJで`.envrc`の環境変数を使うために実行/デバッグ構成の環境変数の設定で`.envrc`を選択して適用しましょう。

![IntelliJの環境変数設定](https://storage.googleapis.com/zenn-user-upload/2a246344bb5e-20250504.png)

# Spring Bootアプリを動かしてみる
ここまでの設定がうまくいっているかSpring Bootアプリを起動して確かめましょう。

## Spring Bootアプリの起動確認
IntelliJの右上のApiApplicationの起動ボタンで起動できます。([DBを立ち上げて](#db%E3%81%AE%E7%AB%8B%E3%81%A1%E4%B8%8A%E3%81%92-%26-%E3%83%87%E3%83%BC%E3%82%BF%E5%BE%A9%E5%85%83%E6%89%8B%E9%A0%86)いないと起動失敗します)

![IntelliJのアプリ起動ボタン](https://storage.googleapis.com/zenn-user-upload/5379a3c1034d-20250504.png)

コンソールに以下のような表示が出れば起動成功です。

```log
2025-04-28T20:26:31.303+09:00  INFO 9834 --- [api] [           main] c.a.api.ApiApplicationKt                 : Started ApiApplicationKt in 0.953 seconds (process running for 1.137)
```

この状態でブラウザから`localhost:8080`へアクセスしても、ルートのエンドポイントが未実装なので404エラーになります。

![404エラーページ](https://storage.googleapis.com/zenn-user-upload/aa4fc9382d98-20250507.png)

## ルートのエンドポイントでDBのデータを返すようにする
以下4つのファイルを[私のaws-practiceリポジトリ](https://github.com/taichi-web-engineer/aws-practice)と同じパスに配置してください。各ファイルの`package com.awsPracticeTaichi`の部分は[Spring InitializrのProject MetadataのGroup](#spring-initializr%E3%81%A7%E3%83%97%E3%83%AD%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88%E4%BD%9C%E6%88%90)で自身で設定した値に書き換えましょう。

- [api/presentation/ApiController.kt](https://github.com/taichi-web-engineer/aws-practice/blob/main/api/src/main/kotlin/com/awsPracticeTaichi/api/presentation/ApiController.kt)
- [api/usecase/ApiUsecase.kt](https://github.com/taichi-web-engineer/aws-practice/blob/main/api/src/main/kotlin/com/awsPracticeTaichi/api/usecase/ApiUsecase.kt)
- [api/infra/repository/db/AwsTestRepository.kt](https://github.com/taichi-web-engineer/aws-practice/blob/main/api/src/main/kotlin/com/awsPracticeTaichi/api/infra/repository/db/AwsTestRepository.kt)
- [api/infra/entity/db/AwsTest.kt](https://github.com/taichi-web-engineer/aws-practice/blob/main/api/src/main/kotlin/com/awsPracticeTaichi/api/infra/entity/db/AwsTest.kt)

処理の流れをざっと説明すると、
 
 1. `ApiController`でルートのエンドポイントへのアクセスを受ける
 2. `ApiUsecase`で`AwsTestRepository`を使ってDBのデータを取得して`AwsTest`のインスタンスに入れ、`AwsTest.testText`を取得
 3. `ApiController`で取得した`testTest`をListで返す

といった感じ。

## APIでDBデータを取得して返す動作確認
アプリを再起動して`localhost:8080`へアクセスすると、APIがDBから取得したデータを返していることが確認できます。

![APIのデータ取得成功画面](https://storage.googleapis.com/zenn-user-upload/19cea3d42b7e-20250507.png)

「プリティ　プリント」という表示は私が使っている[Braveブラウザ](https://brave.com/ja/)が出しているもので、アプリとは無関係です。

# 静的解析ツールdetekt導入
Kotlin、Spring Boot環境では[detekt](https://detekt.dev/)という静的解析ツール(LinterかつFormatter)をよく使います。
![detektの使用例](https://storage.googleapis.com/zenn-user-upload/f19ee4ce6d30-20250504.png)

detektを導入すると整っていないコードはこのようにハイライトされます。整っていないコードとは、

- 不要なスペース、改行
- importの順番
- 未使用の変数
- マジックナンバー

などです。整っていないコードを整形するフォーマット機能もあります。

## 初期設定
detektの設定は公式Docsの[Quick Start with Gradle](https://detekt.dev/docs/intro#quick-start-with-gradle)にそってやります。

といっても`build.gradle.kts`のdetekt設定はすでに反映済なので、`aws-practice/api`のディレクトリで公式Docsの手順通り`gradlew detektGenerateConfig`で`config/detekt/detekt.yml`を生成しましょう。

```bash
cd {path to aws-practice}/api

gradlew detektGenerateConfig
```

`zsh: command not found: gradlew`というエラーが出ます。公式Docsの通りにやるとエラーになる罠ですw

gradlewコマンドの実態は`api/gradlew`にあるシェルスクリプトファイルです。なのでこれを実行するためには`./gradlew detektGenerateConfig`が正しいコマンドになります。コマンドが実行できると`api/config/detekt/detekt.yml`が生成され、detekt設定は完了です。

## IntelliJにdetektプラグインをインストール
ここまでの手順で、コマンドによるdetektの静的解析を実行できるようになりました。ですが、IntelliJでdetektのハイライトを出すためにはdetektプラグインが必要です。IntelliJの設定からdetektプラグインをインストールして適用しましょう。

![IntelliJのdetektプラグイン](https://storage.googleapis.com/zenn-user-upload/4a8ea5d55c44-20250504.png)

プラグインを適用するとdetektの設定ができるようになります。以下のように設定し、Configuration fileとして`config/detekt/detekt.yml`を追加して適用します。

![detektプラグインの設定](https://storage.googleapis.com/zenn-user-upload/33e84faef6ca-20250504.png)

## detektの動作確認
適当なファイルで適当にスペースを入れ、以下のようにdetektのハイライトが出ればOKです。

![detektの使用例](https://storage.googleapis.com/zenn-user-upload/f19ee4ce6d30-20250504.png)

apiディレクトリで`./gradlew detekt`を実行するとプロジェクトの全ファイルを対象にdetektの静的解析が行われます。ですが、今の状態で実行すると`ApiApplication.kt`で`SpreadOperator`というdetektのチェックに引っかかります。

```
> Task :detekt FAILED
/Users/taichi1/Desktop/application/aws-practice/api/src/main/kotlin/com/awsPracticeTaichi/api/ApiApplication.kt:10:35: In most cases using a spread operator causes a full copy of the array to be created before calling a method. This may result in a performance penalty. [SpreadOperator]
```

エラーの概要は「スプレッド演算子(*)は内部的には配列のフルコピーをするのでパフォーマンスに悪影響かもしれないよ」といった感じです。

```kotlin:ApiApplication.kt
fun main(args: Array<String>) {
    runApplication<ApiApplication>(*args)
}
```

ただ、スプレッド演算子を使っている上記コードはKotlin、Spring Bootアプリの土台となるもので手を加えることはほぼありません。なので`SpreadOperator`のdetektチェックを無効にしましょう。`detekt.yml`の`SpreadOperator`を`active: false`にします。

```yml:detekt.yml
  SpreadOperator:
    active: false
```

ついでに`detekt.yml`の`output-reports:`の部分で

```
スキーマ検証: タイプに互換性がありません。
必須: array。 実際: null.
```

というwarningが出るので、空配列を設定してwarningを回避します。

```yml:detekt.yml
  exclude: []
  # - 'TxtOutputReport'
  # - 'XmlOutputReport'
  # - 'HtmlOutputReport'
  # - 'MdOutputReport'
  # - 'SarifOutputReport'
```

そして再度`./gradlew detekt`を実行すると`BUILD SUCCESSFUL`になるはずです。

`./gradlew detekt --auto-correct`を実行すると、プロジェクトの全ファイルをdetektがフォーマットします。適当なktファイルに不要なスペースを入れて保存し、`./gradlew detekt --auto-correct`を実行すれば動作確認ができます。

ファイル単位でのdetekt実行は右クリックで可能です。

![ファイル単位のdetekt実行](https://storage.googleapis.com/zenn-user-upload/b9ce70a673fa-20250507.png =640x)

detektのフォーマットはよく使うので、私は`Ctrl + A`のショートカットを割り当てています。

![detektのフォーマットのショートカット設定](https://storage.googleapis.com/zenn-user-upload/759fef48fe81-20250504.png)

保存時に自動フォーマットが理想ですが、別途プラグインやツールが必要で面倒なため、私はショートカットを使っています。

## detektの静的解析をcommit時に自動実行する
commit時にdetektを実行すれば、フォーマットの整っていないコードがcommitされることはありません。
[aws-practice/.githooks/pre-commit](https://github.com/taichi-web-engineer/aws-practice/blob/main/.githooks/pre-commit)に、commit時にdetektのチェックおよびフォーマットをかけるスクリプトがあるので、自身の`aws-practice`へコピーしてください。

スクリプトの内容は[detekt公式Docs](https://detekt.dev/docs/gettingstarted/git-pre-commit-hook/)をもとにしています。
このスクリプトがcommit時に自動実行されるよう設定をしましょう。

ルートで`git config core.hooksPath .githooks`を実行し、gitにスクリプトの場所を教えます。次に`chmod +x .githooks/pre-commit`でスクリプトの実行権限を付与して準備完了です。

適当なファイルに不要なスペースを入れてcommitすると、以下のようなエラーになってdetektのフォーマットが実行されます。

```bash
git commit -m "pre-commitテスト"
Running detekt check...

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':detekt'.
> Analysis failed with 1 weighted issues.

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.

BUILD FAILED in 436ms

> Task :detekt FAILED
/Users/taichi1/Desktop/application/aws-practice/api/src/main/kotlin/com/awsPracticeTaichi/api/usecase/ApiUsecase.kt:9:56: Unnecessary long whitespace [NoMultipleSpaces]

1 actionable task: 1 executed
***********************************************
                 detekt failed                 
 Please fix the above issues before committing 
***********************************************
```

# アプリをDockerコンテナ化
## Dockerfile作成
AWSのFargateでKotlin、Spring Bootアプリを動かすにはDockerコンテナ化する必要があります。Gensparnkスーパーエージェントで`Dockerfile`を作成しましょう。

「kotlin、springbootアプリケーションをDockerコンテナ化するDockerfileのベストプラクティスを教えてください」というプロンプトでひな型を作成します。

[Gensparkとのやりとり](https://www.genspark.ai/agents?id=ce6d61d7-b89a-4f95-9da7-ddf923eeb6d5)

そしてAIとのやりとりを踏まえて修正、コメントを追記した完成版`Dockerfile`が以下です。`aws-practice/api/Dockerfile`として配置してください。

https://github.com/taichi-web-engineer/aws-practice/blob/main/api/Dockerfile

またDockerイメージに不要なファイルが含まれないよう`aws-practice/api/.dockerignore`を作成します。`.dockerignore`も[ChatGPT o3に作成依頼](https://chatgpt.com/share/6815e84e-9f50-8009-8e2a-1aad835bfd52)をしました。

https://github.com/taichi-web-engineer/aws-practice/blob/main/api/.dockerignore

## Dockerコンテナでアプリを動かしてみる
Dockerコンテナで正常にアプリが動くか動作確認をしましょう。まず`aws-practice/api`ディレクトへ移動します。

```bash
cd api
```

OrbStackを起動したあと、Dockerイメージをビルドします。

```bash
docker build -t aws-practice-api .
```

Dockerでアプリを起動する前に[DBを立ち上げて](#db%E3%81%AE%E7%AB%8B%E3%81%A1%E4%B8%8A%E3%81%92-%26-%E3%83%87%E3%83%BC%E3%82%BF%E5%BE%A9%E5%85%83%E6%89%8B%E9%A0%86)おかないと起動が失敗します。DB立ち上げ後、以下コマンドでDockerコンテナを起動しましょう。

```bash
docker run -p 8080:8080 \
  -e DB_HOST=host.docker.internal \
  -e DB_USERNAME=postgres \
  -e DB_PASSWORD=postgres \
aws-practice-api
```

`host.docker.internal`はホストマシンのIPアドレスに名前解決されます。IntelliJでのアプリ起動時は`DB_HOST=localhost`で環境変数を設定しました。

ですが今回アプリはDockerコンテナで動いているので、`DB_HOST=localhost`とするとアプリのDockerコンテナ自身を参照してDBにつなげません。なのでホストマシンで動いているDBに接続するため、`DB_HOST=host.docker.internal`としてホストマシンに名前解決をしているわけです。

Dockerコンテナ起動後、ブラウザで`localhost:8080`へアクセスするとIntelliJのアプリ起動時と同じ画面が表示されます。

![APIのデータ取得成功画面](https://storage.googleapis.com/zenn-user-upload/19cea3d42b7e-20250507.png)

Dockerコンテナのアプリ停止は`Ctrl + C`です。

# Dockerイメージのセキュリティ対策
## Trivyで脆弱性チェック
アプリのDockerイメージに脆弱性があると攻撃される危険があります。[Trivy](https://trivy.dev/latest/)というOSSでイメージの脆弱性チェックをしましょう。

まずTrivyをインストールします。

```bash
brew install trivy
```

`trivy image イメージ名`のコマンドでイメージの脆弱性チェックができます。

```bash
trivy image aws-practice-api
```

以下の表示が出れば脆弱性は0件です。

```bash
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)
```

## 脆弱性チェックをGithub Actionsで定期実行する
定期的に手動で脆弱性チェックをするのはしんどいです。なのでGithub Actionsでtrivyを週1回0時に定期実行するようにしましょう。

今回もChatGPT o3にやり方を聞きました。

```
プロジェクトのDockerコンテナのTrivyによる脆弱性スキャンをGitHub Actionsで毎週日曜0時に実行したい
```

完成したGithub Actionsのymlファイルが以下です。これを`aws-practice/.github/workflows/trivy-weekly-scan.yml`に配置してコミットします。

https://github.com/taichi-web-engineer/aws-practice/blob/main/.github/workflows/trivy-weekly-scan.yml

これで毎週日曜0時にSpring BootアプリのDockerイメージにtrivyによる脆弱性チェックが実行されます。

手動実行で動作確認もできます。自身のリポジトリのActionsタブ → Weekly Trivy Scan → Run workflowをクリックすれば手動実行可能です。

![Github Actionsの脆弱性チェック手動実行](https://storage.googleapis.com/zenn-user-upload/98feefa4e979-20250507.png)

脆弱性チェックの結果はActionsタブのトップページに表示されます。緑のチェックは脆弱性なし、赤のバツは脆弱性ありです。

![脆弱性チェック結果](https://storage.googleapis.com/zenn-user-upload/abc1efe7496c-20250507.png)

またワークフローの詳細画面からチェック結果詳細をテキストファイルでダウンロードもできます。

![脆弱性チェック結果のダウンロード](https://storage.googleapis.com/zenn-user-upload/b495db13776a-20250507.png)

脆弱性ありのときはメールやslack通知を飛ばしたいですが、それは後ほど対応します。

# 次回：AWS環境構築
次回は今回作成したバックエンドAPIを使ったAWS環境構築します。お楽しみに！

https://zenn.dev/taichi_hack_we/articles/b2e94844c6b08d