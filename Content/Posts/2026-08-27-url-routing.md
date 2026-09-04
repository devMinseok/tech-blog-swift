---
id: post-type-safe-routing-001
title: 정적 블로그에도 라우터가 필요한 이유
slug: type-safe-routing-for-static-sites
date: 2026-08-27
summary: 링크 문자열을 흩어 놓지 않고 하나의 라우트 모델에서 URL과 출력 경로를 함께 관리하는 방법을 설명합니다.
tags: Swift, Web, Testing
draft: false
---

정적 사이트에서는 서버 요청을 처리하지 않으니 라우터가 필요 없어 보인다. 하지만 공개 URL과 디스크의 출력 경로는 계속 존재한다.

## 하나의 모델, 두 개의 표현

```swift
enum SiteRoute {
  case home
  case posts
  case post(slug: String)
  case tag(String)
}
```

`post(slug: "swift")`는 공개 경로 `/posts/swift/`와 출력 경로 `posts/swift/index.html`로 각각 변환된다. 링크를 생성하는 화면과 파일을 쓰는 생성기가 같은 모델을 쓰므로 둘 사이의 불일치를 테스트하기 쉽다.

## 프로젝트 Pages의 하위 경로

GitHub Pages 프로젝트 사이트는 저장소 이름이 URL에 포함된다. 개발 중에는 `/posts/`였던 링크가 운영에서는 `/tech-blog-swift/posts/`가 되어야 한다. 모든 링크를 라우터에서 만들면 `basePath`를 한 곳에서 적용할 수 있다.

```swift
let configuration = SiteConfiguration(
  baseURL: "https://example.github.io",
  basePath: "/tech-blog-swift"
)
```

생성 후에는 각 HTML의 내부 링크가 실제 파일을 가리키는지도 검사한다. 타입 안전성과 결과물 검증을 함께 써야 실수를 충분히 줄일 수 있다.
