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

[ $# -ge 1 -a $# -le 2 ] \
  || fail "Usage: $0 repo-slug [branch]"

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

[ -n "${TRAVIS_AUTH_TOKEN}" ] \
  || fail 'missing $TRAVIS_AUTH_TOKEN'

function url-encode() {
  sed -e 's: :%20:g' \
      -e 's:<:%3C:g' \
      -e 's:>:%3E:g' \
      -e 's:#:%23:g' \
      -e 's:%:%25:g' \
      -e 's:{:%7B:g' \
      -e 's:}:%7D:g' \
      -e 's:|:%7C:g' \
      -e 's:\\:%5C:g' \
      -e 's:\^:%5E:g' \
      -e 's:~:%7E:g' \
      -e 's:\[:%5B:g' \
      -e 's:\]:%5D:g' \
      -e 's:`:%60:g' \
      -e 's:;:%3B:g' \
      -e 's:/:%2F:g' \
      -e 's:?:%3F:g' \
      -e 's^:^%3A^g' \
      -e 's:@:%40:g' \
      -e 's:=:%3D:g' \
      -e 's:&:%26:g' \
      -e 's:\$:%24:g' \
      -e 's:\!:%21:g'<<<"$1"
}

endpoint=https://api.travis-ci.org
repo_slug="$1"
branch="${2:-master}"

curl -s -X POST \
     -H "Authorization: token ${TRAVIS_AUTH_TOKEN}" \
     -H 'Content-Type: application/json' \
     -H 'Accept: application/json' \
     -H "Travis-API-Version: 3" \
     "${endpoint}/$(url-encode ${repo_slug})/requests" "${TRAVIS_REPO_SLUG}" \
     -d "{
  \"request\": {
    \"message\": \"Dependent build for ${TRAVIS_COMMIT} of ${TRAVIS_REPO_SLUG}\",
    \"branch\": \"${branch}\",
    \"config\": {
      \"merge_mode\": \"deep_merge\",
      \"env\": {
        \"DEPENDENT_BUILD\": true,
        \"TRIGGER_COMMIT\": \"${TRAVIS_COMMIT}\",
        \"TRIGGER_REPO\": \"${TRAVIS_REPO_SLUG}\"
      }
    }
  }
}" 
