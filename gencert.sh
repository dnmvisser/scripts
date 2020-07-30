#!/usr/bin/env bash
#
# Script to generate a private key and corresponding Certificate
# Signing Request, or self-signed certificate.
# For increased security, the private key is not written to disk.
#
# First items are defaults
SIGN_TYPES=(CA-signed Self-signed)
KEY_TYPES=(ECC RSA)
EC_CURVES=(prime256v1 secp384r1)
RSA_SIZES=(2048 3072 4096)

#if test -t 0 ; then
#  PRIVATE_KEY=""
#else
#  PRIVATE_KEY="$(cat -)"
#  echo "input: $input"
#fi


if [ $# -lt 1 ]; then
  echo "Usage: ${BASH_SOURCE} cn <san_1 san_2 san_3 san_4 ... san_n>
The first argument is cn (Common Name).
Optional further arguments are treated as Subject Altenative Names."
  exit 1
fi

# mimics bash' select
function selectWithDefault() {
  local item i=0 numItems=$#
  # Print numbered menu items, based on the arguments passed.
  for item; do
    # Add an asterisk to the first (default) option
    printf '%s\n' "$((++i))) $item$([[ $i == 1 ]] && echo ' *')"
  done >&2 # Print to stderr, as `select` does.

  # Prompt the user for the index of the desired item.
  while :; do
    printf %s "${PS3-#? }" >&2 # Print the prompt string to stderr, as `select` does.
    read -r index
    # Make sure that the input is either empty or that a valid index was entered.
    [[ -z $index ]] && break  # empty input
    (( index >= 1 && index <= numItems )) 2>/dev/null || { echo "Invalid selection. Please try again." >&2; continue; }
    break
  done

  # Output the selected item, if any.
  if [[ -n $index ]]; then
    printf %s "${@: index:1}"
  else
    # Default: first item
    printf %s "${1}"
  fi
}



echo "Select generation type"
SIGN_TYPE=$(selectWithDefault "${SIGN_TYPES[@]}")
# For self-signed RSA is better default
if [ $SIGN_TYPE = "Self-signed" ]; then
  KEY_TYPES=(RSA ECC)
fi


echo "Select key type"
KEY_TYPE=$(selectWithDefault "${KEY_TYPES[@]}")

if [ "$KEY_TYPE" = "ECC" ]; then
  echo "Select curve"
  EC_CURVE=$(selectWithDefault "${EC_CURVES[@]}")
  EC_PARAMS=$(mktemp)
  openssl ecparam -name ${EC_CURVE} -out ${EC_PARAMS}
  KEY_SPEC="ec:${EC_PARAMS}"
elif [ "$KEY_TYPE" = "RSA" ]; then
  echo "Select RSA size"
  RSA_SIZE=$(selectWithDefault "${RSA_SIZES[@]}")
  KEY_SPEC="rsa:${RSA_SIZE}"
else
  echo "Not implemented yet"
fi


if [ $SIGN_TYPE = "CA-signed" ]; then
  if [ $# -eq 1 ]; then
    # One argument, this must be cn
    if [ -z "${PRIVATE_KEY}" ]; then
      # no key on stdin, generate one ourselves
      echo "no key on stdin, geenreat one ourselves"
      openssl req -newkey ${KEY_SPEC} \
        -nodes -subj /CN=${1}/ -keyout /dev/stdout 2>/dev/null
    else
      # use key from stdin
      echo "found key on stdin, using that"
      openssl req -key <(echo $PRIVATE_KEY) \
        -nodes -subj /CN=${1}/ 2>/dev/null
    fi
  else
    # More than one argument => first is cn, rest is list of SANs
    s="subjectAltName="
    for san in `echo $@`; do s="${s}DNS:$san,"; done
    openssl req -newkey ${KEY_SPEC} \
      -nodes -subj /CN=${1}/ -keyout /dev/stdout 2>/dev/null \
      -reqexts SAN -extensions SAN \
      -config <(printf "[req]\ndistinguished_name=rdn\n[rdn]\n[SAN]\n`echo ${s} | sed 's/.$//'`")
  fi
elif [ $SIGN_TYPE = "Self-signed" ]; then
  all_args="${@}"

  # For self-signed there is only CN=blah (no SubjAltNames etc)
  openssl req -new -newkey ${KEY_SPEC} -days 3650 \
    -nodes -x509 -subj /CN="${all_args}"/ -keyout /dev/stdout 2>/dev/null
else
  echo "Not implemented yet"
fi

# Clean up EC params
if [ -n "$EC_PARAMS" ]; then
  rm  "${EC_PARAMS}"
fi
