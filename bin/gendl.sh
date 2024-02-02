#!/usr/bin/env bash
set -euo pipefail

err() {
    >&2 echo "error: $1"
}

if [ "$(pwd)" != "${CYBERDROP_DIR}" ]; then
    err "script must be run from $(realpath --relative-to=$(pwd) ${CYBERDROP_DIR})"
    exit 1
fi

if [ -z "$1" ]; then
    err "required name argument missing"
    exit 1
fi

CONFIG_DIR="${CYBERDROP_DIR}/${1}"
DL_DIR="${CYBERDROP_DL_DIR}/${1}"

mkdir -p "${CONFIG_DIR}" "${DL_DIR}"
touch "${CONFIG_DIR}/URLs.txt"
cat > "${CONFIG_DIR}/config.yaml" <<EOF
Download_Options:
  block_download_sub_folders: false
  disable_download_attempt_limit: false
  disable_file_timestamps: false
  include_album_id_in_folder_name: false
  include_thread_id_in_folder_name: false
  remove_domains_from_folder_names: false
  remove_generated_id_from_filenames: false
  scrape_single_forum_post: false
  separate_posts: false
  skip_download_mark_completed: false
File_Size_Limits:
  maximum_image_size: 0
  maximum_other_size: 0
  maximum_video_size: 0
  minimum_image_size: 0
  minimum_other_size: 0
  minimum_video_size: 0
Files:
  download_folder: ${DL_DIR}
  input_file: URLs.txt
Ignore_Options:
  exclude_audio: false
  exclude_images: false
  exclude_other: false
  exclude_videos: false
  ignore_coomer_ads: false
  only_hosts: []
  skip_hosts: []
Logs:
  download_error_urls_filename: Download_Error_URLs.csv
  last_forum_post_filename: Last_Scraped_Forum_Posts.txt
  log_folder: logs
  main_log_filename: downloader.log
  scrape_error_urls_filename: Scrape_Error_URLs.csv
  unsupported_urls_filename: Unsupported_URLs.txt
Runtime_Options:
  delete_partial_files: false
  ignore_history: false
  log_level: 10
  send_unsupported_to_jdownloader: false
  skip_check_for_empty_folders: false
  skip_check_for_partial_files: false
Sorting:
  sort_downloads: false
  sort_folder: Downloads/Cyberdrop-DL Sorted Downloads
  sort_incremementer_format: ' ({i})'
  sorted_audio: '{sort_dir}/{base_dir}/Audio/{filename}{ext}'
  sorted_image: '{sort_dir}/{base_dir}/Images/{filename}{ext}'
  sorted_other: '{sort_dir}/{base_dir}/Other/{filename}{ext}'
  sorted_video: '{sort_dir}/{base_dir}/Videos/{filename}{ext}'
EOF