#!/usr/bin/bash

ELEMENT_INSTALL_DIR=
ELEMENT_GITHUB_REPO=
TELEGRAM_BOT_TOKEN=
CHANNEL_ID=

source .env

UPDATE_MESSAGE="""
 🔄 المنت به نسخه‌ی :LAST_VERSION: اپدیت شد.
🔄 Element web updated to :LAST_VERSION: 


 شما میتوانید با استفاده از این لینک از طریف مرورگر از ویز استفاده کنین:
 -> [Web Element](https://chat.wiiz.ir) 
"""

# ----------------- inline vars
DOWNLOAD_URL=""
APP_VERSION=""
LAST_VERSION=""



function log {
    echo "[$(date)] $1"
}

function get_current_version {
    APP_VERSION=v$(cat $ELEMENT_INSTALL_DIR/version)
    log "Current version: $APP_VERSION"
}

function fetch_latest_release {
    log "Fetching latest release..."
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/$ELEMENT_GITHUB_REPO/releases/latest | jq -r '.assets[0].browser_download_url')
    LAST_VERSION=$(curl -s https://api.github.com/repos/$ELEMENT_GITHUB_REPO/releases/latest | jq -r '.tag_name')
    log "Latest release URL: $DOWNLOAD_URL"
}

function download_element {
    log "Downloading Element..."
    proxychains curl -L -o element.tar.gz $DOWNLOAD_URL
    log "Element downloaded."
}

function extract_to_temp {
    log "Extracting Element to temp..."
    mkdir -p /tmp/element
    tar -xzf element.tar.gz -C /tmp/element
    log "Element extracted to temp."
}

function update_element {
    log "Updating Element..."
    mv $ELEMENT_INSTALL_DIR/config.json /tmp/config.json
    rm -rf $ELEMENT_INSTALL_DIR/* $ELEMENT_INSTALL_DIR/.*
    mv /tmp/element/element-*/* $ELEMENT_INSTALL_DIR
    mv /tmp/config.json $ELEMENT_INSTALL_DIR/config.json
    log "Element updated."
}

function cleanup {
    log "Cleaning up..."
    rm -rf /tmp/element
    rm element.tar.gz
    log "Cleanup done."
}


function send_telegram_message {
    MARKDOWN_MESSAGE=$(echo "$UPDATE_MESSAGE" | sed "s/:LAST_VERSION:/$LAST_VERSION/g") 
    proxychains curl -s -X POST https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage -d chat_id=$CHANNEL_ID -d text="$MARKDOWN_MESSAGE" -d parse_mode=Markdown
    log "Telegram message sent."
}

function check_if_it_is_updated {
    CHECK_VERSION=v$(cat $ELEMENT_INSTALL_DIR/version)
    if [ "$CHECK_VERSION" == "$LAST_VERSION" ]; then
        log "Element is correctly updated."
        echo 0
    fi
    log "Element is not updated."
    echo 1
}

function main {
    fetch_latest_release
    get_current_version
    if [ "$APP_VERSION" == "$LAST_VERSION" ]; then
        log "$APP_VERSION $LAST_VERSION"
        log "Element is already up to date."
        exit 0
    fi

    download_element
    extract_to_temp
    update_element

    if ! check_if_it_is_updated; then
        log "Element is not updated."
        exit 1
    fi

    send_telegram_message
    cleanup
}

main
