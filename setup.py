#!/usr/bin/env python


import os
import sys
from pip.req import parse_requirements
from pip.download import PipSession
from setuptools import setup, find_packages

THIS_DIR = os.path.basename(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(THIS_DIR, 'virtualcandy'))
import virtualcandy


def get_requires(rname='requirements.txt'):
    this_dir = os.path.realpath(os.path.dirname(__file__))
    fname = os.path.join(this_dir, rname)
    res = []

    # We work around a pip bug here.
    try:
        reqs = parse_requirements(fname)
        res = [str(ir.req) for ir in reqs]
    except TypeError:
        reqs = parse_requirements(fname, session=PipSession())
        res = [str(ir.req) for ir in reqs]

    return res


setup(
    name="virtualcandy",
    version=virtualcandy.__version__,
    packages=find_packages(),
    author="jeff",
    author_email="jeff@example.com",
    description="Virtualcandy description",
    # license="Apache",
    url="https://github.com/jeffbuttars/virtualcandy",

    long_description=open('README.rst').read(),

    # classifiers=[
    #     'License :: OSI Approved :: Apache Software License',
    #     'Operating System :: POSIX',
    #     'Programming Language :: Python',
    #     'Programming Language :: Python :: 2.6',
    #     'Programming Language :: Python :: 2.7',
    #     'Topic :: Internet',
    # ],

    install_requires=get_requires() + []
)
