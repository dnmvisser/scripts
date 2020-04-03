#!/usr/bin/env bash
# Script to generate an ECC private key and corresponding Certificate Signing
# Request, without writing key material to disk.

if [ $# -lt 1 ]; then
  echo "Usage: ${BASH_SOURCE} fqdn <fqdn_2 fqdn_3 fqdn_4 ... fqdn_x>
The first argument will be treated as the Common Name.
Any further arguments will treated as Subject Altenative Names."
  exit 1
elif [ $# -eq 1 ]; then
  # One argument => cn 
openssl req -newkey ec:<(openssl ecparam -name prime256v1) \
  -nodes -subj /CN=${1}/ -keyout /dev/stdout 2>/dev/null 
else
  # More than one argument => first is cn, rest is SANs
  s="subjectAltName="
  for san in `echo $@`; do s="${s}DNS:$san,"; done
  openssl req -newkey ec:<(openssl ecparam -name prime256v1) \
    -nodes -subj /CN=${1}/ -keyout /dev/stdout 2>/dev/null \
    -reqexts SAN -extensions SAN \
    -config <(printf "[req]\ndistinguished_name=rdn\n[rdn]\n[SAN]\n`echo ${s} | sed 's/.$//'`")
fi
