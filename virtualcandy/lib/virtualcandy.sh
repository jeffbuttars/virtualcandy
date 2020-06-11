# VirtualCandy
# Use at your own risk, no quarentee provided.
# Author: Jeff Buttars
# git@github.com:jeffbuttars/virtualcandy.git
# See the README.md

# Source in the common code first, override
# what's necessary

POETRY_COMPLETION_FILE="/tmp/${USER}_poetry.bash-completion"

export THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$THIS_DIR/vc_common_code.sh"

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
alias vca='vcactivate'

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

# Install the command completion if needed
if [[ ! -f ${POETRY_COMPLETION_FILE} ]]; then
    poetry completions bash > ${POETRY_COMPLETION_FILE}
fi

if [[ -f ${POETRY_COMPLETION_FILE} ]]; then
    . ${POETRY_COMPLETION_FILE}
fi

# vim:set ft=sh:
