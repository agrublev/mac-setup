#!/usr/bin/env bash

sub "Installing useful apps"
TEMPAPPS_WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/tempapps.XXXXXX")" || {
    echo "Unable to create a temporary directory for app downloads" >&2
    return 1
}
# This replaces setup.sh's EXIT trap, so keep its progress bar cleanup too.
trap 'rm -rf "$TEMPAPPS_WORKDIR"; progress_end' EXIT

sub "Installing Apps"

bundle_version() {
    local bundle_path="$1"
    local version

    version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
        "$bundle_path/Contents/Info.plist" 2>/dev/null)"
    if [[ -z "$version" ]]; then
        version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' \
            "$bundle_path/Contents/Info.plist" 2>/dev/null)"
    fi
    printf '%s' "$version"
}

version_is_newer() {
    # Compare numeric version components without relying on GNU sort -V,
    # which is not available in the default macOS toolchain.
    python3 - "$1" "$2" <<'PY'
import re
import sys

def parts(version):
    return tuple(int(value) for value in re.findall(r"\d+", version))

candidate = parts(sys.argv[1])
installed = parts(sys.argv[2])
length = max(len(candidate), len(installed))
candidate += (0,) * (length - len(candidate))
installed += (0,) * (length - len(installed))
sys.exit(0 if candidate > installed else 1)
PY
}

installApp() {
    local format="$1"
    local label="$2"
    local app_bundle="$3"
    local url="$4"
    local archive="$TEMPAPPS_WORKDIR/$label"
    local extract_dir="$TEMPAPPS_WORKDIR/extracted-$label"
    local mount_dir="$TEMPAPPS_WORKDIR/mounted-$label"
    local source_app=""
    local installed_app="/Applications/$app_bundle"
    local installed_version=""
    local downloaded_version=""

    sub "Downloading $label..."
    case "$format" in
        dmg) archive="$archive.dmg" ;;
        zip) archive="$archive.zip" ;;
        tar) archive="$archive.tar.bz2" ;;
        *) printf 'Unsupported archive type: %s\n' "$format" >&2; return 1 ;;
    esac

    if ! curl --fail --location --silent --show-error --retry 2 \
        --output "$archive" "$url"; then
        printf 'Failed to download %s; skipping.\n' "$label" >&2
        return 1
    fi

    case "$format" in
        dmg)
            mkdir -p "$mount_dir"
            if ! hdiutil attach -nobrowse -readonly -mountpoint "$mount_dir" \
                "$archive" >/dev/null; then
                printf 'Failed to mount %s; skipping.\n' "$label" >&2
                return 1
            fi
            source_app="$(find "$mount_dir" -type d -name "$app_bundle" -print -quit)"
            ;;
        zip)
            mkdir -p "$extract_dir"
            if ! ditto -x -k "$archive" "$extract_dir"; then
                printf 'Failed to extract %s; skipping.\n' "$label" >&2
                return 1
            fi
            source_app="$(find "$extract_dir" -type d -name "$app_bundle" -print -quit)"
            ;;
        tar)
            mkdir -p "$extract_dir"
            if ! tar -xjf "$archive" -C "$extract_dir"; then
                printf 'Failed to extract %s; skipping.\n' "$label" >&2
                return 1
            fi
            source_app="$(find "$extract_dir" -type d -name "$app_bundle" -print -quit)"
            ;;
    esac

    if [[ -z "$source_app" ]]; then
        printf 'Could not find %s in the downloaded archive; skipping.\n' \
            "$app_bundle" >&2
        if [[ "$format" == "dmg" ]]; then
            hdiutil detach "$mount_dir" -quiet >/dev/null 2>&1 || true
        fi
        return 1
    fi

    if [[ -d "$installed_app" ]]; then
        installed_version="$(bundle_version "$installed_app")"
        downloaded_version="$(bundle_version "$source_app")"
        if [[ -n "$installed_version" && -n "$downloaded_version" ]] && \
            ! version_is_newer "$downloaded_version" "$installed_version"; then
            printf '%s is already up to date (%s).\n' "$label" "$installed_version"
        elif ditto "$source_app" "$installed_app"; then
            printf 'Successfully updated %s.\n' "$label"
        else
            printf 'Failed to update %s. Check /Applications permissions.\n' \
                "$label" >&2
        fi
    elif ditto "$source_app" "$installed_app"; then
        printf 'Successfully installed %s.\n' "$label"
    else
        printf 'Failed to install %s. Check /Applications permissions.\n' \
            "$label" >&2
    fi

    if [[ "$format" == "dmg" ]]; then
        hdiutil detach "$mount_dir" -quiet >/dev/null 2>&1 || true
    fi
}

url="$(curl -fsSL "https://api.github.com/repos/rxhanson/Rectangle/releases/latest" | jq -r '.assets[] | select(.name | endswith(".dmg")) | .browser_download_url')"

installApp "dmg" "Chrome" "Google Chrome.app" \
    "https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg"
installApp "zip" "GitHub" "GitHub Desktop.app" \
    "https://central.github.com/deployments/desktop/desktop/latest/darwin"
installApp "dmg" "SequelPro" "Sequel Pro.app" \
    "https://sequelpro.com/release?do=download-latest"
installApp "zip" "Sketch" "Sketch.app" \
    "https://www.sketchapp.com/download/sketch.zip"
installApp "zip" "Postman" "Postman.app" \
    "https://dl.pstmn.io/download/latest/osx"
installApp "dmg" "Transmission" "Transmission.app" \
    "https://github.com/transmission/transmission-releases/raw/master/Transmission-3.00.dmg"
installApp "zip" "1Password" "1Password 7.app" \
    "https://cachefly-origin.agilebits.com/dist/1P/mac7/1Password-7.10.4.zip"
installApp "zip" "ForkLift" "ForkLift.app" \
    "https://download.binarynights.com/ForkLift3.zip"
installApp "dmg" "Etcher" "balenaEtcher.app" \
    "https://github.com/balena-io/etcher/releases/download/v1.7.2/balenaEtcher-1.7.2.dmg"
installApp "dmg" "HandBrake" "HandBrake.app" \
    "https://download.handbrake.fr/releases/1.1.1/HandBrake-1.1.1.dmg"
installApp "dmg" "Rectangle" "Rectangle.app" "$(url)"

divider
