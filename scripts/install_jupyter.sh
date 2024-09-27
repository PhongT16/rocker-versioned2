#!/bin/bash
set -e

## build ARGs
NCPUS=${NCPUS:-"-1"}

NB_USER=${NB_USER:-${DEFAULT_USER:-"rstudio"}}
NB_UID=${NB_UID:-${DEFAULT_USERID:-"1000"}}
NB_GID=${NB_GID:-${DEFAULT_USERGID:-"1000"}}
NB_GROUP=${NB_GROUP:-${DEFAULT_GROUP:-"rstudio"}}

# a function to install apt packages only if they are not installed
function apt_install() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
            apt-get update
        fi
        apt-get install -y --no-install-recommends "$@"
    fi
}

apt_install \
    git \
    sudo \
    libzmq3-dev

# set up the default user if it does not exist
# This script snippet checks if a user with the name stored in the environment variable ${NB_USER} exists. 
# If the user does not exist (as checked by id -u), it calls a script /rocker_scripts/default_user.sh with ${NB_USER} as an argument to create or set up the user.


if ! id -u "${NB_USER}" >/dev/null 2>&1; then
    /rocker_scripts/default_user.sh "${NB_USER}" "${NB_UID}" "${NB_GID}" "${NB_GROUP}" 
fi

# install python & setup venv
# shellcheck source=/dev/null
source /rocker_scripts/install_python.sh

python3 -m pip install --no-cache-dir jupyter-rsession-proxy notebook jupyterlab jupyterhub

install2.r --error --skipmissing --skipinstalled -n "$NCPUS" remotes

R --quiet -e 'remotes::install_github("IRkernel/IRkernel@*release")'
R --quiet -e 'IRkernel::installspec(user = FALSE)'

# Install texlive if it has not already been installed
if ! command -v tlmgr; then
    # shellcheck source=/dev/null
    source /rocker_scripts/install_texlive.sh
fi

# If we are using official Ubuntu binaries, we do not need tex packages installed manually with tlmgr
if [[ ! -x "/usr/bin/latex" ]]; then
    # Install tex packages needed for Jupyter's nbconvert to work correctly & convert to PDF
    # Sourced from https://github.com/jupyter/nbconvert/issues/1328
    tlmgr install adjustbox caption collectbox enumitem environ eurosym etoolbox jknapltx parskip \
        pdfcol pgf rsfs tcolorbox titling trimspaces ucs ulem upquote \
        ltxcmds infwarerr iftex kvoptions kvsetkeys float geometry amsmath fontspec \
        unicode-math fancyvrb grffile hyperref booktabs soul ec
fi

# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/downloaded_packages

## Strip binary installed lybraries from RSPM
## https://github.com/rocker-org/rocker-versioned2/issues/340
strip /usr/local/lib/R/site-library/*/libs/*.so

# Check jupyter
echo -e "Check the avalable jupyter kernels...\n"

jupyter kernelspec list

echo -e "\nInstall jupyter, done!"
