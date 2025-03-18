# Voxpupuli Semantic Release Container

[![CI](https://github.com/voxpupuli/container-semantic-release/actions/workflows/ci.yaml/badge.svg)](https://github.com/voxpupuli/container-semantic-release/actions/workflows/ci.yaml)
[![License](https://img.shields.io/github/license/voxpupuli/container-semantic-release.svg)](https://github.com/voxpupuli/container-semantic-release/blob/main/LICENSE)
[![Sponsored by betadots GmbH](https://img.shields.io/badge/Sponsored%20by-betadots%20GmbH-blue.svg)](https://www.betadots.de)

## Introduction

This container can be used to create project releases.
It encapsulates [semantic-release](https://semantic-release.gitbook.io/semantic-release) and all necessary plugins.
See [package.json](package.json) for details. This is a npm application running in an alpine container.

## Usage

### Variables

The container has the following pre-defined environment variables:

| Variable                | Default |
|-------------------------|---------|
| CERT_JSON               | no default |
| PATH                    | `$PATH:/npm/node_modules/.bin` |
| NODE_OPTIONS            | `--use-openssl-ca` |
| ROCKETCHAT_EMOJI        | `:tada:` |
| ROCKETCHAT_MESSAGE_TEXT | `A new tag for the project ${CI_PROJECT_NAME} was created by ${CI_COMMIT_AUTHOR}.` |
| ROCKETCHAT_HOOK_URL     | `https://rocketchat.example.com/hooks/here_be_dragons` |
| ROCKETCHAT_TAGS_URL     | `${CI_PROJECT_URL}/-/tags` |
| MATTERMOST_EMOJI        | `:tada:` |
| MATTERMOST_MESSAGE_TEXT | `A new tag for the project ${CI_PROJECT_NAME} was created by ${CI_COMMIT_AUTHOR}.` |
| MATTERMOST_HOOK_URL     | `https://mattermost.example.com/hooks/here_be_dragons` |
| MATTERMOST_TAGS_URL     | `${CI_PROJECT_URL}/-/tags` |
| MATTERMOST_USERNAME     | `Semantic Release` |

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
        - { type: 'chore',    section: '🧹 Chores' }
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
    - /docker-entrypoint.sh
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

podman run -it --rm \
  -v $PWD:/data:Z \
  -v ~/.gitconfig:/etc/gitconfig:Z \
  -v ~/.ssh:/root/.ssh:Z \
  -v ${SSH_AUTH_SOCK}:${SSH_AUTH_SOCK} \
  -e SSH_AUTH_SOCK="${SSH_AUTH_SOCK}" \
  ghcr.io/voxpupuli/semantic-release:latest --dry-run --no-ci
```

### Work on a branch and create GitLab MR

Sometimes you are not allowed to run in the CI and maybe want to do all steps locally and just push and tag automatically from your machine.
This will configure SR to work only on a branch called `release`.
Though SR checks remote branches in the repository, the idea here is to get latest `main`, create `release` and push the empty branch.
When running SR locally it will then pick up from here.
It will co the commit and tag on your local and push it to the remote branch and open a MR for it.

`.releaserc`

```yaml
---
branches:
 - 'release'

# ...

plugins:
# ...
  - path: '@semantic-release/exec'
    publishCmd: "/scripts/gitlab-merge-request.sh \"${config.gitlabUrl}${config.gitlabApiPathPrefix}\" \"Release v${nextRelease.version}\" \"${process.env.PROJECT}\" \"${process.env.GL_TOKEN}\""
```

Terminal

```shell
cd dummy-project

git pull -r origin main
git switch -c release
git push origin HEAD

podman run -it --rm \
  -v $PWD:/data:Z \
  -v ~/.gitconfig:/etc/gitconfig:Z \
  -v ~/.ssh:/root/.ssh:Z \
  -e GL_TOKEN="token_MC_TOKEN_face" \
  -e PROJECT=$(basename $PWD) \
  ghcr.io/voxpupuli/semantic-release:latest --no-ci
```

### Notifying

#### RocketChat

There is a helper script in the container, which can send some data over curl to RocketChat.
You need a RocketChat hook link.

The script has the parameters `-V`, `-o` and `-d`.

- `-V` specifies the version which should be announced.
- `-o` can specify optional extra curl parameters. Like for example `--insecure`.
- `-d` turn on debug output.

The script accesses the environment variables:

- `ROCKETCHAT_EMOJI`
- `ROCKETCHAT_MESSAGE_TEXT`
- `ROCKETCHAT_TAGS_URL`
- `ROCKETCHAT_HOOK_URL`

#### Mattermost

There is a helper script in the container, which can send some data over curl to Mattermost.
You need a Mattermost hook link.

The script has the parameters `-V`, `-o` and `-d`.

- `-V` specifies the version which should be announced.
- `-o` can specify optional extra curl parameters. Like for example `--insecure`.
- `-d` turn on debug output.

The script accesses the environment variables:

- `MATTERMOST_EMOJI`
- `MATTERMOST_MESSAGE_TEXT`
- `MATTERMOST_TAGS_URL`
- `MATTERMOST_HOOK_URL`
- `MATTERMOST_USERNAME`

#### .releaserc.yaml

```yaml
---
# ...
plugins:
# Most people will choose between one of those two:
# ...
  - path: '@semantic-release/exec'
    publishCmd: "/scripts/notify-rocketchat.sh -V v${nextRelease.version} -o '--insecure' -d"
# ...
  - path: '@semantic-release/exec'
    publishCmd: "/scripts/notify-mattermost.sh -V v${nextRelease.version} -o '--insecure' -d"
# ...

```

#### .gitlab-ci.yml

```yaml
---
release:
# Most people will choose between one of those two:
# ...
  variables:
    ROCKETCHAT_NOTIFY_TOKEN: "Some hidden CI Variable to not expose the token"
    ROCKETCHAT_EMOJI: ":tada:"
    ROCKETCHAT_MESSAGE_TEXT: "A new tag for the project ${CI_PROJECT_NAME} was created by ${GITLAB_USER_NAME}"
    ROCKETCHAT_HOOK_URL: "https://rocketchat.example.com/hooks/${ROCKETCHAT_NOTIFY_TOKEN}"
    ROCKETCHAT_TAGS_URL: "${CI_PROJECT_URL}/-/tags"
# ...
    MATTERMOST_NOTIFY_TOKEN: "Some hidden CI Variable to not expose the token"
    MATTERMOST_EMOJI: ":tada:"
    MATTERMOST_MESSAGE_TEXT: "A new tag for the project ${CI_PROJECT_NAME} was created by ${GITLAB_USER_NAME}"
    MATTERMOST_HOOK_URL: "https://mattermost.example.com/hooks/${MATTERMOST_NOTIFY_TOKEN}"
    MATTERMOST_TAGS_URL: "${CI_PROJECT_URL}/-/tags"
    MATTERMOST_USERNAME: "Semantic Release [Bot]"
# ...
```

```text
15:07 🤖 bot-account:
A new tag for the project dummy-module was created by Jon Doe.
Release v1.2.3
```

### Adding additional certificates to the container

If you somehow need own certificates inside the container, you can add them over the entrypoint script.

For example: you want to run the a webhook on a target with your own ca certificates.
Export the `CERT_JSON` and the container will import it on runtime.
It is expected that the certificates are a json hash of PEM certificates.
It is preferable that the json is uglified into a onliner.

You may add this as a CI Variable for your runners on Github/Gitlab.

```json
{"certificates":{"root_ca":"-----BEGIN CERTIFICATE-----\n...","signing_ca":"-----BEGIN CERTIFICATE-----\n..."}}
```

For more details have a look at [docker-entrypoint.sh](docker-entrypoint.sh) and [docker-entrypoint.d](docker-entrypoint.d/).
