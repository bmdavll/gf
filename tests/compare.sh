#!/bin/bash

IFS=$'\n'
TIMEFORMAT=$'\n%2lR\t%P%%'

cleanUp() {
	rm -f $TEMPFILE *.inp *gf.$suf
}

trap 'cleanUp' 1 2 3 15

makeTemp() {
	local TEMPDIR
	if [ -d "$HOME/tmp" ]
	then TEMPDIR="$HOME/tmp"
	else TEMPDIR=/tmp
	fi
	TEMPFILE=$(mktemp -q -p "$TEMPDIR" "$(basename $0).$$.XXXX")
	if [ $? -ne 0 ]; then
		echo >&2 "Could not create temp file"
		exit 2
	fi
}
TEMPFILE=

errorUsage() {
	echo >&2 "$(basename $0) INPUT_FILE... | N..."
	exit 2
}

[ $# -eq 0 ] && errorUsage

for arg in "$@"; do

	if [ -r "$arg" ]; then
		if [ -f "$arg" ]; then
			input=$arg
		else
			makeTemp
			cat $arg >$TEMPFILE
			input=$TEMPFILE
		fi
	elif [[ "$arg" =~ ^[1-9][0-9]*$ ]]; then
		input=$arg.inp
		echo -n "input_gen.py $arg >$input"
		input_gen.py $arg >$input
		[ $? -ne 0 ] && exit 3
		echo
	else
		errorUsage
	fi

	suf=$(basename $arg).out
	diff=$(basename $arg).diff

	echo $input

	echo -n "_gf.sh "
	time _gf.sh $input >_gf.$suf

	echo -n " gf.sh "
	time gf.sh  $input > gf.$suf

	diff _gf.$suf gf.$suf >$diff 2>/dev/null

	cleanUp

	if [ -s $diff ]; then
		echo >&2 $diff
		exit 1
	else
		rm -f $diff
		echo
	fi

done
