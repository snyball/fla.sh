#!/usr/bin/env bash

c_none='\033[0m'
c_br='\033[1;31m'
c_g='\033[1;32m'
c_urgb='\033[4;37m'
c_brgb='\033[1;37m'

set -eo pipefail
shopt -s lastpipe

for p in jq lsblk; do
    if ! command -v "$p" &>/dev/null; then
        echo "Error: missing dependency \`$p'"
        exit 1
    fi
done

THIS="$(basename "${BASH_SOURCE[0]}")"
if [[ $# -lt 1 ]]; then
    echo "Usage: $THIS <image file>"
    exit 1
fi

img="$1"

if [[ ! -f "$img" ]]; then
    echo -e "${c_br}Error${c_brgb}: Cannot read image from ${img}${c_none}"
    exit 1
fi

devices() {
    lsblk --fs --json \
    | jq -c '.blockdevices[]' \
    | while read -r dev; do
        echo "$dev" | jq -ec '.. | select(.mountpoints?[0])' &>/dev/null || echo "$dev" | jq -r '.name'
    done \
    | while read -r dev; do
        [[ "$(cat "/sys/block/$dev/removable")" = 1 ]] || continue
        echo "$dev"
    done
}

label-of() {
    lsblk --fs --json \
    | jq -r --arg name "$1" '.blockdevices[] | select(.name==$name) | .. | .label? // empty' \
    | paste -sd "/" -
}

devices | readarray -t devs
vendors=()
models=()
labels=()
for dev in "${devs[@]}"; do
    vendors+=("$(xargs < "/sys/block/$dev/device/vendor")")
    models+=("$(xargs < "/sys/block/$dev/device/model")")
    labels+=("$(label-of "$dev")")
done

show-devs() {
    for i in "${!devs[@]}"; do
        echo "/dev/${devs[$i]}: ${labels[$i]} ${vendors[$i]} ${models[$i]}"
    done
}

select-dev() {
    awk -vFS=': ' '{print $1}'
}

echo -e "${c_brgb}Select a ${c_g}disk${c_none}"
if command -v fzff &>/dev/null; then
    tgt=$(show-devs | fzf --height=${#devs[@]} | select-dev)
else
    show-devs | readarray -t opts
    select opt in "${opts[@]}"; do
        if [[ 1 -le "$REPLY" && "$REPLY" -le "${#opts[@]}" ]]; then
            ((REPLY--))
            tgt="/dev/${devs[$REPLY]}"
            break
        else
            echo "Error: No such option"
        fi
    done
fi

for by_id in /dev/disk/by-id/*; do
    if [[ $tgt = "$(realpath "$by_id")" ]]; then
        tgt=$by_id
        break
    fi
done

cmd=(sudo dd if="$img" of="$tgt" bs=4096 status=progress)
echo -ne "$c_br"
echo -e "${c_brgb}Are you sure you want to ${c_br}ERASE ALL DATA${c_brgb} on ${c_g}$(basename "$tgt")${c_brgb}?${c_none}"
echo -e "${c_none}I ${c_urgb}will${c_none} execute the following command:${c_none}"
echo -e \$ "${cmd[*]}"
echo -n "yes/N?) "
read -r ans
[[ "$ans" == "yes" ]] || exit 0
"${cmd[@]}"
echo "Waiting for sync ..."
sync
echo "Done."
