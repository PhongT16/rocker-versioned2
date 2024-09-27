#!/bin/bash
set -e

DEFAULT_USER=${1:-${DEFAULT_USER:-"rstudio"}}
DEFAULT_USER_ID=${2:-${DEFAULT_USER_ID:-"1000"}}
DEFAULT_GROUP_ID=${3:-${DEFAULT_GROUP_ID:-"1000"}}
DEFAULT_GROUP_NAME=${4:-${DEFAULT_GROUP_NAME:-"rstudio"}}

if id -u "${DEFAULT_USER}" >/dev/null 2>&1; then
    echo "User ${DEFAULT_USER} already exists"
else
    ## Need to configure non-root user for RStudio
    useradd -s /bin/bash -m "$DEFAULT_USER" 
    echo "${DEFAULT_USER}:${DEFAULT_USER}" | chpasswd
    usermod -a -G staff "$DEFAULT_USER"
    # Change UID
    usermod -u "${DEFAULT_USER_ID}" "${DEFAULT_USER}"

    # Create group if doesn't exist
    if ! getent group "${DEFAULT_GROUP_ID}" > /dev/null; then
        echo "Creating group ${DEFAULT_GROUP_NAME}"
        groupadd -g "${DEFAULT_GROUP_ID}" "${DEFAULT_GROUP_NAME}"
    fi
    # Change GID
    usermod -g "${DEFAULT_GROUP_ID}" "${DEFAULT_USER}"
    
    id "${DEFAULT_USER}"

    ## Rocker's default RStudio settings, for better reproducibility
    mkdir -p "/home/${DEFAULT_USER}/.config/rstudio/"
    cat <<EOF >"/home/${DEFAULT_USER}/.config/rstudio/rstudio-prefs.json"
{
    "save_workspace": "never",
    "always_save_history": false,
    "reuse_sessions_for_project_links": true,
    "posix_terminal_shell": "bash"
}
EOF
    chown -R "${DEFAULT_USER}:${DEFAULT_USER}" "/home/${DEFAULT_USER}"
fi

# If shiny server installed, make the user part of the shiny group
if [ -x "$(command -v shiny-server)" ]; then
    adduser "${DEFAULT_USER}" shiny
fi

## configure git not to request password each time
if [ -x "$(command -v git)" ]; then
    git config --system credential.helper 'cache --timeout=3600'
    git config --system push.default simple
fi
