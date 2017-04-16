#!/usr/bin/env python
# encoding: utf-8

import sys
import json

def main():
    pkg_key = 'default'

    if len(sys.argv) < 2:
        print("You must provide a Pipfile path!")
        sys.exit(1)

    if len(sys.argv) > 2 and sys.argv[2] == '--dev':
        pkg_key = 'develop'

    with open(sys.argv[1]) as fd:
        pf = json.load(fd)
        pkgs = pf.get(pkg_key)
        if not pkgs:
            sys.exit(0)

        for k, v in pkgs.items():
            print("%s%s" % (k, v.get('version')))

if __name__ == '__main__':
    main()
