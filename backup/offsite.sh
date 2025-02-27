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

_readme() {
    cat <<"EOF"
# Backup Repository

This is a repository for offsite backups containing data of high importance and
sentimentality to the Brodersen household. This document contains instructions
for reading and restoring data from the archives in the event that the
original data or the cloud archives are unavailable.

## Organization

The drive contains a `backups` folder, which contains indiviual repositories of
data. These repositories are formatted with [Restic](https://restic.net/), an
open source backup software. The repositories contain application specific
data. More details can be learned by restoring and inspecting individual files
from the repositories.

The repositories store the file data as snapshots. Each snapshot represents the
state of all the files at a specific point in time. The Restic command line
interface allows listing the snapshots in a repository and seeing the relevant
timestamp. It also allows restoring files from a snapshot to another folder.

## Password

The repositories on this drive are encrypted. The password is stored on the
root of this external drive in a file called `password.txt`. It can be
referenced directly during restore operations like in the below examples.

## Instructions

To restore the data from a snapshot, follow these instructions specified below.
If you need assistance, find a technical person with Linux experience to assist
you with this process. The process is easiest on a Linux or macOS based system.

1. On a working computer, follow the [Restic installation instructions](https://restic.readthedocs.io/en/stable/020_installation.html)
to install the command line interface.

2. Connect the external drive to a computer with Restic installed. Open a
terminal window, and navigate to the root of the external drive.

3. Run the following command to list the available snapshots in the repository.
Be sure to replace `repository_name` with the name of the repository you wish
to restore from.

```bash
restic -r /path/to/external/drive/backups/repository_name --password-file /path/to/external/drive/password.txt snapshots
```

The output of the command will look like this:
```bash
ID        Date                 Host        Tags        Directory
----------------------------------------------------------------------
d789xyz    2023-06-15 14:30    laptop      docs        /home/user/documents
ab123de    2023-06-14 10:15    laptop      photos      /home/user/pictures
f456uvw    2023-06-13 09:00    laptop      backup      /home/user/backup
```

4. Identify the snapshot you wish to restore files from. Run the following
command to restore all files in the snapshot to the new location.

```bash
restic -r /path/to/external/drive/backups/repository_name --password-file /path/to/external/drive/password.txt restore d789xyz --target /path/to/new/location
```
EOF
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

    instructions_file=$(mktemp)
    _readme > "$instructions_file"
    rsync -av --checksum "$instructions_file" "$disk_mount/instructions.txt"
    password_file=$(mktemp)
    target_restic_password="$(_require_secret restic_id offsite_password)"
    printf "%s" "$target_restic_password" > "$password_file"
    rsync -av --checksum "$password_file" "$disk_mount/password.txt"
    echo "Backup procedure was last performed at $(date)." > "$disk_mount/timestamp.txt"

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


    
