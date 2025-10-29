# App Store Submission Guide - Word Chains

## Overview

This project is now configured with all necessary files for App Store submission. This document provides a quick overview of what's been added and what you still need to do.

---

## What's Been Added ✓

### 1. Privacy Manifest (REQUIRED)
**File:** `Word_Chains/PrivacyInfo.xcprivacy`

Apple requires all iOS apps submitted in 2025 to include a privacy manifest. This file declares:
- No user tracking
- No personal data collection
- UserDefaults usage for local game state storage (Required Reason API: CA92.1)

**Important:** Open Xcode and verify this file has Target Membership checked for the Word_Chains target.

### 2. App Icon Asset Catalog
**Location:** `Word_Chains/Assets.xcassets/`

The asset catalog structure has been created with:
- Main Assets.xcassets directory
- AppIcon.appiconset folder
- AccentColor colorset
- Proper Contents.json files

**Action Required:** You need to create and add the actual app icon image (see below).

### 3. Complete Documentation Package
**Location:** `AppStore/` directory

All submission documentation has been created:

- **SubmissionChecklist.md** - Master checklist covering entire submission process
- **AppStoreMetadata.md** - All App Store Connect metadata and descriptions
- **PrivacyPolicy.md** - Ready-to-use privacy policy
- **AppReviewNotes.md** - Detailed testing guide for Apple reviewers
- **README.md** - Overview of all submission materials

---

## What You Need to Do ✗

### Critical (Required for Submission):

#### 1. Create App Icon
**Required:** 1024 x 1024 pixel PNG image

**Steps:**
1. Design your app icon (or hire a designer)
2. Export as PNG at 1024x1024 pixels
3. Save as `icon_1024x1024.png`
4. Place in: `Word_Chains/Assets.xcassets/AppIcon.appiconset/`
5. Open Xcode and build to verify icon appears

**Design Tips:**
- Keep it simple and recognizable
- Works well at small sizes (60x60 and below)
- No transparency (will be rejected)
- No rounded corners (iOS adds them automatically)
- Consider word/puzzle theme (letters, chains, tiles, etc.)

#### 2. Verify Privacy Manifest in Xcode
**Steps:**
1. Open `Word_Chains.xcodeproj` in Xcode
2. In Project Navigator, select `PrivacyInfo.xcprivacy`
3. In File Inspector (right sidebar), check "Target Membership" for Word_Chains
4. If unchecked, check the box
5. Build project to verify no errors

**Why:** Without proper Target Membership, the privacy manifest won't be included in your build and submission will be rejected.

#### 3. Host Privacy Policy (Public URL Required)
**Steps:**
1. Edit `AppStore/PrivacyPolicy.md`
2. Replace `[YOUR_EMAIL@example.com]` with your actual email
3. Replace `[YOUR_WEBSITE_URL]` with your website
4. Upload to a public website
5. Example URL: `https://yourwebsite.com/wordchains/privacy`
6. Verify URL is accessible in a browser

**Options for Hosting:**
- Your own website
- GitHub Pages (free)
- Netlify (free)
- Any web hosting service

#### 4. Create Support Page (Public URL Required)
**Required Content:**
- FAQ or help documentation
- Contact email or form
- Basic troubleshooting

**Example URL:** `https://yourwebsite.com/wordchains/support`

#### 5. Create Screenshots
**Required Sizes:**
- iPhone 6.7" (1290 x 2796) - 3 to 10 screenshots
- iPhone 6.5" (1242 x 2688) - 3 to 10 screenshots
- iPhone 5.5" (1242 x 2208) - 3 to 10 screenshots

**Suggested Content:**
1. Main game screen with Puzzle of the Day
2. Active gameplay showing letter tiles and keyboard
3. Puzzle completion celebration
4. Free Roam mode
5. Tutorial/onboarding overlay
6. Word length selection

**How to Capture:**
- Use iOS Simulator
- Press Cmd+S to save screenshot
- Or use File > Save Screen
- Select device sizes matching requirements

#### 6. Fill Out App Store Connect
**Steps:**
1. Log into https://appstoreconnect.apple.com
2. Create new app
3. Enter Bundle ID: `smax.wordchains`
4. Fill in all metadata from `AppStore/AppStoreMetadata.md`
5. Upload screenshots
6. Enter Privacy Policy URL and Support URL
7. Complete age rating questionnaire (should be 4+)

#### 7. Build and Upload
**Steps:**
1. Open Xcode
2. Select "Generic iOS Device" (not Simulator)
3. Product > Archive
4. Click "Distribute App"
5. Select "App Store Connect"
6. Upload
7. Wait for processing (10-60 minutes)

---

## Submission Checklist Quick Reference

Use this quick checklist, then see `AppStore/SubmissionChecklist.md` for complete details:

### Pre-Submission
- [ ] App icon created and added to Xcode
- [ ] Privacy manifest verified in Target Membership
- [ ] Privacy policy hosted at public URL
- [ ] Support page created and hosted
- [ ] Screenshots created for all required sizes
- [ ] Metadata prepared (from AppStoreMetadata.md)

### Xcode Configuration
- [ ] Bundle ID: smax.wordchains
- [ ] Version: 1.0
- [ ] Build: 1 (or higher)
- [ ] Code signing configured
- [ ] App builds without errors
- [ ] Tested on physical device

### App Store Connect
- [ ] App created
- [ ] All metadata fields filled
- [ ] Screenshots uploaded
- [ ] Privacy Policy URL entered
- [ ] Support URL entered
- [ ] Age rating completed (4+)
- [ ] App Review Notes entered (from AppReviewNotes.md)

### Build & Upload
- [ ] Archive created in Xcode
- [ ] Archive validated successfully
- [ ] Uploaded to App Store Connect
- [ ] Build processed and ready

### Final Submission
- [ ] Build selected in App Store Connect
- [ ] All information reviewed
- [ ] "Submit for Review" clicked

---

## Important Notes

### 2025 Requirements
Your app is configured to meet all 2025 App Store requirements:
- ✓ Privacy manifest included
- ✓ Built with Xcode 16.3
- ✓ iOS 18.4 deployment target
- ✓ UserDefaults API usage declared

### No Login Required
Word Chains doesn't require user accounts, which simplifies submission:
- No demo account needed for Apple reviewers
- No password reset flows to implement
- Easier privacy compliance
- Faster review process

### Privacy Compliance
The app is privacy-friendly:
- No personal data collection
- No third-party analytics
- No tracking
- No ads
- All data stored locally
- GDPR/CCPA compliant

### Age Rating
Expected rating: **4+** (suitable for all ages)
- No violence
- No mature content
- No profanity
- Educational value

---

## Timeline Estimate

| Phase | Time | Status |
|-------|------|--------|
| Create app icon | 1-3 hours | ✗ To do |
| Verify Xcode configuration | 30 min | ⚠ Partial |
| Create screenshots | 1-2 hours | ✗ To do |
| Set up web hosting | 1-2 hours | ✗ To do |
| Fill out App Store Connect | 1-2 hours | ✗ To do |
| Build and upload | 1 hour | ✗ To do |
| **Total prep time** | **6-11 hours** | |
| **Apple review time** | **1-3 days** | |

---

## Resources

### Documentation
- `AppStore/SubmissionChecklist.md` - Complete step-by-step guide
- `AppStore/AppStoreMetadata.md` - All metadata and descriptions
- `AppStore/PrivacyPolicy.md` - Privacy policy to host
- `AppStore/AppReviewNotes.md` - Testing guide for Apple
- `AppStore/README.md` - Overview of submission package

### Apple Resources
- App Store Connect: https://appstoreconnect.apple.com
- Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Privacy Manifest Guide: https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
- Screenshot Specs: https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications

---

## Common Issues and Solutions

### "Privacy manifest not found"
**Solution:** Check Target Membership in Xcode for `PrivacyInfo.xcprivacy`

### "Missing app icon"
**Solution:** Add 1024x1024 PNG to `Word_Chains/Assets.xcassets/AppIcon.appiconset/icon_1024x1024.png`

### "Invalid privacy policy URL"
**Solution:** Host privacy policy at public URL and test in browser before submitting

### "Missing required screenshots"
**Solution:** Provide screenshots for all three required iPhone sizes

### Build fails during archive
**Solution:** Select "Generic iOS Device" not Simulator, check code signing

---

## Next Steps

1. **Read the complete checklist**
   - Open `AppStore/SubmissionChecklist.md`
   - Review all requirements thoroughly

2. **Create your app icon**
   - This is the most time-consuming task
   - Consider hiring a designer if needed

3. **Set up web hosting**
   - Host privacy policy and support pages
   - Test URLs before submission

4. **Create screenshots**
   - Use iOS Simulator
   - Capture all required sizes
   - Optionally add marketing text overlays

5. **Submit!**
   - Follow the step-by-step checklist
   - Review everything carefully before clicking "Submit for Review"

---

## Questions?

Refer to the comprehensive documentation in the `AppStore/` directory for detailed guidance on every step of the submission process.

**Good luck with your App Store submission!** 🚀
