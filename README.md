# 52°North Travis CI Tools

## `deploy-maven-snapshot.sh`

Will run `mvn deploy -DskipTests=true` to deploy the current branch to the Sonatype Snapshot repository.

The server in the deployment configuration of your `pom.xml` has to have the id `sonatype-nexus-snapshots` (the default for projects depending on [`maven-parents`](https://github.com/52North/maven-parents)).

### Configuration

| Environment variable | Description                                                             |
|----------------------|-------------------------------------------------------------------------|
| `SNAPSHOT_BRANCH`    | The branch to deploy, all other branches and pull requests are ignored. |
| `CI_DEPLOY_USERNAME` | The user name to use for Sonatype.                                      |
| `CI_DEPLOY_PASSWORD` | The password to use for Sonytype.                                       |

### Example

Add the credentials to your `.travis.yml`:

```sh
travis encrypt -a "CI_DEPLOY_USERNAME=${SONATYPE_USERNAME}"
travis encrypt -a "CI_DEPLOY_PASSWORD=${SONATYPE_PASSWORD}"
```

Add the following to your `.travis.yml`:

```yaml
after_success:
  - curl -Ls https://git.io/deploy-maven-snapshot | bash
env:
  global:
  - SNAPSHOT_BRANCH=master
```


## `trigger-dependent-build.sh`

This script will trigger the last build of branch (per default `master`) of another repository to be rebuild. The syntax is:
```sh
trigger_dependent_build.sh repository [branch]
```
Builds are only triggered for a configured branch, all other branches and pull requests are ignored. Dependent builds are not transitive, a dependent build won't trigger it's dependencies.

The script will add the following environment variables to the dependent build:

| Environment variable | Description                                               |
|----------------------|-----------------------------------------------------------|
| `DEPENDENT_BUILD`    | Always `true`.                                            |
| `TRIGGER_REPO`       | The repo slug of the repository that triggered the build. |
| `TRIGGER_COMMIT`     | The commit that triggered the build                       |

### Configuration

| Environment variable | Description                                         |
|----------------------|-----------------------------------------------------|
| `SNAPSHOT_BRANCH`    | The branch for which dependent build are triggered. |
| `TRAVIS_AUTH_TOKEN` | The authorization token for Travis CI.               |

### Example

Add the Travis CI token to your `.travis.yml`:

```sh
travis encrypt -a "TRAVIS_AUTH_TOKEN=${TRAVIS_TOKEN}"
```

To generate a token:
```sh
travis login --auto
travis token
```

The script requires `jq` to be installed:

```yaml
addons:
  apt:
    packages:
    - jq
```

Define the branch for which the builds should be triggered:
```yaml
env:
  global:
  - SNAPSHOT_BRANCH=master
```

Configure your dependent builds:

```yaml
after_success:
- SCRIPT=$(mktemp)
- curl -Ls https://git.io/v7gXY -o "$SCRIPT"
- bash "${SCRIPT}" 52North/faroe
- bash "${SCRIPT}" 52North/iceland
- bash "${SCRIPT}" 52North/svalbard
- bash "${SCRIPT}" 52North/shetland
- bash "${SCRIPT}" 52North/sos feature/5.x
- bash "${SCRIPT}" 52North/javaPS
```

For a single dependent build, this may be more concise:
```yaml
after_success:
- curl -Ls https://git.io/v7gXY | bash -s -- 52North/faroe
```
