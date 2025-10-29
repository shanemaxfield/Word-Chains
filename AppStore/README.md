# App Store Submission Package for Word Chains

This directory contains all the documentation and templates needed to submit Word Chains to the Apple App Store.

## What's Included

### 1. SubmissionChecklist.md
**The master checklist** - Step-by-step guide covering everything needed for App Store submission.

**Start here!** This comprehensive checklist includes:
- Pre-submission requirements
- Xcode project configuration
- Asset creation guidelines
- App Store Connect setup
- Build and upload instructions
- Post-submission monitoring

### 2. AppStoreMetadata.md
Complete metadata template for App Store Connect including:
- App name and subtitle
- Full description and promotional text
- Keywords and categories
- Screenshot requirements and suggestions
- Age rating information
- Support URLs
- Pricing and availability

**Action Required:** Fill in placeholders marked with [YOUR_INFO]

### 3. PrivacyPolicy.md
Ready-to-use privacy policy for Word Chains.

**Action Required:**
1. Update contact email and website URL
2. Host this at a public URL (required for App Store submission)
3. Example: `https://yourwebsite.com/wordchains/privacy`

### 4. AppReviewNotes.md
Detailed testing guide for Apple reviewers including:
- Quick start instructions
- Complete feature walkthrough
- Testing checklist
- Privacy and compliance information
- FAQ for common questions

**Action Required:** Copy this content into the "App Review Information" section in App Store Connect

---

## Files Added to Your Xcode Project

### Privacy Manifest (REQUIRED for 2025)
**Location:** `Word_Chains/PrivacyInfo.xcprivacy`

This file is **mandatory** for all iOS apps submitted in 2025. It declares:
- No tracking
- No personal data collection
- UserDefaults usage (Required Reason API: CA92.1)

**Important:** After opening in Xcode, verify this file has Target Membership checked for the Word_Chains target.

### App Icon Asset Catalog
**Location:** `Word_Chains/Assets.xcassets/AppIcon.appiconset/`

The asset catalog structure has been created. **You need to add the actual icon image:**

**Required:**
- Create/design app icon: 1024 x 1024 pixels PNG
- Save as: `icon_1024x1024.png`
- Place in: `Word_Chains/Assets.xcassets/AppIcon.appiconset/`
- No transparency, no rounded corners (iOS handles this)

**Icon Design Suggestions:**
- Chain of letter blocks
- Interlocking word bubbles
- Stylized letter tiles
- Puzzle piece motif
- Keep it simple and recognizable at small sizes

---

## Quick Start: Next Steps

### Immediate Actions (Before Submission):

1. **Create App Icon**
   - Design 1024x1024 PNG icon
   - Add to `Word_Chains/Assets.xcassets/AppIcon.appiconset/icon_1024x1024.png`
   - Build in Xcode to verify

2. **Verify Privacy Manifest in Xcode**
   - Open Word_Chains.xcodeproj in Xcode
   - Select `PrivacyInfo.xcprivacy` in Project Navigator
   - In File Inspector (right panel), ensure "Target Membership" is checked for Word_Chains target
   - This is critical - submissions will be rejected if privacy manifest isn't included in build

3. **Host Privacy Policy**
   - Update `PrivacyPolicy.md` with your contact info
   - Upload to your website (or use GitHub Pages)
   - Make publicly accessible at a URL
   - Test the URL in a browser

4. **Create Support Page**
   - Create simple support/FAQ page
   - Include contact information
   - Host at public URL

5. **Create Screenshots**
   - Run app in iOS Simulator
   - Use required device sizes (iPhone 6.7", 6.5", 5.5")
   - Capture 3-10 screenshots showing key features
   - See `AppStoreMetadata.md` for screenshot content suggestions

6. **Update Metadata**
   - Review `AppStoreMetadata.md`
   - Replace all [PLACEHOLDER] values with your actual information

7. **Follow Submission Checklist**
   - Open `SubmissionChecklist.md`
   - Check off each item as you complete it
   - Don't skip any critical items

---

## Privacy Manifest - Important Notes

### Why It's Required
Apple requires privacy manifests for all apps submitted in 2025, especially if your app:
- Uses UserDefaults (Word Chains does - for onboarding state)
- Accesses system boot time
- Accesses file timestamps
- Checks disk space

### What We've Declared
The privacy manifest for Word Chains declares:
- **NSPrivacyTracking:** false (we don't track users)
- **NSPrivacyTrackingDomains:** empty array (no tracking domains)
- **NSPrivacyCollectedDataTypes:** empty array (we don't collect data)
- **NSPrivacyAccessedAPITypes:** UserDefaults with reason CA92.1 (app-only storage)

### Verification Steps
1. Open Xcode
2. Select `Word_Chains` target
3. Build Settings > Search for "privacy"
4. Ensure privacy manifest is included in build
5. In Project Navigator, select `PrivacyInfo.xcprivacy`
6. Check Target Membership in File Inspector (right sidebar)

---

## Common Rejection Reasons (And How We've Addressed Them)

### 1. Missing Privacy Manifest ✓
**Status:** Created and included
**Location:** `Word_Chains/PrivacyInfo.xcprivacy`
**Action:** Verify Target Membership in Xcode

### 2. Missing App Icon ✗
**Status:** You need to add this
**Action:** Create 1024x1024 PNG and add to asset catalog

### 3. Missing Privacy Policy URL ✗
**Status:** Document created, needs hosting
**Action:** Host `PrivacyPolicy.md` at public URL

### 4. Incomplete Metadata ✗
**Status:** Template created
**Action:** Fill in all placeholders in `AppStoreMetadata.md`

### 5. No Screenshots ✗
**Status:** Guidelines provided
**Action:** Capture screenshots per requirements

### 6. App Crashes on Launch ✓
**Status:** App should run correctly
**Action:** Test thoroughly before submission

### 7. Placeholder Content ✓
**Status:** All content is real (word dictionary, puzzles, etc.)
**Action:** None needed

---

## Estimated Time to Complete

| Task | Time Required |
|------|---------------|
| Create app icon | 1-3 hours |
| Create screenshots | 1-2 hours |
| Set up web hosting for privacy policy | 1-2 hours |
| Fill out App Store Connect metadata | 1-2 hours |
| Verify Xcode configuration | 30 minutes |
| Build and upload | 30-60 minutes |
| Testing on device | 1-2 hours |
| **Total** | **6-12 hours** |

Apple Review Time: 1-3 days (typically 24-48 hours)

---

## App Store Connect URLs

Once you're ready to submit:

1. **App Store Connect:** https://appstoreconnect.apple.com
2. **Create New App:** Apps > + button
3. **Bundle ID:** Use `smax.wordchains` (matches your Xcode project)
4. **SKU:** Create unique identifier like `wordchains-ios-2025`

---

## Resources

### Apple Documentation
- App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Privacy Manifest Guide: https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
- App Store Connect Help: https://developer.apple.com/help/app-store-connect/
- Screenshot Specifications: https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications

### Design Resources
- Apple Design Resources: https://developer.apple.com/design/resources/
- SF Symbols (for icons): https://developer.apple.com/sf-symbols/
- Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/

### Testing
- TestFlight Beta Testing: https://developer.apple.com/testflight/

---

## Troubleshooting

### "Privacy manifest not found" error
- Check Target Membership in Xcode File Inspector
- Ensure file is named exactly `PrivacyInfo.xcprivacy`
- Verify file is in Word_Chains directory (not subdirectory)
- Clean build folder (Product > Clean Build Folder)

### "App icon missing" error
- Ensure PNG file is 1024x1024 pixels
- No transparency in image
- File named `icon_1024x1024.png`
- Asset catalog Contents.json references the file
- Build project to refresh asset catalog

### Build fails during Archive
- Select "Generic iOS Device" not Simulator
- Check code signing settings
- Verify all required files have Target Membership
- Update to latest Xcode if needed

### Validation fails during upload
- Read error message carefully
- Check App Store Connect for detailed logs
- Verify all capabilities match your app's needs
- Ensure bundle ID matches App Store Connect

---

## Getting Help

If you encounter issues:

1. **Check SubmissionChecklist.md** - Most common issues covered
2. **Apple Developer Forums** - Search for similar issues
3. **App Store Connect Support** - Contact Apple directly
4. **Review rejection messages** - Usually very specific about what's needed

---

## Version History

- **v1.0** (October 29, 2025) - Initial submission package created
  - Privacy manifest added (2025 requirement)
  - Asset catalog structure created
  - All documentation templates prepared
  - Ready for icon and screenshot creation

---

## Notes

- This package was created specifically for Word Chains version 1.0
- All templates are based on 2025 App Store requirements
- Privacy manifest includes UserDefaults declaration (for onboarding state storage)
- App requires no special permissions or capabilities
- Suitable for 4+ age rating (all ages)
- No in-app purchases or subscriptions in v1.0

---

## Questions?

Review the comprehensive `SubmissionChecklist.md` for detailed step-by-step instructions, or consult individual documents for specific areas.

**Good luck with your App Store submission!**
