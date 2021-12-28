#!/usr/bin/env bash
set -e

USERNAME=lanrat
URL="https://github.com/$USERNAME.keys"
KEY_FILE="$HOME/.ssh/authorized_keys"

# create dir and file if they do not exist
mkdir -p "$(dirname $KEY_FILE)"
touch "$KEY_FILE"

# update permissions
chmod go-w $(dirname "$KEY_FILE")
chown "$USER" "$KEY_FILE"
chmod 600 "$KEY_FILE"

# get and sort remote and local keys
echo "> Downloading keys from $URL"
remote_keys=$(curl --silent "$URL" | sort)
local_keys=$(cat "$KEY_FILE" | cut -f1-2 -d ' ' | sort)

# print counts. Need to use sed to remove blank lines and cleanup wc output whitespace
echo "> Found "$(echo "$remote_keys" | sed '/^\s*$/d' | wc -l | sed 's/^ *//g')" remote keys"
echo "> Checking agenst "$(echo "$local_keys" | sed '/^\s*$/d' | wc -l | sed 's/^ *//g')" local keys"

# perform diff of sorted keys and store common and new keys in variables.
common_keys=$(comm -1 -2 <(echo "$local_keys") <(echo "$remote_keys"))
new_keys=$(comm -1 -3 <(echo "$local_keys") <(echo "$remote_keys"))

# print number of keys in common
echo "> Found "$(echo "$common_keys" | sed '/^\s*$/d' | wc -l | sed 's/^ *//g')" common keys"

# if there are new keys, then print count, print new keys, and add new keys to authorized_keys
if [ ! -z "$new_keys" ]; then
    # add slug to new_keys
    new_keys=$(echo "$new_keys" | sed "s/\$/ "$USERNAME"@github/")

    echo "> Adding "$(echo "$new_keys" | sed '/^\s*$/d' | wc -l | sed 's/^ *//g')" new keys to $KEY_FILE"
    echo "========== NEW KEYS =========="
    echo "$new_keys"
    echo "=============================="

    # append the new keys to local file
    echo "$new_keys" >> "$KEY_FILE"
else
    echo "> Nothing to do"
fi
