FROM node:22.9.0-alpine3.20 AS build

WORKDIR /npm
COPY package.json /npm

RUN npm install

###############################################################################

FROM node:22.9.0-alpine3.20 AS final

LABEL org.label-schema.maintainer="Voxpupuli Team <voxpupuli@groups.io>" \
      org.label-schema.vendor="Voxpupuli" \
      org.label-schema.url="https://github.com/voxpupuli/container-semantic-release" \
      org.label-schema.name="Vox Pupuli Container for semantic-release" \
      org.label-schema.license="AGPL-3.0-or-later" \
      org.label-schema.vcs-url="https://github.com/voxpupuli/container-semantic-release" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.dockerfile="/Dockerfile"

RUN apk update && apk upgrade \
    && apk add --no-cache --update git git-lfs openssh-client bash

COPY Dockerfile /
COPY --from=build /npm /npm

# fix ENOGITREPO Not running from a git repository.
RUN git config --global --add safe.directory '*'

WORKDIR /data

ENV PATH="$PATH:/npm/node_modules/.bin"
ENTRYPOINT [ "semantic-release" ]
CMD [ "--dry-run" ]
