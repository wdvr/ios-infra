# iOS Apps Infrastructure

## Project Goal

Consolidate shared infrastructure across three iOS apps (trivit, snow/Powder Chaser, footprint) to:
- Reduce maintenance burden (currently maintaining 3x identical workflows)
- Ensure consistency in release processes
- Enable faster iteration on CI/CD improvements
- Share AI-powered asset generation (release notes, descriptions, icons)

## Apps

This infrastructure supports multiple iOS apps. Each app has its own repository and uses the shared workflows from this repo.

## Shared Infrastructure

### GitHub Workflows (Reusable)
- `ios-build.yml` - Build and archive IPA
- `ios-testflight-internal.yml` - Distribute to internal testers
- `ios-testflight-external.yml` - Submit for external beta review
- `ios-app-store-release.yml` - Screenshots, metadata, App Store submission

### Scripts
- `generate_release_notes.py` - AI-generated release notes from commits
- `generate_description.py` - AI-generated App Store description
- `generate_icons.py` - Programmatic app icon generation

### Fastlane
- Shared lane definitions
- Consistent device lists for screenshots
- Unified delivery configuration

### Swift Packages
- AnalyticsService - Firebase Analytics + Crashlytics wrapper with conditional compilation

## Configuration

All apps share:
- Same Apple Developer Team
- Same App Store Connect API key
- Self-hosted macOS ARM64 runners (with GitHub-hosted fallback)

## Usage

### Adding a New App

1. Create app repo with standard structure
2. Add `GoogleService-Info.plist` for Firebase
3. Create workflow that calls reusable workflows:
   ```yaml
   uses: YOUR_ORG/ios-infra/.github/workflows/ios-build.yml@main
   with:
     bundle_id: com.yourcompany.newapp
     scheme: NewApp
   ```
4. Add app-specific fastlane metadata

### Making Infrastructure Changes

1. Create PR in ios-infra repo
2. Test with one app first
3. Roll out to other apps by updating workflow refs

## Repository Structure

```
ios-infra/
├── .github/
│   └── workflows/
│       ├── ios-build.yml              # Reusable: Build & archive IPA
│       ├── ios-testflight-internal.yml # Reusable: Upload to internal TestFlight
│       ├── ios-testflight-external.yml # Reusable: Submit for external beta
│       └── ios-app-store-release.yml   # Reusable: Full App Store preparation
├── scripts/
│   ├── generate_release_notes.py      # AI-generated release notes
│   ├── generate_description.py        # AI-generated App Store description
│   └── generate_icons.py              # Programmatic icon generation
├── fastlane/
│   └── shared/
│       ├── Fastfile.template          # Shared Fastlane lanes
│       └── Snapfile.template          # Screenshot device configuration
├── swift/
│   ├── Package.swift                  # Swift Package for AnalyticsService
│   ├── Sources/
│   │   └── AnalyticsService/
│   │       └── AnalyticsService.swift
│   └── Tests/
│       └── AnalyticsServiceTests/
├── CLAUDE.md                          # This file
└── README.md                          # Public documentation
```

## Secrets Required

Each app repo needs these secrets configured:
- `APP_STORE_CONNECT_KEY_ID` - API key ID
- `APP_STORE_CONNECT_ISSUER_ID` - Issuer ID
- `APP_STORE_CONNECT_PRIVATE_KEY` - Private key content (.p8 file)
- `DISTRIBUTION_CERTIFICATE_BASE64` - Code signing certificate (base64-encoded .p12)
- `DISTRIBUTION_CERTIFICATE_PASSWORD` - Certificate password
- `KEYCHAIN_PASSWORD` - Temporary keychain password
- `ANTHROPIC_API_KEY` - For AI-generated content (optional)

## Workflow Inputs

### ios-build.yml
| Input | Required | Description |
|-------|----------|-------------|
| `bundle_id` | Yes | App bundle identifier |
| `scheme` | Yes | Xcode scheme name |
| `project_path` | No | Path to .xcodeproj (default: auto-detect) |
| `workspace_path` | No | Path to .xcworkspace (if using workspace) |
| `use_xcodegen` | No | Run xcodegen before build (default: false) |
| `info_plist_path` | No | Path to Info.plist for version extraction |

### ios-testflight-internal.yml
| Input | Required | Description |
|-------|----------|-------------|
| `bundle_id` | Yes | App bundle identifier |
| `run_id` | No | Build workflow run ID (default: latest) |

### ios-testflight-external.yml
| Input | Required | Description |
|-------|----------|-------------|
| `bundle_id` | Yes | App bundle identifier |
| `build_number` | No | Build to submit (default: latest) |
| `whats_new` | No | Beta tester release notes |

### ios-app-store-release.yml
| Input | Required | Description |
|-------|----------|-------------|
| `bundle_id` | Yes | App bundle identifier |
| `app_version` | Yes | Marketing version (e.g., 1.0.0) |
| `build_number` | Yes | Build number to release |
| `generate_screenshots` | No | Generate new screenshots (default: true) |
| `generate_description` | No | AI-generate description (default: true) |
| `submit_for_review` | No | Submit to App Store review (default: false) |

## Current Status

- [x] ios-infra repo created
- [x] Reusable workflows extracted
- [x] Scripts parameterized
- [x] Swift Package created
- [x] All apps migrated to shared infrastructure
