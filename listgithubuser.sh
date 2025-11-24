#!/bin/bash

# listgithubuser.sh
# -----------------
# Simple GitHub repository access checker.
# Lists collaborators for a repository and prints their permission level.
# Requirements: `curl` and `jq`. Provide a GitHub token via the
# environment variable `GITHUB_TOKEN` or pass `--token <token>`.
#
# Usage:
#   ./listgithubuser.sh owner repo
#   ./listgithubuser.sh owner/repo
#   GITHUB_TOKEN=ghp_xxx ./listgithubuser.sh owner repo
#
set -euo pipefail

PROG=$(basename "$0")

usage() {
	cat <<EOF
Usage: $PROG <owner> <repo> [--token TOKEN]
			 $PROG owner/repo [--token TOKEN]

Environment:
	GITHUB_TOKEN   Personal access token with repo access (preferred)

The script lists collaborators and their permission (admin, write, read).
EOF
}

if ! command -v curl >/dev/null 2>&1; then
	echo "Error: curl is required" >&2
	exit 3
fi
if ! command -v jq >/dev/null 2>&1; then
	echo "Error: jq is required" >&2
	exit 3
fi

TOKEN="${GITHUB_TOKEN:-}" || true

OWNER=""
REPO=""

# simple arg parsing
while [ "$#" -gt 0 ]; do
	case "$1" in
		--help|-h)
			usage; exit 0 ;;
		--token)
			shift
			TOKEN="$1"; shift ;;
		--*)
			echo "Unknown option: $1" >&2; usage; exit 2 ;;
		*)
			if [[ -z "$OWNER" ]]; then
				if [[ "$1" == *"/"* ]]; then
					OWNER="${1%%/*}"
					REPO="${1##*/}"
				else
					OWNER="$1"
				fi
				shift
			elif [[ -z "$REPO" ]]; then
				REPO="$1"; shift
			else
				echo "Unexpected argument: $1" >&2; usage; exit 2
			fi
			;;
	esac
done

if [[ -z "$REPO" ]]; then
	echo "Repository not specified." >&2
	usage
	exit 2
fi

if [[ -z "$TOKEN" ]]; then
	read -rp "No GITHUB_TOKEN set. Enter token (will not be stored): " -s TOKEN
	echo
fi

API_BASE="https://api.github.com"

hdr_auth=( -H "Authorization: token $TOKEN" )
hdr_json=( -H "Accept: application/vnd.github.v3+json" )

repo_url="$API_BASE/repos/$OWNER/$REPO"

# quick check if repo exists / token valid
http_status=$(curl -sS -o /dev/null -w "%{http_code}" "${hdr_json[@]}" "${hdr_auth[@]}" "$repo_url") || true
if [ "$http_status" -ne 200 ]; then
	echo "Failed to access repository $OWNER/$REPO (HTTP $http_status). Check token and repo name." >&2
	exit 4
fi

echo "Listing collaborators for $OWNER/$REPO"

collab_api="$repo_url/collaborators?per_page=100"
collab_json=$(curl -sS "${hdr_json[@]}" "${hdr_auth[@]}" "$collab_api")

count=$(echo "$collab_json" | jq 'if type=="array" then length else 0 end')
if [ "$count" -eq 0 ]; then
	echo "No collaborators found or insufficient permission to list collaborators." >&2
	exit 0
fi

printf "%-20s %-8s %-6s %-30s\n" "Login" "ID" "Perm" "Name"
printf "%s\n" "$(printf '%.0s-' {1..80})"

echo "$collab_json" | jq -r '.[] | [.login, (.id|tostring), .type, (.name // "")] | @tsv' | while IFS=$'\t' read -r login id type name; do
	# query permission for each collaborator
	perm_json=$(curl -sS "${hdr_json[@]}" "${hdr_auth[@]}" "$repo_url/collaborators/$login/permission") || perm_json="{}"
	perm=$(echo "$perm_json" | jq -r '.permission // empty')
	perm=${perm:-unknown}
	printf "%-20s %-8s %-6s %-30s\n" "$login" "$id" "$perm" "$name"
done

exit 0
