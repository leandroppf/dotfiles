# awsmfa — refresh temporary STS session credentials for the [mfa] profile.
#
# The device serial is read from `mfa_serial` in ~/.aws/config, so the account
# details live in your AWS config rather than in this repository.
#
# Usage:  awsmfa [6-digit-code] [duration-seconds]
#         awsmfa           # prompts for the code
#         awsmfa 123456    # non-interactive
#
# Override the device for one shell with AWSMFA_SERIAL=arn:...

: ${AWSMFA_SOURCE_PROFILE:=default}
: ${AWSMFA_TARGET_PROFILE:=mfa}
: ${AWSMFA_DURATION:=43200}   # 12h, the get-session-token default

# Set this in ~/.zshrc.local if an account registers a U2F key as its mfa_serial
# (see the u2f branch below). Empty here on purpose: an ARN embeds an account ID.
: ${AWSMFA_SERIAL_FALLBACK:=}

awsmfa() {
  emulate -L zsh
  local code=$1 duration=${2:-$AWSMFA_DURATION}

  # Resolved per call, not at shell startup: picks up config edits immediately
  # and keeps `aws` off the startup path.
  local serial=${AWSMFA_SERIAL:-$(aws configure get mfa_serial --profile "$AWSMFA_SOURCE_PROFILE" 2>/dev/null)}

  # AWS accepts U2F security keys for console sign-in only, never for
  # get-session-token, so fall back to the virtual TOTP device if one is known.
  if [[ $serial == *:u2f/* ]]; then
    if [[ -n $AWSMFA_SERIAL_FALLBACK ]]; then
      print -u2 "awsmfa: mfa_serial names a U2F security key, which works only for"
      print -u2 "        console sign-in. Using \$AWSMFA_SERIAL_FALLBACK instead."
      serial=$AWSMFA_SERIAL_FALLBACK
    else
      print -u2 "awsmfa: mfa_serial names a U2F security key, which cannot be used for"
      print -u2 "        get-session-token. Set AWSMFA_SERIAL (or AWSMFA_SERIAL_FALLBACK"
      print -u2 "        in ~/.zshrc.local) to your virtual TOTP device's ARN."
      return 1
    fi
  fi

  if [[ -z $serial ]]; then
    print -u2 "awsmfa: no mfa_serial in [$AWSMFA_SOURCE_PROFILE] and no AWSMFA_SERIAL set."
    print -u2 "        Fix with: aws configure set mfa_serial arn:... --profile $AWSMFA_SOURCE_PROFILE"
    return 1
  fi

  [[ -z $code ]] && read -r "code?MFA code for ${serial:t}: "

  if [[ ! $code =~ ^[0-9]{6}$ ]]; then
    print -u2 "awsmfa: token code must be 6 digits (got '$code')"
    return 1
  fi

  # --profile beats the exported AWS_PROFILE; clearing it too avoids any
  # chance of authenticating with the very creds we are trying to refresh.
  local creds
  creds=$(AWS_PROFILE= AWS_SESSION_TOKEN= aws sts get-session-token \
    --profile "$AWSMFA_SOURCE_PROFILE" \
    --serial-number "$serial" \
    --token-code "$code" \
    --duration-seconds "$duration" \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken,Expiration]' \
    --output text 2>&1) || {
      print -u2 "awsmfa: get-session-token failed:"
      print -u2 "$creds"
      return 1
    }

  local key secret token expiry
  IFS=$'\t' read -r key secret token expiry <<< "$creds"

  if [[ -z $key || -z $secret || -z $token ]]; then
    print -u2 "awsmfa: unexpected STS response, [$AWSMFA_TARGET_PROFILE] left untouched:"
    print -u2 "$creds"
    return 1
  fi

  aws configure set aws_access_key_id     "$key"    --profile "$AWSMFA_TARGET_PROFILE"
  aws configure set aws_secret_access_key "$secret" --profile "$AWSMFA_TARGET_PROFILE"
  aws configure set aws_session_token     "$token"  --profile "$AWSMFA_TARGET_PROFILE"

  # Not a key the CLI knows about — it ignores unrecognised settings — but it
  # gives awsmfa_status something to read. STS does not store the expiry
  # anywhere the CLI can retrieve later, so if we do not record it here, the
  # only way to discover the session died is to make a call and have it fail.
  aws configure set x_session_expires "$expiry" --profile "$AWSMFA_TARGET_PROFILE"

  print "awsmfa: [$AWSMFA_TARGET_PROFILE] refreshed — expires $expiry"
}

# awsmfa_status — how much longer the current session is good for.
#
# Usage:  awsmfa_status          # human readable
#         awsmfa_status --quiet  # no output; exit 0 if valid, 1 if expired/missing
#
# The quiet form is meant for scripts and prompts:
#     awsmfa_status --quiet || awsmfa
awsmfa_status() {
  emulate -L zsh
  local quiet=0
  [[ $1 == (-q|--quiet) ]] && quiet=1

  local expiry
  expiry=$(aws configure get x_session_expires --profile "$AWSMFA_TARGET_PROFILE" 2>/dev/null)

  if [[ -z $expiry ]]; then
    (( quiet )) || print -u2 "awsmfa: no session recorded for [$AWSMFA_TARGET_PROFILE] — run awsmfa"
    return 1
  fi

  # STS returns ISO-8601 UTC (2026-08-24T12:34:56+00:00). BSD date needs the
  # offset stripped and an explicit input format; -u reads it as UTC.
  local expiry_epoch now_epoch remaining
  expiry_epoch=$(date -u -j -f "%Y-%m-%dT%H:%M:%S" "${expiry%%+*}" +%s 2>/dev/null) || {
    (( quiet )) || print -u2 "awsmfa: could not parse recorded expiry '$expiry'"
    return 1
  }
  now_epoch=$(date -u +%s)
  remaining=$(( expiry_epoch - now_epoch ))

  if (( remaining <= 0 )); then
    (( quiet )) || print -u2 "awsmfa: [$AWSMFA_TARGET_PROFILE] expired $(( -remaining / 60 ))m ago — run awsmfa"
    return 1
  fi

  (( quiet )) || print "awsmfa: [$AWSMFA_TARGET_PROFILE] valid for $(( remaining / 3600 ))h $(( remaining % 3600 / 60 ))m (until $expiry)"
  return 0
}
