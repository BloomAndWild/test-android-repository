#! /bin/bash

# Define global variables
VERSION_CODE_KEY=sharedVersionCode
BW_VERSION_KEY=bandwVersionName
BLOOMON_VERSION_KEY=bloomonVersionName
VERSIONS_LOCATION=./gradle.properties
COMMIT_MESSAGE=
GITHUB_USER=
GITHUB_EMAIL=
GITHUB_TOKEN=
REPO=mvettosi/test-repository
BASE_BRANCH=develop

function usage() {
  echo "Usage: ${0} [--bandw <bandw version>] [--bloomon <bloomon version] --user <github_user> --email <github_email> --token <github_token>"
}

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
  --bandw)
    BW_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
  --bloomon)
    BLOOMON_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
  --user)
    GITHUB_USER="$2"
    shift # past argument
    shift # past value
    ;;
  --email)
    GITHUB_EMAIL="$2"
    shift # past argument
    shift # past value
    ;;
  --token)
    GITHUB_TOKEN="$2"
    shift # past argument
    shift # past value
    ;;
  -h | --help | --usage)
    usage
    exit 0
    ;;
  *) # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift              # past argument
    ;;
  esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# Check at least one variant has a new version to set
if [ -z "${BW_VERSION}" ] && [ -z "${BLOOMON_VERSION}" ]; then
  echo "At least one variant needs to adopt a new version name!"
  usage
  exit 1
elif [ -z "${GITHUB_USER}" ] || [ -z "${GITHUB_EMAIL}" ] || [ -z "${GITHUB_TOKEN}" ]; then
  echo "Github credentials are missing"
  usage
  exit 1
fi

# Abort if there are uncommitted changes
if [[ $(git status --porcelain) ]]; then
  echo "Deal with uncommitted changes first!"
  exit 1
fi

# Calculate next version VERSION_CODE
VERSION_CODE=$(grep "${VERSION_CODE_KEY}" ${VERSIONS_LOCATION} | sed'' "s/${VERSION_CODE_KEY}=//")
((VERSION_CODE++))
COMMIT_MESSAGE="[Release ${VERSION_CODE}]"

# Checkout develop and make version bump branch
RELEASE_BRANCH="release/${VERSION_CODE}"
git checkout develop
git pull
git checkout -b ${RELEASE_BRANCH}

# Set new version code
sed -i'.backup' "s/${VERSION_CODE_KEY}=.*/${VERSION_CODE_KEY}=$VERSION_CODE/" ${VERSIONS_LOCATION}

# Set new BW version, if specified
if [ -n "${BW_VERSION}" ]; then
  sed -i'.backup' "s/${BW_VERSION_KEY}=.*/${BW_VERSION_KEY}=\"${BW_VERSION}\"/" ${VERSIONS_LOCATION}
  COMMIT_MESSAGE="${COMMIT_MESSAGE} bandw ${BW_VERSION}"
fi

# Set new bloomon version, if specified
if [ -n "${BLOOMON_VERSION}" ]; then
  sed -i'.backup' "s/${BLOOMON_VERSION_KEY}=.*/${BLOOMON_VERSION_KEY}=\"${BLOOMON_VERSION}\"/" ${VERSIONS_LOCATION}
  COMMIT_MESSAGE="${COMMIT_MESSAGE} bloomon ${BLOOMON_VERSION}"
fi

# Make version bump commit
git config user.name "${GITHUB_USER}"
git config user.email "${GITHUB_EMAIL}"
git add ${VERSIONS_LOCATION}
git commit -m "${COMMIT_MESSAGE}"

# Push the newly created release branch with version bump in it
git push --set-upstream origin ${RELEASE_BRANCH}

# Open Pull Request for the started release
PR_BODY="Pull Request representing release \`${VERSION_CODE}\`. Included version updates:\n"
if [ -n "${BW_VERSION}" ]; then
  PR_BODY="${PR_BODY} BloomAndWild ${BW_VERSION}"
fi
if [ -n "${BLOOMON_VERSION}" ]; then
  PR_BODY="${PR_BODY} bloomon ${BLOOMON_VERSION}"
fi
curl \
  --user "${GITHUB_USER}:${GITHUB_TOKEN}" \
  --request POST \
  --header "Accept: application/vnd.github.v3+json" \
  --data "{\"title\":\"${COMMIT_MESSAGE}\", \"head\":\"${RELEASE_BRANCH}\", \"base\":\"${BASE_BRANCH}\", \"body\":\"${PR_BODY}\"}" \
  https://api.github.com/repos/${REPO}/pulls
