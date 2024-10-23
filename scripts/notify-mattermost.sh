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
      \"icon_emoji\": \"${MATTERMOST_EMOJI}\",
      \"username\": \"${MATTERMOST_USERNAME}\",
      \"text\": \"${MATTERMOST_MESSAGE_TEXT}\",
      \"attachments\": [
        {
          \"title\": \"Release ${VERSION}\",
          \"title_link\": \"${MATTERMOST_TAGS_URL}/${VERSION}\"
        }
      ]
    }"

if [ "${DEBUG}" == 1 ]; then
echo "Version is: ${VERSION}"
echo "Options are: ${OPTIONS}"
echo "Payload is:"
echo "${payload}"
fi

if [[ -n ${MATTERMOST_HOOK_URL} ]]; then
  curl \
    -X POST \
    -H 'Content-Type: application/json' \
    --data "${payload}" \
    ${OPTIONS} ${MATTERMOST_HOOK_URL}
fi
