#!/usr/bin/env bash

if [ "$#" -lt 1 ]; then
  echo "At least one domain is required"
  exit 1
fi

#TEST_IP="1.1.1.1"
#TEST_STR="cloudflare"

#TEST_IP="142.250.72.78"
TEST_IP="$(getent ahostsv4 google.com | cut -f1 -d ' ' | head -1)"
TEST_STR="google"

for SNI_DOMAIN in "$@"; do
  echo "> Testing: $SNI_DOMAIN"
  #if curl -sk --connect-timeout 5 --resolve $SNI_DOMAIN:443:1.1.1.1 "https://$SNI_DOMAIN" | grep -q cloudflare; then
  if curl -sk --connect-timeout 5 --resolve "$SNI_DOMAIN:443:$TEST_IP" "https://$SNI_DOMAIN" | grep -q "$TEST_STR"; then
    echo "> PASS: $SNI_DOMAIN"
  fi
done

