# VirtualCandy
# Use at your own risk, no quarentee provided.
# Author: Jeff Buttars
# git@github.com:jeffbuttars/virtualcandy.git
# See the README.md

# Source in the common code first, override
# what's necessary

THIS_FILE=$0:A
export THIS_DIR=$(dirname $THIS_FILE)

source "$THIS_DIR/vc_common_code.sh"

function vcfinddir()
{
    _vcfinddir
}

function vcignore()
{
    _vc_ignore
}

# Start a new virtualenv, or 
# rebuild on from a requirements.txt file.
function vcstart()
{
    _vcstart $@
}

# Upgrade the nearest virtualenv packages
# and re-freeze them
function vcup()
{
    _vcup $@
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

function vcmod()
{
    _vcmod $@
}

function vcin()
{
    _vcin $@
}

function vcrem()
{
    _vcrem $@
}

function vc_auto_activate()
{
    _vc_auto_activate $@
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
        read "?!???! y/N: "
        if [[ $REPLY =~ ^[yY]$ ]]; then
            echo
            _vc_clean $@
        else
            _vc_clean
        fi
    fi
}

# chpwd_functions=(${chpwd_functions[@]} "vc_auto_activate")
# Automatically activate the current directories
# Virtualenv is one exists
if [[ "$VC_AUTO_ACTIVATION" == "true" ]]; then
    chpwd_functions=(${chpwd_functions[@]} "vc_auto_activate")
    # We want to run it now in case the terminal was started
    # with CWD in a virtuanenv directory
    vc_auto_activate
fi

zshexit_functions=(${zshexit_functions[@]} "_vc_exit")

# vim:set ft=zsh:
