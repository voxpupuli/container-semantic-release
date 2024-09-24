# Voxpupuli Semantic Release Container

[![CI](https://github.com/voxpupuli/container-semantic-release/actions/workflows/ci.yaml/badge.svg)](https://github.com/voxpupuli/container-semantic-release/actions/workflows/ci.yaml)
[![License](https://img.shields.io/github/license/voxpupuli/container-semantic-release.svg)](https://github.com/voxpupuli/container-semantic-release/blob/main/LICENSE)
[![Sponsored by betadots GmbH](https://img.shields.io/badge/Sponsored%20by-betadots%20GmbH-blue.svg)](https://www.betadots.de)

## Introduction

This container can be used to create project releases. It encapsulates [semantic-release](https://semantic-release.gitbook.io/semantic-release) and all necessary plugins. See [package.json](package.json) for details. This is a npm application running in an alpine container.

## Usage

### Example `.releaserc.yaml` for a Gitlab project

```yaml
---
branches:
 - 'main'
 - 'master'
 - 'production'

ci: true
debug: true
dryRun: false
tagFormat: '${version}'
preset: 'conventionalcommits'

gitlabUrl: 'https://gitlab.example.com'
gitlabApiPathPrefix: '/api/v4'

plugins:
  - path: '@semantic-release/commit-analyzer'
    releaseRules:
      - { breaking: true, release: major }
      - { type: build,    release: patch }
      - { type: chore,    release: false }
      - { type: ci,       release: false }
      - { type: dep,      release: patch }
      - { type: docs,     release: patch }
      - { type: feat,     release: minor }
      - { type: fix,      release: patch }
      - { type: perf,     release: patch }
      - { type: refactor, release: false }
      - { type: revert,   release: patch }
      - { type: test,     release: false }

  - path: '@semantic-release/release-notes-generator'
    writerOpts:
      groupBy: 'type'
      commitGroupsSort: 'title'
      commitsSort: 'header'
    linkCompare: true
    linkReferences: true
    parserOpts:
      # detect JIRA issues in merge commits
      issuePrefixes: ['SUP', 'BUG', 'FEATURE']
      mergePattern: "^Merge branch '(.*)' into (.*)$"
      mergeCorrespondence: ['branch_src', 'branch_dst']
      noteKeywords: ["BREAKING CHANGE", "BREAKING CHANGES", "BREAKING"]
    presetConfig:
      issueUrlFormat: "https://jira.example.com/browse/{{prefix}}{{id}}"
      types:
        - { type: 'build',    section: '👷 Build' }
        - { type: 'chore',    section: '🧹 Chorses' }
        - { type: 'ci',       section: '🚦 CI/CD' }
        - { type: 'dep',      section: '👾 Dependencies' }
        - { type: 'docs',     section: '📚 Docs' }
        - { type: 'feat',     section: '🚀 Features' }
        - { type: 'fix',      section: '🛠️ Fixes' }
        - { type: 'perf',     section: '⏩ Performance' }
        - { type: 'refactor', section: '🔨 Refactor' }
        - { type: 'revert',   section: '🙅‍♂️ Reverts' }
        - { type: 'test',     section: '🚥 Tests' }

  - path: '@semantic-release/changelog'
  - path: '@semantic-release/git'

verifyConditions:
  - '@semantic-release/changelog'
  - '@semantic-release/git'
```

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
