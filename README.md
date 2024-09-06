# Voxpupuli Semantic Release Container

[![CI](https://github.com/voxpupuli/container-semantic-release/actions/workflows/ci.yaml/badge.svg)](https://github.com/voxpupuli/container-semantic-release/actions/workflows/ci.yaml)
[![License](https://img.shields.io/github/license/voxpupuli/container-semantic-release.svg)](https://github.com/voxpupuli/container-semantic-release/blob/main/LICENSE)
[![Sponsored by betadots GmbH](https://img.shields.io/badge/Sponsored%20by-betadots%20GmbH-blue.svg)](https://www.betadots.de)

## Introduction

This container can be used to create project releases. It encapsulates semantic-release and all necessary plugins.

## Development

### How to generate package.json and package-lock.json

```shell
npm install \
  semantic-release \
  @bobvanderlinden/semantic-release-pull-request-analyzer \
  @semantic-release/changelog \
  @semantic-release/commit-analyzer \
  @semantic-release/exec \
  @semantic-release/git \
  @semantic-release/github \
  @semantic-release/gitlab \
  @semantic-release/release-notes-generator \
  semantic-release-commits-lint \
  semantic-release-github-milestones \
  semantic-release-github-pullrequest \
  semantic-release-jira-notes \
  semantic-release-license \
  semantic-release-major-tag \
  semantic-release-pypi \
  semantic-release-replace-plugin
```
