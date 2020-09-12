
export VC_VENV_NAME='.venv'

# Activate environment in a new shell, disabled by default
if [[ -z $VC_VENV_NEW_SHELL ]]
then
    export VC_VENV_NEW_SHELL='false'
fi

# Auto activate the virtualenv when it's directory is entered
if [[ -z $VC_AUTO_ACTIVATION ]]
then
    export VC_AUTO_ACTIVATION=true
fi

if [[ -z $POETRY_VIRTUALENVS_IN_PROJECT ]]; then
    export POETRY_VIRTUALENVS_IN_PROJECT=true
fi

if [[ -z $POETRY_VIRTUALENVS_CREATE ]]; then
    export POETRY_VIRTUALENVS_CREATE=true
fi

# Initial packages.
# A list of packages to always install in a fresh environment with `vcstart`
# EX:
#     export VC_VENV_INITIAL_PKGS="neovim"
if [[ -z $VC_VENV_INITIAL_PKGS ]]
then
    export VC_VENV_INITIAL_PKGS=''
fi

# Define which python to use
if [[ -z $VC_PYTHON_EXE ]]
then
    res=$(which python3)
    if [[ -n $res ]]; then
        export VC_PYTHON_EXE=$(basename $(which python3))
    else
        export VC_PYTHON_EXE=$(basename $(which python))
    fi
fi

if [[ -z $VC_CMD_INIT_ARGS ]]
then
    export VC_CMD_INIT_ARGS=""
fi

if [[ -z $VC_CMD_FREEZE_ARGS ]]
then
    export VC_CMD_FREEZE_ARGS=""
fi
