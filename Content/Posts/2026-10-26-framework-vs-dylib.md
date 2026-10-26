---
id: post-linking-framework-vs-dylib
title: framework와 dylib는 뭐가 다를까?
slug: framework-vs-dylib
date: 2026-10-26
summary: (작성 예정) 누구를 위한 글이고 무엇을 얻는지 한 줄로
tags: iOS, Xcode, Mach-O
draft: true
series: teardown
topic: linking
part: 1
# 발행할 때: draft를 false로, date를 발행일로, summary를 채웁니다. id는 발행 후 바꾸지 않습니다.
# 도입부 메모: 첫 세 문장: 누구를 위한 글이고, 읽고 나면 무엇을 얻는지
---

## 라이브러리는 결국 Mach-O 파일이다

- Mach-O를 한 문장으로 정의
- `file`, `otool -hv`로 `.a` / `.dylib` / 실행 파일의 타입 확인

## .a는 오브젝트 파일 묶음이다

- static library의 정체: `ar -t`로 안을 열어보기

## framework는 dylib를 폴더로 감싼 것이다

- `Foo.framework/Foo`가 `MH_DYLIB`인지 확인
- Info.plist, 리소스, `Modules/`가 함께 있는 이유

## 그래서 무엇을 골라야 할까

- static/dynamic × library/framework 네 조합 정리

## 더 읽을거리
