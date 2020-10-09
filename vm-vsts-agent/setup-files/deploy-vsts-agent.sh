#!/bin/bash

set -e

TOKEN=$1
ORG=$2
AGENT=$3
VSTS_AGENT_VERSION=2.175.2
DOTNET_RUNTIME_VERSION=3.1
VSTS_AGENT_DIR=/opt/vstsagent
MY_TIMEZONE=Asia/Tokyo

export AGENT_ALLOW_RUNASROOT=yes

set_timezone() {
    timedatectl set-timezone $MY_TIMEZONE
}

download_aptfiles() {
    curl https://devtracon.blob.core.windows.net/setup-azure-pipelines-agent/azure-cli.list -o /etc/apt/sources.list.d/azure-cli.list
    curl https://devtracon.blob.core.windows.net/setup-azure-pipelines-agent/microsoft-prod.gpg -o /etc/ap/trusted.gpg.d/microsoft-prod.gpg
}

install_packages() {
    apt-get update && apt-get install -y \
        build-essential \
        jq \
        zip \
        git \
        azure-cli \
        dotnet-runtime-${DOTNET_RUNTIME_VERSION}
}

download_vsts_agent() {
    mkdir ${VSTS_AGENT_DIR} \
        && curl -sL https://vstsagentpackage.azureedge.net/agent/${VSTS_AGENT_VERSION}/vsts-agent-linux-x64-${VSTS_AGENT_VERSION}.tar.gz | tar zxf - -C ${VSTS_AGENT_DIR}
}

configure_vsts_agent() {
    cd ${VSTS_AGENT_DIR}

    ./config.sh \
        --unattended \
        --url "${URL:-https://dev.azure.com/${ORG}}" \
        --auth pat \
        --token "${TOKEN}" \
        --pool "${POOL:-Default}" \
        --agent "${AGENT:-ubuntu-agent}" \
        --replace \
        acceptTeeEula
}
