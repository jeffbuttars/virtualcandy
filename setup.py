#!/usr/bin/env python

import os
import sys
from setuptools import setup

THIS_DIR = os.path.basename(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(THIS_DIR, 'virtualcandy'))
import virtualcandy


setup(
    name="virtualcandy",
    version=virtualcandy.__version__,
    packages=['virtualcandy'],
    author="Jeff Buttars",
    author_email="jeff@jeffbuttars.com",
    description="Virtualcandy description",
    license="Apache",
    url="https://github.com/jeffbuttars/virtualcandy",

    long_description=open('README.rst').read(),

    classifiers=[
       'License :: OSI Approved :: Apache Software License',
       'Operating System :: POSIX',
       'Programming Language :: Python',
       'Topic :: Internet',
    ],

    install_requires=['pipenv'],
    scripts=['virtualcandy/vcshellinstaller'],
    package_data={'virtualcandy': ['lib/*', 'lib/tmpl/*']},

    #  data_files=[
    #      (
    #          '/etc/profile.d/virtualcandy',
    #          ['virtualcandy/vc_common_code.sh', 'virtualcandy/vc_config.sh',
    #           'virtualcandy/virtualcandy.sh', 'virtualcandy/virtualcandy.zsh'
    #           ]
    #      )
    #  ]
)
