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


# chpwd_functions=(${chpwd_functions[@]} "_vc_auto_activate")
# Automatically activate the current directories
# Virtualenv is one exists
if [[ "$VC_AUTO_ACTIVATION" == "true" ]]; then
    # Don't add it more than once, check the array first.
    if [[ ${chpwd_functions[(r)_vc_auto_activate]} !=  "_vc_auto_activate" ]]
    then
        chpwd_functions=(${chpwd_functions[@]} "_vc_auto_activate")
    fi

    # We want to run it now in case the terminal was started
    # with CWD in a virtuanenv directory
    _vc_auto_activate
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
