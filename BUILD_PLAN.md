# Swift 기술 블로그 구축 계획서

## 1. 프로젝트 개요

Swift로 작성한 정적 사이트 생성기를 이용해 개인 기술 블로그를 구축한다. 콘텐츠 모델, 타입 안전한 라우팅, HTML 생성, 콘텐츠 검증과 테스트를 하나의 Swift Package로 구성한다.

운영 환경은 공개 GitHub 저장소의 GitHub Pages를 사용한다. Swift는 로컬과 GitHub Actions에서 Markdown을 HTML로 변환하는 빌드 도구로만 실행하고, Pages는 완성된 정적 파일을 제공한다. 좋아요와 댓글은 GitHub Discussions 기반의 giscus로 제공하므로 애플리케이션 서버, 데이터베이스, 사용자 인증 기능은 두지 않는다.

## 2. 핵심 목표

- 사이트의 콘텐츠 처리, 라우팅, HTML 생성을 Swift로 구현한다.
- Markdown 파일 하나만 추가하면 새 글을 발행할 수 있게 한다.
- 컴파일 타임 타입 검사와 빌드 시 콘텐츠 검증을 활용한다.
- 모바일과 데스크톱에서 읽기 편한 반응형 UI를 제공한다.
- RSS 또는 Atom, sitemap, Open Graph 등 기술 블로그의 기본 기능을 지원한다.
- 테스트와 단순하고 되돌릴 수 있는 배포가 가능한 구조를 만든다.
- 사이트 자체 계정이나 별도 데이터베이스 없이 좋아요와 댓글 참여 기능을 제공한다.
- 공개 저장소에서 제공되는 GitHub Pages와 GitHub Actions를 사용해 호스팅 비용 없이 운영한다.
- 기본 브랜치의 검증된 변경만 자동 배포한다.
- 서버 운영, 보안 패치, SSH 키와 인프라 자원 관리를 제거한다.

## 3. 설계 범위와 원칙

### 3.1 설계 원칙

다음 원칙에 따라 애플리케이션을 설계한다.

- `Model → Router → View → Builder`로 역할을 분리한다.
- Swift 타입으로 라우트를 정의하고 URL 파싱과 생성을 한곳에서 관리한다.
- `swift-html` 기반 DSL로 타입 안전한 HTML을 생성한다.
- Markdown 콘텐츠와 글 메타데이터를 `BlogPost` 모델로 통합한다.
- 동일한 글 데이터를 목록, 상세 화면, 피드, sitemap 생성에 재사용한다.
- 공통 레이아웃에서 SEO 메타데이터와 스타일을 관리한다.
- 라우트, HTML, 피드와 생성된 내부 링크에 대한 자동 테스트를 작성한다.
- 생성 결과가 웹 서버 없이 동작하도록 모든 페이지를 정적 파일로 출력한다.

### 3.2 MVP 기능 범위

초기 버전은 글을 발행하고 읽고 반응하는 경험과 안정적인 운영 환경에 집중한다.

- Markdown 기반 글 작성과 발행
- 글 목록, 상세, 태그, 소개 페이지
- giscus 기반 좋아요 reaction과 댓글
- RSS 또는 Atom, sitemap, robots
- 반응형 UI, 다크 모드, 접근성
- GitHub Actions 기반 정적 사이트 자동 배포
- Pages 배포 이력과 Git commit 기반 복구

### 3.3 모듈 분리 기준

- 데이터 모델과 콘텐츠 파싱은 `BlogCore`가 담당한다.
- URL 규칙과 양방향 변환은 `BlogRouter`가 담당한다.
- HTML 컴포넌트와 페이지는 `BlogViews`가 담당한다.
- 페이지, 피드, sitemap과 메타데이터 조립은 `BlogSite`가 담당한다.
- 전체 콘텐츠 검증과 정적 사이트 출력은 `BlogBuilder`가 담당한다.
- 로컬 미리보기는 생성 디렉터리를 제공하는 범용 정적 HTTP 서버를 사용한다.
- 하위 모듈은 상위 실행 타깃을 알지 못하도록 의존성 방향을 단방향으로 유지한다.

## 4. 기술 방향

### 4.1 권장 운영 방식

Swift Package는 `BlogBuilder` 실행 타깃을 제공한다. 이 도구가 콘텐츠 모델, 라우터와 뷰를 이용해 전체 사이트를 정적 파일로 생성하고 내부 링크를 검사한다. 운영 환경에는 Swift 런타임이 필요하지 않으며 GitHub Pages가 빌드 결과물을 직접 제공한다.

```text
Markdown 글
    ↓
ContentLoader
    ↓
[BlogPost]
    ↓
타입 안전한 SiteRoute
    ↓
Swift HTML View
    ↓
BlogBuilder: 콘텐츠 검증 및 정적 사이트 생성
    ↓
.build/site/

인터넷
    ↓ HTTPS :443
GitHub Pages
    └── Actions가 업로드한 정적 artifact 제공
```

### 4.2 기본 기술 구성

- Swift 6.3 및 Swift Package Manager
- `swift-html`: HTML 생성
- `swift-markdown`: Markdown 파싱
- `swift-url-routing`: 타입 안전한 라우팅
- 범용 정적 HTTP 서버: 로컬 미리보기 전용
- giscus와 GitHub Discussions: 좋아요 reaction, 댓글 작성과 관리
- CSS: 디자인 시스템과 반응형 화면
- Prism.js 또는 동등한 도구: 코드 구문 강조
- Swift Testing 또는 XCTest: 단위 및 스냅샷 테스트
- GitHub Pages: 정적 사이트 호스팅과 HTTPS
- GitHub Actions: 테스트, 콘텐츠 검증, 사이트 빌드와 자동 배포
- Pages artifact: 생성 결과물을 브랜치에 커밋하지 않고 배포하는 방식
- Git commit과 Pages 배포 이력: 변경 추적과 롤백

새 의존성의 구체적인 버전은 구현 시작 시 호환성을 확인한 후 `Package.resolved`에 고정한다.

## 5. 권장 디렉터리 구조

```text
tech-blog-swift/
├── Package.swift
├── Package.resolved
├── Sources/
│   ├── BlogCore/
│   │   ├── BlogPost.swift
│   │   ├── ContentLoader.swift
│   │   ├── FrontMatter.swift
│   │   └── Slug.swift
│   ├── BlogRouter/
│   │   └── SiteRoute.swift
│   ├── BlogViews/
│   │   ├── PageLayout.swift
│   │   ├── HomeView.swift
│   │   ├── PostListView.swift
│   │   ├── PostDetailView.swift
│   │   ├── TagView.swift
│   │   ├── AboutView.swift
│   │   └── Components/
│   ├── BlogSite/
│   │   ├── Site.swift
│   │   ├── Feed.swift
│   │   ├── Sitemap.swift
│   │   └── Metadata.swift
│   └── BlogBuilder/
│       └── main.swift
├── Content/
│   └── Posts/
│       ├── 2026-09-03-first-post.md
│       └── 2026-09-10-second-post.md
├── Public/
│   ├── styles/
│   │   └── site.css
│   ├── scripts/
│   │   └── prism.js
│   ├── fonts/
│   └── images/
├── Tests/
│   ├── BlogCoreTests/
│   ├── BlogRouterTests/
│   ├── BlogSiteTests/
│   └── BlogSnapshotTests/
└── .github/
    └── workflows/
        └── pages.yml
```

## 6. 콘텐츠 모델

### 6.1 BlogPost

초기 `BlogPost` 모델은 다음 정보를 가진다.

```swift
struct BlogPost: Identifiable, Sendable {
  let id: String
  let title: String
  let slug: String
  let publishedAt: Date
  let summary: String
  let tags: [String]
  let isDraft: Bool
  let coverImage: String?
  let content: String
}
```

필요해지면 수정일, 시리즈, 작성자, 대표 색상 등의 속성을 추가한다.

### 6.2 글 파일 형식

글과 메타데이터는 하나의 Markdown 파일로 관리한다.

```markdown
---
id: post-swift-sendable-001
title: Swift의 Sendable 이해하기
slug: understanding-swift-sendable
date: 2026-09-03
summary: Swift 동시성에서 Sendable이 필요한 이유를 알아봅니다.
tags: Swift, Concurrency
draft: false
coverImage: /images/posts/sendable.png
---

Swift 6에서는 데이터 경쟁을 컴파일 타임에 방지하기 위해...
```

### 6.3 빌드 시 콘텐츠 검증

`ContentLoader`는 다음 항목을 검사한다.

- 필수 필드 존재 여부
- 날짜 형식
- slug 형식과 중복 여부
- 태그 표기 정규화
- 대표 이미지 파일 존재 여부
- Markdown 파싱 가능 여부
- 내부 링크 유효성
- 운영 빌드에서 초안과 미래 날짜 글 제외

검증 실패는 경고로 숨기지 않고 빌드 실패로 처리한다.

## 7. 라우팅 계획

라우트는 문자열을 화면에 직접 작성하지 않고 enum으로 정의한다.

```swift
enum SiteRoute: Equatable {
  case home
  case posts
  case post(slug: String)
  case tag(String)
  case about
  case feed
  case sitemap
  case robots
  case notFound
}
```

초기 URL 구조는 다음과 같다.

| 경로 | 기능 |
|---|---|
| `/` | 소개와 최신 글 |
| `/posts/` | 전체 글 목록 |
| `/posts/:slug/` | 글 상세 |
| `/tags/:tag/` | 태그별 글 목록 |
| `/about/` | 프로필과 블로그 소개 |
| `/feed.xml` | RSS 또는 Atom 피드 |
| `/sitemap.xml` | 검색엔진용 사이트맵 |
| `/robots.txt` | 크롤러 정책 |
| `/404.html` | 찾을 수 없는 페이지 |

모든 URL은 `SiteRoute`를 통해 생성한다. 각 라우트는 `/posts/example/index.html`처럼 정적 호스팅에 맞는 출력 경로로 변환한다.

현재 저장소는 프로젝트 Pages이므로 초기 공개 주소는 `https://devminseok.github.io/tech-blog-swift/`를 기준으로 한다. 빌더는 출력 파일 경로와 공개 URL을 분리하고 다음 설정을 입력받는다.

- `baseURL`: `https://devminseok.github.io`
- `basePath`: `/tech-blog-swift`

내부 링크, CSS, JavaScript, 이미지, canonical URL, Open Graph URL, 피드와 sitemap에는 `basePath`를 빠짐없이 적용한다. 로컬 개발의 빈 base path와 GitHub Pages의 하위 경로를 모두 테스트한다. 향후 사용자 지정 도메인을 적용할 때는 `baseURL`과 `basePath`만 변경하고 라우트 구현은 바꾸지 않는다.

## 8. 화면 및 디자인 계획

### 8.1 공통 레이아웃

- 사이트 로고 또는 텍스트 로고
- 글 목록, 태그, 소개 메뉴
- 현재 페이지 표시
- 최대 본문 폭 제한
- 푸터의 GitHub, 이메일, RSS 링크
- 시스템 설정을 따르는 다크 모드
- 키보드 탐색과 명확한 포커스 표시

### 8.2 홈 화면

- 블로그와 작성자에 대한 짧은 소개
- 최신 글 5개
- 주요 태그
- 전체 글 보기와 RSS 구독 링크

### 8.3 글 목록 화면

- 발행일 기준 최신순 정렬
- 제목, 요약, 날짜, 태그 표시
- 모바일에서 읽기 쉬운 단일 열 구성
- 글이 많아지면 페이지네이션 추가

### 8.4 글 상세 화면

- 제목, 요약, 발행일, 태그
- 예상 읽기 시간
- Markdown 본문
- Swift 코드 구문 강조
- giscus 좋아요 reaction과 댓글 영역
- 이전 글과 다음 글
- GitHub에서 오탈자 수정 링크
- 공유용 Open Graph 이미지와 메타데이터

### 8.5 접근성 기준

- 의미에 맞는 HTML 태그 사용
- 모든 이미지에 적절한 대체 텍스트 제공
- 본문과 배경의 충분한 색상 대비 확보
- 키보드만으로 모든 링크에 접근 가능
- `prefers-reduced-motion` 지원
- 장식 목적 요소가 스크린 리더에 노출되지 않도록 처리

## 9. 좋아요와 댓글 설계

### 9.1 적용 방식

좋아요와 댓글을 모두 giscus로 제공한다. giscus가 각 글을 GitHub Discussion과 연결하며 댓글과 reaction 데이터도 GitHub Discussions에 저장한다. 블로그 사이트는 참여 데이터를 저장하는 API나 데이터베이스를 가지지 않는다.

| 기능 | 적용 방식 |
|---|---|
| 좋아요 | giscus의 GitHub Discussions reaction |
| 댓글 | giscus의 GitHub Discussions comment |
| 데이터 저장 | `devMinseok/tech-blog-swift` 저장소의 Discussions |
| 관리 | GitHub Discussions에서 숨김, 삭제, 잠금, 신고 대응 |

### 9.2 저장소와 글 연결

- 현재 공개 저장소 `devMinseok/tech-blog-swift`에서 Discussions를 활성화한다.
- giscus GitHub App은 현재 저장소에만 설치한다.
- 댓글용 Discussion 카테고리를 만들어 다른 대화와 분리한다.
- 각 글의 변경되지 않는 post slug 또는 ID를 Discussion과 일대일로 연결한다.
- 제목은 바뀔 수 있으므로 글 제목을 연결 키로 사용하지 않는다.
- 글 slug를 변경해야 할 때는 기존 Discussion 연결을 유지할 수 있도록 별도 고정 ID를 사용한다.

### 9.3 화면 동작

- 글 본문 아래에 giscus reaction과 댓글 UI를 함께 배치한다.
- giscus reaction을 활성화하고 별도의 좋아요 버튼은 만들지 않는다.
- 사이트의 라이트·다크 모드가 바뀌면 giscus iframe 테마도 함께 전환한다.
- giscus 스크립트는 글 상세 페이지에서만 지연 로딩한다.
- 로딩 중에는 레이아웃이 움직이지 않도록 댓글 영역의 최소 높이를 확보한다.
- giscus 로딩에 실패하면 해당 글의 GitHub Discussion으로 이동하는 링크를 표시한다.

### 9.4 접근과 보안

- 댓글과 reaction 열람에는 별도 계정이 필요하지 않다.
- 작성과 reaction 참여는 giscus가 제공하는 GitHub OAuth 흐름을 사용한다.
- 블로그 사이트는 GitHub access token이나 참여자의 계정 정보를 전달받거나 저장하지 않는다.
- 현재 저장소의 `giscus.json`에는 운영 도메인과 허용할 로컬 개발 origin만 등록한다.
- giscus App 권한은 현재 저장소로 제한한다.
- 댓글 숨김, 삭제, 잠금과 신고 대응은 GitHub Discussions에서 수행한다.

### 9.5 제약사항

- GitHub 계정이 없는 독자는 댓글과 reaction을 작성할 수 없다.
- reaction은 독립적인 하트 버튼이 아니라 GitHub Discussions의 반응 UI로 표시된다.
- giscus 또는 GitHub 장애 시 참여 UI를 사용할 수 있지만 본문 열람에는 영향이 없어야 한다.
- 댓글 UI의 디자인과 기능은 giscus가 제공하는 범위 안에서 조정한다.

## 10. SEO와 배포 필수 기능

각 페이지의 공통 레이아웃에서 다음 메타데이터를 생성한다.

- `<title>`
- meta description
- canonical URL
- Open Graph title, description, image, URL
- Twitter card
- RSS 또는 Atom 자동 발견 링크
- 올바른 viewport와 charset

추가로 다음 파일을 빌드 시 자동 생성한다.

- `feed.xml`
- `sitemap.xml`
- `robots.txt`
- `404.html`

## 11. GitHub Pages 운영 아키텍처

### 11.1 전체 구성

공개 저장소 `devMinseok/tech-blog-swift`의 GitHub Pages를 운영 환경으로 사용한다. 애플리케이션 서버와 별도 인프라는 두지 않는다.

```text
Markdown과 Swift 소스
  ↓ main push
GitHub Actions
  ├── swift build
  ├── swift test
  ├── BlogBuilder 정적 사이트 생성
  ├── 콘텐츠와 내부 링크 검증
  └── Pages artifact 업로드
        ↓
GitHub Pages
  └── https://devminseok.github.io/tech-blog-swift/

브라우저의 참여 영역
  ↓
giscus → GitHub Discussions의 reaction과 댓글
```

### 11.2 Pages 저장소 설정

- GitHub 저장소의 `Settings → Pages → Build and deployment → Source`를 `GitHub Actions`로 설정한다.
- 배포 환경 이름은 GitHub의 기본값인 `github-pages`를 사용한다.
- Pages 배포 권한은 워크플로에만 부여하고 개인 액세스 토큰을 저장하지 않는다.
- `main` 브랜치만 운영 환경에 배포하도록 제한한다.
- Pull Request에서는 테스트와 빌드만 수행하고 운영 배포는 하지 않는다.
- Actions가 만든 `.build/site`를 artifact로 올리며 생성 파일을 `main`이나 별도 배포 브랜치에 커밋하지 않는다.

### 11.3 GitHub Actions 워크플로

`.github/workflows/pages.yml`은 `build`와 `deploy` 두 작업으로 나눈다.

#### build 작업

1. 저장소를 checkout한다.
2. 프로젝트가 고정한 Swift 버전의 Linux 환경을 준비한다.
3. `swift build`와 `swift test`를 실행한다.
4. 운영 `baseURL`과 `basePath`를 전달해 `BlogBuilder`를 실행한다.
5. 생성 파일, 내부 링크, sitemap과 피드를 검사한다.
6. `actions/upload-pages-artifact`로 `.build/site`를 업로드한다.

#### deploy 작업

1. `build` 작업 성공 후에만 실행한다.
2. `pages: write`와 `id-token: write` 최소 권한을 사용한다.
3. `github-pages` environment를 사용한다.
4. `actions/deploy-pages`로 artifact를 배포한다.
5. 출력된 Pages URL에 대해 홈, 최신 글, 피드 smoke test를 수행한다.

동시 배포는 concurrency group으로 하나만 허용한다. 새 `main` 배포가 시작되면 진행 중인 이전 배포를 취소해 오래된 결과가 나중에 게시되지 않게 한다.

### 11.4 프로젝트 Pages 경로 처리

초기 운영 주소에는 저장소 이름이 하위 경로로 포함된다.

```text
https://devminseok.github.io/tech-blog-swift/
```

따라서 빌더는 다음 두 개념을 분리한다.

| 값 | 초기 설정 | 용도 |
|---|---|---|
| `baseURL` | `https://devminseok.github.io` | canonical, Open Graph, sitemap의 절대 URL |
| `basePath` | `/tech-blog-swift` | 내부 링크와 정적 리소스 경로 |

`/styles/site.css` 같은 루트 기준 경로를 직접 작성하지 않는다. 모든 사이트 내부 URL은 설정과 `SiteRoute`를 통해 생성한다. 사용자 지정 도메인을 도입하면 `baseURL`을 새 도메인으로, `basePath`를 빈 문자열로 바꾼다.

### 11.5 사용자 지정 도메인과 HTTPS

- MVP는 무료 기본 주소로 먼저 공개한다.
- 사용자 지정 도메인은 선택 사항이며 도메인 구매 비용은 별도다.
- 도메인을 연결할 때 GitHub Pages 설정과 DNS 제공자의 레코드를 함께 변경한다.
- GitHub Pages의 `Enforce HTTPS`를 활성화한다.
- `CNAME` 파일이 필요하면 `BlogBuilder`의 출력에 포함해 배포마다 유지한다.
- 도메인 변경 전후에도 댓글 연결을 유지하도록 giscus는 URL 대신 변경되지 않는 post ID를 사용한다.

### 11.6 배포와 롤백

- `main` push를 새 글과 사이트 변경의 배포 트리거로 사용한다.
- 배포는 테스트, 콘텐츠 검증과 정적 생성에 모두 성공한 경우에만 진행한다.
- Git commit SHA와 GitHub Pages deployment 기록으로 배포 버전을 추적한다.
- 문제가 생기면 원인 commit을 되돌리거나 마지막 정상 commit을 다시 배포한다.
- 배포 실패는 기존에 게시된 정상 사이트에 영향을 주지 않아야 한다.
- workflow와 Actions 버전은 Dependabot 또는 정기 점검으로 갱신한다.

### 11.7 운영 확인

- GitHub Actions의 build와 deploy 작업 결과를 확인한다.
- 배포 후 홈, 최신 글, `feed.xml`, `sitemap.xml`과 `404.html`을 확인한다.
- Pages environment의 deployment history에서 운영 버전을 확인한다.
- 외부 상태 확인이 필요하면 무료 사용 가능한 모니터링 수단을 선택적으로 추가한다.
- 이미지 크기를 최적화하고 큰 동영상 파일은 저장소나 Pages에 직접 넣지 않는다.

글 원본과 코드는 Git 저장소, 댓글과 reaction은 GitHub Discussions가 복구 원본이 된다.

## 12. 테스트 전략

### 12.1 단위 테스트

- front matter 파싱
- slug 생성 및 검증
- 날짜 파싱
- 초안과 예약 글 필터링
- 태그 정규화와 집계
- 예상 읽기 시간 계산

### 12.2 라우팅 테스트

- 각 `SiteRoute`의 URL 생성 결과
- URL을 다시 파싱했을 때 원래 라우트와 일치하는지 확인
- 존재하지 않는 slug의 404 처리
- 특수문자가 포함된 태그 인코딩
- trailing slash 및 canonical redirect 처리

### 12.3 출력 테스트

- 홈, 목록, 상세 화면 HTML 스냅샷
- 모바일과 데스크톱 레이아웃 확인
- RSS 또는 Atom XML 구조
- sitemap URL 목록
- canonical URL과 Open Graph 태그
- 생성된 사이트 내부 링크 검사

### 12.4 정적 출력 및 배포 테스트

- Pages 기본 주소와 주요 페이지의 HTTP 200 응답
- giscus 저장소, 카테고리, 글 식별자 설정 렌더링
- giscus reaction 활성화 여부와 테마 전환
- 허용하지 않은 origin 차단 설정
- 빈 base path와 `/tech-blog-swift` base path에서 내부 링크와 정적 리소스 경로 확인
- GitHub Pages에서 CSS, JavaScript, 이미지의 content type 확인
- 운영 배포가 `main` 브랜치에서만 실행되는지 확인
- 빌드 실패 시 기존 Pages 배포가 유지되는지 확인
- 배포 후 홈, 최신 글, 피드 smoke test

### 12.5 CI 통과 조건

- `swift build` 성공
- `swift test` 성공
- 콘텐츠 검증 성공
- 정적 사이트 생성과 내부 링크 검사 성공
- 생성 디렉터리를 범용 정적 서버로 제공했을 때 smoke test 성공
- Pages artifact 업로드와 배포 성공

## 13. 구현 단계

### 1단계: 프로젝트 기반 구축

작업 내용:

- 루트에 Swift Package 생성
- 핵심 라이브러리와 `BlogBuilder` 실행 타깃 구성
- 기본 HTML 문서와 정적 파일 출력 구현
- `baseURL`과 `basePath` 설정 구현
- 공통 개발 명령 정리

완료 조건:

- `swift build`가 성공한다.
- `swift run BlogBuilder --output .build/site`가 성공한다.
- 범용 정적 서버로 `.build/site`를 열어 홈과 정적 리소스를 확인할 수 있다.

### 2단계: 콘텐츠 파이프라인

작업 내용:

- `BlogPost` 모델 구현
- front matter와 Markdown 로더 구현
- 콘텐츠 유효성 검사 구현
- 샘플 글 2~3개 작성

완료 조건:

- Markdown 파일 하나를 추가하면 글 목록과 상세 화면에 반영된다.
- 잘못된 콘텐츠는 테스트 또는 빌드 단계에서 발견된다.

### 3단계: 라우터와 주요 페이지

작업 내용:

- `SiteRoute` 구현
- URL 파싱과 생성 구현
- 홈, 글 목록, 글 상세, 태그, 소개 페이지 구현
- 404와 canonical redirect 처리

완료 조건:

- 모든 초기 URL이 정상 렌더링된다.
- 화면의 내부 링크는 라우터를 통해 생성된다.

### 4단계: 디자인 시스템과 반응형 UI

작업 내용:

- 색상, 타이포그래피, 간격 토큰 정의
- 공통 헤더와 푸터 구현
- Markdown 본문 스타일 정의
- 코드 블록과 인라인 코드 스타일 적용
- 다크 모드, 모바일 화면, 접근성 개선

완료 조건:

- 모바일과 데스크톱에서 레이아웃이 깨지지 않는다.
- 긴 글과 긴 코드도 가독성을 유지한다.
- 키보드 탐색과 색상 대비 검사를 통과한다.

### 5단계: SEO와 피드

작업 내용:

- 페이지별 메타데이터 생성
- RSS 또는 Atom 생성
- sitemap과 robots 생성
- canonical URL 설정
- favicon과 소셜 공유 이미지 적용

완료 조건:

- 글 URL을 공유했을 때 제목, 설명, 이미지가 표시될 수 있다.
- 피드 리더에서 새 글 목록을 구독할 수 있다.
- 검색엔진이 sitemap을 읽을 수 있다.

### 6단계: 좋아요와 댓글

작업 내용:

- 현재 GitHub 저장소의 Discussions와 댓글 카테고리 구성
- giscus GitHub App 설치
- giscus reaction과 댓글 컴포넌트 구현
- 고정 post ID 기반 Discussion 연결
- 라이트·다크 테마 연동과 지연 로딩
- 현재 저장소의 Discussions와 origin 제한 구성
- giscus 실패 시 Discussion 직접 링크 제공

완료 조건:

- 글별 reaction과 댓글을 작성할 수 있다.
- reaction과 댓글이 올바른 GitHub Discussion에 저장된다.
- GitHub Discussions에서 댓글을 관리할 수 있다.
- 블로그 사이트가 참여자의 인증 정보에 접근하지 않는다.
- giscus가 실패해도 글 본문은 정상적으로 표시된다.

### 7단계: GitHub Pages 자동 배포

작업 내용:

- 저장소의 Pages source를 GitHub Actions로 설정
- `pages.yml`의 build와 deploy 작업 구성
- Swift 빌드, 테스트와 정적 생성 단계 연결
- Pages artifact 업로드와 배포 구성
- `main` 전용 배포와 최소 권한 설정

완료 조건:

- `main`에 반영된 정적 사이트가 GitHub Pages에 자동 배포된다.
- Pull Request는 검증만 수행하고 운영 사이트를 변경하지 않는다.
- 기본 Pages 주소에서 HTTPS로 사이트를 볼 수 있다.

### 8단계: 운영 검증과 출시 점검

작업 내용:

- Pages 운영 origin을 giscus 허용 목록에 반영
- 고정 post ID 기반 Discussion 연결 검증
- Pages의 홈, 글, 피드, sitemap과 404 smoke test
- 모바일과 데스크톱 레이아웃 최종 확인
- 접근성, 메타데이터와 공유 미리보기 확인
- 배포 실패와 이전 정상 commit 복구 절차 점검

완료 조건:

- 기본 Pages 주소에서 본문, reaction과 댓글이 정상 동작한다.
- Git commit을 통해 이전 정상 배포로 복구할 수 있다.
- 주요 페이지의 접근성, SEO와 반응형 화면 점검을 통과한다.

## 14. 개발 및 발행 흐름

### 로컬 개발

```bash
swift run BlogBuilder --output .build/site
```

생성 결과는 macOS에 설치된 범용 정적 HTTP 서버로 `.build/site`를 제공해 확인한다. 구체적인 미리보기 명령은 구현 시 선택한 도구에 맞춰 README에 고정한다.

글을 수정하면 `BlogBuilder`를 다시 실행하고 브라우저에서 결과를 확인한다. 필요하면 이후 단계에서 파일 변경 감지와 자동 재빌드를 추가한다.

### 새 글 발행

1. `Content/Posts`에 Markdown 파일을 추가한다.
2. 대표 이미지가 있으면 `Public/images/posts`에 추가한다.
3. 로컬 서버에서 글을 검토한다.
4. 콘텐츠 검증과 테스트를 실행한다.
5. `BlogBuilder`로 운영용 정적 사이트를 생성한다.
6. 변경 사항과 콘텐츠 원본을 Git 저장소에 반영한다.
7. GitHub Actions가 생성 결과를 Pages artifact로 업로드하고 배포한다.
8. Pages 기본 주소의 홈, 최신 글과 피드 smoke test가 성공하면 배포가 완료된다.

## 15. MVP 범위

첫 번째 배포의 목표는 다음과 같다.

- Swift 기반 정적 사이트 생성
- 샘플 기술 글 3개
- 홈, 글 목록, 글 상세, 태그, 소개 페이지
- 반응형 UI와 다크 모드
- Swift 코드 구문 강조
- RSS 또는 Atom
- sitemap, robots, 404
- 기본 SEO 및 Open Graph
- giscus 좋아요 reaction과 댓글
- 단위 테스트와 CI
- GitHub Pages 정적 호스팅
- `main` push 기반 GitHub Actions 자동 배포
- 기본 Pages 도메인의 HTTPS
- Git commit 기반 배포 복구

다음 기능은 MVP 이후로 미룬다.

- 전문 검색
- 방문자 분석
- 다국어 지원
- 시리즈 및 목차 기능
- GitHub 계정이 없는 독자를 위한 별도 참여 방식
- 별도 API 서버와 동적 백엔드 기능

## 16. 주요 위험과 대응

| 위험 | 대응 |
|---|---|
| 초기 구조가 과도하게 복잡해짐 | 책임이 명확한 핵심 라이브러리와 실행 타깃만 구성한다. |
| 글 발행 과정이 복잡해짐 | 글과 메타데이터를 Markdown 한 파일로 통합한다. |
| 잘못된 콘텐츠가 배포됨 | 빌드 전에 slug, 날짜, 이미지, 내부 링크를 검사한다. |
| 프로젝트 Pages의 하위 경로에서 링크가 깨짐 | `baseURL`과 `basePath`를 분리하고 로컬·운영 경로를 모두 테스트한다. |
| Actions의 Swift 환경과 로컬 버전이 다름 | 프로젝트 Swift 버전을 고정하고 동일 버전으로 CI를 실행한다. |
| Pages 빌드 또는 배포 실패 | build 성공 후에만 deploy하고 기존 정상 배포가 유지되는지 검증한다. |
| 잘못된 변경이 즉시 운영에 반영됨 | Pull Request 검증과 `main` 브랜치 보호 규칙을 사용한다. |
| giscus 또는 GitHub 장애 | 참여 영역만 실패하도록 격리하고 Discussion 직접 링크를 제공한다. |
| 글 URL 변경으로 Discussion 연결 손실 | URL이나 제목이 아닌 변경되지 않는 post ID를 연결 키로 사용한다. |
| GitHub 계정이 없는 독자의 참여 제한 | 운영 후 실제 요구를 확인해 별도 참여 방식 도입 여부를 판단한다. |
| 사용자 지정 HTTP 응답 헤더 제어가 제한됨 | 정적 사이트에 필요한 범위만 사용하고 가능한 보안 정책은 HTML과 리소스 설계에 반영한다. |
| 외부 CDN 장애로 코드 스타일이 깨짐 | CSS와 필요한 스크립트를 `Public`에 포함해 자체 제공한다. |

## 17. 최종 완료 기준

다음 조건을 모두 만족하면 첫 버전 구축이 완료된 것으로 본다.

- 저장소를 새로 clone한 뒤 문서의 명령만으로 빌드할 수 있다.
- Markdown 파일 추가만으로 새 글을 발행할 수 있다.
- 홈, 목록, 상세, 태그, 소개, 피드, sitemap, 404가 정상 동작한다.
- 모바일과 데스크톱에서 주요 페이지를 읽을 수 있다.
- 다크 모드와 기본 접근성을 지원한다.
- 글별 giscus reaction과 댓글을 읽고 작성할 수 있다.
- reaction과 댓글이 해당 글의 GitHub Discussion에 저장된다.
- 테스트와 콘텐츠 검증이 CI에서 자동 실행된다.
- 생성된 정적 파일이 Pages artifact로 자동 배포된다.
- `https://devminseok.github.io/tech-blog-swift/`가 HTTPS로 응답한다.
- 프로젝트 Pages 하위 경로에서 링크와 리소스가 정상 동작한다.
- Actions와 Pages deployment history에서 운영 상태를 확인할 수 있다.
- 문제가 있는 배포를 Git commit으로 되돌릴 수 있다.

## 18. 권장 첫 구현 단위

첫 구현은 다음 결과물을 만드는 것을 목표로 한다.

> 샘플 글 3개와 giscus reaction·댓글을 포함한 반응형 정적 기술 블로그를 Swift로 생성하고, GitHub Pages에 자동 배포한다.

작업은 아래 8개 단위로 나누어 진행한다.

1. Swift Package와 `BlogBuilder`
2. Markdown 콘텐츠 로더와 모델
3. 타입 안전 라우터와 기본 페이지
4. 디자인 시스템과 반응형 UI
5. RSS, SEO, sitemap, 코드 구문 강조
6. giscus reaction과 댓글
7. GitHub Actions와 GitHub Pages 배포
8. 운영 검증, 접근성·SEO 점검과 배포 복구

## 19. 공식 참고 문서

- [GitHub Pages 사이트 생성](https://docs.github.com/pages/getting-started-with-github-pages/creating-a-github-pages-site)
- [GitHub Pages 사용자 정의 워크플로](https://docs.github.com/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages)
- [GitHub Pages 게시 소스 설정](https://docs.github.com/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)
- [GitHub Pages 사용자 지정 도메인](https://docs.github.com/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site)
- [giscus 댓글 시스템](https://github.com/giscus/giscus)
- [GitHub Discussions 문서](https://docs.github.com/en/discussions)
