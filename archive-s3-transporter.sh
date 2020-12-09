#!/bin/bash

# based on https://github.com/nordic-institute/X-Road/blob/develop/src/addons/messagelog/scripts/archive-http-transporter.sh

LOCK=/var/lock/xroad-archive.lock

DEFAULT_ARCHIVE_DIR=/var/lib/xroad

BUCKET=
ARCHIVE_DIR=$DEFAULT_ARCHIVE_DIR
REMOVE_TRANSPORTED_FILES=
SYNC_BACKUP_FILES=

die () {
  echo >&2 "ERROR: $@"
  exit 1
}

usage () {
  echo >&2 "$@"
  echo
  echo "Usage: $0 [options...] <BUCKET>"
  echo "Options:"
  echo " -d, --dir DIR    Archive directory. Defaults to '$DEFAULT_ARCHIVE_DIR'"
  echo " -r, --remove     Remove successfully transported files form the"
  echo "                  archive directory."
  echo " -h, --help       This help text."

  exit 2
}

# Main

while [[ $# > 0 ]]
do
  case $1 in
    -d|--dir)
      ARCHIVE_DIR="$2"
      shift
      ;;
    -r|--remove)
      REMOVE_TRANSPORTED_FILES=true
      ;;
    -s|--sync-backup)
      SYNC_BACKUP_FILES=true
      ;;
    -h|--help)
      usage
      ;;
    *)
      if [[ $# = 1 ]]; then
        BUCKET="$1"
      else
        # Unknown option
        usage "Unknown option '$1'"
      fi
      ;;
  esac
  shift
done

if [ -z $BUCKET ]; then
  usage "ERROR: Required BUCKET option is missing"
fi

shopt -u nocasematch

if [ ! -d $ARCHIVE_DIR ]; then
  die "Archive directory '$ARCHIVE_DIR' not found"
fi

(
flock -n 123 || die "There is archive transporter process already running"

  echo "Transfer message log files"

  shopt -s nullglob
  for i in "$ARCHIVE_DIR"/*.zip; do
    i_md5_checksum=$(openssl md5 -binary $i | base64)
    aws s3api put-object \
      --bucket $BUCKET \
      --key mlog/$(hostname)/$(basename $i) \
      --body $i \
      --content-md5 $i_md5_checksum
    ret=$?

    if [ $ret -ne 0 ]; then
      # aws s3api alredy wrote error message to stderr.
      exit 3
    fi

    if [[ $REMOVE_TRANSPORTED_FILES ]]; then
      rm -f "$i"
    fi
  done

  if [[ $SYNC_BACKUP_FILES ]]; then
    echo "Synchronize database backup files to the storage bucket"
    aws s3 sync $ARCHIVE_DIR/backup s3://$BUCKET/backup/$(hostname)
  fi

) 123> $LOCK || die "Cannot aquire lock"

exit 0
