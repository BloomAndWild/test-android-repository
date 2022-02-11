#! /bin/bash

# Define global variables
REPO=BloomAndWild/test-android-repository
GITHUB_USER=
GITHUB_EMAIL=
GITHUB_TOKEN=
BASE_BRANCH=
HEAD_BRANCH=
TITLE=
DESCRIPTION=

function usage() {
  echo "Usage: ${0} [--base <base branch>] [--head <head branch>] [--title <pull request title>] [--description <pull request description>] --user <github_user> --email <github_email> --token <github_token>"
}

# Script arguments

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
  --base)
    BASE_BRANCH="$2"
    shift # past argument
    shift # past value
    ;;
  --head)
    HEAD_BRANCH="$2"
    shift # past argument
    shift # past value
    ;;
  --title)
    TITLE="$2"
    shift # past argument
    shift # past value
    ;;
  --description)
    DESCRIPTION="$2"
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

# Check if Github credentials are missing
if [ -z "${GITHUB_USER}" ] || [ -z "${GITHUB_EMAIL}" ] || [ -z "${GITHUB_TOKEN}" ]; then
  echo "Github credentials are missing"
  usage
  exit 1
fi

# Open Pull Request
curl \
  --user "${GITHUB_USER}:${GITHUB_TOKEN}" \
  --request POST \
  --header "Accept: application/vnd.github.v3+json" \
  --data "{\"title\":\"${TITLE}\", \"head\":\"${HEAD_BRANCH}\", \"base\":\"${BASE_BRANCH}\", \"body\":\"${DESCRIPTION}\"}" \
  https://api.github.com/repos/${REPO}/pulls