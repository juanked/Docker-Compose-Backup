#!/bin/sh

Help() {
  echo "Create compose files from running containers"
  echo "Syntax: $0 [-h] backup-dir user-name"
}

Incorrect() {
  echo "Incorrect usage, use -h for help"
}

while getopts ":h" option; do
  case $option in
  h)
    Help
    exit
    ;;
  *)
    Incorrect
    exit
    ;;
  esac
done

if [ $# -lt 2 ]; then
  Incorrect
  exit 1
fi

image="ghcr.io/red5d/docker-autocompose:latest"

exists=$(docker images -q $image)
if [ -z "$exists" ]; then
  docker pull $image
else
  id_local=$(docker images --format "{{.ID}}" $image)
  id_remote=$(docker pull $image | sed -n -e 's/^.*Digest: \(.*\)$/\1/p')
  if [ "$id_local" != "$id_remote" ]; then
    docker pull $image
  fi
fi

# Path to backup location
backup_dir="$1/compose-backups"
user_name="$2"

if [ ! -d "$backup_dir" ]; then
  mkdir "$backup_dir"
  echo "Made backup dir at $backup_dir"
fi

current_time=$(date "+%Y.%m.%d-%H.%M.%S")
docker ps --format '{{.Names}}' >"$backup_dir/containers.txt"
while IFS="" read -r p || [ -n "$p" ]; do
  docker run --rm -v /var/run/docker.sock:/var/run/docker.sock ghcr.io/red5d/docker-autocompose $p >"$backup_dir/$p-$current_time.yaml"
done <"$backup_dir/containers.txt"
# chown "$user_name":"$user_name" "$backup_dir/containers.txt"
chown -R "$user_name":"$user_name" "$backup_dir"
find "$backup_dir" -name "*.yaml" -mtime +5 -exec rm {} \;
