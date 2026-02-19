#!/usr/bin/env bash
set -eu
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

DRY_RUN=true

# Check for the --apply flag
for arg in "$@"; do
    if [[ "$arg" == "--apply" ]]; then
        DRY_RUN=false
        break
    fi
done

if $DRY_RUN; then
    echo "============================================================"
    echo " DRY RUN MODE: No changes will be made."
    echo " Run with '--apply' to actually disable auto-connect."
    echo "============================================================"
else
    echo "============================================================"
    echo " APPLY MODE: Disabling auto-connect for open networks..."
    echo "============================================================"
fi

# Retrieve all saved wireless connections
nmcli -t -f NAME,TYPE connection show | grep '802-11-wireless' | cut -d: -f1 | while read -r conn; do
    # Check if the network has a security key management property
    sec=$(nmcli -g 802-11-wireless-security.key-mgmt connection show "$conn" 2>/dev/null)
    
    # Check the current auto-connect status
    autoconnect=$(nmcli -g connection.autoconnect connection show "$conn" 2>/dev/null)

    # If the security property is empty (open network) AND auto-connect is not already 'no'
    if [ -z "$sec" ] && [ "$autoconnect" != "no" ]; then
        if $DRY_RUN; then
            echo "[Dry Run] Found open network with auto-connect enabled (would disable): $conn"
        else
            nmcli connection modify "$conn" connection.autoconnect no
            echo "[Applied] Disabled auto-connect for: $conn"
        fi
    fi
done

if $DRY_RUN; then
    echo "------------------------------------------------------------"
    echo "Dry run complete. Use './disable-open-wifi.sh --apply' to make changes."
fi