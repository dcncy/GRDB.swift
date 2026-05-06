#!/bin/bash

set -euo pipefail

cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
release_version=""
upstream_tag=""
release_repository="${GITHUB_REPOSITORY:-}"
verbose=0

print_usage_and_exit() {
	cat <<-EOF
	Usage:
	  $ $(basename "$0") -r <release_version> [-g <upstream_grdb_tag>] [-R <owner/repo>] [-v]

	Options:
	  -g    Upstream GRDB tag to release, for example v7.4.1
	  -r    Release version number for this fork, format x.y.z
	  -R    Override GitHub repository, format owner/repo
	  -v    Verbose output
	EOF

	exit 1
}

while getopts 'g:r:R:v' OPTION; do
	case "${OPTION}" in
		g)
			upstream_tag="${OPTARG}"
			;;
		r)
			release_version="${OPTARG}"
			;;
		R)
			release_repository="${OPTARG}"
			;;
		v)
			verbose=1
			;;
		*)
			print_usage_and_exit
			;;
	esac
done

if [[ -z "${release_version}" ]] || ! [[ "${release_version}" =~ [0-9]\.[0-9]\.[0-9] ]]; then
	echo "Invalid or missing release version. Expected format x.y.z"
	print_usage_and_exit
fi

require_command() {
	local command_name=$1

	if ! command -v "${command_name}" >/dev/null 2>&1; then
		echo "Missing required command: ${command_name}"
		exit 1
	fi
}

resolve_release_repository() {
	if [[ -n "${release_repository}" ]]; then
		printf '%s' "${release_repository}"
		return 0
	fi

	local origin_url
	origin_url="$(git -C "${cwd}" remote get-url origin 2>/dev/null || true)"
	origin_url="${origin_url%.git}"

	case "${origin_url}" in
		git@github.com:*)
			printf '%s' "${origin_url#git@github.com:}"
			;;
		https://github.com/*)
			printf '%s' "${origin_url#https://github.com/}"
			;;
		ssh://git@github.com/*)
			printf '%s' "${origin_url#ssh://git@github.com/}"
			;;
		*)
			echo "Unable to determine GitHub repository from origin remote: ${origin_url:-<empty>}"
			exit 1
			;;
	esac
}

assert_clean_worktree() {
	if [[ -n "$(git -C "${cwd}" status --porcelain)" ]]; then
		echo "Working tree is not clean. Commit, stash, or discard local changes before publishing."
		git -C "${cwd}" status --short
		exit 1
	fi
}

assert_tag_not_exists() {
	local tag_name=$1
	local repository=$2

	if git -C "${cwd}" rev-parse -q --verify "refs/tags/${tag_name}" >/dev/null 2>&1; then
		echo "Local tag already exists: ${tag_name}"
		exit 1
	fi

	if gh release view "${tag_name}" --repo "${repository}" >/dev/null 2>&1; then
		echo "GitHub release already exists: ${repository}@${tag_name}"
		exit 1
	fi
}

require_command git
require_command gh
require_command envsubst
require_command xcodebuild
require_command xcrun
require_command dwarfdump
require_command dsymutil

gh auth status >/dev/null

release_repository="$(resolve_release_repository)"
assert_clean_worktree
assert_tag_not_exists "${release_version}" "${release_repository}"

echo "Repository: ${release_repository}"
echo "Release version: ${release_version}"
if [[ -n "${upstream_tag}" ]]; then
	echo "Upstream GRDB tag: ${upstream_tag}"
fi

command=("${cwd}/prepare_release.sh" "-r" "${release_version}")
if [[ ${verbose} -eq 1 ]]; then
	command+=("-v")
fi
if [[ -n "${upstream_tag}" ]]; then
	command+=("${upstream_tag}")
fi

GITHUB_REPOSITORY="${release_repository}" "${command[@]}"
