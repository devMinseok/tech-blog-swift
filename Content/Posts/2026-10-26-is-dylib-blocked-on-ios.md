---
id: post-linking-is-dylib-blocked-on-ios
title: iOS에서 dylib는 정말 막혀 있을까?
slug: is-dylib-blocked-on-ios
date: 2026-10-26
summary: (작성 예정) 누구를 위한 글이고 무엇을 얻는지 한 줄로
tags: iOS, Xcode, Tuist, Mach-O
draft: true
series: teardown
topic: linking
part: 2
# 발행할 때: draft를 false로, date를 발행일로, summary를 채웁니다. id는 발행 후 바꾸지 않습니다.
# 도입부 메모: 첫 세 문장: Tuist에서 dynamic library로 바꿨더니 import부터 깨진 상황 → "iOS는 dylib를 못 쓴다"는 답 → 정말인지 직접 확인
---

## 문제 상황

- Tuist에서 product를 `.dynamicLibrary`로 바꾼 설정
- 재현한 정확한 오류 메시지

## 흔히 듣는 답: "보안 때문에 막혀 있다"

- 코드 서명, 샌드박스, App Store 정책이라는 설명 요약

## 실험 1: Xcode 템플릿은 무엇을 허용할까

- iOS와 macOS의 Library 템플릿 비교 (스크린샷)

## 실험 2: SPM의 dynamic 라이브러리는 iOS에서 될까

- `type: .dynamic` 결과물을 `file`, `otool -L`로 확인

## 실험 3: 실행할 때 dyld는 무엇을 불러올까

- 시뮬레이터에서 `DYLD_PRINT_LIBRARIES=1`
- `codesign -dv`로 번들 안 서명 확인
- 참고: iOS 12.2 이전 앱의 `libswiftCore.dylib`

## 그래서 막혀 있는 건 무엇인가

- 실험으로 확인한 것만 결론으로

## 더 읽을거리
