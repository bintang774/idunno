#!/usr/bin/env bash
set -eo pipefail
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
rm -rf $tempdir

if [ "$TARGET_IMAGE" == "boot" ]; then
    log "Extracting kernel string from boot.img"
    # extract kernel version
    mkdir -p k && cd k
    cp $OLDPWD/boot.img .
    setup_magiskboot
    magiskboot_output=$(magiskboot unpack boot.img 2>&1)
    [ -z "$magiskboot_output" ] && error "Failed to unpack the boot.img"
    k_fmt=$(echo "$magiskboot_output" | grep 'KERNEL_FMT' | tr -d '[]' | awk '{print $2}' 2>/dev/null)
    k_str=$(strings kernel | grep -E -m1 'Linux version.*#' 2>/dev/null)
    [ -z "$k_str" ] && error "Failed to extract kernel string"
    [ -z "$k_fmt" ] && error "Failed to get kernel format"
    cd $OLDPWD
    rm -rf k
fi

log "Uploading $TARGET_IMAGE.img to GitHub Release"
fw=$(echo "$FIRMWARE_URL" | awk -F'/' '{print $4}')
tag_name="$TARGET_IMAGE-$codename-$fw"
release_name="$TARGET_IMAGE $codename $fw"
release_args=("$tag_name" "$release_name" "$(pwd)/$TARGET_IMAGE.img")

if [ "$TARGET_IMAGE" == "boot" ]; then
    sed -i "s|k_str|$k_str|g" $(pwd)/skibidi.md
    sed -i "s|k_fmt|$k_fmt|g" $(pwd)/skibidi.md
    release_args+=("$(pwd)/skibidi.md")
fi

create_release "${release_args[@]}"

log "Sending info message to telegram"
gh_repo=$(git config --get remote.origin.url | sed 's/\.git$//' | sed 's|^git@github.com:|https://github.com/|' | sed 's|^https://.*@github.com|https://github.com|')
download_link="${gh_repo}/releases/download/$tag_name/$TARGET_IMAGE.img"
text="*$release_name*\n[Download]($download_link)"
send_msg "$text"

log "Done :)"
