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

# Print the download URL of the newest release asset ending in ".$2" for the
# GitHub repo $1 (owner/name).
latest_github_asset() {
    curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
        | grep -o "\"browser_download_url\": *\"[^\"]*\\.$2\"" \
        | head -n 1 \
        | sed 's/.*"\(https[^"]*\)"/\1/'
}

# Install the download entries from app-catalog.sh that were picked in the
# setup checklist; cask and section entries are installed elsewhere.
for entry in "${APP_CATALOG[@]}"; do
    IFS='|' read -r app_name app_kind app_bundle app_url <<< "$entry"
    case "$app_kind" in
        dmg|zip|tar) ;;
        *) continue ;;
    esac
    app_selected "$app_name" || continue

    if [[ "$app_url" == github:* ]]; then
        app_url="$(latest_github_asset "${app_url#github:}" "$app_kind")"
        if [[ -z "$app_url" ]]; then
            printf 'No .%s in the latest %s release; skipping.\n' \
                "$app_kind" "$app_name" >&2
            continue
        fi
    fi
    installApp "$app_kind" "$app_name" "$app_bundle" "$app_url"
done

divider
