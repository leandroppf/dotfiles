# Working with an MFA-enforced AWS account

Some AWS accounts are configured so that an IAM user's access keys do almost
nothing on their own. Every meaningful action is behind a policy condition like
`aws:MultiFactorAuthPresent: "true"`. Configure the CLI the normal way on such
an account and the very first command fails:

```console
$ aws s3 ls
An error occurred (AccessDenied) when calling the ListBuckets operation:
User: arn:aws:iam::111122223333:user/your.name is not authorized to perform:
s3:ListAllMyBuckets with an explicit deny in an identity-based policy
```

The keys are valid. The credentials are correct. The account simply will not act
on them until you have proved possession of a second factor **for that specific
API session** — something a console login does not do for you.

This is what `awsmfa` (in [`functions/aws-mfa.zsh`](../functions/aws-mfa.zsh))
exists to handle.

## How the pieces fit

AWS's answer is `sts:GetSessionToken`: you hand it your long-lived keys plus a
current TOTP code, and it hands back a **temporary** trio — access key id,
secret, and a *session token* — that carries a "this session did MFA" flag.
Anything using all three passes the condition.

So two profiles, with different jobs:

```
~/.aws/credentials
├── [default]  long-lived IAM keys. Nearly powerless. Only job: call GetSessionToken.
└── [mfa]      temporary keys + session token. What you actually work with.
                Expires (36h here). Rewritten by awsmfa.
```

`AWS_PROFILE=mfa` is exported in [`.exports`](../.exports), so every `aws`
command, SDK and Terraform run picks up the second profile without `--profile`
on every invocation.

The device serial lives in `~/.aws/config` under `[default]`, not in the shell
function. One source of truth, and it keeps an account id out of this
repository.

## One-time setup

**1. Install the CLI.** The `Brewfile` has `awscli`. Amazon's own installer
works too and is what put `aws` in `~/.local/bin` on this machine — which is
exactly why [`.paths`](../.paths) puts `~/.local/bin` on `PATH`:

```sh
curl -fsSL https://awscli.amazonaws.com/v2/install.sh | bash
```

**2. Register a virtual MFA device.** IAM → Users → *your user* → Security
credentials → Multi-factor authentication → Assign MFA device → **Authenticator
app**. Scan it into 1Password, Authy, or whatever you use.

> A hardware security key (passkey, YubiKey in FIDO mode) will **not** work
> here. AWS accepts U2F/WebAuthn for console sign-in only — `GetSessionToken`
> rejects it. If you have both, register a TOTP app as well and point
> `mfa_serial` at that one. `awsmfa` detects a `:u2f/` serial and says so rather
> than failing with an opaque STS error.

**3. Create access keys** for the same user, and put them in `[default]`.

**4. Write the config.** Copy the annotated templates:

```sh
cp aws/config.example      ~/.aws/config
cp aws/credentials.example ~/.aws/credentials
chmod 600 ~/.aws/credentials
```

Then fill in your real values. Find your device serial with:

```sh
aws iam list-mfa-devices --query 'MFADevices[].SerialNumber' --output text
```

## Daily use

```console
$ awsmfa
MFA code for your.name: 123456
awsmfa: [mfa] refreshed — expires 2026-08-24T22:13:41+00:00
```

Then work normally — `AWS_PROFILE=mfa` means nothing needs a flag:

```console
$ aws s3 ls
2026-03-14 09:22:10 my-bucket
```

Non-interactively, pass the code, and optionally a duration in seconds:

```sh
awsmfa 123456
awsmfa 123456 3600     # a short-lived session instead
```

### Session length

`AWSMFA_DURATION` defaults to `129600` — 36 hours, which is the **maximum**
`GetSessionToken` permits for IAM user credentials. The API's own default is
43200 (12h); 36h is chosen here so a session comfortably outlives a working day
and you are not re-entering a code mid-afternoon. Anything above the cap is
rejected with `ValidationError`, and root account credentials are limited to 1h
regardless.

Override it per call or per shell:

```sh
awsmfa 123456 3600                  # this session only
export AWSMFA_DURATION=43200        # back to 12h for this shell
```

A longer session is a longer window in which a stolen `~/.aws/credentials` is
usable, so it is a convenience/exposure trade rather than a free win.

Check what is left without making a call that might fail:

```console
$ awsmfa_status
awsmfa: [mfa] valid for 7h 41m (until 2026-08-24T22:13:41+00:00)
```

`awsmfa_status --quiet` prints nothing and exits non-zero when the session is
dead, which composes:

```sh
awsmfa_status --quiet || awsmfa      # refresh only if needed
```

Add that to a deploy script's preamble and it prompts exactly when it has to.
Do **not** put it in `.zshrc` — every new tab would demand a code.

The spaceship prompt's `aws` section reads `AWS_PROFILE`, so the active profile
is visible in the prompt without asking.

## Why the function looks the way it does

Three details in `awsmfa` are not obvious, and each one is a bug that was hit
before it was fixed:

**The serial is resolved per call, not at shell start.** Reading it into a
variable when zsh loads would mean shelling out to `aws` on every new tab
(slow) and caching a value that goes stale the moment you edit `~/.aws/config`.

**`AWS_PROFILE` and `AWS_SESSION_TOKEN` are cleared for the STS call.**

```zsh
creds=$(AWS_PROFILE= AWS_SESSION_TOKEN= aws sts get-session-token --profile "$AWSMFA_SOURCE_PROFILE" ...)
```

Because `AWS_PROFILE=mfa` is exported globally, an unguarded call would try to
refresh the `[mfa]` session *using the `[mfa]` session* — which works right up
until it expires, at which point refreshing becomes impossible and the failure
looks like a credentials problem rather than a bootstrapping one. `--profile`
outranks the env var, but clearing both removes the ambiguity entirely.

**The expiry is written to a non-standard `x_session_expires` key.** STS returns
an expiry once, in the response, and stores it nowhere retrievable. The CLI
ignores settings it does not recognise, so parking it in the profile is a free
place to keep it — and it is the only reason `awsmfa_status` can answer without
making a live call.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `AccessDenied ... explicit deny` on everything | No valid session. Run `awsmfa`. |
| `MultiFactorAuthentication failed with invalid MFA one time pass code` | Code expired mid-typing, or device clock drift. Wait for the next code. |
| `... is not authorized to perform: sts:GetSessionToken` | `[default]` keys are wrong or disabled — this call must work *without* MFA. |
| Works in one tab, fails in another | You exported credentials into one shell by hand. `awsmfa` writes to the profile, so all shells see it; unset any manual `AWS_ACCESS_KEY_ID`. |
| `awsmfa: mfa_serial names a U2F security key` | Register a TOTP authenticator app and point `mfa_serial` at it. |
| `ExpiredToken` shortly after refreshing | Machine clock is off. TOTP is time-based; check Settings ▸ General ▸ Date & Time. |
