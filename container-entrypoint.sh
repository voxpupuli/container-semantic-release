#!/bin/bash
# bash is required to pass ENV vars with dots as sh cannot do this

set -e

if [ -d /docker-entrypoint.d/ ]; then
    find /docker-entrypoint.d/ -type f -name "*.sh" \
        -exec echo Running {} \; -exec bash {} \;
fi

exec /npm/node_modules/.bin/semantic-release "$@"
