#!/bin/bash

# set -x

LOG_NAME=$(basename -- $0)
API=$1
MR_NAME=$2
PROJECT=$3
TOKEN=$4
S_BRANCH=${5:-release}
T_BRANCH=${6:-main}

projects_json=$(curl -s -XGET --header "PRIVATE-TOKEN: ${TOKEN}" "${API}/projects?search=${PROJECT}&simple=true")
count=$(echo $projects_json | jq -r ". | length")

echo "${LOG_NAME} | INFO | projects found: ${count}"

if [[ $count -eq 0 ]]; then
  echo "${LOG_NAME} | ERROR | No project found"
  exit 1
elif [[ $count -gt 1 ]]; then
  echo "${LOG_NAME} | ERROR | Found more than one project"
  exit 1
fi

ID=$(echo $projects_json | jq -r ".[].id")

echo "${LOG_NAME} | INFO | Project ID: ${ID}"

payload=$(jq --null-input \
  --compact-output \
  --raw-output \
  --arg source_branch ${S_BRANCH} \
  --arg target_branch ${T_BRANCH} \
  --arg title "${MR_NAME}" \
  --argjson remove_source_branch true \
  '$ARGS.named')

create_mr_json=$(curl -s -XPOST --header "Content-Type: application/json" --header "PRIVATE-TOKEN: ${TOKEN}" -d "${payload}" "${API}/projects/${ID}/merge_requests")

if [[ $(echo $create_mr_json | jq -e 'has("created_at")') == 'true' ]]; then
  echo "${LOG_NAME} | INFO | Successfully opened new MR with title \"${MR_NAME}\""
else
  echo "${LOG_NAME} | WARN | ${create_mr_json}"
fi
