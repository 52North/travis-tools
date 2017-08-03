#!/bin/bash

set -e

function stop() {
  echo $* >&2
  exit 0
}

function fail() {
 echo $* >&2
 exit 1
}

function usage() {
  echo "Usage: $0 repo-slug [branch]" >&2
}

[ "${TRAVIS_BRANCH}" = "${SNAPSHOT_BRANCH}" ] \
  || stop "won't trigger for branch ${TRAVIS_BRANCH}"

[ "${TRAVIS_SECURE_ENV_VARS}" = "true" ] \
  || stop "no secure enviroment variables were provided"

[ "${TRAVIS_JOB_NUMBER}" = "${TRAVIS_BUILD_NUMBER}.1" ] \
  || stop "only the first build job will trigger"

[ "${TRAVIS_PULL_REQUEST}" = "false" ] \
  || stop "won't trigger for pull requests"

[ "${DEPENDENT_BUILD}" != "true" ] \
  || stop "won't trigger for dependent build"

function travis-api() {
  curl -s -H "Authorization: token ${TRAVIS_AUTH_TOKEN}" \
          -H 'Content-Type: application/json' "$@"
}

function get_repo_id() {
  travis-api "${endpoint}/repos/${1}"  | jq -r '.id'
}

function create_env_var() {
  local req=$(printf '{ "env_var": { "name": "%s", "value": "%s", "public": true } }' "${2}" "${3}")
  travis-api -X POST "${endpoint}/settings/env_vars?repository_id=${1}" -d "${req}" | jq -r '.env_var.id'
}

function delete_env_var() {
  travis-api -X DELETE "${endpoint}/settings/env_vars/${2}?repository_id=${1}" > /dev/null
}

function restart_build() {
  travis-api -X POST "${endpoint}/builds/${1}/restart" | jq -r '.result'
}

function last_build() {
  travis-api "${endpoint}/repos/${1}/branches/${2}" | jq '.branch.id'
}

function build_state() {
  travis-api "${endpoint}/builds/${1}" | jq -r '.state'
}

function delete_env_vars() {
  for id in "${env_var_ids[@]}"; do
    delete_env_var "${repo_id}" "${id}"
  done
}

function create_env_vars() {
  env_var_ids=(
    $(create_env_var "${repo_id}" DEPENDENT_BUILD "true")
    $(create_env_var "${repo_id}" TRIGGER_COMMIT "${TRAVIS_COMMIT}")
    $(create_env_var "${repo_id}" TRIGGER_REPO "${TRAVIS_REPO_SLUG}")
  )
}

[ -n "${TRAVIS_AUTH_TOKEN}" ] \
  || fail 'missing $TRAVIS_AUTH_TOKEN'

[ $# -ge 1 -a $# -le 2 ] \
  || fail $(usage)

endpoint=https://api.travis-ci.org
repo_id=$(get_repo_id "${1}")
branch="${2:-master}"
last_build_id=$(last_build "${repo_id}" "${branch}")

declare -a env_var_ids

create_env_vars

if [ "$(restart_build "${last_build_id}")" != "true" ]; then
  delete_env_vars
  fail "could not restart build"
else
  until [ "$(build_state "${last_build_id}")" = "started" ]; do
    sleep 5
  done
  delete_env_vars
fi
