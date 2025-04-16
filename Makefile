SHELL := /bin/bash -o pipefail
AWS_REGION ?= ap-northeast-1
# AWS_ACCOUNT_ID デフォルトはCloud Pratica stg accountになっているので、自身のstgのAWSアカウントIDを指定する
AWS_ACCOUNT_ID ?= 043309350350
AWS_PROFILE ?= cp-terraform-stg

IMAGE_REPOSITORY_BASE := ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
# ECR_NAMEが指定されていない場合は、コマンド実行時のcurrent directory名をECR_NAMEとして使用する
ECR_NAME ?= $(shell basename $(CURDIR))
IMAGE_REPOSITORY_URI := ${IMAGE_REPOSITORY_BASE}/${ECR_NAME}-${ENV}
# imageタグを管理するParameter Store名
PARAMETER_STORE_NAME_IMAGE_TAG := image-tag-${ECR_NAME}-${ENV}

# Gitのコミットハッシュを取得
GIT_COMMIT_HASH ?= $(shell git rev-parse --short HEAD)

# ECRにログインする
# e.g. make docker-login ENV=stg
docker-login: .check-env .check-ecr-name
	aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${IMAGE_REPOSITORY_URI}

# Dockerイメージをビルドする
# e.g. make build-image ENV=stg
build-image: .check-env .check-ecr-name
	docker build --platform=linux/amd64 -t ${IMAGE_REPOSITORY_URI}:${GIT_COMMIT_HASH} -f Dockerfile .

# DockerイメージをECRにpushする
# e.g. make push-image ENV=stg
push-image: .check-env .check-ecr-name
	docker push ${IMAGE_REPOSITORY_URI}:${GIT_COMMIT_HASH}

# DockerイメージをビルドしてECRにpushする
# e.g. make release-image ENV=stg
release-image: docker-login build-image push-image

# Parameter Storeで管理しているimageタグを更新する
update-image-tag: .check-env
	aws ssm put-parameter --name ${PARAMETER_STORE_NAME_IMAGE_TAG} --value ${GIT_COMMIT_HASH} --type String --overwrite > /dev/null

# ECR ARNを取得する
# e.g. make get-ecr-arn ENV=stg
get-ecr-arn: .check-env
	@echo ${IMAGE_REPOSITORY_URI}:$(shell aws ssm get-parameter --name ${PARAMETER_STORE_NAME_IMAGE_TAG} --query Parameter.Value --output text)

.PHONY: docker-login build-image push-image release-image update-image-tag

.check-env:
ifndef ENV
	$(error ENV is required.)
endif

.check-ecr-name:
ifndef ECR_NAME
	$(error ECR_NAME is required.)
endif
