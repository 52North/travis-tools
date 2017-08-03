#!/bin/bash

stop() {
  echo $* >&2
  exit 0
}

[ "${TRAVIS_BRANCH}" = "${SNAPSHOT_BRANCH}" ] \
  || stop "won't build branch ${TRAVIS_BRANCH}"

[ "${TRAVIS_SECURE_ENV_VARS}" = "true" ] \
  || stop "no secure enviroment variables were provided"

[ "${TRAVIS_JOB_NUMBER}" = "${TRAVIS_BUILD_NUMBER}.1" ] \
  || stop "only the first build job will be deployed"

[ "${TRAVIS_PULL_REQUEST}" = "false" ] \
  || stop "no deployment for pull requests"

settings=$(mktemp --suffix .xml)

cat > ${settings} <<-'EOF'
  <settings xmlns="http://maven.apache.org/SETTINGS/1.0.0">
    <servers>
      <server>
        <id>sonatype-nexus-snapshots</id>
        <username>${env.CI_DEPLOY_USERNAME}</username>
        <password>${env.CI_DEPLOY_PASSWORD}</password>
      </server>
    </servers>
  </settings>
EOF

mvn deploy -DskipTests=true --settings "${settings}"
