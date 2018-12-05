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

# export _VC_DEF_CONFIG="${THIS_DIR}/vc_config.sh"

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

    VC_VIRTUALENV_EXE=virtualenv

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

_vc_source_project_file()
{
    # If VIRTUAL_ENV is set, source the proj file in that dir, if it exists.
    # Else, look in the current dir
    # Otherwise, try to find it with 'pipenv --where'.
    local vdir=$(vcfinddir)
    local vpf="$vdir/$VC_PROJECT_FILE"

    if [[ -f "$vpf" ]]; then
        if [[ "$SHELL" == "bash" ]]; then
            . "$vpf"
        else
            source "$vpf"
        fi
    fi
}


function _vcfinddir()
{
    # 1 If VIRTUAL_ENV is set, use it's value
    # 2 If 1 fails, ask pipenv
    # 3 If 2 fails, traverse up the file system
    local cur=$PWD
    local vname=$VC_VENV_NAME
    local found='false'
    local vpf=""

    if [[ -n "$VIRTUAL_ENV" ]]; then
        vpf="$(dirname $VIRTUAL_ENV)"
    else
        vpf=$(PIPENV_VERBOSITY=-1 pipenv --where --bare)
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
    local igfile="$(vcfinddir)/.gitignore"

    if [[ ! -f $igfile ]]; then
        echo "$VC_VENV_NAME" > $igfile
        echo "*.pyo" >> $igfile
        echo "*.pyc" >> $igfile
        git add $igfile
    else
        echo "A .gitignore already exists, doing nothing."
    fi
}


# Start a new virtualenv, or
# rebuild one from a Pipenv file.
function _vcstart()
{
    _vc_source_project_file

    local vname=$VC_VENV_NAME

    if [[ -e "$vname" ]]; then
        pr_fail "A virtualenv already exists here, acitvating and bailing out!"
        vcactivate
        return 1
    fi

    # Create the virtualenv.
    pr_info "$VC_VIRTUALENV_EXE --python=$VC_PYTHON_EXE $vname"
    $VC_VIRTUALENV_EXE --python=$VC_PYTHON_EXE $vname
    pr_info "Pre-Activating..."
    . $vname/bin/activate

    pr_info "Updating pip to the latest for the virtualenv"
    pip install --upgrade pip

    # install local pipenv!
    pr_info "Installing project pipenv"
    pip install pipenv

    # Do a little dance to get the virtualenv pipenv into our path
    _vcdeactivate
    pr_info "Deactivating after pipenv install..."
    . $vname/bin/activate
    pr_info "Re-Activating after pipenv install, $(which pipenv)"

   # Initialize pipenv and install any packages we track
    _install
    if [[ -n "$1" ]]; then
        # Install any additional packages given with the command,
        # then lock and freeze them
        _install $@
    fi

    if [[ -n "$VC_VENV_INITIAL_PKGS" ]]; then
        # Install any initial packages given by the environment,
        pr_info "Installing initial packages: $VC_VENV_INITIAL_PKGS"
        _install "$VC_VENV_INITIAL_PKGS"
    fi

    if [[ -n "$VC_VENV_INITIAL_DEV_PKGS" ]]; then
        # Install any initial development packages given by the environment,
        pr_info "Installing initial deveopment packages: $VC_VENV_INITIAL_DEV_PKGS"
        _install --dev "$VC_VENV_INITIAL_DEV_PKGS"
    fi

   # Create a .vc_proj file if one doesn't exist
   if [[ ! -f $VC_PROJECT_FILE ]]; then
      _vc_proj > $VC_PROJECT_FILE
   fi

   return 0
}

# Upgrade the nearest virtualenv packages
# and re-freeze them
function _vcup()
{
    local vdir=$(vcfinddir)
    local vname=$VC_VENV_NAME

    if [ -n "$1" ]; then
        local def_pkgs=''
        local dev_pkgs=''
        local pipfile="$vdir/Pipfile.lock"

        for pkg in $@ ; do
            $develop=$(cat $pipfile | jq "select(.develop.$pkg)")
            $default=$(cat $pipfile | jq "select(.default.$pkg)")

            local has_pkg="${develop}${default}"

            if [[ -z $has_pkg ]]; then
                pr_fail "The package '$pkg' is not installed, bailing out."
                return 1
            fi

            if [[ -n $develop ]]; then
                dev_pkgs="$dev_pkgs $pkg"
            else
                def_pkgs="$def_pkgs $pkg"
            fi
        done

        if [[ -n "$def_pkgs" ]]; then
            pr_info "Removing production packages: $def_pkgs "
            eval pipenv uninstall $def_pkgs

            pr_pass "Updating production packages: $def_pkgs "
            eval pipenv install $def_pkgs
        fi

        if [[ -n "$dev_pkgs" ]]; then
            pr_info "Removing development packages : $dev_pkgs"
            eval pipenv uninstall $dev_pkgs

            pr_pass "Updating development packages: $dev_pkgs "
            eval pipenv install --dev $dev_pkgs
        fi

    else
        pr_info "Updating all packages..."
        pipenv update
    fi

    res="$?"
    return $res
}

function _vcfindenv()
{
    cur=$PWD
    local vdir=$(vcfinddir)
    local vname=$VC_VENV_NAME
    local res=""

    if [[ -n "$vdir" ]]; then
        res="$vdir/$vname"
    fi

    echo $res
}

function _vcactivate()
{
    # Prefer a new shell environment via 'pipenv shell' if it's configured
    if [[ "$VC_VENV_NEW_SHELL" == 'true' ]]; then
        # The new shell will try to activate when it's started,
        # so avoid the nesting warning from pipenv
        if [[ -n $PIPENV_ACTIVE ]]; then
            return
        fi

        pr_info "Activating environment in a new shell ..."
        _vc_source_project_file
        pipenv shell
        return
    fi

    local vname=$VC_VENV_NAME
    local vloc=''

    vloc=$(vcfindenv)

    if [[ -n "$vloc" ]]; then
       pr_pass "Activating ~${vloc#$HOME/}"
       . "$vloc/bin/activate"
       # Source a second time, after we enter the virtualenv
       # There is no guarentee we sourced on the first call, and not necessary.
       # But we _should_ source anytime things are activated and we have a known venv dir.
       _vc_source_project_file
    else
       pr_fail "No virtualenv named $vname found."
    fi
}

function _vcmod()
{
    if [[ -z $1 ]]
    then
        pr_fail "$0: At least one module name is required."
        return 1
    fi

    for m in $@ ; do
        mkdir -p "$m"
        if [[ ! -f "$m/__init__.py" ]]
        then
            touch "$m/__init__.py"
        else
            pr_info "$0: A module named $m already exists."
        fi
        pr_pass "created $m/__init__.py"
    done

    return 0
}

# Private func, installs pkgs only, no freeze or locking.
_install()
{
    _vc_source_project_file
    local args='install'

    if [[ -z $1 ]]
    then
        pr_info "Installing project packages..."

        if [[ $PYTHON_ENV == 'debug' ]]; then
            args="$args --dev"
            pr_info "\tInstalling project dev packages as well"
        fi

        eval pipenv $args
    else
        # Install whatever params are given
        args="$args $@"
        eval pipenv $args
    fi
}

_vcin()
{
    _install $@
}

_vcrem()
{
    eval pipenv uninstall $@
}

function _vc_auto_activate()
{
    # see if we're under a virtualenv.
    local c_venv="$(vcfindenv)"

    if [[ -n "$c_venv" ]]; then
        # We're in/under an environment.
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
            vcactivate
        fi
    elif [[ -n "$VIRTUAL_ENV" ]]; then
        # We've left an environment, so deactivate.
        pr_info "Deactivating ~/${VIRTUAL_ENV#$HOME/}\n"
        if [[ -n $PIPENV_ACTIVE ]]; then
            exit
        fi
       _vcdeactivate
    fi
}


function _vc_reset()
{
    local to="$(vcfindenv)"
    # If we can't find an env and the current directory 'looks' like a project, use cwd
    if [[ ! -d "$to" ]]; then
        if [[ -f 'Pipfile' ]] || [[ -f "$VC_VENV_REQFILE" ]]; then
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
        if [[ "$?" != '0' ]]; then
            pr_fail "vcreset error while removing $to"
            return 1
        fi
        cd $dto
        pr_info "vcreset restarting virtualenv in $dto"
        _vcstart
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
    echo "# $pkg_name_title\n" > $pkg_name/README.rst
    echo "include LICENSE.txt\ninclude README.rst" > "$pkg_name/MANIFEST.in"

    # Add an __init__.py with version vars
    tmp_out=$(. "${TMPL_DIR}/pkg_init.tmpl.sh")
    echo "$tmp_out" > "$pkg_name/$pkg_name_u/__init__.py"

    # Add an initial setup.py
    tmp_out=$(. "${TMPL_DIR}/pkg_setup.tmpl.sh")
    echo "$tmp_out" > "$pkg_name/setup.py"

    # Add a Makefile
    tmp_out=$(. "${TMPL_DIR}/pkg_makefile.tmpl.sh")
    echo "$tmp_out" > "$pkg_name/Makefile"

    return 0
}

function _vc_clean()
{
    # Do some basic python specific and general cleaning from current directory.
    # Args will be treated as find -iname parameters and be deleted!
    find . -iname '*.pyc' | xargs rm -fv
    find . -iname '*.pyo' | xargs rm -fv

    if [[ -n "$1" ]]; then
        if [[ $REPLY =~ ^[yY]$ ]]; then
            for re in $@ ; do
                find . -iname "$re" | xargs rm -fv
            done
        fi
    fi
}

function _vc_proj()
{
    # Spit out the current VC environment vars.
    # suitable for a skeleton .vc_proj file
    echo "# VC_PYTHON_EXE The python executable name to use"
    echo "VC_PYTHON_EXE='$VC_PYTHON_EXE'"
    echo ""
    echo "# VC_VIRTUALENV_EXE The name of the virtualenv executable to use"
    echo "VC_VIRTUALENV_EXE='$VC_VIRTUALENV_EXE'"
    echo ""
    echo "# VC_VENV_NEW_SHELL use 'pipenv shell' to enter the virtualenv in a new shell"
    echo "VC_VENV_NEW_SHELL='false'"
    echo ""
    echo "# PIPENV_VENV_IN_PROJECT"
    echo "export PIPENV_VENV_IN_PROJECT=$VC_VENV_NAME"
    echo ""
    echo "### Initial packages always installed on project creation ###"
    echo "# VC_VENV_INITIAL_PKGS"
    echo "export VC_VENV_INITIAL_PKGS=$VC_VENV_INITIAL_PKGS"
    echo ""
    echo "# VC_VENV_INITIAL_DEV_PKGS"
    echo "export VC_VENV_INITIAL_DEV_PKGS=$VC_VENV_INITIAL_DEV_PKGS"


}
