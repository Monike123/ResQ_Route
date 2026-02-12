# 04 — App Store Deployment

## Objective
Deploy ResQ Route to Google Play Store and Apple App Store with proper listings, content ratings, and compliance documentation.

---

## Pre-Deployment Checklist

### Build Preparation
```bash
# Android Release Build
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info/android/

# iOS Release Build
flutter build ipa --release --obfuscate --split-debug-info=build/debug-info/ios/
```

### App Signing
- **Android**: Generate upload keystore, configure `key.properties`
- **iOS**: Configure signing in Xcode with distribution certificate

---

## Google Play Store

### App Listing
- **Title**: ResQ Route - Safe Navigation
- **Short description**: AI-powered safety navigation with SOS alerts
- **Full description**: (Detailed description of features)
- **Category**: Travel & Local → Navigation
- **Content rating**: IARC questionnaire (safety app, no violent content)
- **Target audience**: 18+ (due to safety/emergency nature)

### Required Assets
- Icon: 512x512 PNG
- Feature graphic: 1024x500
- Screenshots: Phone (min 4), Tablet (min 4)
- Privacy policy URL: https://resqroute.app/privacy

### Permissions Justification
| Permission | Justification for Review |
|-----------|------------------------|
| Background location | Required for journey safety monitoring |
| Microphone | Voice-activated SOS trigger |
| SEND_SMS | Offline emergency backup |
| Foreground service | Active journey tracking |

---

## Apple App Store

### Special Considerations
- **Background modes**: Location updates, Background fetch
- **App Review**: May take longer due to emergency feature claims
- **Privacy Nutrition Labels**: Declare all data collected

### App Store Connect
- **Category**: Navigation
- **Subcategory**: Safety
- **Price**: Free
- **In-app purchases**: None (MVP)

---

## Release Strategy

### Phase 1: Internal Testing
- Google Play: Internal test track (10 testers)
- App Store: TestFlight (25 testers)
- Duration: 2 weeks

### Phase 2: Closed Beta
- Google Play: Closed testing (100 users)
- App Store: TestFlight (100 users)
- Duration: 4 weeks
- Collect feedback on safety features

### Phase 3: Open Beta / Soft Launch
- Google Play: Open testing
- Geographic limit: Bangalore only (controlled launch)
- Duration: 2 weeks

### Phase 4: Production Release
- Full production deployment
- App Store Optimization (ASO)
- Marketing launch

---

## Rollback Plan

If critical issues found post-launch:
1. **Staged rollout**: Start at 1%, increase to 5%, 20%, 50%, 100%
2. **Rollback**: Halt rollout and revert to previous version
3. **Hotfix**: Fast-track fix through expedited review (Play Store: hours, App Store: days)

---

## Verification
- [ ] Release builds generated and signed
- [ ] App listing assets prepared
- [ ] Privacy policy published
- [ ] Permissions justified for review
- [ ] Internal testing completed
- [ ] Beta testing feedback addressed
- [ ] Staged rollout configured
