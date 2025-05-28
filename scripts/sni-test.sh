#!/usr/bin/env bash

if [ "$#" -lt 1 ]; then
  echo "At least one domain is required"
  exit 1
fi

for SNI_DOMAIN in "$@"; do
  echo "> Testing: $SNI_DOMAIN"
  if curl -sk --connect-timeout 5 --resolve $SNI_DOMAIN:443:1.1.1.1 "https://$SNI_DOMAIN" | grep -q cloudflare; then
    echo "> PASS: $SNI_DOMAIN"
  fi
done

