#!/usr/bin/env python
# encoding: utf-8

import sys
import json
import argparse


def freeze_list(fname, dev=False):
    pkg_key = 'default' if not dev else 'develop'

    with open(fname) as fd:
        pf = json.load(fd)
        pkgs = pf.get(pkg_key)
        if not pkgs:
            sys.exit(0)

        for k, v in pkgs.items():
            print("%s%s" % (k, v.get('version')))


def main(args):
    if args.freeze:
        freeze_list(args.obj_name[0], args.dev)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Virtual Candy packaging helper')
    parser.add_argument('--dev', action='store_true',
                        help='Apply operation as development packaging'
                        )
    parser.add_argument('--freeze', action='store_true',
                        help='Create a pip freeze list from the lock file.'
                        )
    parser.add_argument('--type', action='store_true',
                        help='check if package is default, develop or not in the lock file'
                        )
    parser.add_argument('obj_name', nargs=argparse.ZERO_OR_MORE)

    print(parser.parse_args())
    main(parser.parse_args())
