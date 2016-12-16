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
    echo -en "${KGRN}$*${KNRM}\n"
}

pr_fail()
{
    echo -en "${KRED}$*${KNRM}\n" >&2
}

pr_info()
{
    echo -en "${KBLU}$*${KNRM}\n"
}

_backup_if_exists()
{
    if [[ -f "$1" ]]; then
        mv -f "$1"  "$(dirname $1)/.$(basename $1).bak"
    fi
}

SED='sed'
which gsed > /dev/null
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

if [[ -z $VC_NEW_SHELL ]]
then
    # Highly recommend using 'yes', but the default behavior of
    # virtualenv is not use a new shell, so we mimick it's defaults.
    VC_NEW_SHELL='no'
fi

_vc_source_project_file()
{
    # If a project file exists, source it.
    if [[ -f "$VC_PROJECT_FILE" ]]; then
        if [[ "$SHELL" == "bash" ]]; then
            . ./"$VC_PROJECT_FILE"
        else
            source ./"$VC_PROJECT_FILE"
        fi
    fi
}


function _vcfinddir()
{
    _vc_source_project_file
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
# rebuild on from a requirements.txt file.
function _vcstart()
{
    _vc_source_project_file

    if [[ "$VC_NEW_SHELL" != 'no' ]]; then
        # get our current shell
        C_SHELL="$SHELL"

        # Enter the new shell and start up the env.
        $C_SHELL -c "$THIS_DIR/vc_new_shell.sh"
    fi

    vname=$VC_VENV_NAME

    # Create the virtualenv.
    pr_info "$VC_VIRTUALENV_EXE --python=$VC_PYTHON_EXE $vname"
    $VC_VIRTUALENV_EXE --python=$VC_PYTHON_EXE $vname
    . $vname/bin/activate

    # If there is a requriemnts file, install it's packages.
    if [[ -f requirements.txt ]]; then
        _vcin
    fi

    # Treat any parameters as packages to install.
    # In the case of command line packages given for install
    # we'll also run freeze after word.
    if [[ -n $1 ]]; then
        for pkg in $@ ; do
            err_out_file="/tmp/${pkg}_errs_$$"
            pr_info "pip install $pkg"
            eout=$(pip install $pkg 2>&1)
            res="$?"
            if [[ "0" != "$res" ]]; then
                pr_fail "pip install $pkg had a failure, $res"
                echo "$eout" > $err_out_file
            fi
        done

        vcfreeze
    fi

    # If there is no requrirements.txt, create one from the
    # current environment.
    if [[ ! -f requirements.txt ]]; then
        vcfreeze
    fi

    # Create a .vc_proj file if one doesn't exist
    if [[ ! -f $VC_PROJECT_FILE ]]; then
       _vc_proj > $VC_PROJECT_FILE
    fi

    # If we had install errors, display them.
    for pkg in $@ ; do
        err_out_file="/tmp/${pkg}_errs_$$"
        if [[ -f $err_out_file ]]; then
            pr_fail "An error occurred while installing ${pkg}"
            pr_info "See file $err_out_file for details, error contents:\n"
            pr_info "$(cat $err_out_file)"
            echo
        fi
    done
}

# A simple, and generic, pip update script.
# For a given file containing a pkg lising
# all packages are updated. If no args are given,
# then a 'requirements.txt' file will be looked
# for in the current directory. If the $VC_VENV_REQFILE
# variable is set, than that filename will be looked
# for in the current directory.
# If an argument is passed to the function, then
# that file and path will be used.
# This function is used by the vcpkgup function
function _pip_update()
{
    _vc_source_project_file
    reqf="requirements.txt"

    if [[ -n $VC_VENV_REQFILE ]]; then
        reqf="$VC_VENV_REQFILE"
    fi

    if [[ -n $1 ]]; then
        reqf="$1"
    fi

    res=0
    if [[ -f $reqf ]]; then
        tfile="/tmp/pkglist_$RANDOM.txt"
        pr_info "$tfile"
        cat $reqf | awk -F '==' '{print $1}' > $tfile
        pip install --upgrade -r $tfile
        res=$?
        rm -f $tfile
    else
        pr_fail "Unable to find package list file: $reqf"
        res=1
    fi

    echo $res
}

# Upgrade the nearest virtualenv packages
# and re-freeze them
function _vcpkgup()
{
    _vc_source_project_file
    local vname=$VC_VENV_NAME
    local vdir=$(vcfinddir)

    reqlist="$vdir/$VC_VENV_REQFILE"

    if [ ! -z $1 ]; then
        pr_info "Updating $@"
        for pkg in "$@" ; do
            pip install -U --no-deps $pkg
            res=$?
        done
        vcfreeze
    elif [[ -f $reqlist ]]; then
        pr_info "Updating all in $reqlist"
        vcactivate
        pip_update $reqlist
        res=$?
        if [[ "$res" == 0 || "$res" == "" ]]; then
            vcfreeze
        else
            pr_fail "Bad exit status from pip_update, not freezing the package list."
        fi
    else
        pr_fail "No requirements.txt file found!"
        res=0
    fi

    return $res
}

function _vcfindenv()
{
    _vc_source_project_file
    cur=$PWD
    local vname=$VC_VENV_NAME
    local vdir=$(vcfinddir)
    local res=""

    if [[ -n $vdir ]]; then
        res="$vdir/$vname"
    fi

    echo $res
}

function _vcfreeze()
{
    _vc_source_project_file
    local vd=$(vcfinddir)
    local vdev=''

    # Check if this is a dev freeze
    if [[ -n $1 ]]; then
        if [[ $1 == '-d' ]]; then
            touch "$vd/$VC_VENV_DEV_REQFILE"
            vdev='true'
            shift
        fi
    elif [[ -f "$vd/$VC_VENV_DEV_REQFILE" ]]; then
        vdev='true'
    fi

    if [[ -z "$vd" ]]; then
        pr_fail "Unable to determine virtualenv project directory"
        return
    fi

    # make sure virutalenv is activated
    vcactivate

    # If this is a dev freeze, cat the package list to the dev req file.
    if [[ -n $vdev ]]; then
        local tmp_req_file="$(mktemp)"
        echo "# vcdevfreeze:start" >> $tmp_req_file
        cat "$vd/$VC_VENV_DEV_REQFILE" >> $tmp_req_file
        for pkg in $@ ; do
            pkg_reqs=($(pip show $pkg | $SED -n '/^Requires:.*/{p}' | $SED 's/^Requires: //' | $SED 's/,//g'))
            echo "$pkg" >> "$tmp_req_file"
            for pkg_req in $pkg_reqs ; do
                echo "$pkg_req" >> "$tmp_req_file"
            done
        done
        echo "# vcdevfreeze:stop" >> $tmp_req_file
        cat "$vd/$VC_VENV_REQFILE" >> $tmp_req_file

        _backup_if_exists "$vd/$VC_VENV_DEV_REQFILE"
        pip freeze -q -r $tmp_req_file | $SED -n '/# vcdevfreeze:start/,/# vcdevfreeze:stop/{//!p}' | $SED '/^##/ d' >  "$vd/$VC_VENV_DEV_REQFILE"

        _backup_if_exists "$vd/$VC_VENV_REQFILE"
        pip freeze -q -r $tmp_req_file | $SED -n '/# vcdevfreeze:start/,/# vcdevfreeze:stop/!{p}'  | $SED '/^##/ d' >  "$vd/$VC_VENV_REQFILE"
    else
        _backup_if_exists "$vd/$VC_VENV_REQFILE"
        pip freeze > "$vd/$VC_VENV_REQFILE"
    fi

    if [[ -f  "$vd/$VC_VENV_DEV_REQFILE" ]]; then
        pr_info "Development requirements..."
        cat "$vd/$VC_VENV_DEV_REQFILE"
    fi

    pr_info "\nProduction requirements..."
    cat "$vd/$VC_VENV_REQFILE"
}

function _vcactivate()
{
    _vc_source_project_file

    local vname=$VC_VENV_NAME
    vloc=''

    vloc=$(vcfindenv)

    if [[ -n $vloc ]]; then
        pr_pass "Activating ~${vloc#$HOME/}"
        . "$vloc/bin/activate"
    else
        pr_fail "No virtualenv named $vname found."
    fi

}

function _vctags()
{
    _vc_source_project_file
    vloc=$(vcfindenv)
    filelist="$vloc"

    # ccmd="ctags --sort=yes --tag-relative=no -R --python-kinds=-i"
    ccmd="ctags --tag-relative=no -R --python-kinds=-i"
    pr_info "$ccmd"
    if [[ -n $vloc ]]; then
        pr_info "Making tags with $vloc"
        filelist="$vloc"
    fi

    if [[ "$#" == "0" ]]; then
        filelist="$filelist *"
    else
        filelist="$filelist $@"
    fi

    ccmd="$ccmd $filelist"
    pr_info "Using command $ccmd"
    $ccmd

    res=$(which inotifywait)
    VC_AUTOTAG_RUN=1
    if [[ -n $res ]]; then
        while [[ "$VC_AUTOTAG_RUN" == "1" ]]; do
            inotifywait -e modify -r $filelist
            nice -n 19 ionice -c 3 $ccmd
            # Sleep a bit to keep from hitting the disk
            # to hard during a mad editing burst from 
            # those mad men coders
            sleep 30
        done
    fi
}


function _vcbundle()
{
    _vc_source_project_file
    vcactivate
    vdir=$(vcfinddir)
    bname="${VC_VENV_NAME#.}.pybundle"
    pr_info "Creating bundle $bname"
    pip bundle "$bname" -r "$vdir/$VC_VENV_REQFILE"
}


function _vcmod()
{
    _vc_source_project_file
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
    local freeze_params=''

    if [[ -z $1 ]]
    then
        pr_info "No packages given. Running install on requirements.txt"
        pip install -r "$(_vcfinddir)/$VC_VENV_REQFILE"
        if [[ $PYTHON_ENV != 'production' ]]; then
            if [[ -f  "$(_vcfinddir)/$VC_VENV_DEV_REQFILE"  ]]; then
                pr_info "Found the development requirements file, installing it's packages..."
                pip install -r "$(_vcfinddir)/$VC_VENV_DEV_REQFILE"
            fi
        fi
        vcfreeze
    elif [[ $1 == "-d" ]]
    then
        pr_info "Installing as development packages...\n"
        freeze_params=($@)
        shift
    fi

    pip install $@
    vcfreeze $freeze_params
}

_vcrem()
{
    _vc_source_project_file
    pip uninstall $@
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
                # Do we need to be this verbose?
                # echo -e "Switching from '$from' to '$to'"
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
    echo "# VC_VENV_NAME The name of the virtualenv directory"
    echo "VC_VENV_NAME='$VC_VENV_NAME'"
    echo ""
    echo "# VC_VENV_REQFILE The name of the requirements file to use for packaging"
    echo "VC_VENV_REQFILE='$VC_VENV_REQFILE'"
    echo ""
    echo "# VC_VIRTUALENV_EXE The name of the virtualenv executable to use"
    echo "VC_VIRTUALENV_EXE='$VC_VIRTUALENV_EXE'"
}

