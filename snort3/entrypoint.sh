#!/bin/bash
set -e

if [ "${1:0:1}" = '-' ]; then
    set -- snort "$@"
fi

if [ "$1" = 'snort' ]; then
	/init-snort.sh "${@:2}"
fi

exec "$@"