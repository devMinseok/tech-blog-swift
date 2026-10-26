# Minseok.dev

> AI 딸깍으로 개발이 너무 편해져버린 나머지 원초적인 걸 파보기로 했습니다.

Swift와 iOS 개발을 하며 배운 것을 기록하는 기술 블로그입니다.

**👉 https://devminseok.github.io/tech-blog-swift/**

## 무엇을 쓰나요

- **뜯어보기**: AI가 한 줄로 답해주는 것들의 밑바닥을 직접 파봅니다. 예를 들면 SPM이 패키지를 어떻게 빌드하는지, iOS에서 dynamic library가 정말 막혀 있는지 같은 것들입니다. 주제마다 여러 편으로 나뉘지만, 관심 있는 편만 골라 읽어도 되도록 씁니다.
- **단독 글**: Swift 동시성, 아키텍처, 그때그때 배운 것들.

## 이 블로그는 어떻게 만들어졌나요

블로그 자체도 "직접 만들어 보기"의 결과물입니다.

- **생성기**: Swift로 직접 만든 정적 사이트 생성기입니다. Markdown 글을 빌드할 때 HTML로 바꿉니다. 사용한 패키지는 [swift-markdown](https://github.com/swiftlang/swift-markdown), [swift-html](https://github.com/pointfreeco/swift-html), [swift-url-routing](https://github.com/pointfreeco/swift-url-routing)입니다.
- **배포**: GitHub Actions가 테스트하고 GitHub Pages로 배포합니다. 서버나 데이터베이스는 없습니다.
- **댓글과 반응**: GitHub Discussions 기반의 [giscus](https://giscus.app/ko)를 씁니다.

로컬에서 띄워 보려면 Swift 6.3 이상이 필요합니다. 아래 명령은 초안을 포함해 빌드하고, 브라우저를 열고, 파일을 저장할 때마다 다시 빌드합니다.

```bash
./scripts/preview.sh
```

## 라이선스

[LICENSE](LICENSE)를 참고하세요.
