# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A static tech blog written in Swift. `BlogBuilder` turns Markdown posts in `Content/Posts` into a static site at `.build/site`, and GitHub Actions deploys it to GitHub Pages at `https://devminseok.github.io/tech-blog-swift/`. There is no app server or database. Comments and reactions come from giscus (GitHub Discussions). The docs, user-facing strings, and error messages are in Korean. `BUILD_PLAN.md` holds the full design rationale.

## Commands

The toolchain is pinned to Swift 6.3.3 (`.swift-version`); CI uses the `swift:6.3.3-noble` container.

```bash
swift test                                              # all tests (XCTest)
swift test --filter BlogSiteTests                       # one test target
swift test --filter SiteGeneratorTests/testGeneratesCompleteProjectPagesSite  # one test

swift run BlogBuilder                                   # production build (base path /tech-blog-swift)
swift run BlogBuilder --base-url http://127.0.0.1:8000 --base-path ""   # local preview build
swift run BlogBuilder --include-drafts                  # include drafts and future-dated posts
python3 -m http.server 8000 --directory .build/site     # serve the preview
```

giscus is enabled only when both `GISCUS_REPO_ID` and `GISCUS_CATEGORY_ID` are set (`GISCUS_CATEGORY` is optional). If they are missing, the build still succeeds and shows a placeholder.

CI (`.github/workflows/pages.yml`) runs `swift test` and a production build on every PR. Pushes to `main` also deploy. Never commit `.build/site`.

## Architecture

The pipeline is Model → Router → View → Builder. Each layer is its own SwiftPM target, and dependencies point one way only:

- **BlogCore** — the `BlogPost` model, a hand-written front matter parser, `ContentLoader`, and series support (`SeriesLoader` reads `Content/Series`; `SeriesCatalog` groups published posts into series → topic → part and hides empty topics/series). Content validation is strict: invalid fields, duplicate slugs or ids, missing cover images, and so on throw `ContentError` and fail the build rather than warn. In production builds, drafts and posts dated in the future are filtered out here.
- **BlogRouter** — the `SiteRoute` enum (parsed with swift-url-routing) and `SiteConfiguration` (baseURL, basePath, site metadata, giscus). All URLs must come from `configuration.path(for:)`, `url(for:)`, or `assetPath(_:)`, so that `basePath` gets applied. Each route has both a `sitePath` (its public URL) and an `outputPath` (a file such as `posts/<slug>/index.html`).
- **BlogViews** — HTML pages built with the pointfreeco swift-html DSL. `PageLayout` wraps every page and owns the SEO/Open Graph metadata. `MarkdownRenderer` is a custom `MarkupWalker` that produces safe HTML: raw HTML blocks and inline HTML get escaped, not passed through, and root-relative links get `basePath` added.
- **BlogSite** — `SiteGenerator` loads posts, renders every page, the Atom feed, the sitemap, and robots.txt into a temporary staging directory, and copies in `Public/`. It then runs `LinkValidator` over the generated HTML. The staging directory replaces the output directory only if no internal link is broken and none points outside `basePath`. The generator refuses to write output anywhere except under the repo root or the temp directory.
- **BlogBuilder** — the CLI. It parses arguments and environment variables (no argument-parser dependency) and calls `SiteGenerator`.

Tests match the targets. `BlogSnapshotTests` checks rendered HTML strings (escaping, basePath links, the giscus `data-term`). `BlogSiteTests` builds a full site in a temp directory with a non-empty basePath.

## Content conventions

Each post is one Markdown file in `Content/Posts` with front matter (`id`, `title`, `slug`, `date` as yyyy-MM-dd, `summary`, `tags`, `draft`, optional `coverImage`). See README.md for the template.

- `id` is the permanent giscus mapping key (`data-mapping="specific"`). Never change it once the post is published.
- `slug` may only contain lowercase letters, digits, and single hyphens.
- `coverImage` must be a root-relative path to a file that exists under `Public/`.
- Series are defined in `Content/Series/<series-slug>/_series.md`. Each topic is another `.md` file in that directory, with `status: ongoing|completed`. A post joins a topic with `series`, `topic`, and `part` (all three or none). Parts are ordered by `part`, not by date. Unknown series or topics, and duplicate parts, fail the build.

## Notes

- `pointfreeco-main/` is a local, gitignored copy of the pointfreeco site source, kept for reference. It is not part of this package, so don't edit it or import from it.
- Any new link or asset must work under both an empty basePath and `/tech-blog-swift`. Tests cover both cases.
