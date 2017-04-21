#!/usr/bin/env python
# encoding: utf-8

import os
import sys
import json
import argparse
from pprint import pformat


class PipLock(object):

    def __init__(self, fd=None):
        self._fd = fd or open(os.path.join(os.getcwd(), 'Pipfile.lock'), 'r')
        self._pf = json.load(self._fd)
        self._def_key = 'default'
        self._dev_key = 'develop'

    def _to_freeeze_list(self, pkgs):
        res = []
        for k, v in pkgs.items():
            if isinstance(v, dict) and v.get('version'):
                res.append("%s%s" % (k, v.get('version')))

        return res

    def has(self, pkg_name):
        return self.has_def(pkg_name) or self.has_dev(pkg_name)

    def has_dev(self, pkg_name):
        return pkg_name in self.develop

    def has_def(self, pkg_name):
        return pkg_name in self.default

    @property
    def default(self):
        return self._pf.get(self._def_key, {})

    @property
    def default_freeze(self):
        return self._to_freeeze_list(self.default)

    @property
    def develop(self):
        return self._pf.get(self._dev_key, {})

    @property
    def develop_freeze(self):
        return self._to_freeeze_list(self.develop)

    def __str__(self):
        return pformat(self._pf)

    def __repr__(self):
        return pformat(self._pf)


def freeze(args, pl):
    if args.dev:
        print('\n'.join(pl.develop_freeze))
    else:
        print('\n'.join(pl.default_freeze))


def pkgs(args, pl):
    pkg = args.pkg[0]
    res = ''

    if pl.has_def(pkg):
        res = 'default'
    elif pl.has_dev(pkg):
        res = 'develop'

    print(res)


def main(parser):
    args = parser.parse_args()
    pl = PipLock(fd=args.lock_file)

    if hasattr(args, 'func'):
        args.func(args, pl)
        sys.exit(0)

    parser.print_help()
    sys.exit(1)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Virtual Candy packaging helper')
    parser.add_argument('--dev', action='store_true',
                        help='Apply operation as development packaging'
                        )
    parser.add_argument('--lock-file', type=argparse.FileType('r'),
                        help='Specify the path to the lock file'
                        )

    subparsers = parser.add_subparsers()

    parser_freeze = subparsers.add_parser(
        'freeze',
        aliases=['f', 'fr'],
        help="Create 'pip freeze' output from locked packages."
    )
    parser_freeze.add_argument('--freeze', default=True)
    parser_freeze.set_defaults(func=freeze)

    parser_info = subparsers.add_parser(
        'info',
        aliases=['i'],
        help="Get info about a pkg. Currently just reports if a package is default or dev"
    )
    parser_info.add_argument(
        'pkg',
        nargs=argparse.ONE_OR_MORE,
        help="The name of the package to look for info on."
    )
    parser_info.set_defaults(func=pkgs)

    main(parser)
