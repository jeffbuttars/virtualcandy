cat << __EOF__
#!/usr/bin/env python


import os
import sys
from pip.req import parse_requirements
from pip.download import PipSession
from setuptools import setup, find_packages

THIS_DIR = os.path.basename(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(THIS_DIR, '$pkg_name_u'))
import $pkg_name_u


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
    name="$pkg_name",
    version=${pkg_name_u}.__version__,
    packages=find_packages(),
    author="$USER",
    author_email="$USER@example.com",
    description="$pkg_name_title description",
    # license="Apache",
    url="https://github.com/jeffbuttars/virtualcandy",

    long_description=open('README.md').read(),

    # classifiers=[
    #     'License :: OSI Approved :: Apache Software License',
    #     'Operating System :: POSIX',
    #     'Programming Language :: Python',
    #     'Programming Language :: Python :: 3.8',
    #     'Topic :: Internet',
    # ],

    install_requires=get_requires() + []
)
__EOF__
