cat << __EOF__
#!/usr/bin/env python


import os
from pip.req import parse_requirements
from setuptools import setup, find_packages

import $pkg_name_u


def get_requires(rname='requirements.txt'):
    this_dir = os.path.realpath(os.path.dirname(__file__))
    fname = os.path.join(this_dir, rname)
    reqs = parse_requirements(fname)
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
__EOF__
