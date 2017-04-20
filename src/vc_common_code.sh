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

vcfreeze_py="python $THIS_DIR/vcfreeze.py"

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

if [[ -z $VC_VENV_NEW_SHELL ]]
then
    # Highly recommend using 'yes', but the default behavior of
    # virtualenv is not use a new shell, so we mimick it's defaults.
    VC_VENV_NEW_SHELL='false'
fi

_vc_source_project_file()
{
    # If VIRTUAL_ENV is set, source the proj file in that dir, if it exists.
    # Otherwise, look in the current dir.
    local vpf="$PWD/$VC_PROJECT_FILE"

    if [[ -n $VIRTUAL_ENV ]]; then
        vpf="$(dirname $VIRTUAL_ENV)/$VC_PROJECT_FILE"
    fi

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
    cur=$PWD
    vname=$VC_VENV_NAME
    found='false'

    while [[ "$cur" != "/" ]]; do
        if [[ -d "$cur/$vname" ]]; then
            found="true"
            echo "$cur"
            break
        fi

        cur=$(dirname $cur)
    done

    if [[ "$cur" == "/" ]]; then
        found="false"
    fi

    if [[ "$found" == "false" ]]; then
        echo ""
    fi
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
# rebuild one from a requirements.txt file.
function _vcstart()
{
    _vc_source_project_file

    # if [[ "$VC_VENV_NEW_SHELL" == 'true' ]]; then
    #     # get our current shell
    #     C_SHELL="$SHELL"

    #     # Enter the new shell and start up the env.
    #     $C_SHELL -c "$THIS_DIR/vc_new_shell.sh"
    # fi

    local vname=$VC_VENV_NAME

    if [[ -e "$vname" ]]; then
        pr_fail "A virtualenv already exists here, bailing out!"
        exit 1
    fi

    # Create the virtualenv.
    pr_info "$VC_VIRTUALENV_EXE --python=$VC_PYTHON_EXE $vname"
    $VC_VIRTUALENV_EXE --python=$VC_PYTHON_EXE $vname
    . $vname/bin/activate

    # install pipenv!
    pr_info "Installing pipenv"
    pip install pipenv

   # Initialize pipenv and install any packages we track
    _vcin
    if [[ -n $1 ]]; then
        # Install any additional packages given with the command
        _vcin $@
    fi

   # Create a .vc_proj file if one doesn't exist
   if [[ ! -f $VC_PROJECT_FILE ]]; then
      _vc_proj > $VC_PROJECT_FILE
   fi
}

# Upgrade the nearest virtualenv packages
# and re-freeze them
function _vcup()
{
    local vdir=$(vcfinddir)
    local vname=$VC_VENV_NAME

    reqlist="$vdir/$VC_VENV_REQFILE"

    if [ ! -z $1 ]; then
        pr_fail "I can't upgrade individual packages at this time :("
        res=0
    else
        vcactivate
        pipenv uninstall --all
        vcin
        res="$?"
    fi

    return $res
}

function _vcfindenv()
{
    cur=$PWD
    local vdir=$(vcfinddir)
    local vname=$VC_VENV_NAME
    local res=""

    if [[ -n $vdir ]]; then
        res="$vdir/$vname"
    fi

    echo $res
}

function _vcfreeze()
{
    local vd=$(vcfinddir)

    if [[ -z "$vd" ]]; then
        pr_fail "Unable to determine virtualenv project directory"
        return
    fi

    # make sure virutalenv is activated
    vcactivate
    local pipfile="$(pipenv --bare --where).lock"

    if [[ ! -f $pipfile ]]; then
        pr_fail "No $pipfile present, can only freeze lock packages."
        pr_fail "Trying running the 'vcin' command first to lock the packages."
        return
    fi

    # _backup_if_exists "$vd/$VC_VENV_REQFILE"

    eval $vcfreeze_py $pipfile >! "$vd/${VC_VENV_REQFILE}.new"
    eval $vcfreeze_py $pipfile --dev >! "$vd/dev-${VC_VENV_REQFILE}.new"

    if [[ -f "$vd/${VC_VENV_REQFILE}.new"   ]]; then
        mv -f "$vd/${VC_VENV_REQFILE}.new" "$vd/${VC_VENV_REQFILE}"
    fi

    if [[ -f "$vd/dev-${VC_VENV_REQFILE}.new" ]]; then
        mv -f "$vd/dev-${VC_VENV_REQFILE}.new" "$vd/dev-${VC_VENV_REQFILE}"
    fi

    pr_info "\nFreezing requirements..."
    cat "$vd/$VC_VENV_REQFILE"

    pr_info "\nFreezing devlopment requirements..."
    cat "$vd/dev-${VC_VENV_REQFILE}"
}

function _vcactivate()
{
    local vname=$VC_VENV_NAME
    vloc=''

    vloc=$(vcfindenv)

    if [[ -n $vloc ]]; then
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
        exit 1
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
}

_vcin()
{
    _vc_source_project_file
    local ARGS='install'

    if [[ -z $1 ]]
    then
        pr_info "Installing project packages..."

        if [[ $PYTHON_ENV == 'debug' ]]; then
            ARGS="$ARGS --dev"
            pr_info "\tInstalling project dev packages as well"
        fi
    else
        # Install whatever params are given
        ARGS="$ARGS --lock $@"
    fi

    eval pipenv $ARGS
    vcfreeze
}

_vcrem()
{
    pipenv uninstall --lock $@
    vcfreeze
}

function _vc_auto_activate()
{
    # see if we're under a virtualenv.
    local c_venv="$(vcfindenv)"

    if [[ -n $c_venv ]]; then
        # We're in/under an environment.
        # If we're activated, switch to the new one if it's different from the
        # current.
        if [[ -n $VIRTUAL_ENV ]]; then
            from="~/${VIRTUAL_ENV#$HOME/}"
            to="~/${c_venv#$HOME/}"
            if [ "$from" != "$to" ]; then
                pr_info "Switching from '$from' to '$to'"
                deactivate
            fi
        fi

        if [[ -z $VIRTUAL_ENV ]]; then
            vcactivate
        fi
    elif [[ -n $VIRTUAL_ENV ]]; then
        # We've left an environment, so deactivate.
        pr_info "Deactivating ~/${VIRTUAL_ENV#$HOME/}\n"
        deactivate
    fi
}


function _vc_reset()
{
    to="$(vcfindenv)"
    dto=$(dirname "$to")
    if [[ -d "$to" ]]; then
        rm -fr "$to"
        if [[ "$?" != '0' ]]; then
            exit 1
        fi
        cd $dto
        vcstart
        cd -
    fi

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
        exit 1
    fi

    local pkg_name_u=$(echo "$pkg_name" | $SED -e 's/-/_/g') # underscored
    local pkg_name_s="$(echo $pkg_name_u | $SED -e 's/_/ /g')" # spaces
    local pkg_name_title="$(echo $pkg_name_s | $SED -e 's/\b\(.\)/\u\1/g')" # titled

    mkdir -p "$pkg_name"
    mkdir -p "$pkg_name/tests"
    mkdir -p "$pkg_name/$pkg_name_u"
    touch "$pkg_name/LICENSE.txt"
    touch "$pkg_name/requirements.txt"

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

}

function _vc_clean()
{
    # Do some basic python specific and general cleaning from current directory.
    # Args will be treated as find -iname parameters and be deleted!
    find . -iname '*.pyc' | xargs rm -fv
    find . -iname '*.pyo' | xargs rm -fv

    if [[ -n $1 ]]; then
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
    echo "# VC_VENV_REQFILE The name of the requirements file to use for standard packaging"
    echo "VC_VENV_REQFILE='$VC_VENV_REQFILE'"
    echo ""
    echo "# VC_VIRTUALENV_EXE The name of the virtualenv executable to use"
    echo "VC_VIRTUALENV_EXE='$VC_VIRTUALENV_EXE'"
    echo ""
    echo "# VC_VENV_NEW_SHELL use `pipenv shell` to enter the virtualenv in a new shell"
    echo "# VC_VENV_NEW_SHELL='true'"
    echo ""
    echo "# PIPENV_VENV_IN_PROJECT"
    echo "export PIPENV_VENV_IN_PROJECT=$VC_VENV_NAME"
}
