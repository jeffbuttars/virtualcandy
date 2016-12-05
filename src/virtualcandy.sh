# VirtualCandy
# Use at your own risk, no quarentee provided.
# Author: Jeff Buttars
# git@github.com:jeffbuttars/virtualcandy.git
# See the README.md

# Source in the common code first, override
# what's necessary

export THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$THIS_DIR/vc_common_code.sh"

function clean_on_exit()
{
    if [[ -n $VC_VCTAGS_PID ]]; then
        kill $VC_VCTAGS_PID
        wait $VC_VCTAGS_PID
    fi
    VC_AUTOTAG_RUN=0
}

trap "clean_on_exit" EXIT SIGINT SIGHUP SIGKILL SIGTERM

function vcfinddir()
{
    _vcfinddir
}

vcignore()
{
    _vc_ignore
}

# Start a new virtualenv, or 
# rebuild on from a requirements.txt file.
function vcstart()
{
_vcstart
}

# A simple, and generic, pip update script.
# For a given file containing a pkg lising
# all packages are updated. If no args are given,
# then a 'requirements.txt' file will be looked
# for in the current directory. If the $VC_DEFAULT_VENV_REQFILE
# variable is set, than that filename will be looked
# for in the current directory.
# If an argument is passed to the function, then
# that file and path will be used.
# This function is used by the vcpkgup function
function pip_update()
{
    _pip_update $@
}

# Upgrade the nearest virtualenv packages
# and re-freeze them
function vcpkgup()
{
    _vcpkgup $@
}

function vcfindenv()
{
    _vcfindenv $@
}

function vcfreeze()
{
    _vcfreeze $@
}

function vcactivate()
{
    _vcactivate $@
}
alias vca='vcactivate'


function vctags()
{
    _vctags $@
} #vctags

function vcbundle()
{
    _vcbundle $@
}

function vcmod()
{
    _vcmod $@
}

function vc_auto_activate()
{
    _vc_auto_activate $@
}

function vcin()
{
    _vcin $@
}

function vcrem()
{
    _vcrem $@
}

function vcreset()
{
    _vc_reset $@
}

function vcpkgskel()
{
    _vc_pkgskel $@
}

function vcproj()
{
    _vc_proj $@
}

function vcclean()
{
    if [[ -n $1 ]]; then
        echo "Are you sure you want to recursively delete files"
        echo "that match the pattern(s):"
        echo "$@"
        read -p "!???! y/N" -n 1
        if [[ $REPLY =~ ^[yY]$ ]]; then
            echo
            _vc_clean $@
        else
            _vc_clean
        fi
    fi
}

# Automatically activate the current directories
# Virtualenv is one exists
if [[ "$VC_AUTO_ACTIVATION" == "true" ]]; then
    if [[ -n "$PROMPT_COMMAND" ]]; then
        export VC_OLD_PROMPT_COMMAD="$PROMPT_COMMAND"
        PROMPT_COMMAND="$PROMPT_COMMAND;vc_auto_activate"
    else
        PROMPT_COMMAND="vc_auto_activate"
    fi
fi

# vim:set ft=sh:
