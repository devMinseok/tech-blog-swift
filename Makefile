SWIFT_SOURCES := Package.swift Sources Tests
PORT ?= 8000

.DEFAULT_GOAL := help
.PHONY: help preview build test format lint check clean

help: ## 사용할 수 있는 명령 보기
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  make %-8s %s\n", $$1, $$2}'

preview: ## 초안 포함 미리보기 (서버 + 브라우저 + 저장하면 다시 빌드, PORT=8000)
	@./scripts/preview.sh $(PORT)

build: ## 운영용 사이트 빌드 (.build/site, base path /tech-blog-swift)
	swift run BlogBuilder

test: ## 테스트 실행
	swift test

format: ## .swift-format으로 Swift 코드 정리
	swift format format --in-place --recursive --parallel $(SWIFT_SOURCES)

lint: ## 포맷 검사 (CI와 같은 조건)
	swift format lint --strict --recursive --parallel $(SWIFT_SOURCES)

check: lint test build ## 커밋 전 전체 점검 (lint + test + build)

clean: ## 생성된 사이트 삭제
	rm -rf .build/site
