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

# Automatically activate the current directories
# Virtualenv is one exists
if [[ "$VC_AUTO_ACTIVATION" == "true" ]]; then
    if [[ -n "$PROMPT_COMMAND" ]]; then
        export VC_OLD_PROMPT_COMMAD="$PROMPT_COMMAND"
        PROMPT_COMMAND="$PROMPT_COMMAND;_vc_auto_activate"
    else
        PROMPT_COMMAND="_vc_auto_activate"
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
