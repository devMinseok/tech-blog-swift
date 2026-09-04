---
id: post-swift-static-site-001
title: Swift로 정적 사이트 생성기 만들기
slug: building-a-static-site-with-swift
date: 2026-08-10
summary: Swift Package Manager와 타입 안전한 HTML을 이용해 작은 정적 사이트 생성기의 뼈대를 만듭니다.
tags: Swift, Web, Architecture
draft: false
---

블로그에 서버가 꼭 필요한 것은 아니다. 글을 빌드할 때 HTML로 바꾸고 결과 파일만 배포하면 운영 과정은 훨씬 단순해진다. 이 블로그도 같은 원칙으로 구성했다.

## 생성 과정

정적 생성기는 다음 단계를 순서대로 수행한다.

1. `Content/Posts`의 Markdown을 읽는다.
2. front matter를 검증하고 `BlogPost`로 변환한다.
3. 라우터가 공개 URL과 출력 파일 경로를 계산한다.
4. `swift-html`로 페이지를 렌더링한다.
5. CSS, JavaScript, 이미지와 함께 `.build/site`에 저장한다.

```swift
let report = try SiteGenerator(configuration: .production).generate(
  repositoryRoot: repositoryRoot,
  outputDirectory: outputDirectory
)
print("Generated \(report.pageCount) pages")
```

## 왜 정적 파일인가

요청마다 Markdown을 파싱할 필요가 없고 데이터베이스도 없다. 배포 결과를 통째로 재현할 수 있으며 문제가 생겨도 이전 Git commit으로 돌아가기 쉽다.

프로젝트 구조는 [모든 글](/posts/)에서 이어서 살펴볼 수 있다.
