---
# Cartouche v1
title: "swift-holons — Swift SDK for Organic Programming"
author:
  name: "B. ALTER"
created: 2026-02-12
revised: 2026-02-12
lang: en-US
access:
  humans: true
  agents: false
status: draft
---
# swift-holons

**Swift SDK for Organic Programming** — transport URI parsing, serve flag parsing,
and HOLON.md identity parsing.

## Features

- Transport URI surface:
  - `tcp://`
  - `unix://`
  - `stdio://`
  - `mem://`
  - `ws://`
  - `wss://`
- Standard CLI flag parsing (`--listen`, `--port`)
- HOLON.md frontmatter parser

## Package

```swift
.package(path: "../swift-holons")
```

## API

- `Transport.defaultURI`
- `Transport.scheme(_:)`
- `Transport.parse(_:)`
- `Transport.listen(_:)`
- `Serve.parseFlags(_:)`
- `Identity.parseHolon(_:)`

## Test

```bash
swift test
```
