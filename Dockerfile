FROM node:22.9.0-alpine3.20

LABEL org.label-schema.maintainer="Voxpupuli Team <voxpupuli@groups.io>" \
      org.label-schema.vendor="Voxpupuli" \
      org.label-schema.url="https://github.com/voxpupuli/container-semantic-release" \
      org.label-schema.name="Vox Pupuli Container for semantic-release" \
      org.label-schema.license="AGPL-3.0-or-later" \
      org.label-schema.vcs-url="https://github.com/voxpupuli/container-semantic-release" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.dockerfile="/Dockerfile"

RUN apk update \
    && apk upgrade \
    && apk add --no-cache --update git git-lfs openssh-client

# TODO: https://github.com/voxpupuli/container-semantic-release/issues/3
# RUN addgroup -g 1001 release && adduser -G release -u 1001 -D semantic \
#     && mkdir -p /npm /data \
#     && chown -R semantic:release /npm /data
# USER semantic

WORKDIR /npm
COPY Dockerfile /
COPY package.json package-lock.json /npm/

RUN npm ci

WORKDIR /data

ENV PATH="$PATH:/npm/node_modules/.bin"
ENTRYPOINT [ "semantic-release" ]
CMD [ "--dry-run" ]
