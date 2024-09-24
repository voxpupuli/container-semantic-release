# Voxpupuli Semantic Release Container

[![CI](https://github.com/voxpupuli/container-semantic-release/actions/workflows/ci.yaml/badge.svg)](https://github.com/voxpupuli/container-semantic-release/actions/workflows/ci.yaml)
[![License](https://img.shields.io/github/license/voxpupuli/container-semantic-release.svg)](https://github.com/voxpupuli/container-semantic-release/blob/main/LICENSE)
[![Sponsored by betadots GmbH](https://img.shields.io/badge/Sponsored%20by-betadots%20GmbH-blue.svg)](https://www.betadots.de)

## Introduction

This container can be used to create project releases. It encapsulates [semantic-release](https://semantic-release.gitbook.io/semantic-release) and all necessary plugins. See [package.json](package.json) for details. This is a npm application running in an alpine container.

## Usage

### Gitlab

This is a example to use this container in Gitlab.
It requires, that you have:

- A `.releaserc` file, written in YAML or JSON, with optional extensions: `.yaml` / `.yml` / `.json` / `.js` / `.cjs` / `.mjs`
- A `release.config.(js|cjs|.mjs)` file that exports an object
- A `release` key in the project's `package.json` file

```yaml
---
release:
  stage: release
  image:
    name: ghcr.io/voxpupuli/semantic-release:latest
    entrypoint: [""]  # overwrite entrypoint - gitlab-ci quirk
  script:
    - semantic-release
  only:
    - master
    - main
    - production
```
