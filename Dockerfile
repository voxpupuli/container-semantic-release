FROM node:23.8.0-alpine3.20 AS build

WORKDIR /npm
COPY package.json /npm

RUN npm install

###############################################################################

FROM node:23.8.0-alpine3.20 AS final

LABEL org.label-schema.maintainer="Voxpupuli Team <voxpupuli@groups.io>" \
      org.label-schema.vendor="Voxpupuli" \
      org.label-schema.url="https://github.com/voxpupuli/container-semantic-release" \
      org.label-schema.name="Vox Pupuli Container for semantic-release" \
      org.label-schema.license="AGPL-3.0-or-later" \
      org.label-schema.vcs-url="https://github.com/voxpupuli/container-semantic-release" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.dockerfile="/Dockerfile"

COPY Dockerfile /
COPY docker-entrypoint.sh /
COPY docker-entrypoint.d /docker-entrypoint.d
COPY scripts /scripts
COPY --from=build /npm /npm

RUN apk update && apk upgrade \
    && apk add --no-cache --update git git-lfs openssh-client bash jq curl \
    && chmod +x /docker-entrypoint.sh /docker-entrypoint.d/*.sh

# fix ENOGITREPO Not running from a git repository.
RUN git config --global --add safe.directory '*'

WORKDIR /data

ENV CERT_JSON=""
ENV PATH="$PATH:/npm/node_modules/.bin"
ENV NODE_OPTIONS="--use-openssl-ca"

# The CI_* are empty, because docker does not know about them on build time.
ENV ROCKETCHAT_EMOJI=":tada:"
ENV ROCKETCHAT_MESSAGE_TEXT="A new tag for the project ${CI_PROJECT_NAME} was created by ${CI_COMMIT_AUTHOR}."
ENV ROCKETCHAT_HOOK_URL="https://rocketchat.example.com/hooks/here_be_dragons"
ENV ROCKETCHAT_TAGS_URL="${CI_PROJECT_URL}/-/tags"

ENV MATTERMOST_EMOJI=":tada:"
ENV MATTERMOST_USERNAME="Semantic Release"
ENV MATTERMOST_MESSAGE_TEXT="A new tag for the project ${CI_PROJECT_NAME} was created by ${CI_COMMIT_AUTHOR}."
ENV MATTERMOST_HOOK_URL="https://mattermost.example.com/hooks/here_be_dragons"
ENV MATTERMOST_TAGS_URL="${CI_PROJECT_URL}/-/tags"

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "--dry-run" ]
