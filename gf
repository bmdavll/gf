#!/bin/bash
######################################################################{{{
#
#   Copyright 2009 David Liang
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#   Revisions:
#   2008-04-09  File created
#   2008-04-21  Added help
#   2008-12-13  Added second form
#   2009-04-05  Added "! -wholename" functionality
#   2009-04-17  Changed shell to bash
#   2009-04-19  Escape sequence conversion for \[sS] and \[dD]
#
######################################################################}}}

PROG=$(basename "$0")
VERSION="0.9"

# default $GREPOPTS if it's not set
if [ ! "${GREPOPTS+set}" ]; then
    GREPOPTS="-I --color"
fi

# indicator character for exclude patterns
EXCL_CHAR='^'

# grep one letter options that take an argument
GREP_ARG_OPTS='efmABCDd'

# change regular expression mode
[[ "$PROG" =~ ^[efgp] ]] && GREPOPTS+=" -${BASH_REMATCH^?}"

# usage/help {{{
printUsage() {
local SPCS=$(printf '%*s' ${#PROG} '')
cat << -EOF-
Usage: $PROG [PATH]...  [-e] PATTERN | -f PAT_FILE  [PATH]...
       $SPCS [ NAME | ${EXCL_CHAR}EXCLUDE | GREP_OPT ]...

       $PROG [-e] PATTERN | -f PAT_FILE
       $SPCS [ NAME | ${EXCL_CHAR}EXCLUDE | GREP_OPT | FILE ]...

-EOF-
}
helpText() {
local PAT1 PAT2 S
if [[ "$PROG" == f* ]]; then
    PAT1='retrasado'
    PAT2='import popen2'
else
    [[ "$PROG" != [ep]* ]] && S="\\"
    PAT1='retrasad[oa]'
    PAT2="$S(import$S|from$S) popen\d"
fi
cat << -EOF-
$PROG $VERSION

$(printUsage)

Use \`find' to search for files in the current directory or the given PATHs,
then grep in found files for a regular expression PATTERN. The set of files to
search in can be refined by one or more filename patterns NAME and EXCLUDE.
Options to \`grep' also follow the pattern. The first usage form is same as

  find [PATH]... [ ! -path "*EXCLUDE*" | -iname NAME ]... -type f \\
  -print0 | xargs -0 grep [ -e PATTERN | -f FILE ] [GREP_OPT]...

If this script is run with a name starting with "e", \`egrep' will be used;
likewise for "f" and \`fgrep', and "p" and \`grep -P'. In addition to grep
regular expression syntax, the character escapes \s, \d, \S, and \D, when not
inside a bracket expression, are replaced with their character class
equivalents [[:space:]], [[:digit:]], etc.

The second usage form relies on no PATHs and at least one existing FILE on the
comand line, and can be used in conjunction with \`xargs' or command-line
expansion to filter results:

  ls | xargs -r  $PROG  PATTERN  "*.py" ^foo
  $PROG  PATTERN  "*.txt"  \`cat filelist\`

This also allows \`xargs' to run \`grep' with default options, which are
defined in \$GREPOPTS in this script if it hasn't been exported.

Options:
    -h, --help      display this help message and exit
    -e  PATTERN     use PATTERN as the pattern
    -f  PAT_FILE    read patterns from PAT_FILE

Examples:
    $PROG  "$PAT1"  -in -C 2  "README*"
    $PROG  ~/foo/src  '$PAT2'  "*.py"  $EXCL_CHAR/.svn/  -l

-EOF-
}
errorUsage() {
    printUsage >&2
    [ $# -gt 0 ] && echo >&2 $'\n'"$PROG: $@"
    exit 2
}
# }}}

# options {{{
if [ "$1" = "--help" ]; then
    helpText
    exit 0
fi

PATOPT=-e
unset PATTERN

while getopts 'h?e:f:' option
do
    case "$option" in
    h)      helpText
            exit 0
            ;;
    \?)     printUsage
            exit 0
            ;;
    e)      PATOPT=-e
            PATTERN="$OPTARG"
            ;;
    f)      PATOPT=-f
            PATTERN="$OPTARG"
            ;;
    ?)      errorUsage
            ;;
    esac
done
shift $((OPTIND - 1))
# }}}

# parse PATHs and PATTERN {{{
PATHS=()

# shift any PATHs
while [ -d "$1" ]; do
    PATHS+=("$1")
    shift
done

# set PATTERN
if [ ! "${PATTERN+set}" ]; then
    if [[ "$1" == -[ef] ]]; then
        PATOPT="$1"
        shift
    fi
    [ $# -eq 0 ] && errorUsage
    PATTERN="$1"
    shift
fi

# escape sequence conversion for \s, \d, \S, and \D {{{
if type _sd &>/dev/null; then
    PATTERN=$(_sd "$PATTERN")
else
ESCAPE='^(([^[\\]|\\.|\[((\^[^[]|[^^[]|\^?(\[|\[:[a-z]*|\[:[a-z]*:)*(\[:
[a-z]*:\]|\[:[a-z]*:[^[\]]|\[:[a-z]*[^a-z:[\]]|\[[^:[\]]))([^[\]]|(\[|\[
:[a-z]*|\[:[a-z]*:)*(\[:[a-z]*:\]|\[:[a-z]*:[^[\]]|\[:[a-z]*[^a-z:[\]]|\
[[^:[\]]))*((\[|\[:[a-z]*|\[:[a-z]*:)*(\[|\[:[a-z]*))?|\^?((\[|\[:[a-z]*
|\[:[a-z]*:)*(\[|\[:[a-z]*)))\])*)\\[sSdD]'
ESCAPE="${ESCAPE//$'\n'/}"
PATTERN=$(echo "$PATTERN" | gawk '{
    while (match($0, /'"$ESCAPE"'/)) {
        char = substr($0, RSTART+RLENGTH-1, 1);
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
}')
fi
# }}}

# shift any PATHs
while [ -d "$1" ]; do
    PATHS+=("$1")
    shift
done
# }}}

# parse NAME and EXCLUDE patterns, grep options, and files {{{
NAMES=()
GREPOPTS=($GREPOPTS)
FILES=()

while [ $# -gt 0 ]; do

    if [[ "$1" == --* ]]; then
        GREPOPTS+=("$1")
    elif [[ "$1" =~ ^-[^$GREP_ARG_OPTS]*[$GREP_ARG_OPTS](.*)$ ]]; then
        GREPOPTS+=("$1")
        if [ -z "${BASH_REMATCH[1]}" ]; then
            if [ $# -gt 1 ]; then
                GREPOPTS+=("$2")
                shift
            else
                GREPOPTS+=("")
            fi
        fi
    elif [[ "$1" == -?* ]]; then
        GREPOPTS+=("$1")
    elif [[ "$1" == "$EXCL_CHAR"* ]]; then
        if [ "${1:1}" ]; then
            NAMES+=(! -path "*${1:1}*")
        fi
    elif [ -f "$1" -o -p "$1" -o "$1" = "-" ]; then
        FILES+=("$1")
    else
        [ -z "$1" ] && continue
        if [[ "$1" == */* ]]; then
            errorUsage "NAME contains slash: $1"
        else
            NAMES+=(-iname "$1")
        fi
    fi

    shift
done
# }}}

# run grep {{{
exitCode() {
    if [ ${codes[0]} -ne 0 ]
    then exit ${codes[0]}
    else exit ${codes[1]}
    fi
}

if [ ${#PATHS[@]} -gt 0 ]; then

    [ ${#FILES[@]} -gt 0 ] && errorUsage "Specify either PATHs or FILEs"

elif [ ${#FILES[@]} -gt 0 ]; then

    if [ ${#NAMES[@]} -gt 0 ]; then
        find "${FILES[@]}" -maxdepth 0 "${NAMES[@]}" -print0 | \
        xargs -0 grep $PATOPT "$PATTERN" "${GREPOPTS[@]}"
        codes=(${PIPESTATUS[@]}) && exitCode
    else
        grep $PATOPT "$PATTERN" "${GREPOPTS[@]}" "${FILES[@]}"
        exit
    fi

else
    PATHS='.'
fi

find "${PATHS[@]}" "${NAMES[@]}" -type f -print0 | \
xargs -0 grep $PATOPT "$PATTERN" "${GREPOPTS[@]}"
codes=(${PIPESTATUS[@]}) && exitCode
# }}}

# vim:set ts=4 sw=4 et fdm=marker:
