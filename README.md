# iOS Infrastructure

Shared CI/CD infrastructure for iOS apps.

## Overview

This repository contains reusable GitHub Actions workflows, scripts, and shared code for iOS app development and deployment.

## Features

- Reusable GitHub Actions workflows for iOS CI/CD
- AI-powered release notes and App Store description generation
- Shared Swift Package for Firebase Analytics integration
- Fastlane templates for screenshots and App Store uploads

## Quick Start

### Using Reusable Workflows

In your app's `.github/workflows/build.yml`:

```yaml
name: Build

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build:
    uses: YOUR_ORG/ios-infra/.github/workflows/ios-build.yml@main
    with:
      bundle_id: com.yourcompany.yourapp
      scheme: YourApp
    secrets: inherit  # Requires APPLE_TEAM_ID secret
```

### Available Workflows

| Workflow | Purpose |
|----------|---------|
| `ios-build.yml` | Build and archive IPA |
| `ios-testflight-internal.yml` | Upload to TestFlight internal |
| `ios-testflight-external.yml` | Submit for external beta review |
| `ios-app-store-release.yml` | Full App Store release preparation |

### Using Scripts

```bash
# Clone as submodule
git submodule add https://github.com/YOUR_ORG/ios-infra.git infra

# Generate release notes
python infra/scripts/generate_release_notes.py --app yourapp --app-name "Your App"

# Generate App Store description
python infra/scripts/generate_description.py --app yourapp --app-name "Your App"
```

### Using AnalyticsService Swift Package

In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/YOUR_ORG/ios-infra.git", from: "1.0.0")
]
```

Or in Xcode: File > Add Package Dependencies > Enter repository URL.

## Configuration

All apps share the same Apple Developer Team and App Store Connect credentials. Configure these values in your `ios-infra` workflows or as environment variables.

### Required Secrets

Configure these secrets in each app repository that uses the shared workflows.

| Secret | Description |
|--------|-------------|
| `APPLE_TEAM_ID` | Apple Developer Team ID (10-character alphanumeric) |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect API key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect issuer ID |
| `APP_STORE_CONNECT_PRIVATE_KEY` | App Store Connect private key (`.p8` file contents) |
| `DISTRIBUTION_CERTIFICATE_BASE64` | Code signing certificate (base64-encoded `.p12` file) |
| `DISTRIBUTION_CERTIFICATE_PASSWORD` | Password for the `.p12` certificate |
| `KEYCHAIN_PASSWORD` | Temporary keychain password (any random string) |
| `ANTHROPIC_API_KEY` | For AI content generation (optional) |

### How to Set Up Secrets

#### 1. App Store Connect API Key

1. Go to [App Store Connect > Users and Access > Keys](https://appstoreconnect.apple.com/access/api)
2. Create a new key with "App Manager" role
3. Download the `.p8` file (you can only download it once!)
4. Note the Key ID and Issuer ID

```bash
# Set secrets using GitHub CLI
gh secret set APP_STORE_CONNECT_KEY_ID --body "YOUR_KEY_ID" --repo OWNER/REPO
gh secret set APP_STORE_CONNECT_ISSUER_ID --body "YOUR_ISSUER_ID" --repo OWNER/REPO
gh secret set APP_STORE_CONNECT_PRIVATE_KEY < ~/.private_keys/AuthKey_YOUR_KEY_ID.p8 --repo OWNER/REPO
```

#### 2. Distribution Certificate

1. Export your Apple Distribution certificate from Keychain Access as a `.p12` file
2. Set a password when exporting
3. Base64 encode it:

```bash
# Encode the certificate
base64 -i Certificates.p12 | pbcopy

# Set the secrets
gh secret set DISTRIBUTION_CERTIFICATE_BASE64 --body "$(base64 -i Certificates.p12)" --repo OWNER/REPO
gh secret set DISTRIBUTION_CERTIFICATE_PASSWORD --body "your-p12-password" --repo OWNER/REPO
```

#### 3. Keychain Password

This is just a temporary password used to create a keychain during CI. Use any random string:

```bash
gh secret set KEYCHAIN_PASSWORD --body "$(openssl rand -base64 32)" --repo OWNER/REPO
```

#### 4. Anthropic API Key (Optional)

For AI-generated release notes and descriptions:

```bash
gh secret set ANTHROPIC_API_KEY --body "sk-ant-..." --repo OWNER/REPO
```

### Copy Secrets Between Repos

If you have secrets configured in one repo, you can copy them to another:

```bash
# List secrets from source repo
gh secret list --repo OWNER/SOURCE_REPO

# Copy each secret (requires reading the value from a secure location)
# Note: You cannot read secret values from GitHub, only set them
```

## License

MIT License - See [LICENSE](LICENSE) for details.
