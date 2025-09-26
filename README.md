# hello-lightdash-binary-example

TypeScript app that compiles to standalone macOS binaries.

## Structure

- `src/` - TypeScript source
- `dist/` - TypeScript compilation output
- `build/` - Bundled single-file JavaScript
- `bin/` - Final binary executables

## Commands

```bash
pnpm dev          # Run TypeScript directly
pnpm build        # Compile TS → JS
pnpm build:binary # Full build → binary
```

## Binary Compilation Process

1. **TypeScript → JavaScript** (`tsc`)
   Compiles to CommonJS in `dist/`

2. **Bundle dependencies** (`@vercel/ncc`)
   Creates single-file bundle in `build/` with all node_modules included

3. **JavaScript → Binary** (`@yao-pkg/pkg`)
   Packages Node.js runtime + bundled code into standalone executables

## Output

Creates two binaries in `bin/`:
- `hello-lightdash-arm64` - Apple Silicon (~46MB)
- `hello-lightdash-x64` - Intel Macs (~51MB)

These run without Node.js installed. Each binary contains:
- Node.js runtime (v20)
- Your bundled application code
- All dependencies

## Code Signing & Notarization

For macOS distribution without Gatekeeper warnings:

### 1. Code Sign
```bash
pnpm codesign
```
Signs both binaries with Developer ID and Bundle ID configured in `scripts/codesign.sh`.

### 2. Notarize
```bash
pnpm notarize
```
Submits binaries to Apple for notarization and staples the ticket for offline verification.

### Setup (one-time)

1. Copy `.envrc.example` to `.envrc` and update with your credentials
2. If using direnv: `direnv allow`
3. Store Apple credentials in keychain:
```bash
xcrun notarytool store-credentials "AppPasswordCodesignNotarize" \
  --apple-id "your-apple-id@email.com" \
  --team-id "AF5SF5H727" \
  --password "app-specific-password"
```

Generate app-specific password at [appleid.apple.com](https://appleid.apple.com).

### Verify
```bash
spctl -a -v bin/hello-lightdash-x64
spctl -a -v bin/hello-lightdash-arm64
```

## Distribution

Ship the appropriate binary for the target architecture. No installation required - users just run the executable.

## Testing

To check gatekeeper locally, force the quarantine attribute:

```
xattr -w com.apple.quarantine "0083;$(date +%s);Safari;F643CD5F-6071-46AB-83AB-390BA944DEC5" /path/to/your/binary
```

## CI/CD - GitHub Actions

The release workflow automatically builds, signs, notarizes, and publishes binaries when you push a version tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

### Required Configuration

#### GitHub Secrets
Configure these in Settings → Secrets and variables → Actions → Secrets:

1. **MACOS_CERTIFICATE** - Base64 encoded p12 certificate
   ```bash
   base64 -i DeveloperIDApplication.p12 | pbcopy
   ```

2. **MACOS_CERTIFICATE_PASSWORD** - Password for the p12 certificate

3. **DEVELOPER_ID** - Your Developer ID (e.g., "Developer ID Application: Name (TEAMID)")

4. **APPLE_ID** - Your Apple ID email

5. **APPLE_PASSWORD** - App-specific password for notarization

6. **APPLE_TEAM_ID** - Your Apple Team ID (e.g., "AF5SF5H727")

#### Repository Variables
Configure these in Settings → Secrets and variables → Actions → Variables:

1. **BUNDLE_ID** - Your bundle identifier (e.g., "com.lightdash.hello")

### Export Certificate for CI

To export your Developer ID certificate:
```bash
# Find your certificate
security find-identity -v -p codesigning

# Export to p12 (use the exact certificate name from above)
security export -k ~/Library/Keychains/login.keychain-db \
  -t identities -f pkcs12 -o DeveloperIDApplication.p12

# When prompted, enter a password for the p12 file
# This password goes in MACOS_CERTIFICATE_PASSWORD secret

# Convert to base64 for GitHub secret
base64 -i DeveloperIDApplication.p12 | pbcopy

# The clipboard now contains the value for MACOS_CERTIFICATE secret
```

**Important**: When creating the MACOS_CERTIFICATE secret in GitHub, paste the base64 string directly without any line breaks.
