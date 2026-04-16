#!/usr/bin/env bash

project_root() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cd "$script_dir/../.." && pwd
}

read_version() {
    local root version_file version
    root="$(project_root)"
    version_file="$root/version.txt"

    if [[ ! -f "$version_file" ]]; then
        echo "Version file not found: $version_file" >&2
        return 1
    fi

    version="$(tr -d '[:space:]' < "$version_file")"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid version '$version'. Expected semantic version, e.g. 0.1.0" >&2
        return 1
    fi

    printf '%s\n' "$version"
}