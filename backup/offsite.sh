#!/usr/bin/env bash
set -euo pipefail

declare -a labels=("BRODERSEN01" "BRODERSEN02")
declare -A repos
repos["juicefs"]="s3:https://s3.us-west-000.backblazeb2.com/broderbak-juicefs/juicefs 000f94a76ebf9e70000000020 broderbak-juicefs-juicefs"
repos["immich"]="s3:https://s3.us-west-000.backblazeb2.com/broderbak-volsync/yggdrasil/immich/images 000f94a76ebf9e70000000021 broderbak-volsync-immich-images"

_get_mount() {
    findmnt -S PARTLABEL=$1 --output TARGET --noheadings
}

_log() {
    echo >&2 "$@"
}

_fatal() {
    echo >&2 "$@"
    exit 1
}

_require_secret() {
    local value="$(secret-tool lookup $1 $2)"
    if [ -z "$value" ]; then
        _fatal "failed to find secret with $1=$2"
    fi
    printf "%s" "$value"
}

for label in "${labels[@]}"; do
    _log "checking for attached disk for $label ..."
    disk_path=$(blkid --label "$label" --output device || true)
    if [ -z "$disk_path" ]; then
        _log "no mounted disk found for $label"
        continue
    fi
    
    while test -z "$(_get_mount "$label")"; do
        _log "disk label:$label, path:$disk_path is not mounted, attempting mount ..."
        ((c++)) && ((c==10)) && break 1
        sleep 1
    done


    disk_mount=$(_get_mount "$label")
    if [ -z "$disk_mount" ]; then
        _log "failed to mount disk label:$label, path:$disk_path"
        continue
    fi

    _log "saving snapshots to disk mounted at $disk_mount ..."
    for repo in "${!repos[@]}"; do
        _log "processing repo $repo ..."
        output_repo="$disk_mount/backups/$repo"
        read -r -a repo_data <<< "${repos[$repo]}"
        repo_url="${repo_data[0]}"
        backblaze_key_id="${repo_data[1]}"
        restic_lookup_id="${repo_data[2]}"

        backblaze_secret_key="$(_require_secret key_id $backblaze_key_id)"
        source_restic_password="$(_require_secret restic_id $restic_lookup_id)"
        target_restic_password="$(_require_secret restic_id offsite_password)"

        if [ ! -d "$output_repo" ]; then
            _log "directory $output_repo does not exist. initializing restic repo ..."
            mkdir -p "$output_repo"
            RESTIC_PASSWORD="$target_restic_password" restic init -r "$output_repo"
        fi

        _log "copying snapshots from $repo_url to $output_repo ..."
        AWS_ACCESS_KEY_ID="$backblaze_key_id" \
        AWS_SECRET_ACCESS_KEY="$backblaze_secret_key" \
        RESTIC_FROM_PASSWORD="$source_restic_password" \
        RESTIC_PASSWORD="$target_restic_password" \
        restic -r "$output_repo" copy --verbose --no-lock --from-repo "$repo_url"

        _log "unlinking old snapshots ..."
        RESTIC_PASSWORD="$target_restic_password" restic -r "$output_repo" forget  --verbose --keep-monthly 12 --keep-yearly 7

        _log "pruning orphan blocks ..."
        RESTIC_PASSWORD="$target_restic_password" restic -r "$output_repo" prune --verbose

        _log "verifying repo consistency ..."
        RESTIC_PASSWORD="$target_restic_password" restic -r "$output_repo" check --verbose

    done
done


    
