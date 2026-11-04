#!/bin/bash
# Baut das ISO in einem Debian-Container – praktisch unter Ubuntu, Fedora,
# Arch usw. oder in GitHub Actions. Benötigt nur Docker.
set -euo pipefail
cd "$(dirname "$0")"
. ./distro.conf

docker run --rm --privileged \
	-v "${PWD}:/build" -w /build \
	-e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
	${APT_HTTP_PROXY:+-e APT_HTTP_PROXY="${APT_HTTP_PROXY}"} \
	${BUILD_SOURCE:+-e BUILD_SOURCE="${BUILD_SOURCE}"} \
	"debian:${DEBIAN_SUITE}" \
	bash -c './build.sh "$@"; rc=$?; chown -R "${HOST_UID}:${HOST_GID}" /build; exit $rc' -- "$@"
