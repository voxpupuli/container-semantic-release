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
    parserOpts:
      # detect JIRA issues in merge commits
      issuePrefixes: ['SUP', 'BUG', 'FEATURE']
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
    changelogFile: 'CHANGELOG.md'

  - path: '@semantic-release/git'
    assets:
      - 'CHANGELOG.md'

  - path: '@intuit/semantic-release-slack'
    fullReleaseNotes: true

verifyConditions:
  - '@semantic-release/changelog'
  - '@semantic-release/git'
```

### Update metadata.json of a Puppet module

This refers to the example config from above...

```yaml
plugins:
#...
  - path: 'semantic-release-replace-plugin'
    replacements:
      - files: ['metadata.json']
        from: "\"version\": \".*\""
        to: "\"version\": \"${nextRelease.version}\""
        countMatches: true
        results:
          - file: 'metadata.json'
            hasChanged: true
            numMatches: 1
            numReplacements: 1
#...
  - path: '@semantic-release/git'
    assets:
      # ...
      - 'metadata.json'
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
  stage: Release🚀
  image:
    name: ghcr.io/voxpupuli/semantic-release:latest
    entrypoint: [""]  # overwrite entrypoint - gitlab-ci quirk
    pull_policy:
      - always
      - if-not-present
  interruptible: true
  script:
    - 'for f in /docker-entrypoint.d/*.sh; do echo "INFO: Running ${f}";"${f}";done'
    - semantic-release
  rules:
    - if: $CI_COMMIT_BRANCH == "master"
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_COMMIT_BRANCH == "production"
```

### Running as local user

When using git+ssh remotes, you might encounter issues accessing your git server.

This solution launches your local ssh-agent (if it's not already running) and adds your default SSH key. It then sets an environment variable within the container to locate the ssh-agent socket and bind-mounts the socket from your host system into the container, enabling secure access to your git server.

```shell
eval $(ssh-agent)
ssh-add

docker run -it --rm \
  -e "SSH_AUTH_SOCK=/ssh-agent" \
  -v $SSH_AUTH_SOCK:/ssh-agent \
  -v $PWD:/data \
  ghcr.io/voxpupuli/semantic-release:latest
```

### Notifing RocketChat

There is a helper script in the container, which can send some data over curl to RocketChat.

#### .releaserc.yaml

```yaml
---
# ...
plugins:
# ...
  - path: '@semantic-release/exec'
    publishCmd: "/scripts/notify-rocketchat.sh v${nextRelease.version} '--insecure' 'debug'"
# ...

```


#### .gitlab-ci.yml

```yaml
---
release:
# ...
  variables:
    ROCKETCHAT_NOTIFY_TOKEN: "Some hidden CI Variable to not expose the token"
    ROCKETCHAT_EMOJI: ":tada:"
    ROCKETCHAT_MESSAGE_TEXT: "A new tag for the project $CI_PROJECT_NAME was created by $GITLAB_USER_NAME"
    ROCKETCHAT_HOOK_URL: "https://rocketchat.example.com/hooks/$ROCKETCHAT_NOTIFY_TOKEN"
    ROCKETCHAT_TAG_URL: "${CI_PROJECT_URL}/-/tags"
# ...
```

```
15:07 🤖 bot-account:
A new tag for the project dummy-module was created by Jon Doe.
Release v1.2.3
```
