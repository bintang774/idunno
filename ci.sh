#!/usr/bin/env bash
set -e
ARIA2C_OPT='-q -c -x16 -s32 -k8M --file-allocation=falloc --timeout=60 --retry-wait=5 -o firmware.tgz'
tempdir=$(mktemp -d)
source ./functions.sh

log "Downloading firmware"
aria2c $ARIA2C_OPT "$FIRMWARE_URL"

log "Extracting $TARGET_IMAGE.img"
tar -xzf firmware.tgz -C $tempdir
codename=$(ls $tempdir | cut -d'_' -f1)
if [ $(find "$tempdir" -mindepth 1 -maxdepth 1 -type d | wc -l) -eq 1 ] &&
    [ $(find "$tempdir" -mindepth 1 -maxdepth 1 -type f | wc -l) -eq 0 ]; then
    SINGLE_DIR=$(find "$tempdir" -mindepth 1 -maxdepth 1 -type d)
    mv $SINGLE_DIR/* $tempdir/
    rm -rf $SINGLE_DIR
fi
mv $tempdir/images/$TARGET_IMAGE.img .

log "Uploading $TARGET_IMAGE.img to GitHub Release"
fw=$(echo "$FIRMWARE_URL" | awk -F'/' '{print $4}')
tag_name="$TARGET_IMAGE-$codename-$fw"
release_name="$TARGET_IMAGE $codename $fw"
create_release "$tag_name" "$release_name" "$(pwd)/$TARGET_IMAGE.img"

log "Sending info message to telegram"
gh_repo=$(git config --get remote.origin.url | sed 's/\.git$//' | sed 's|^git@github.com:|https://github.com/|' | sed 's|^https://.*@github.com|https://github.com|')
download_link="${gh_repo}/releases/download/$tag_name/$TARGET_IMAGE.img"
text="*$release_name*\n[Download]($download_link)"
send_msg "$text"

log "Done :)"
