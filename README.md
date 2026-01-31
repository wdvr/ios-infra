# iOS Infrastructure

Shared CI/CD infrastructure for iOS apps.

## Overview

This repository contains reusable GitHub Actions workflows, scripts, and shared code for iOS app development and deployment.

## Apps Using This Infrastructure

- **Trivit** - Tally counter app
- **Powder Chaser** - Ski resort snow tracker
- **Footprint** - Travel tracking app

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
    uses: wdvr/ios-infra/.github/workflows/ios-build.yml@main
    with:
      bundle_id: com.yourcompany.yourapp
      scheme: YourApp
    secrets: inherit
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
git submodule add https://github.com/wdvr/ios-infra.git infra

# Generate release notes
python infra/scripts/generate_release_notes.py --app yourapp --app-name "Your App"

# Generate App Store description
python infra/scripts/generate_description.py --app yourapp --app-name "Your App"
```

### Using AnalyticsService Swift Package

In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/wdvr/ios-infra.git", from: "1.0.0")
]
```

Or in Xcode: File > Add Package Dependencies > Enter repository URL.

## Configuration

All apps share:
- **Team ID**: YOUR_TEAM_ID
- **App Store Connect Key**: GA9T4G84AU

### Required Secrets

Configure these in each app repository:

| Secret | Description |
|--------|-------------|
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect API key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect issuer ID |
| `APP_STORE_CONNECT_PRIVATE_KEY` | App Store Connect private key |
| `DISTRIBUTION_CERTIFICATE_BASE64` | Code signing certificate (base64) |
| `DISTRIBUTION_CERTIFICATE_PASSWORD` | Certificate password |
| `KEYCHAIN_PASSWORD` | Temporary keychain password |
| `ANTHROPIC_API_KEY` | For AI content generation |

## License

Private repository - All rights reserved.
