#!/usr/bin/env bash

read_package_namespace() {
    local package_dir="$1"
    local package_namespace=""

    if [ -f "$package_dir/metadata.desktop" ]; then
        package_namespace=$(kreadconfig5 --file "$package_dir/metadata.desktop" \
            --group "Desktop Entry" --key "X-KDE-PluginInfo-Name") || return 1
    elif [ -f "$package_dir/metadata.json" ]; then
        package_namespace=$(jq -er '.KPlugin.Id | select(type == "string")' \
            "$package_dir/metadata.json") || return 1
    else
        echo "ERROR: No metadata.desktop or metadata.json found in the package directory." >&2
        return 1
    fi

    if [[ -z "$package_namespace" || ! "$package_namespace" =~ ^[A-Za-z0-9._-]+$ \
        || "$package_namespace" == "." || "$package_namespace" == ".." ]]; then
        echo "ERROR: Invalid package name in package metadata." >&2
        return 1
    fi

    printf '%s\n' "$package_namespace"
}
