#!/bin/bash

while getopts V:o:d flag
do
    case "${flag}" in
        V) VERSION=${OPTARG};;
        o) OPTIONS=${OPTARG};;
        d) DEBUG=1;;
    esac
done

payload="{
      \"emoji\": \"${ROCKETCHAT_EMOJI}\",
      \"text\": \"${ROCKETCHAT_MESSAGE_TEXT}\",
      \"attachments\": [
        {
          \"title\": \"Release ${VERSION}\",
          \"title_link\": \"${ROCKETCHAT_TAGS_URL}/${VERSION}\"
        }
      ]
    }"

if [ "${DEBUG}" == 1 ]; then
echo "Version is: ${VERSION}"
echo "Options are: ${OPTIONS}"
echo "Payload is:"
echo "${payload}"
fi

if [[ -n ${ROCKETCHAT_HOOK_URL} ]]; then
  curl \
    -X POST \
    -H 'Content-Type: application/json' \
    --data "${payload}" \
    ${OPTIONS} ${ROCKETCHAT_HOOK_URL}
fi
