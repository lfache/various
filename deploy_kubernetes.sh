#!/bin/sh
set -e

GITHUB_URL=https://github.com/lfache
DEPLOY_K3S_YAML_DIR=/home/debian
default_user=debian
default_group=debian

# --- helper functions for logs ---
info()
{
    echo '[INFO] ' "$@"
}
warn()
{
    echo '[WARN] ' "$@" >&2
}
fatal()
{
    echo '[ERROR] ' "$@" >&2
    exit 1
}

# --- verify existence of curl and git downloader executable ---
verify_downloader() {
    # Return failure if it doesn't exist or is no executable
    [ -x "$(which $1)" ] || return 1

    return 0
}

# --- download from github url ---
download() {
    if [[ -d "$YAML_DIR" ]]
    then
        $SUDO cd $YAML_DIR
    fi
    $SUDO git clone $GITHUB_URL/awesome-traefik-kubernetes
    # Abort if download command failed
    [ $? -eq 0 ] || fatal 'Download failed'
    $SUDO chown $default_user:$default_group -R awesome-traefik-kubernetes
}

install_k3s() {
    info "K3S installation start"
    curl -sfL https://get.k3s.io | sh -s - --no-deploy=traefik
    # Abort if K3S installation command failed
    [ $? -eq 0 ] || fatal 'K3S installation failed'
}

setup_env() {
    # --- use sudo if we are not already root ---
    SUDO=sudo
    if [ $(id -u) -eq 0 ]; then
        SUDO=
    fi

    # --- use binary install directory if defined or create default ---
    if [ -n "${DEPLOY_K3S_YAML_DIR}" ]; then
        YAML_DIR=${DEPLOY_K3S_YAML_DIR}
    else
        YAML_DIR=/home/debian
    fi
}

# --- run the install process --
{
    verify_downloader curl && verify_downloader git || fatal 'Can not find curl or git for downloading files'
    setup_env
    install_k3s
    download awesome-traefik-kubernetes
    deploy 
}
