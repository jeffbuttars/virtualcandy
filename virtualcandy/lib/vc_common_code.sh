# VirtualCandy
# Use at your own risk, no quarentee provided.
# Author: Jeff Buttars
# git@github.com:jeffbuttars/virtualcandy.git
# See the README.md

KNRM="\033[0m"
KRED="\033[0;31m"
KGRN="\033[0;32m"
KYEL="\x1B[33m"
KBLU="\033[0;34m"
KMAG="\x1B[35m"
KCYN="\x1B[36m"
KWHT="\x1B[37m"

TMPL_DIR="${THIS_DIR}/tmpl"
. "${THIS_DIR}/vc_config.sh"

pr_pass()
{
    echo -en "${KGRN}$*${KNRM}\n" >&2
}

pr_fail()
{
    echo -en "${KRED}$*${KNRM}\n" >&2
}

pr_info()
{
    echo -en "${KBLU}$*${KNRM}\n" >&2
}

SED='sed'
which gsed > /dev/null 2>&1
if [[ "$?" == "0" ]]; then
    SED='gsed'
fi

# Common code sourced by both bash and zsh
# implimentations of virtualcandy.
# Shell specific code goes into each shells
# primary file.

if [[ -z $VC_VIRTUALENV_EXE ]]
then

    VC_VIRTUALENV_EXE='python -m venv'

    # If we think we're using python2, try to use virtualenv2 if
    # it's available
    $VC_PYTHON_EXE --version 2>&1 | awk '{print $2}' | grep -e '^2*$'
    res="$?"
    if [[ "$res" == "0" ]]; then
        which virtualenv2 > /dev/null 2>&1
        res="$?"
        if [[ "$res" == "0" ]]; then
            VC_VIRTUALENV_EXE=$(basename "$(which virtualenv2)")
        fi
    fi
fi

_vcdeactivate()
{
    if [[ -n "$VIRTUAL_ENV" ]]; then
        deactivate > /dev/null 2>&1
    fi
}

function _vc_find_dir()
{
    # 1 If VIRTUAL_ENV is set, use it's value
    # 2 If 1 fails, ask poetry
    # 3 If 2 fails, traverse up the file system
    local cur=$PWD
    local vname=$VC_VENV_NAME
    local found='false'
    local vpf=""

    if [[ -n "$VIRTUAL_ENV" ]]; then
        vpf="$(dirname $VIRTUAL_ENV)"
    else
        vpf=$(dirname $(poetry env info --path 2>/dev/null) 2>/dev/null)
    fi

    if [[ -n $vpf ]]; then
        if [[ -d "$vpf/$vname" ]]; then
            echo $vpf
            return 0
        fi
    fi

    # Traverse up the filesystem until something is found or we reach the top
    while [[ "$cur" != "/" ]]; do
        if [[ -d "$cur/$vname" ]]; then
            found="true"
            echo "$cur"
            return 0
        fi

        cur=$(dirname $cur)
    done

    echo ""
}

_vc_ignore()
{
    # Add a git ignore with python friendly defaults.
    local igfile="$(_vc_find_dir)/.gitignore"

    if [[ ! -f $igfile ]]; then
        echo "$VC_VENV_NAME" > $igfile
cat >> $igfile <<EOF
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# C extensions
*.so

# Distribution / packaging
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
share/python-wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# PyInstaller
#  Usually these files are written by a python script from a template
#  before PyInstaller builds the exe, so as to inject date/other infos into it.
*.manifest
*.spec

# Installer logs
pip-log.txt
pip-delete-this-directory.txt

# Unit test / coverage reports
htmlcov/
.tox/
.nox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
*.py,cover
.hypothesis/
.pytest_cache/
cover/

# Translations
*.mo
*.pot

# Django stuff:
*.log
local_settings.py
db.sqlite3
db.sqlite3-journal

# Flask stuff:
instance/
.webassets-cache

# Scrapy stuff:
.scrapy

# Sphinx documentation
docs/_build/

# PyBuilder
.pybuilder/
target/

# Jupyter Notebook
.ipynb_checkpoints

# IPython
profile_default/
ipython_config.py

# PEP 582; used by e.g. github.com/David-OConnor/pyflow
__pypackages__/

# Celery stuff
celerybeat-schedule
celerybeat.pid

# SageMath parsed files
*.sage.py

# Environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# Spyder project settings
.spyderproject
.spyproject

# Rope project settings
.ropeproject

# mkdocs documentation
/site

# mypy
.mypy_cache/
.dmypy.json
dmypy.json

# Pyre type checker
.pyre/

# pytype static type analyzer
.pytype/

# Cython debug symbols
cython_debug/
EOF
        git add $igfile
    else
        echo "A .gitignore already exists, doing nothing."
    fi
}


# Start a new virtualenv, or
# rebuild one using poetry
function _vc_init()
{
    local vname=$VC_VENV_NAME
    local fresh_init='false'

    if [[ -e "$vname" ]]; then
        pr_fail "A virtualenv already exists here, acitvating and attempty to re-initialize it."
        _vc_activate
    else
        # If no project file is found, initialize now
        if [[ ! -f "$PWD/pyproject.toml" ]]; then
            pr_info "Initializing project directory"
            poetry init --quiet --no-interaction
            fresh_init='true'
        fi
    fi

    # Initialize poetry and venv
    _vc_install

    pr_info "Activating Virtualenv"
    . $vname/bin/activate

    pr_info "Updating pip to the latest for the virtualenv"
    pip install --upgrade pip

    if [[ -n "$1" ]]; then
        # Install any additional packages given with the command
        # install them one at a time because of any one them is already installed,
        # poetry won't install the others
        for pkg in $@; do
            _vc_install $pkg
        done
        echo
    fi

    if [[ -n "$VC_VENV_INITIAL_PKGS" ]]; then
        # Install any initial packages given by the environment,
        pr_info "Installing initial packages: $VC_VENV_INITIAL_PKGS"
        if [[ "$fresh_init" == "true" ]]; then
            _vc_install $VC_VENV_INITIAL_PKGS
        else
            for pkg in $(echo $VC_VENV_INITIAL_PKGS) ; do
                _vc_install $pkg
            done
        fi
    fi

    if [[ -n "$VC_VENV_INITIAL_DEV_PKGS" ]]; then
        # Install any initial development packages given by the environment,
        pr_info "Installing initial deveopment packages: $VC_VENV_INITIAL_DEV_PKGS"
        if [[ "$fresh_init" == "true" ]]; then
            _vc_install --dev $VC_VENV_INITIAL_DEV_PKGS
        else
            for pkg in $(echo $VC_VENV_INITIAL_DEV_PKGS) ; do
                _vc_install --dev $pkg
            done
        fi
    fi

    _vc_install
   return 0
}

function _vcfindenv()
{
    cur=$PWD
    local vdir=$(_vc_find_dir)
    local vname=$VC_VENV_NAME
    local res=""

    if [[ -n "$vdir" ]]; then
        # if [[ "$(_under_envdir)" ]]; then
        #     res="$vdir/$vname"
        # fi
        res="$vdir/$vname"
    fi


    echo $res
}

function _vc_activate()
{
    # Prefer a new shell environment via 'poetry shell' if it's configured
    if [[ "$VC_VENV_NEW_SHELL" == 'true' ]]; then
        if [[ -n $POETRY_ACTIVE ]]; then
            # Already in an active Poetry env
            return
        fi

        pr_info "Activating environment in a new shell ..."
        poetry shell
        return
    fi

    local vname=$VC_VENV_NAME
    local vloc=''

    vloc=$(_vcfindenv)

    if [[ -n "$vloc" ]]; then
       pr_pass "Activating ~/${vloc#$HOME/}"
       . "$vloc/bin/activate"
       # Source a second time, after we enter the virtualenv
       # There is no guarentee we sourced on the first call, and not necessary.
       # But we _should_ source anytime things are activated and we have a known venv dir.
    else
        pr_fail "No virtualenv named $vname found."
    fi
}

function _vcmod()
{
    if [[ -z $1 ]]
    then
        pr_fail "vcmod: At least one module name is required."
        return 1
    fi

    for m in $@ ; do
        mkdir -p "$m"
        if [[ ! -f "$m/__init__.py" ]]
        then
            touch "$m/__init__.py"
        else
            pr_info "vcmod: A module named $m already exists."
        fi
        pr_pass "created $m/__init__.py"
    done

    return 0
}

# Private func, installs pkgs only, no freeze or locking.
_vc_install()
{
    if [[ -z $1 ]]
    then
        pr_info "Installing existing project..."
        eval poetry install
    else
        # Add whatever params are given as arguments
        eval poetry add $@
    fi
}

_under_envdir()
{
    local vdir=$(_vc_find_dir)
    # pr_info "_under_envdir $vdir"

    if [[ -z $vdir ]]; then
        # pr_info "_under_envdir nope"
        echo ""
        return 0
    fi

    # pr_info "_under_envdir checking '${PWD##$vdir}' == '$PWD'"
    # look for a common ancestor
    # If there is no common ancestor, PWD will equal the lhs
    if [[ "${PWD##$vdir}" == "$PWD" ]]; then
        # pr_info "_under_envdir checking '${PWD##$vdir}' == '$PWD', NOPE"
        echo ""
        return 0
    fi

    # pr_info "_under_envdir YUP $vdir"
    echo $vdir
}

function _vc_auto_activate()
{
    # see if we're under a virtualenv.
    local c_venv="$(_vcfindenv)"
    local under_venv="$(_under_envdir)"

    # pr_info "auto a, c_venv: $c_venv, under_venv: $under_venv"

    if [[ -z $under_venv ]]; then
        if [[ $VIRTUAL_ENV ]]; then
            # Not under the $VIRTUAL_ENV environment
            pr_info "Deactivating ${VIRTUAL_ENV#$HOME/}"
            if [[ -n $POETRY_ACTIVE ]]; then
                exit
            else
                _vcdeactivate
            fi
        fi
    fi

    if [[ -n "$c_venv" ]]; then
        # If we're activated, switch to the new one if it's different from the
        # current.
        if [[ -n "$VIRTUAL_ENV" ]]; then
            from="~/${VIRTUAL_ENV#$HOME/}"
            to="~/${c_venv#$HOME/}"
            if [ "$from" != "$to" ]; then
                pr_info "Switching from '$from' to '$to'"
               _vcdeactivate
            fi
        fi

        if [[ -z $VIRTUAL_ENV ]]; then
            _vc_activate
        fi
    fi
}


function _vc_reset()
{
    local to="$(_vcfindenv)"

    # If we can't find an env and the current directory 'looks' like a project, use cwd
    if [[ ! -d "$to" ]]; then
        if [[ -f 'pyproject.toml' ]] || [[ -f "$VC_VENV_REQFILE" ]]; then
            to="$PWD/$VC_VENV_NAME"
            mkdir $to
            pr_info "vcreset using current directory $PWD"
        fi
    fi

    local dto=$(dirname "$to")
    if [[ -d "$to" ]]; then
        _vcdeactivate
        pr_info "vcreset removing $to"
        rm -fr "$to"

        if [[ -f "$dto/poetry.lock" ]]; then
            rm -f "$dto/poetry.lock"
        fi

        if [[ "$?" != '0' ]]; then
            pr_fail "vcreset error while removing $to"
            return 1
        fi

        cd $dto
        pr_info "vcreset restarting virtualenv in $dto"
        _vc_init
        cd -
    fi

    return 0
}

function _vc_pkgskel()
{
    if [[ -z $1 ]]; then
        pr_fail "a package name is required"
        pr_fail "vcpkgskel <package-name>"
    fi

    local pkg_name="$1"

    if [[ -d "$pkg_name" ]]; then
        pr_fail "A directory named $pkg_name already exists."
        pr_fail "Not building package skeleton for $pkg_name."
        return 1
    fi

    local pkg_name_u=$(echo "$pkg_name" | $SED -e 's/-/_/g') # underscored
    local pkg_name_s="$(echo $pkg_name_u | $SED -e 's/_/ /g')" # spaces
    local pkg_name_title="$(echo $pkg_name_s | $SED -e 's/\b\(.\)/\u\1/g')" # titled

    mkdir -p "$pkg_name"
    mkdir -p "$pkg_name/tests"
    mkdir -p "$pkg_name/$pkg_name_u"
    touch "$pkg_name/LICENSE.txt"

    # Create some boilerplate
    echo "# $pkg_name_title\n" > $pkg_name/README.md
    echo "include LICENSE.txt\ninclude README.md" > "$pkg_name/MANIFEST.in"

    # Add an __init__.py with version vars
    tmp_out=$(. "${TMPL_DIR}/pkg_init.tmpl.sh")
    echo "$tmp_out" > "$pkg_name/$pkg_name_u/__init__.py"

    # Add an initial setup.py
    tmp_out=$(. "${TMPL_DIR}/pkg_setup.tmpl.sh")
    echo "$tmp_out" > "$pkg_name/setup.py"

    return 0
}

function _vc_clean_dirs()
{
    # Do some basic python specific and general cleaning from current directory.
    # Args will be treated as find -iname parameters and be deleted!
    find . -not -path "*/$VC_VENV_NAME/*" -not -path "*/.git/*" -iname '*.pyc' | xargs rm -fv
    find . -not -path "*/$VC_VENV_NAME/*" -not -path "*/.git/*" -iname '*.pyo' | xargs rm -fv
    find . -not -path "*/$VC_VENV_NAME/*" -not -path "*/.git/*" -iname '__pycache__' | xargs rm -frv
}

function _vc_help()
{
    echo "VirtualCandy, poetry and virtualenv convenience wrapper"
    echo "usage: vc <sub_cmd> [arguments]"
    echo
    echo "  Syntax: vc <subcommand> [arguments]"
    echo "  sub commands:"
    echo "  init:     Initialize a new project, in the current directory, with an activated virtualenv"
    echo "      args:        optional pacakges to install after activation"
    echo "                   [pkg_name] | [pkg_name] | ..."
    echo "  freeze:      Create a requirements.txt for the current or nearest environment."
    echo "  clean:       Recursively clean up common temporary files from the current directory"
    echo "  ignore:      Create a Python specific .gitignore in the current directory"
    echo "  reset:       Deactivate and re-init current environment"
    echo "  activate:    Activate the nearest virtualenv"
    echo
    echo "  Any other sub commands will be passed to a 'poetry' command call"
    echo "$(poetry --help)"
}


function vc() {
    # Use a single function as the entry point, with sub commands
    if [[ -z $1 ]]
    then
        _vc_help
        return 1
    fi

    local sub_cmd="$1"
    shift

    if [[ "$sub_cmd" == "activate" ]]; then
        _vc_activate $@
        return 0
    fi

    if [[ "$sub_cmd" == "add" ]]; then
        poetry add $@
        return 0
    fi

    if [[ "$sub_cmd" == "install" ]]; then
        poetry install $@
        return 0
    fi

    if [[ "$sub_cmd" == "reset" ]]; then
        _vc_reset
        return 0
    fi

    if [[ "$sub_cmd" == "init" ]]; then
        _vc_init $VC_CMD_INIT_ARGS $@
        return 0
    fi

    if [[ "$sub_cmd" == "freeze" ]]; then
        _vc_activate
        poetry export --format requirements.txt --output requirements.txt $VC_CMD_FREEZE_ARGS $@
        return 0
    fi

    if [[ "$sub_cmd" == "clean" ]]; then
        echo -n "Are you sure you want to recursively clean files y/N ? "
        read REPLY

        case $REPLY in
            [Yy]) _vc_clean_dirs ;;
            [Nn]) ;;
            *) ;;
        esac
        return 0
    fi

    if [[ "$sub_cmd" == "ignore" ]]; then
        _vc_ignore
        return 0
    fi

    if [[ "$sub_cmd" == "help" ]]; then
        _vc_help
        return 0
    fi

    eval poetry $sub_cmd $@
}
