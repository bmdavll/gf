#!/bin/bash

CCLASS_OPN='\[|\[:[a-z]*'
CCLASS_PRE="$CCLASS_OPN"'|\[:[a-z]*:'
AFT_CLAUSE='('"$CCLASS_PRE"')*('"$CCLASS_OPN"')'
OPEN_BRACK='('"$CCLASS_PRE"')*(
  \[:[a-z]*:\]        |
  \[:[a-z]*:[^[\]]    |
  \[:[a-z]*[^a-z:[\]] |
  \[[^:[\]]
)'
ESCAPE='^((
  [^[\\] |
  \\.    |
  \[(
    (\^[^[]|[^^[]|\^?'"$OPEN_BRACK"') ([^[\]]|'"$OPEN_BRACK"')* ('"$AFT_CLAUSE"')? |
    \^?                                                         ('"$AFT_CLAUSE"')
  )\]
)*)\\[sSdD]'

ESCAPE="${ESCAPE// /}"
ESCAPE="${ESCAPE//$'\n'/}"
# echo "$ESCAPE"

process() {
	echo "$1" | gawk '{
		while (match($0, /'"$ESCAPE"'/)) {
			char = substr($0, RSTART+RLENGTH-1, 1)
			if (char == "s")
				class = "[[:space:]]";
			else if (char == "S")
				class = "[^[:space:]]";
			else if (char == "d")
				class = "[[:digit:]]";
			else if (char == "D")
				class = "[^[:digit:]]";
			$0 = gensub(/'"$ESCAPE"'/, "\\1"class, 1);
		}
		print;
	}'
}

# command-line input
if [ $# -eq 1 -a -f "$1" -a -r "$1" ]; then
	set -e
	IFS=$'\n'
	for line in $(cat "$1"); do
		process "$line"
	done
	exit
elif [ $# -gt 0 ]; then
	set -e
	for arg in "$@"; do
		process "$arg"
	done
	exit
fi

# self-test
if type echoc &>/dev/null
then c=c
else unset c
fi

t() {
	local n=$1 && shift

	for arg in "$@"; do
		num+=1

		pattern=$(process "$arg")

		if [ "$(echo "$pattern" | grep -c "$MATCH")" -ne $n ]; then
			failures+=1
			echo${c} ${c+yellow} "Number $num:"
			[ $n -eq 0 ] && echo "$arg"
			echo "$pattern" | grep --color=auto "$MATCH"
			[ $? -ne 0 ] && echo "$arg"
		fi
	done
}
MATCH='\[\^\?\[:space:]]'

check() {
	if [ $failures -eq 0 ]; then
		echo${c} ${c+green} "$num tests passed"
	else
		echo${c} ${c+red} "$failures failure(s)"
	fi
	code+=$failures
	echo
}

declare -i code num failures

code=0

n=0 && echo${c} ${c+blue} "Testing unchanged:"
num=0 && failures=0

t $n '[\S]' '[^\S]'
t $n '[[\S]' '[]\S]'
t $n '[^[\S]' '[^]\S]' '[^][:foo:]\S]'
t $n '[[:foo:]\S]'
t $n '[[:foo:]bar[:baz:]\S]'
t $n '[]\S' '[^]\S'
t $n '[[:foo\S]' '[^][:foo\S]'
t $n '[[:foo\S' '[^]\S'
t $n '[[:foo:]\S' '[^[:foo:]\S'
t $n '[[:[:foo[:foo:[:#\S]'
t $n '[[:[:foo[:foo:[:bar:]\S]'

check

n=1 && echo${c} ${c+blue} "Testing one substitution:"
num=0 && failures=0

t $n '[[]\s' '[]]\s' '[\]\s' '[:]\s' '[a]b\s'
t $n '[^[]\s' '[^]]\s' '[^\]\s' '[^:]\s' '[^a]b\s'
t $n '[[:]\s' '[]:]\s'
t $n '[^[:]\s' '[^]:]\s'
t $n '[[:foo]\s' '[]:foo]\s'
t $n '[^[:foo]\s' '[^]:foo]\s'
t $n '[]:foo:]\s'
t $n '[^]:foo]\s' '[^][:foo]\s'
t $n '[[:foo:][]\s' '[[:foo:][:]\s' '[[:foo:][:bar]\s'
t $n '[^[:foo:][]\s' '[^[:foo:]bar[:]\s' '[^[:foo:][:bar\]\s'
t $n '[[[\s]]]\s' '[[:[:foo[:foo:[:bar:]]\s'
t $n '[[:bar:]:]]\s' '[[:bar:]baz:]]\s'
t $n '[[:f]oo\s' '[^[:fo]:]\s'
t $n '[[:[:foo[:foo:[:#]\s'
t $n '[[:az:[:az]\s'

check

exit $code
