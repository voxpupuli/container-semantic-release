#!/bin/bash

set -e

#
# @summary Create a rootless CA bundle with optional custom certificates.
#
# @example
# Mount PEM certificates with a .crt or .pem extension into /certificates.
#
readonly certificate_directory="/certificates"
readonly system_ca_bundle="/etc/ssl/certs/ca-certificates.crt"
readonly ca_bundle="${SSL_CERT_FILE:-/tmp/semantic-release-ca-certificates.crt}"
readonly ca_bundle_directory="${ca_bundle%/*}"

if [ ! -r "${system_ca_bundle}" ]; then
  echo "ERROR: system CA bundle is not readable: ${system_ca_bundle}" >&2
  exit 1
fi

if [ ! -d "${ca_bundle_directory}" ]; then
  echo "ERROR: CA bundle directory does not exist: ${ca_bundle_directory}" >&2
  exit 1
fi

umask 077
temporary_ca_bundle=$(mktemp "${ca_bundle_directory}/semantic-release-ca-certificates.XXXXXX")

# Remove an incomplete temporary bundle if certificate processing fails.
trap 'rm -f "${temporary_ca_bundle}"' EXIT

cp "${system_ca_bundle}" "${temporary_ca_bundle}"

if [ -e "${certificate_directory}" ] && [ ! -d "${certificate_directory}" ]; then
  echo "ERROR: certificate path is not a directory: ${certificate_directory}" >&2
  exit 1
fi

if [ -d "${certificate_directory}" ]; then
  # Leave unmatched certificate patterns out of the array instead of using them as literal paths.
  shopt -s nullglob
  certificates=(
    "${certificate_directory}"/*.crt
    "${certificate_directory}"/*.pem
  )

  for certificate in "${certificates[@]}"; do
    if [ ! -r "${certificate}" ]; then
      echo "ERROR: certificate is not readable: ${certificate}" >&2
      exit 1
    fi

    {
      printf '\n'
      cat "${certificate}"
      printf '\n'
    } >>"${temporary_ca_bundle}"
    echo "INFO: imported ${certificate}"
  done
fi

mv "${temporary_ca_bundle}" "${ca_bundle}"

# The temporary file was moved successfully and no longer needs cleanup.
trap - EXIT
