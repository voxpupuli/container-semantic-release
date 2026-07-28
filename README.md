# Voxpupuli Semantic Release Container

[![CI](https://github.com/voxpupuli/container-semantic-release/actions/workflows/ci.yaml/badge.svg)](https://github.com/voxpupuli/container-semantic-release/actions/workflows/ci.yaml)
[![License](https://img.shields.io/github/license/voxpupuli/container-semantic-release.svg)](https://github.com/voxpupuli/container-semantic-release/blob/main/LICENSE)
[![Sponsored by betadots GmbH](https://img.shields.io/badge/Sponsored%20by-betadots%20GmbH-blue.svg)](https://www.betadots.de)

## Introduction

This container can be used to create project releases.
It encapsulates [semantic-release](https://semantic-release.gitbook.io/semantic-release) and all necessary plugins.
See [package.json](package.json) for details. This is a npm application running in an alpine container.

## Usage

Main tools in the container:

- conventional-changelog
- semantic-release
- commit-and-tag-version

for more information see the [`package.json`](package.json)

### Running the tools

```shell
# semantic-release is the default entrypoint
podman run -it --rm -v $PWD:/data:Z ghcr.io/voxpupuli/semantic-release:latest

# run commit-and-tag-version
podman run -it --rm -v $PWD:/data:Z --entrypoint commit-and-tag-version ghcr.io/voxpupuli/semantic-release:latest -r v2.0.0 --skip.commit --skip.tag

# run conventional-changelog
podman run -it --rm -v $PWD:/data:Z --entrypoint conventional-changelog ghcr.io/voxpupuli/semantic-release:latest -p angular -i CHANGELOG.md
```

### Variables

The container has the following pre-defined environment variables:

| Variable                | Default                                                                            |
| ----------------------- | ---------------------------------------------------------------------------------- |
| CERT_JSON               | no default                                                                         |
| PATH                    | `$PATH:/npm/node_modules/.bin`                                                     |
| NODE_OPTIONS            | `--use-openssl-ca`                                                                 |
| ROCKETCHAT_EMOJI        | `:tada:`                                                                           |
| ROCKETCHAT_MESSAGE_TEXT | `A new tag for the project ${CI_PROJECT_NAME} was created by ${CI_COMMIT_AUTHOR}.` |
| ROCKETCHAT_HOOK_URL     | `https://rocketchat.example.com/hooks/here_be_dragons`                             |
| ROCKETCHAT_TAGS_URL     | `${CI_PROJECT_URL}/-/tags`                                                         |
| MATTERMOST_EMOJI        | `:tada:`                                                                           |
| MATTERMOST_MESSAGE_TEXT | `A new tag for the project ${CI_PROJECT_NAME} was created by ${CI_COMMIT_AUTHOR}.` |
| MATTERMOST_HOOK_URL     | `https://mattermost.example.com/hooks/here_be_dragons`                             |
| MATTERMOST_TAGS_URL     | `${CI_PROJECT_URL}/-/tags`                                                         |
| MATTERMOST_USERNAME     | `Semantic Release`                                                                 |

### Example release configuration

See [`examples/release.config.mjs`](examples/release.config.mjs) for a complete configuration using the
`conventionalcommits` v10 preset.

Copy the example to the root directory of the project that should be released and name it `release.config.mjs`.
This is the standard location that semantic-release discovers automatically:

```text
your-project/
├── release.config.mjs
├── package.json
└── ...
```

Locations such as `.github/release.config.mjs` or `.gitlab/release.config.mjs` are not discovered automatically.
They only work when semantic-release is invoked with an explicit path, for example
`semantic-release --extends ./.github/release.config.mjs`.
Keeping the file in the project root is recommended unless the CI command is centrally controlled.

The JavaScript configuration allows the example to provide a custom JIRA URL formatter, which cannot be expressed in
YAML.

### Example `.versionrc.json`

This is an example configuration file for a project using commit-and-tag-version.

```json
{
  "types": [
    { "type": "build",    "section": "👷 Build" },
    { "type": "chore",    "section": "🧹 Chores" },
    { "type": "ci",       "section": "🚦 CI/CD" },
    { "type": "dep",      "section": "👾 Dependencies" },
    { "type": "docs",     "section": "📚 Docs" },
    { "type": "feat",     "section": "🚀 Features" },
    { "type": "fix",      "section": "🛠️ Fixes" },
    { "type": "perf",     "section": "⏩ Performance" },
    { "type": "refactor", "section": "🔨 Refactor" },
    { "type": "revert",   "section": "🙅 Reverts" },
    { "type": "test",     "section": "🚥 Tests" }
  ]
}
```

### Update metadata.json of a Puppet module

This can be added to the example configuration:

```javascript
plugins: [
  // ...
  [
    "semantic-release-replace-plugin",
    {
      replacements: [
        {
          files: ["metadata.json"],
          from: '"version": ".*"',
          to: '"version": "${nextRelease.version}"',
          countMatches: true,
          results: [
            {
              file: "metadata.json",
              hasChanged: true,
              numMatches: 1,
              numReplacements: 1,
            },
          ],
        },
      ],
    },
  ],
  // ...
  [
    "@semantic-release/git",
    {
      assets: ["CHANGELOG.md", "metadata.json"],
    },
  ],
],
```

### Gitlab

This is an example of using this container in GitLab.
Configure semantic-release with one of the following:

- A `.releaserc` file, written in YAML or JSON, with optional extensions: `.yaml` / `.yml` / `.json` / `.js` / `.cjs` / `.mjs`
- A `release.config.(js|cjs|mjs)` file that exports an object
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
    - /container-entrypoint.sh
  rules:
    - if: $CI_COMMIT_BRANCH == "master"
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_COMMIT_BRANCH == "production"
```

### Running as local user

When using git+ssh remotes, you might encounter issues accessing your git server.

This solution launches your local ssh-agent (if it's not already running) and adds your default SSH key.
It then sets an environment variable within the container to locate the ssh-agent socket.
It also bind-mounts the socket from your host system into the container, enabling secure access to your git server.

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

#### release.config.mjs

```javascript
plugins: [
  // Most people will choose between one of these two:
  [
    "@semantic-release/exec",
    {
      publishCmd: "/scripts/notify-rocketchat.sh -V v${nextRelease.version} -o '--insecure' -d",
    },
  ],
  [
    "@semantic-release/exec",
    {
      publishCmd: "/scripts/notify-mattermost.sh -V v${nextRelease.version} -o '--insecure' -d",
    },
  ],
],
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

For more details have a look at [container-entrypoint.sh](container-entrypoint.sh) and [container-entrypoint.d](container-entrypoint.d/).
