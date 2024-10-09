#!/bin/bash
# bash is required to pass ENV vars with dots as sh cannot do this

set -e

for f in /docker-entrypoint.d/*.sh; do
    echo "INFO: Running $f"
    "$f"
done

exec /npm/node_modules/.bin/semantic-release "$@"
