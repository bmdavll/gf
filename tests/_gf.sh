#!/bin/bash

set -e

if [ $# -eq 1 -a -f "$1" -a -r "$1" ]; then
	IFS=$'\n'
	for line in $(cat "$1"); do
		_sd "$line"
	done
elif [ $# -gt 0 ]; then
	for arg in "$@"; do
		_sd "$arg"
	done
else
	exit 2
fi
