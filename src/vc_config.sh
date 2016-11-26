
# Name of the virtualenv directory
if [[ -z $VC_DEFAULT_VENV_NAME ]]
then
    export VC_DEFAULT_VENV_NAME='.venv'
fi

# Requirements filename
if [[ -z $VC_DEFAULT_VENV_REQFILE ]]
then
    export VC_DEFAULT_VENV_REQFILE='requirements.txt'
fi

# Dev Requirements filename
if [[ -z $VC_DEFAULT_VENV_DEV_REQFILE ]]
then
    export VC_DEFAULT_VENV_DEV_REQFILE='dev-requirements.txt'
fi

# Auto activate the virtualenv when it's directory is entered
if [[ -z $VC_AUTO_ACTIVATION ]]
then
    export VC_AUTO_ACTIVATION=true
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

export VC_PROJECT_FILE=".vc_proj"
