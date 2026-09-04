# tech-blog-swift

Swift로 작성한 정적 기술 블로그입니다. Markdown 글을 빌드 시점에 HTML로 변환하고 GitHub Actions가 결과물을 GitHub Pages에 배포합니다. 별도 애플리케이션 서버나 데이터베이스는 사용하지 않습니다.

## 요구 환경

- Swift 6.3.3 (`.swift-version`에 고정)
- macOS 또는 Swift가 설치된 Linux
- 로컬 미리보기를 위한 Python 3(선택)

## 빌드와 확인

```bash
swift test
swift run BlogBuilder --base-url http://127.0.0.1:8000 --base-path ""
python3 -m http.server 8000 --directory .build/site
```

브라우저에서 `http://127.0.0.1:8000`을 엽니다. 운영용 기본 빌드는 GitHub Pages 프로젝트 주소인 `https://devminseok.github.io/tech-blog-swift/`에 맞춰 링크를 생성합니다.

```bash
swift run BlogBuilder
```

## 글 작성

`Content/Posts`에 Markdown 파일을 추가합니다.

```markdown
---
id: post-stable-identifier
title: 글 제목
slug: lowercase-slug
date: 2026-09-04
summary: 목록과 검색 결과에 표시할 한 줄 설명
tags: Swift, Testing
draft: false
coverImage: /images/posts/example.png
---

본문을 Markdown으로 작성합니다.
```

- `id`는 giscus Discussion을 연결하는 영구 키이므로 발행 후 바꾸지 않습니다.
- `slug`는 소문자 영문, 숫자와 하이픈만 사용합니다.
- `draft: true`와 미래 날짜 글은 운영 빌드에서 제외됩니다.
- 대표 이미지를 쓸 때는 `Public` 아래의 실제 파일 경로를 지정합니다.
- 초안을 포함한 로컬 빌드는 `swift run BlogBuilder --include-drafts`를 사용합니다.

## giscus 댓글과 반응

댓글과 좋아요 역할의 reaction은 GitHub Discussions 기반 giscus가 담당합니다.

1. 저장소 Settings에서 Discussions를 활성화합니다.
2. [giscus GitHub App](https://github.com/apps/giscus)을 이 저장소에 설치합니다.
3. [giscus.app](https://giscus.app/ko)에서 `devMinseok/tech-blog-swift`와 댓글용 카테고리를 선택합니다.
4. 표시된 repository ID와 category ID를 GitHub Actions repository secret으로 등록합니다.
   - `GISCUS_REPO_ID`
   - `GISCUS_CATEGORY_ID`
5. 기본값은 giscus 권장 방식에 맞춘 `Announcements` 카테고리입니다. 다른 카테고리를 쓸 때만 워크플로의 `GISCUS_CATEGORY`를 바꿉니다.

로컬에서도 같은 환경 변수를 지정하면 giscus 스크립트를 포함해 생성합니다. 값이 없을 때는 빌드를 실패시키지 않고 Discussions 안내 링크를 보여줍니다. 글 제목이나 URL이 바뀌어도 댓글 연결이 유지되도록 `data-mapping="specific"`과 글의 `id`를 사용합니다.

## GitHub Pages 배포

`.github/workflows/pages.yml`은 Pull Request에서 테스트와 생성 검증만 수행하고, `main` 브랜치 push에서는 Pages artifact를 배포합니다.

저장소에서 한 번 설정해야 합니다.

1. Settings → Pages → Build and deployment의 Source를 **GitHub Actions**로 선택합니다.
2. 위 giscus secret을 등록합니다.
3. `main`에 push한 뒤 Actions와 Pages 주소를 확인합니다.

생성 결과인 `.build/site`는 commit하지 않습니다. 문제가 생기면 정상 동작했던 commit을 revert하여 다시 배포합니다.

## 구조

```text
Content/Posts       Markdown 원문
Public              CSS, JavaScript, 이미지
Sources/BlogCore    콘텐츠 모델과 검증
Sources/BlogRouter  URL 및 출력 경로
Sources/BlogViews   HTML과 Markdown 렌더링
Sources/BlogSite    정적 생성, 피드, sitemap, 링크 검증
Sources/BlogBuilder CLI
Tests               핵심 기능과 생성 결과 검증
```

상세 설계와 단계별 운영 기준은 [BUILD_PLAN.md](BUILD_PLAN.md)를 참고하세요.
