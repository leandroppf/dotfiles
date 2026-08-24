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

  print "awsmfa: [$AWSMFA_TARGET_PROFILE] refreshed — expires $expiry"
}
