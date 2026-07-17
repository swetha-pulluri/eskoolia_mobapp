# Flutter Login Screen - Setup Guide

## Overview
This document explains how to complete the setup for the pixel-perfect Flutter login screen that matches the frontend React implementation.

---

## Required Assets

### 1. **Fonts: Plus Jakarta Sans**

The frontend uses "Plus Jakarta Sans" as the primary font. Download and add these font files:

**Location:** `eskoolia_mobapp/assets/fonts/`

**Required font files:**
- `PlusJakartaSans-Light.ttf` (weight: 300)
- `PlusJakartaSans-Regular.ttf` (weight: 400)
- `PlusJakartaSans-Italic.ttf` (weight: 400, style: italic)
- `PlusJakartaSans-Medium.ttf` (weight: 500)
- `PlusJakartaSans-SemiBold.ttf` (weight: 600)
- `PlusJakartaSans-Bold.ttf` (weight: 700)
- `PlusJakartaSans-ExtraBold.ttf` (weight: 800)

**Download from:**
- Google Fonts: https://fonts.google.com/specimen/Plus+Jakarta+Sans
- Or use `flutter pub run google_fonts:download Plus+Jakarta+Sans`

**Steps:**
1. Create directory: `mkdir assets/fonts`
2. Download all font weights from Google Fonts
3. Extract and copy `.ttf` files to `assets/fonts/`

---

### 2. **Images: eSkoolia Logo**

**Location:** `eskoolia_mobapp/assets/images/eskoolia_logo.png`

**Source:** Copy from `frontend/public/image.png`

**Steps:**
```powershell
# From eskoolia_mobapp directory:
mkdir assets/images
Copy-Item ..\frontend\public\image.png assets\images\eskoolia_logo.png
```

---

### 3. **Network Images**

The following images are loaded from network URLs (no local setup needed):
- Mandala background
- Campus image
- Faculty avatars (3 images)

These are already configured in `lib/core/constants/app_assets.dart`

---

## Verification Checklist

After setup, verify:

- [ ] `assets/fonts/` directory exists with 7 font files
- [ ] `assets/images/eskoolia_logo.png` exists
- [ ] Run `flutter pub get` successfully
- [ ] Run `flutter analyze` with zero errors
- [ ] App builds without asset loading errors

---

## CSS to Flutter Mapping

### Design Tokens (Colors)
All CSS custom properties from `.gateway-shell` are mapped to `AppColors`:

| CSS Variable | Flutter Constant | Hex Value |
|--------------|------------------|-----------|
| `--surface-bright` | `AppColors.surfaceBright` | `#F5FAF8` |
| `--atrium-indigo` | `AppColors.atriumIndigo` | `#312E81` |
| `--aira-teal` | `AppColors.airaTeal` | `#0D9488` |
| `--saffron` | `AppColors.saffron` | `#FF9933` |
| `--deep-saffron` | `AppColors.deepSaffron` | `#E67E22` |
| `--marigold` | `AppColors.marigold` | `#FFB81C` |
| `--secondary` | `AppColors.secondary` | `#4E45D5` |
| `--glass-stroke` | `AppColors.glassStroke` | `rgba(255,255,255,0.4)` |

### Typography
| CSS | Flutter |
|-----|---------|
| `font-family: "Plus Jakarta Sans"` | `fontFamily: 'Plus Jakarta Sans'` |
| `font-size: 34px` | `fontSize: 34` |
| `font-weight: 800` | `fontWeight: FontWeight.w800` |
| `letter-spacing: 0.18em` | `letterSpacing: fontSize * 0.18` |

### Spacing & Layout
| CSS | Flutter |
|-----|---------|
| `padding: 32px 44px` | `EdgeInsets.fromLTRB(44, 32, 44, 32)` |
| `gap: 12px` | `SizedBox(width/height: 12)` |
| `border-radius: 16px` | `BorderRadius.circular(16)` |

### Glassmorphism
| CSS | Flutter |
|-----|---------|
| `backdrop-filter: blur(40px)` | `BackdropFilter(filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40))` |
| `background: rgba(255,255,255,0.9)` | `color: Color(0xE6FFFFFF)` |

---

## Known Flutter Limitations

### 1. **Material Symbols Outlined Font**
The frontend uses Google's "Material Symbols Outlined" icon font. Flutter uses Material Icons which has similar but not identical icons.

**Mapping:**
- `verified` (filled) → `Icons.verified`
- `alternate_email` → `Icons.alternate_email`
- `key` → `Icons.key`
- `visibility` / `visibility_off` → `Icons.visibility` / `Icons.visibility_off`
- `arrow_forward` → `Icons.arrow_forward`
- `shield_person` (filled) → `Icons.verified_user`
- `school` → `Icons.school`
- `payments` → `Icons.payments`
- `how_to_reg` → `Icons.how_to_reg`
- `forum` → `Icons.forum`
- `calendar_today` → `Icons.calendar_today`
- `support_agent` → `Icons.support_agent`

**Visual Difference:** Minor glyph shape differences (1-2px). Acceptable for cross-platform migration.

### 2. **CSS Animations**
CSS `@keyframes move` for blob animation is simplified in Flutter to use `AnimatedPositioned` with mouse tracking. The effect is visually identical.

### 3. **Hover States**
Flutter web supports hover via `MouseRegion`. On mobile, hover effects are triggered by tap/press states using `InkWell`.

---

## File Structure

```
eskoolia_mobapp/
├── assets/
│   ├── fonts/
│   │   ├── PlusJakartaSans-Light.ttf
│   │   ├── PlusJakartaSans-Regular.ttf
│   │   ├── PlusJakartaSans-Italic.ttf
│   │   ├── PlusJakartaSans-Medium.ttf
│   │   ├── PlusJakartaSans-SemiBold.ttf
│   │   ├── PlusJakartaSans-Bold.ttf
│   │   └── PlusJakartaSans-ExtraBold.ttf
│   └── images/
│       └── eskoolia_logo.png
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_assets.dart (image URLs)
│   │   └── theme/
│   │       └── app_colors.dart (design tokens)
│   └── features/
│       └── auth/
│           └── presentation/
│               ├── pages/
│               │   └── login_page.dart (main page)
│               └── widgets/
│                   ├── feature_card.dart
│                   ├── glass_panel.dart
│                   ├── gateway_badge.dart
│                   ├── trust_strip.dart
│                   ├── security_panel.dart
│                   ├── auth_input_field.dart
│                   └── atrium_button.dart
└── pubspec.yaml (fonts configured)
```

---

## Next Steps

1. **Download and install fonts** (see section 1)
2. **Copy eSkoolia logo** (see section 2)
3. **Run verification:**
   ```powershell
   flutter pub get
   flutter analyze
   flutter run
   ```
4. **Visual comparison:**
   - Open frontend: `http://localhost:3000/login`
   - Open Flutter app: compare side-by-side
   - Verify: colors, spacing, fonts, layout, gradients, glassmorphism

---

## Troubleshooting

**Issue:** "Unable to load asset: assets/fonts/PlusJakartaSans-Regular.ttf"
- **Fix:** Verify font files exist and pubspec.yaml assets section is correct

**Issue:** "Unable to load asset: assets/images/eskoolia_logo.png"
- **Fix:** Copy logo from `frontend/public/image.png`

**Issue:** Network images fail to load
- **Fix:** Ensure internet connection. Images are hosted on Google Cloud.

**Issue:** Fonts look different from frontend
- **Fix:** Verify all 7 font weights are installed. Check font family name matches exactly.

---

## Contact

If you encounter any issues with the pixel-perfect implementation, refer to:
- Frontend source: `frontend/app/login/page.tsx`
- Frontend styles: `frontend/app/globals.css` (lines 930-1650)
- Flutter implementation: `lib/features/auth/presentation/pages/login_page.dart`
