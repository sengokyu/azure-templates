#!/bin/bash

set -e

if [ -z "$TOKEN" ]; then
    echo 1>&2 'TOKEN must be specified.'
    exit 1
fi

if [ -z "$URL" -a -z "$ORG" ]; then
    echo 1>&2 'URL or ORG must be specired.'
    exit 1
fi

DOTNET_RUNTIME_VERSION=3.1
VSTS_AGENT_DIR_BASE=/opt/vstsagent
FILES_URL_BASE=https://raw.githubusercontent.com/sengokyu/azure-templates/main/vm-vsts-agent/setup-files/
TAR_BALL=/tmp/vsts-agent.tar.gz
WORK_DIR_PREFIX=/mnt/vstswork

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

    curl -L $targzurl -o $TAR_BALL
}

extract_tarball() {
    local dir=${VSTS_AGENT_DIR_BASE}-$1

    mkdir $dir
    tar zxf $TAR_BALL -C $dir
    echo $dir
}

configure_vsts_agent() {
    mkdir -p $3

    cd $1

    ./config.sh \
        --unattended \
        --url "${URL:-https://dev.azure.com/${ORG}}" \
        --auth pat \
        --token "${TOKEN}" \
        --pool "${POOL:-Default}" \
        --agent $2 \
        --replace \
        --work $3 \
        acceptTeeEula
}

install_vsts_agent_service() {
    cd $1

    ## Must specify running user
    ./svc.sh install root
    ./svc.sh start
}

create_rc_local() {
    if [ \! -f /etc/rc.local ]; then
        echo '#!/bin/bash' > /etc/rc.local
        echo 'set +e' >> /etc/rc.local

        chmod u+x /etc/rc.local
    fi
}

add_to_rc_local() {
    echo "mkdir -p $1" >> /etc/rc.local
}

main() {
    download_aptfiles
    install_packages
    download_vsts_agent
    create_rc_local    

    for i in $(seq 1 ${COUNT:-1})
    do
        local dir=$(extract_tarball $i)
        local workdir=${WORK_DIR_PREFIX}${i}
        add_to_rc_local $workdir
        configure_vsts_agent $dir $(hosname)-$i $workdir
        install_vsts_agent_service $dir
    done
}

## Main
main
