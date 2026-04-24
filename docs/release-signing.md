# Production Signing

MacCCP release DMGs must be Developer ID signed, notarized, and stapled before
they are presented as production downloads. Ad-hoc signed builds are suitable
only for local engineering checks.

## Required Secrets

Configure these GitHub repository secrets:

- `BUILD_CERTIFICATE_BASE64`: base64 encoded `.p12` Developer ID Application certificate.
- `P12_PASSWORD`: password for the exported `.p12`.
- `KEYCHAIN_PASSWORD`: temporary CI keychain password.
- `MACCCP_CODESIGN_IDENTITY`: full certificate identity, for example `Developer ID Application: Example, Inc. (TEAMID1234)`.
- `APPLE_ID`: Apple ID used for notarization.
- `APPLE_TEAM_ID`: Apple Developer Team ID.
- `APPLE_APP_SPECIFIC_PASSWORD`: app-specific password for the Apple ID.

## Export Certificate

Export a Developer ID Application certificate from Keychain Access as a `.p12`,
then encode it:

```sh
base64 -i DeveloperIDApplication.p12 | pbcopy
```

Paste the copied value into `BUILD_CERTIFICATE_BASE64`.

## Release

Push a version tag:

```sh
git tag v1.0.0
git push origin v1.0.0
```

The release workflow fails before packaging if any signing or notarization
secret is missing. This prevents accidental public release of a build that would
require users to bypass macOS security prompts.
