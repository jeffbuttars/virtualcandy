# VirtualCandy
# Use at your own risk, no quarentee provided.
# Author: Jeff Buttars
# git@github.com:jeffbuttars/virtualcandy.git
# See the README.md

# Source in the common code first, override
# what's necessary

THIS_FILE=$0:A
export THIS_DIR=$(dirname $THIS_FILE)

POETRY_COMPLETION_FILE="${HOME}/.zfunc/_poetry"

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
    # Don't add it more than once, check the array first.
    if [[ ${chpwd_functions[(r)vc_auto_activate]} !=  "vc_auto_activate" ]]
    then
        chpwd_functions=(${chpwd_functions[@]} "vc_auto_activate")
    fi

    # We want to run it now in case the terminal was started
    # with CWD in a virtuanenv directory
    vc_auto_activate
fi

zshexit_functions=(${zshexit_functions[@]} "_vc_exit")


# Install the command completion if needed
if [[ ! -f ${POETRY_COMPLETION_FILE} ]]; then
    mkdir -p $(dirname ${POETRY_COMPLETION_FILE})
    poetry completions zsh > ${POETRY_COMPLETION_FILE}
    echo "You'll need to restart your shell for the Poetry completions to take effect"
fi

# if the completion file is older than 7 days, replace it.
comp_file_age=$((($(date +%s) - $(date +%s -r "${POETRY_COMPLETION_FILE}")) / 86400))
if [[ $comp_file_age -gt 7 ]]
then
    poetry completions zsh > ${POETRY_COMPLETION_FILE}
fi

# vim:set ft=zsh:
