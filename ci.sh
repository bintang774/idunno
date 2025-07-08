#!/usr/bin/env bash
ARIA2C_OPT='-q -c -x16 -s32 -k8M —file-allocation=falloc --timeout=60 —retry-wait=5 -o firmware.tgz'

source ./functions.sh

tempdir=$(mktemp -d) && cd "$tempdir"

log "Downloading firmware"
aria2c $ARIA2C_OPT "$FIRMWARE_URL"

log "Extracting $TARGET_IMAGE.img"
tar -xzf firmware.tgz images/$TARGET_IMAGE.img --strip-components=1 ||
    error "Failed to extract $TARGET_IMAGE.img"

log "Uploading $TARGET_IMAGE.img to GitHub Release"
fw=$(echo "$FIRMWARE_URL" | awk -F'/' '{print $4}')
tag_name="$TARGET_IMAGE-$fw"
release_name="$TARGET_IMAGE $fw"
create_release "$tag_name" "$release_name" "$(pwd)/$TARGET_IMAGE.img"

log "Sending info message to telegram"
gh_repo=$(git config --get remote.origin.url | sed 's/\.git$//')
download_link="${gh_repo}/releases/download/$tag_name/$TARGET_IMAGE.img"
text="*$release_name*\n[Download]($download_link)"
send_msg "$text"

log "Done :)"
