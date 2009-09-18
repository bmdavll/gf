#!/usr/bin/env python3

try:
    import sys, random, util
    from os import path
    from math import factorial
except ImportError:
    print("util module is needed", file=sys.stderr)

tokens = (
    '\s',
    '\\',
    '^',
    '[',
    '[[',
    '[^',
    '[:',
    '[:az',
    '[:az:',
    '[:az:]',
    ']',
)

def usage():
    print(path.basename(sys.argv[0]), "N", file=sys.stderr)
    sys.exit(2)

if len(sys.argv) != 2:
    usage()

try:
    n = int(sys.argv[1])
except ValueError:
    usage()

l = len(tokens)
limit = 2**18

if n < 0 or n > l:
    usage()

if factorial(l) / factorial(l-n) <= limit:
    for s in util.permutations(n, tokens):
        print(''.join(s))

else:
    strings = set()

    while len(strings) < limit//2:
        new = ''
        choices = list(tokens)
        for i in range(n):
            token = random.choice(choices)
            choices.remove(token)
            new += token
        if tokens[0] in new:
            strings.add(new)

    for s in strings:
        print(s)

