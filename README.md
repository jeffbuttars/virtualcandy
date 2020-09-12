# VirtualVandy

A simple wrapper around `poetry` with some basic shell integration


## Installation

Install the package via pip:: sh

    pip install virtualcandy

You'll need to perform a manual installation step to integrate Virtualcany with your shell.
Virtualcany has utility command called ``vcpkgs`` that will help with this step.
To get the shell snippet with a brief instruction run the command:: sh

    vcpkgs install

That will give you instructions for your current shell environment.
That's it, VirtualCandy is installed!

## Philosophy of Virtualenv

My usage of Virtualenv_ is very similar to how one uses Git.  

I create one Virtualenv_ environment per project and that Virtualenv_ environment
is located at the top of the project's directory tree(in the same directory the ``.git`` directory would be). I also name
all of my Virtualenv_ directories the same name, ``.venv``, and this project
uses that as the default Virtualenv_ directory name. But that is configurable.

Most VirtualCandy functions can be used from anywhere within a project using a
Virtualenv_. VirtualCandy will find the nearest install of Virtualenv_ by traversing
up the directory tree until one or no Virtualenv_ are found.

## Configuration

Configuration is done via shell environemental variables. To change a configuration
variable, set and export the variable in your ``.bashrc`` or ``.zshrc`` before
virtualcandy is sourced.

## Available config variables

* ``VC_VENV_INITIAL_PKGS``
* ``PYTHON_ENV`` (Optional) If set to ``development``, dev packages (if present) will be installed. Otherwise only default packages will be installed.
* ``VC_DEFAULT_VENV_NAME`` (Optional) Name of the Virtualenv directory, default is '.venv'
* ``VC_DEFAULT_VENV_REQFILE`` (Optional) Name of the requirements file, default is 'requirements.txt'
* ``VC_AUTO_ACTIVATION`` (Optional) Enable auto Virtualenv activation, default is true
* ``VC_PYTHON_EXE`` (Optional) Python executable to use for the Virtualenv, default is $(basename $(which python)) with a bias to Python 3.X
* ``VC_VIRTUALENV_EXE`` (Optional) Virtualenv command to use, default is virtualenv
* ``VC_CMD_INIT_ARGS``
* ``VC_CMD_FREEZE_ARGS``


## Naming it:

Set the name of your Virtualenv_

    VC_DEFAULT_VENV_NAME='.venv'


## Auto activation:

The auto activation (when set to 'true', it's off by default) of a Virtualenv_ when you enter its containing directory.
If you use Virtualenv_ often, this is a very handy option.
Example: If you have a directory named ~/Dev1 that has a Virtualenv_ in it. Then upon changing into the ~/Dev1 directory that Virtualenv_ will be activated.
If you a Virtualenv_ activated and cd into a directory containing a Virtualenv_ that is different from the currently activated Virtualenv_, then the current Virtualenv_ will be deactivated and the new one will be activated.

    VC_AUTO_ACTIVATION=true

## Shell Functions

### vc init

Initialize a new virtualenv. This
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

### vc activate

``vcactivate`` will activate the [Virtualenv](http://www.virtualenv.org/en/latest/index.html) of the current project. ``vcactivate`` finds
the current project by using the ``vcfindenv`` command.

### vc freeze

Write a new requirements file for the current [Virtualenv](http://www.virtualenv.org/en/latest/index.html). The
requirements file contents are the result of the ``pip freeze`` command. The
requirements file is written in the same directory that contains the
[Virtualenv](http://www.virtualenv.org/en/latest/index.html) directory, even if the command is ran in a subdirectory.
If you don't want to name the output file to be ``requirements.txt``, you can
change the name of the output file with the ``$VC_DEFAULT_VENV_REQFILE``
environmental variable.


### vc clean

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
