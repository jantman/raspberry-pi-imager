#!/bin/bash
# Script to update 32bit.pkr.hcl and 64bit.pkr.hcl to the latest
# Raspberry Pi OS Lite image release.
#
# Usage: ./update_raspios.sh
#
# This fetches the latest image directory listing from
# downloads.raspberrypi.com, finds the newest release, retrieves
# the SHA256 checksum, and updates both .pkr.hcl files in place.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_URL="https://downloads.raspberrypi.com/raspios_lite"

update_pkr_file() {
    local arch="$1"      # arm64 or armhf
    local pkr_file="$2"  # 64bit.pkr.hcl or 32bit.pkr.hcl
    local images_url="${BASE_URL}_${arch}/images"

    echo ""
    echo "=== Processing ${arch} (${pkr_file}) ==="

    # Find the latest release directory
    echo "Fetching directory listing..."
    local latest_dir
    latest_dir=$(curl -fsL "${images_url}/" \
        | grep -oP "raspios_lite_${arch}-\d{4}-\d{2}-\d{2}/" \
        | sort -V \
        | tail -1)

    if [[ -z "$latest_dir" ]]; then
        echo "ERROR: Could not find latest release directory for ${arch}" >&2
        return 1
    fi
    echo "Latest directory: ${latest_dir}"

    # Find the .img.xz filename within the latest directory
    echo "Fetching file listing..."
    local img_filename
    img_filename=$(curl -fsL "${images_url}/${latest_dir}" \
        | grep -oP "\d{4}-\d{2}-\d{2}-raspios-\w+-${arch}-lite\.img\.xz" \
        | head -1)

    if [[ -z "$img_filename" ]]; then
        echo "ERROR: Could not find image file in ${latest_dir}" >&2
        return 1
    fi
    echo "Image file: ${img_filename}"

    # Fetch the SHA256 checksum
    local sha256_url="${images_url}/${latest_dir}${img_filename}.sha256"
    echo "Fetching SHA256 checksum..."
    local sha256
    sha256=$(curl -fsL "$sha256_url" | awk '{print $1}')

    if [[ -z "$sha256" ]] || [[ ${#sha256} -ne 64 ]]; then
        echo "ERROR: Invalid SHA256 checksum retrieved: '${sha256:-<empty>}'" >&2
        return 1
    fi
    echo "SHA256: ${sha256}"

    # Compute derived values
    local iso_url="${images_url}/${latest_dir}${img_filename}"
    # e.g. 2025-12-04-raspios-trixie-arm64-lite
    local base_name="${img_filename%.img.xz}"
    local output_filename="${base_name}_custom.img"

    echo "New ISO URL:         ${iso_url}"
    echo "New output filename: ${output_filename}"

    # Check if already up to date
    local pkr_path="${SCRIPT_DIR}/${pkr_file}"
    local current_url
    current_url=$(grep -oP 'iso_url\s*=\s*"\K[^"]+' "$pkr_path")

    if [[ "$current_url" == "$iso_url" ]]; then
        echo "${pkr_file} is already up to date."
        return 0
    fi

    echo "Current ISO URL:     ${current_url}"
    echo "Updating ${pkr_file}..."

    # Get the current output_filename so we can replace all derived occurrences
    local old_output
    old_output=$(grep -oP 'output_filename\s*=\s*"\K[^"]+' "$pkr_path")

    # Update iso_url
    sed -i 's|iso_url\s*=\s*"[^"]*"|iso_url                   = "'"${iso_url}"'"|' "$pkr_path"

    # Update iso_checksum
    sed -i 's|iso_checksum\s*=\s*"[^"]*"|iso_checksum              = "sha256:'"${sha256}"'"|' "$pkr_path"

    # Update output_filename and all post-processor outputs that reference it
    # (output_filename, checksum output .sha256sum, compress output .tar.gz)
    sed -i "s|${old_output}|${output_filename}|g" "$pkr_path"

    echo "${pkr_file} updated successfully."
}

update_pkr_file "arm64" "64bit.pkr.hcl"
update_pkr_file "armhf" "32bit.pkr.hcl"

echo ""
echo "Done! Review the changes with: git diff"
