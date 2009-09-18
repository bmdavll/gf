======
``gf``
======

------------------------------------------------
Grep for a pattern in files returned by ``find``
------------------------------------------------

Usage
=====
::

    gf  [PATH]...  [-e] PATTERN | -f PAT_FILE  [PATH]...
        [ NAME | ^EXCLUDE | GREP_OPT ]...

    gf  [-e] PATTERN | -f PAT_FILE
        [ NAME | ^EXCLUDE | GREP_OPT | FILE ]...

Description
===========

Use ``find`` to search for files in the current directory or the given
``PATH``'s, then grep in found files for a regular expression ``PATTERN``. The
set of files to search in can be refined by one or more filename patterns
``NAME`` and ``EXCLUDE``. Options to ``grep`` also follow the pattern. The
first usage form is same as::

    find [PATH]... [ ! -path "*EXCLUDE*" | -iname NAME ]... -type f \
      -print0 | xargs -0 grep [ -e PATTERN | -f FILE ] [GREP_OPT]...

If this script is run with a name starting with "*e*", ``egrep`` will be used;
likewise for "*f*" and ``fgrep``, and "*p*" and ``grep -P``. In addition to
grep regular expression syntax, the character escapes ``\s``, ``\d``, ``\S``,
and ``\D``, when not inside a bracket expression, are replaced with their
character class equivalents ``[[:space:]]``, ``[[:digit:]]``, etc.

The second usage form relies on no ``PATH``'s and at least one existing
``FILE`` on the comand line, and can be used in conjunction with ``xargs`` or
command-line expansion to filter results::

    ls | xargs -r  gf  PATTERN  "*.py" ^foo
    gf  PATTERN  "*.txt"  `cat filelist`

This also allows ``xargs`` to run ``grep`` with default options, which are
defined in ``$GREPOPTS`` in this script if it hasn't been exported.

Options
=======
::

    -h, --help      display this help message and exit
    -e  PATTERN     use PATTERN as the pattern
    -f  PAT_FILE    read patterns from PAT_FILE

Examples
========
::

    gf  "retrasad[oa]"  -in -C 2  README*
    gf  ~/foo/src  '\(import\|from\) popen\d'  "*.py"  ^/.svn/  -l

