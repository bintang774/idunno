#!/usr/bin/env bash

# Logging functions
log() {
    echo "[LOG] $*"
}
error() {
    echo "[ERROR] $*" >&2
    exit 1
}

# telegram
send_msg() {
    local text
    text=$(echo -e "$1")
    curl -s -X POST "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage" \
        -d "chat_id=$TG_CHAT_ID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d "text=$text"
}

# create_release <tag name> <release name> <file>
create_release() {
    local tag_name="$1"
    local release_name="$2"
    local file="$3"

    # check input
    [ -n "$tag_name" ] || error "Tag name must be set"
    [ -n "$release_name" ] || error "Release name must be set"
    [ -f "$file" ] || error "$file doesn't exist"

    # ensure GitHub token is set for gh
    export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN}}"

    # create release with --clobber in case tag already exists
    gh release create "$tag_name" \
        "$file" \
        --title "$release_name"

    return $?
}
