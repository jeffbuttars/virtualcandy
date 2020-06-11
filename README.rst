virtualcandy
============

Smart shell integration for Python_'s Virtualenv_ with poetry_
-----------------------------------------------------------------


Virtualcandy provides Virtualenv_ integration with your Bash or Zsh shell
that provides automatic activation and decativation of Virtualenv_ as you
navigate between Python_ projects that utilize Virtualenv_. Virtualcandy
also provides extra utilities to make working with Pip, Virtualenv_ and Poetry_
a more cohesive experience.

This is a set of shell wrappers that I've built, like, and use
everyday. It is oppinionated but aims to be configurable.

* Installation_
* `Philosophy of Virtualenv`_
* Configuration_
* `Shell Functions`_
    - vcstart_
    - vcin_
    - vcup_
    - vcfreeze_
    - vcclean_
    - vcpkgskel_
    - vcactivate_
    - vcfindenv_
    - vcfinddir_
    - vcproj_
    - vc_auto_activate_
    - vcpkgs_
* `Per project settings`_
    - `Available config variables`_
* References_


Installation
============

Install the package via pip:: sh

    pip install virtualcandy

You'll need to perform a manual installation step to integrate Virtualcany with your shell.
Virtualcany has utility command called ``vcpkgs`` that will help with this step.
To get the shell snippet with a brief instruction run the command:: sh

    vcpkgs install

That will give you instructions for your current shell environment.
That's it, VirtualCandy is installed!

Philosophy of Virtualenv
===========================

My usage of Virtualenv_ is very similar to how one uses Git.
I create one Virtualenv_ environment per project and that Virtualenv_ environment
is located at the top of the project's directory tree(in the same directory the ``.git`` directory would be). I also name
all of my Virtualenv_ directories the same name, ``.venv``, and this project
uses that as the default Virtualenv_ directory name. But that is configurable.

Most VirtualCandy functions can be used from anywhere within a project using a
Virtualenv_. VirtualCandy will find the nearest install of Virtualenv_ by traversing
up the directory tree until one or no Virtualenv_ are found.

Configuration
===========================

Configuration is done via shell environemental variables. To change a configuration
variable, set and export the variable in your ``.bashrc`` or ``.zshrc`` before
virtualcandy is sourced.

Available config variables
------------------------------

* ``PYTHON_ENV`` (Optional) If set to ``development``, dev packages (if present) will be installed. Otherwise only default packages will be installed.
* ``VC_DEFAULT_VENV_NAME`` (Optional) Name of the Virtualenv directory, default is '.venv'
* ``VC_DEFAULT_VENV_REQFILE`` (Optional) Name of the requirements file, default is 'requirements.txt'
* ``VC_AUTO_ACTIVATION`` (Optional) Enable auto Virtualenv activation, default is true
* ``VC_PYTHON_EXE`` (Optional) Python executable to use for the Virtualenv, default is $(basename $(which python)) with a bias to Python 3.X
* ``VC_VIRTUALENV_EXE`` (Optional) Virtualenv command to use, default is virtualenv

Mac OS
------------------------------

Virtualcandy relies on the GNU version of sed. Use homebrew to install ``gnu-sed``
(``brew install gnu-sed``) and make sure you add ``/usr/local/bin`` to your ``PATH`` variable.

In your ``~/.bashrc`` or ``~/.bash_profile`` add the line:

``export PATH=/usr/local/bin:$PATH``

if it's not already present.


Naming it:
------------------------------

Set the name of your Virtualenv_

    VC_DEFAULT_VENV_NAME='.venv'


Requirements files:
------------------------------

Set the name of the requirements file used by Pip_ freeze and VirtualCandy to store your installed package information

    VC_DEFAULT_VENV_REQFILE='requirements.txt'

Auto activation:
------------------------------

The auto activation (when set to 'true', it's off by default) of a Virtualenv_ when you enter its containing directory.
If you use Virtualenv_ often, this is a very handy option.
Example: If you have a directory named ~/Dev1 that has a Virtualenv_ in it. Then upon changing into the ~/Dev1 directory that Virtualenv_ will be activated.
If you a Virtualenv_ activated and cd into a directory containing a Virtualenv_ that is different from the currently activated Virtualenv_, then the current Virtualenv_ will be deactivated and the new one will be activated.

    VC_AUTO_ACTIVATION=true

Shell Functions
================

vcstart
-------------

Start a new virtualenv, or build one from a requirements file. This
function only works on your current working directory(all other functions work
anywhere within a [Virtualenv](http://www.virtualenv.org/en/latest/index.html) project). If you run ``vcstart`` in a
directory without a [Virtualenv](http://www.virtualenv.org/en/latest/index.html) of the name defined by ``$VC_DEFAULT_VENV_NAME`` ,
then a new [Virtualenv](http://www.virtualenv.org/en/latest/index.html) will be created. After the [Virtualenv](http://www.virtualenv.org/en/latest/index.html) is created, if a
requirements file is present, all of the packages listed in the
requirements file will be installed. If a [Virtualenv](http://www.virtualenv.org/en/latest/index.html) defined by the name
``$VC_DEFAULT_VENV_NAME`` already exists and a requirements file exists then no
new [Virtualenv](http://www.virtualenv.org/en/latest/index.html) will be created, the packages listed in a present requirements file will be
installed/updated if necessary.

Any arguments given to the ``vcstart`` command will be considered package names and
will be installed after the virtualenv is created. If package parameters are given
and there is an existing requirements.txt file, the requirements.txt file we be
updated to include the additional packages.

vcactivate
---------------

``vcactivate`` will activate the [Virtualenv](http://www.virtualenv.org/en/latest/index.html) of the current project. ``vcactivate`` finds
the current project by using the ``vcfindenv`` command.

vcin
----
Install a package into the current
[Virtualenv](http://www.virtualenv.org/en/latest/index.html)
and update the requirements file.

Ex:

    # install the latest versions of Django and djnagorestframework
    # and update the requirements file
    vcin Django djnagorestframework


A wrapper around ``pip install``. All arguments to ``vcin`` are passed to ``pip
install``. After ``pip install`` is run ``vcfreeze`` is run.

vcup
-----------

This will upgrade all of the packages listed in the requirements file to their
latest version and then re-write the requirements file to reflect the update.

vcpkgskel
-----------

Create a Python package skeleton of the specified name. This includes some
boilerplate code for ``Makefile``, ``setup.py`` and ``pkg_name.__init__.py``:: sh

    vcpkgskel <package-name>

Will create a folder structure::

    <package-name>
      LICENSE.txt
      MANIFEST.in
      README.rst
      Makefile
      requirements.txt
      setup.py
      \
       <package_name> (directory for package sources)
         __init__.py

The ``README.md`` and ``setup.py`` will include boilerplate. Also the ``__init__.py``
includes default version variables::

    __version__ = "0.1.0.dev1"
    __version_info__ = (0, 1, 0, 'dev1')

vcfreeze
-----------

Write a new requirements file for the current [Virtualenv](http://www.virtualenv.org/en/latest/index.html). The
requirements file contents are the result of the ``pip freeze`` command. The
requirements file is written in the same directory that contains the
[Virtualenv](http://www.virtualenv.org/en/latest/index.html) directory, even if the command is ran in a subdirectory.
If you don't want to name the output file to be ``requirements.txt``, you can
change the name of the output file with the ``$VC_DEFAULT_VENV_REQFILE``
environmental variable.


vcclean
-----------

Recursively clean files matching a set of patterns.  
**Be careful using this. It's very convenient and very destructive**  
By default the file patterns ``*.pyc`` and ``*.pyo`` will be matched by default and
without question. You can add additional patterns as parameters::

    # Ex: clean out all files ending in .txt and .md
    vcclean '*.txt' '*.md'

    # Ex: clean out all tags files.
    vcclean tags

If additional patterns are given you will be prompted to confirm the use of the
additional patterns. 
``vcclean`` is just a wrapper around::

    find . -iname "<pattern>" | xargs rm -fv


vc_auto_activate
-----------------

Checks the current directory for a [Virtualenv](http://www.virtualenv.org/en/latest/index.html) named VC\_DEFAULT\_VENV\_NAME. If it exists it is activated. This function is put into the PROMPT\_COMMAND variable and executed on every changed of directory.
This function is intended for internal use by VirtualCandy itself, but it is
available to the user.

vcfindenv
-----------------

This will find and print the full path of the current project's [Virtualenv](http://www.virtualenv.org/en/latest/index.html)
location.
This function is intended for internal use by VirtualCandy itself, but it is
available to the user.

vcfinddir
-----------------


This is used to find the nearest directory containing the [Virtualenv](http://www.virtualenv.org/en/latest/index.html) named by
the ``$VC_DEFAULT_VENV_NAME`` bash variable. For instance you have [Virtualenv](http://www.virtualenv.org/en/latest/index.html)
located at::

    ``/home/user/project``

and you run vcfinddir from the directory::

    ``/home/user/project/a/subdir``

the result will be::

    ``/home/user/project``

This function is intended for internal use by VirtualCandy itself, but it is
available to the user.


vcproj
-----------------

This will print out environemental variables used by VirtualCandy to stdout. This can be useful for
creating a base ``.vc_proj`` file for a project.


vcpkgs
-------


Per project settings
============================================

You can use per project Virtualcandy settings by adding a file named ``.vc_proj`` in
the same directory as your ``requirements.txt`` file. The ``.vc_proj`` file will be sourced
every time a Virtualcandy command is used. Settings in the ``.vc_proj`` file is a simple matter
of setting shell variables.

Example ``.vc_proj`` file that sets the Python executable to Python3 and sets the name of the
Virtualenv directory to ``.vc_venv``

```sh
VC_PYTHON_EXE=python3
VC_DEFAULT_VENV_NAME='.vc_venv'
```

It's helpful to use the ``vcproj`` command to create a base ``.vc_proj`` file with defaults to get
started with:

```sh
vcproj > .vc_proj
```


References
=================

* Python_
* Virtualenv_
* [Pip](http://pypi.python.org/pypi/pip)
* Poetry_

.. _Python: http://www.python.org/
.. _Virtualenv: http://www.virtualenv.org/en/latest/index.html
.. _Poetry: https://python-poetry.org/
.. _Pip: http://pypi.python.org/pypi/pip
