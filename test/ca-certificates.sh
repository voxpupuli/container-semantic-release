#!/bin/bash

set -euo pipefail

readonly container_runtime="${CONTAINER_RUNTIME:-docker}"
readonly image="${1:?Usage: $0 IMAGE}"

if ! command -v "${container_runtime}" >/dev/null 2>&1; then
  echo "ERROR: container runtime not found: ${container_runtime}" >&2
  exit 1
fi

test_directory=$(mktemp -d)

cleanup() {
  rm -f \
    "${test_directory}/first.key" \
    "${test_directory}/first.crt" \
    "${test_directory}/second.key" \
    "${test_directory}/second test.pem" \
    "${test_directory}/ignored.txt"
  rmdir "${test_directory}"
}

# Always remove the temporary certificates, including when a test command fails.
trap cleanup EXIT

openssl req -x509 -newkey rsa:2048 -sha256 -nodes -days 1 \
  -subj /CN=rootless-crt-test \
  -keyout "${test_directory}/first.key" \
  -out "${test_directory}/first.crt" \
  >/dev/null 2>&1

openssl req -x509 -newkey rsa:2048 -sha256 -nodes -days 1 \
  -subj /CN=rootless-pem-test \
  -keyout "${test_directory}/second.key" \
  -out "${test_directory}/second test.pem" \
  >/dev/null 2>&1

cp "${test_directory}/first.crt" "${test_directory}/ignored.txt"
chmod 0755 "${test_directory}"
chmod 0644 \
  "${test_directory}/first.crt" \
  "${test_directory}/second test.pem" \
  "${test_directory}/ignored.txt"

system_certificate_count=$(
  "${container_runtime}" run --rm --entrypoint sh "${image}" \
    -c 'grep -c "BEGIN CERTIFICATE" /etc/ssl/certs/ca-certificates.crt'
)

# The variables in this command are expanded inside the container.
# shellcheck disable=SC2016
"${container_runtime}" run --rm --entrypoint bash "${image}" -c '
  test "$(id -u)" = 1001
  /container-entrypoint.d/001_add_ca_certificate.sh
  cmp /etc/ssl/certs/ca-certificates.crt "${SSL_CERT_FILE}"
  test "$(stat -c %a "${SSL_CERT_FILE}")" = 600
'

# The variables in this command are expanded inside the container.
# shellcheck disable=SC2016
"${container_runtime}" run --rm \
  --volume "${test_directory}:/certificates:ro,Z" \
  --env "EXPECTED_CERTIFICATE_COUNT=$((system_certificate_count + 2))" \
  --entrypoint bash \
  "${image}" \
  -c '
    test "$(id -u)" = 1001
    /container-entrypoint.d/001_add_ca_certificate.sh
    test "$(stat -c %a "${SSL_CERT_FILE}")" = 600
    test "$(grep -c "BEGIN CERTIFICATE" "${SSL_CERT_FILE}")" = "${EXPECTED_CERTIFICATE_COUNT}"
    test "$(node -p "require(\"tls\").getCACertificates(\"extra\").length")" = "${EXPECTED_CERTIFICATE_COUNT}"
    test "${GIT_SSL_CAINFO}" = "${SSL_CERT_FILE}"
    test "${NODE_EXTRA_CA_CERTS}" = "${SSL_CERT_FILE}"
  '

"${container_runtime}" run --rm "${image}" --version
