#!/bin/bash

set -e

DOTNET_RUNTIME_VERSION=3.1
VSTS_AGENT_DIR=/opt/vstsagent
FILES_URL_BASE=https://raw.githubusercontent.com/sengokyu/azure-templates/main/vm-vsts-agent/setup-files/

export AGENT_ALLOW_RUNASROOT=yes

download_aptfiles() {
    curl -L ${FILES_URL_BASE}/azure-cli.list -o /etc/apt/sources.list.d/azure-cli.list
    curl -L ${FILES_URL_BASE}/microsoft-prod.list -o /etc/apt/sources.list.d/microsoft-prod.list
    curl -L ${FILES_URL_BASE}/microsoft-prod.gpg -o /etc/apt/trusted.gpg.d/microsoft-prod.gpg
}

install_packages() {
    apt-get update
    apt-get upgrade -y
    apt-get install -y \
        build-essential \
        jq \
        zip \
        git \
        azure-cli \
        dotnet-runtime-${DOTNET_RUNTIME_VERSION}
}

get_latest_vsts_agent_url() {
    local assets_url=$(curl -sL https://api.github.com/repos/Microsoft/vsts-agent/releases/latest | jq -r '.assets[0].browser_download_url')
    
    curl -L $assets_url | jq -r '. | map(select(.platform == "linux-x64")) | .[0].downloadUrl'
}

download_vsts_agent() {
    local targzurl=$(get_latest_vsts_agent_url)

    mkdir ${VSTS_AGENT_DIR}
    curl -L $targzurl | tar zxf - -C ${VSTS_AGENT_DIR}
}

configure_vsts_agent() {
    cd ${VSTS_AGENT_DIR}

    ./config.sh \
        --unattended \
        --url "${URL:-https://dev.azure.com/${ORG}}" \
        --auth pat \
        --token "${TOKEN}" \
        --pool "${POOL:-Default}" \
        --agent "$(hostname)" \
        --replace \
        acceptTeeEula
}

install_vsts_agent_service() {
    cd ${VSTS_AGENT_DIR}

    ./svc.sh install
    ./svc.sh start
}


## Main
download_aptfiles
install_packages
download_vsts_agent
configure_vsts_agent
install_vsts_agent_service

##
shutdown -r now
