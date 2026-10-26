---
id: post-linking-dynamic-in-dev-static-in-release
title: 개발은 dynamic, 배포는 static으로 할 수 있을까?
slug: dynamic-in-dev-static-in-release
date: 2026-10-26
summary: (작성 예정) 누구를 위한 글이고 무엇을 얻는지 한 줄로
tags: iOS, Xcode, Tuist
draft: true
series: teardown
topic: linking
part: 3
# 발행할 때: draft를 false로, date를 발행일로, summary를 채웁니다. id는 발행 후 바꾸지 않습니다.
# 도입부 메모: 첫 세 문장: 개발 중엔 빠른 빌드와 Preview, 배포할 땐 빠른 앱 시작 — 둘 다 가질 수 있는지
---

## dynamic과 static은 각각 무엇을 빠르게 할까

- dynamic: 링크 시간, SwiftUI Preview (실행 성능 이점이 아님)
- static: 앱 시작 시간 (dyld가 불러올 라이브러리 수)

## 구성별로 링킹을 바꾸기

- Tuist에서 Debug/Release에 따라 product 타입을 바꾸는 방법

## Xcode의 mergeable libraries

- 개발 중엔 dynamic처럼, 배포 땐 static처럼 합쳐지는 원리

## 직접 재본 결과

- 빌드 시간과 앱 시작 시간 비교

## 더 읽을거리
