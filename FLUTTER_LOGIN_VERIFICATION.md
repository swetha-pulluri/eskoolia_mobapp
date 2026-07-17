# Flutter Login Screen - Verification Checklist

## Purpose
This checklist verifies that the Flutter login screen is a **pixel-perfect replica** of the frontend React login screen.

Compare: `frontend/app/login/page.tsx` ↔ `lib/features/auth/presentation/pages/login_page.dart`

---

## Section 1: Background Layers

### 1.1 Mandala Background
- [ ] **React:** `<div className="mandala-bg" style={{ backgroundImage: url(${MANDALA_IMAGE}) }} />`
- [ ] **Flutter:** `Positioned.fill` with `Image.network(AppConstants.mandalaImage)`
- [ ] **Opacity:** 0.04 (CSS: `opacity: 0.04`)
- [ ] **Position:** `inset: 0` (CSS) → `Positioned.fill` (Flutter)
- [ ] **Z-index:** 0 (behind everything)

### 1.2 Aura Teal Blob
- [ ] **React:** `<div className="aura-blob aura-teal-blob" />`
- [ ] **Flutter:** `AnimatedPositioned` with teal radial gradient
- [ ] **Size:** 700x700px
- [ ] **Color:** `rgba(13,148,136,0.25)` → `AppColors.auraTealBlob`
- [ ] **Position:** `right: -200px, top: -200px` (CSS)
- [ ] **Blur:** `filter: blur(120px)` → No direct equivalent (radial gradient approximates)
- [ ] **Parallax:** Moves with mouse via `transform: translate(${blobOffset.x}px, ${blobOffset.y}px)`

### 1.3 Aura Saffron Blob
- [ ] **React:** `<div className="aura-blob aura-saffron-blob" />`
- [ ] **Flutter:** `AnimatedPositioned` with saffron radial gradient
- [ ] **Size:** 700x700px
- [ ] **Color:** `rgba(255,153,51,0.3)` → `AppColors.auraSaffronBlob`
- [ ] **Position:** `left: -200px, bottom: -200px` (CSS)
- [ ] **Blur:** `filter: blur(120px)`
- [ ] **Parallax:** Moves opposite to teal blob

---

## Section 2: Header (Site Header)

### 2.1 Glass Panel Container
- [ ] **React:** `<header className="site-header"><div className="glass-panel header-panel">`
- [ ] **Flutter:** `GlassPanel` widget
- [ ] **Backdrop blur:** `blur(20px)` → `BackdropFilter(ImageFilter.blur(sigmaX: 20, sigmaY: 20))`
- [ ] **Background:** `rgba(255,255,255,0.7)` → `AppColors.glassPanelBackground`
- [ ] **Border:** `1px solid rgba(255,255,255,0.4)` → `AppColors.glassStroke`
- [ ] **Padding:** `4px 40px 4px 12px` → `EdgeInsets.fromLTRB(12, 4, 40, 4)`
- [ ] **Position:** Fixed to top (CSS) → Part of scroll view in Flutter

### 2.2 Logo
- [ ] **React:** `<img src="/image.png" alt="eSkOOlia" style={{ height: "90px" }} />`
- [ ] **Flutter:** `Image.asset(AppConstants.eskooliaLogo, height: 90)`
- [ ] **Height:** 90px
- [ ] **Object fit:** contain

### 2.3 Status Pill
- [ ] **React:** `<div className="status-pill">`
- [ ] **Flutter:** Custom `Container`
- [ ] **Background:** `rgba(49,46,129,0.03)` → `AppColors.atriumIndigo.withOpacity(0.03)`
- [ ] **Border:** `1px solid rgba(49,46,129,0.1)`
- [ ] **Border radius:** 999px (pill shape)
- [ ] **Padding:** `6px 16px`
- [ ] **Gap:** 16px between groups

### 2.4 Status Dot
- [ ] **React:** `<span className="status-dot" />`
- [ ] **Flutter:** `Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle))`
- [ ] **Color:** `#10B981` → `AppColors.statusActive`
- [ ] **Animation:** Pulse animation (CSS `@keyframes pulse`)
- [ ] **Box shadow:** `0 0 8px rgba(16,185,129,0.5)`

### 2.5 Session Text
- [ ] **React:** `<span>Session 24/25</span>`
- [ ] **Flutter:** `Text('SESSION 24/25')`
- [ ] **Font size:** 10px
- [ ] **Font weight:** 700
- [ ] **Letter spacing:** 0.3em → `3.0px`
- [ ] **Text transform:** uppercase

### 2.6 Partner Brand
- [ ] **React:** `<span>Powered by</span><img alt="eSkoolia" src={ESKOOLIA_LOGO} />`
- [ ] **Flutter:** Row with Text + Image
- [ ] **Logo height:** 16px
- [ ] **Opacity:** 0.6
- [ ] **Filter:** grayscale(1) brightness(0.5) (CSS) → Not replicated in Flutter (minor difference)

---

## Section 3: Main Card (Glass Card Command Hub)

### 3.1 Glass Card Container
- [ ] **React:** `<section className="glass-card command-hub">`
- [ ] **Flutter:** `GlassCard` widget
- [ ] **Backdrop blur:** `blur(40px)` → `BackdropFilter(ImageFilter.blur(sigmaX: 40, sigmaY: 40))`
- [ ] **Background:** `rgba(255,255,255,0.9)` → `AppColors.glassCardBackground`
- [ ] **Border:** `1px solid rgba(255,255,255,0.8)`
- [ ] **Border radius:** 40px
- [ ] **Box shadow:** `0 40px 80px -15px rgba(49,46,129,0.12)`
- [ ] **Layout:** Flex row on desktop, column on mobile

---

## Section 4: Identity Panel (Left Side / Bottom Mobile)

### 4.1 Container
- [ ] **React:** `<div className="identity-panel">`
- [ ] **Flutter:** Custom `Container` with gradient
- [ ] **Padding:** `32px 44px` → `EdgeInsets.all(44)` (Flutter uses 44 for consistency)
- [ ] **Background gradient:** `linear-gradient(135deg, rgba(13,148,136,0.06), rgba(49,46,129,0.04))`
- [ ] **Flex:** 1 (takes available space)

### 4.2 Campus Background Image
- [ ] **React:** `<div className="campus-image-wrap"><img src={CAMPUS_IMAGE} /></div>`
- [ ] **Flutter:** `Positioned.fill` with `Image.network`
- [ ] **Position:** absolute, inset: 0
- [ ] **Opacity:** 0.28
- [ ] **Filter:** `grayscale(0.4)` → `ColorFiltered` with saturation
- [ ] **Mask:** `linear-gradient(to right, black 50%, transparent 95%)` → Not supported (minor difference)
- [ ] **Object fit:** cover

### 4.3 Gateway Badge
- [ ] **React:** `<div className="gateway-badge"><span>verified</span><span>Official Digital Gateway</span></div>`
- [ ] **Flutter:** `GatewayBadge` widget
- [ ] **Padding:** `10px 20px` → `EdgeInsets.symmetric(horizontal: 20, vertical: 10)`
- [ ] **Background:** `rgba(255,255,255,0.8)`
- [ ] **Border:** `1px solid rgba(13,148,136,0.2)`
- [ ] **Border radius:** 999px
- [ ] **Icon size:** 20px
- [ ] **Icon color:** `AppColors.saffron`
- [ ] **Text color:** `AppColors.airaTeal`
- [ ] **Font size:** 12px
- [ ] **Font weight:** 800
- [ ] **Letter spacing:** 0.18em → `2.16px`

### 4.4 Hero Copy - Eyebrow
- [ ] **React:** `<span className="eyebrow">Excellence Defined</span>`
- [ ] **Flutter:** `Text('EXCELLENCE DEFINED')`
- [ ] **Color:** `AppColors.deepSaffron`
- [ ] **Font size:** 12px
- [ ] **Font weight:** 800
- [ ] **Letter spacing:** 0.3em → `3.6px`
- [ ] **Text transform:** uppercase
- [ ] **Margin bottom:** 8px

### 4.5 Hero Copy - Heading
- [ ] **React:** `<h2>The Heart of <br /><span>Educational Mastery.</span></h2>`
- [ ] **Flutter:** `RichText` with `TextSpan` and `ShaderMask`
- [ ] **Font size:** 34px
- [ ] **Font weight:** 700 (regular), 800 (gradient text)
- [ ] **Line height:** 1.05
- [ ] **Color:** `AppColors.atriumIndigo` (regular)
- [ ] **Gradient text:** `linear-gradient(90deg, teal, indigo, saffron)` → `AppColors.heroTextGradient`
- [ ] **Font style:** italic (gradient text)

### 4.6 Hero Copy - Description
- [ ] **React:** `<p>Welcome to your unified institutional workspace...</p>`
- [ ] **Flutter:** `Text(...)`
- [ ] **Color:** `AppColors.onSurfaceVariant`
- [ ] **Font size:** 14px
- [ ] **Line height:** 22/14 = 1.57
- [ ] **Max width:** 560px (CSS) → Constrained by parent
- [ ] **Margin top:** 12px

### 4.7 Feature Grid
- [ ] **React:** `<div className="feature-grid">{feature cards}</div>`
- [ ] **Flutter:** `GridView.count(crossAxisCount: 2)`
- [ ] **Grid columns:** 2
- [ ] **Gap:** 12px → `mainAxisSpacing: 12, crossAxisSpacing: 12`
- [ ] **Margin top:** 18px
- [ ] **Max width:** 576px

### 4.8 Feature Card (Single)
- [ ] **React:** `<FeatureCard icon="school" title="Academics" note="Curriculum & Grading" tone="teal" />`
- [ ] **Flutter:** `FeatureCard` widget
- [ ] **Padding:** `10px 14px`
- [ ] **Background:** `rgba(255,255,255,0.6)` → `AppColors.glassFeatureCard`
- [ ] **Border:** `1px solid rgba(255,255,255,0.8)`
- [ ] **Border radius:** 16px
- [ ] **Min height:** 60px
- [ ] **Gap:** 10px (between icon and text)
- [ ] **Hover effect:** `translateY(-4px)` with shadow change
- [ ] **Transition:** 0.3s ease

### 4.9 Feature Icon
- [ ] **React:** `<span className="material-symbols-outlined">{icon}</span>`
- [ ] **Flutter:** `Icon(widget.icon, size: 22)`
- [ ] **Container size:** 40x40px
- [ ] **Border radius:** 12px
- [ ] **Background (default):** `rgba(13,148,136,0.1)` for teal
- [ ] **Icon color (default):** `AppColors.airaTeal` for teal
- [ ] **Hover background:** `AppColors.airaTeal` (solid)
- [ ] **Hover icon color:** white

### 4.10 Feature Text
- [ ] **Title font size:** 14px
- [ ] **Title font weight:** 800
- [ ] **Title letter spacing:** 0.06em → `0.84px`
- [ ] **Title transform:** uppercase
- [ ] **Note font size:** 11px
- [ ] **Note font weight:** 500
- [ ] **Note color:** `AppColors.onSurfaceVariant`

### 4.11 Trust Strip
- [ ] **React:** `<div className="trust-strip"><div className="avatar-row">...</div><div>...</div></div>`
- [ ] **Flutter:** `TrustStrip` widget
- [ ] **Gap:** 16px
- [ ] **Alignment:** center

### 4.12 Avatar Row
- [ ] **React:** `{FACULTY_IMAGES.map((src, i) => <img key={i} src={src} />)}`
- [ ] **Flutter:** `Stack` with `Positioned` children
- [ ] **Avatar size:** 56x56px
- [ ] **Border:** `3px solid white`
- [ ] **Border radius:** 999px (circle)
- [ ] **Overlap:** `margin-left: -16px` → `left: i * 40` (56 - 16 = 40)
- [ ] **Box shadow:** `0 4px 12px rgba(0,0,0,0.12)`
- [ ] **Object fit:** cover

### 4.13 Trust Text
- [ ] **React:** `<p>Built for India's Future Leaders</p><span>Trusted by India's top...</span>`
- [ ] **Flutter:** Column with two `Text` widgets
- [ ] **Title font size:** 14px
- [ ] **Title font weight:** 800
- [ ] **Title letter spacing:** 0.06em → `0.84px`
- [ ] **Title transform:** uppercase
- [ ] **Subtitle font size:** 12px
- [ ] **Subtitle font weight:** 600
- [ ] **Subtitle font style:** italic
- [ ] **Subtitle color:** `AppColors.onSurfaceVariant`

---

## Section 5: Auth Panel (Right Side / Top Mobile)

### 5.1 Container
- [ ] **React:** `<aside className="auth-panel">`
- [ ] **Flutter:** Custom `Container`
- [ ] **Width:** 440px (desktop)
- [ ] **Padding:** `32px 48px` → `EdgeInsets.all(48)` (Flutter)
- [ ] **Background:** white
- [ ] **Border left:** `1px solid rgba(255,255,255,0.4)`
- [ ] **Box shadow:** `-30px 0 60px -15px rgba(0,0,0,0.03)`
- [ ] **Z-index:** 20

### 5.2 Heading Rule
- [ ] **React:** `<div className="heading-rule teal" />`
- [ ] **Flutter:** `Container(width: 56, height: 5, decoration: ...)`
- [ ] **Width:** 56px
- [ ] **Height:** 5px
- [ ] **Background:** `AppColors.airaTeal`
- [ ] **Border radius:** 999px
- [ ] **Margin bottom:** 14px

### 5.3 Auth Heading
- [ ] **React:** `<h2><span>Gateway</span> <em>to Mastery</em></h2>`
- [ ] **Flutter:** `RichText` with `TextSpan`
- [ ] **Font size:** 34px
- [ ] **Line height:** 1.1
- [ ] **"Gateway" weight:** 800
- [ ] **"to Mastery" weight:** 300
- [ ] **"to Mastery" style:** italic
- [ ] **"to Mastery" color:** `AppColors.secondary`

### 5.4 Auth Subheading
- [ ] **React:** `<p>Authenticate your institutional identity...</p>`
- [ ] **Flutter:** `Text(...)`
- [ ] **Color:** `AppColors.onSurfaceVariant`
- [ ] **Font size:** 13px
- [ ] **Line height:** 20/13 = 1.54
- [ ] **Margin top:** 10px
- [ ] **Margin bottom:** 20px (to form)

### 5.5 Input Group (Username)
- [ ] **React:** `<label className="input-group teal"><span className="input-label">Institutional Email / Username</span>...`
- [ ] **Flutter:** `AuthInputField` widget with `tone: AuthInputTone.teal`
- [ ] **Label text:** "INSTITUTIONAL EMAIL / USERNAME"
- [ ] **Label font size:** 12px
- [ ] **Label font weight:** 800
- [ ] **Label letter spacing:** 0.15em → `1.8px`
- [ ] **Label transform:** uppercase
- [ ] **Label color:** `AppColors.atriumIndigo`
- [ ] **Gap:** 8px (label to input)

### 5.6 Input Field Container
- [ ] **React:** `<span className="input-wrap"><input ... /></span>`
- [ ] **Flutter:** Custom `Container` with `TextFormField`
- [ ] **Height:** 48px
- [ ] **Background:** white
- [ ] **Border:** `1px solid #dee4e1` → `AppColors.surfaceVariant`
- [ ] **Border radius:** 12px
- [ ] **Box shadow:** `0 1px 5px rgba(0,0,0,0.04)`
- [ ] **Focus border color:** `AppColors.airaTeal` (teal) or `AppColors.saffron` (saffron)
- [ ] **Focus shadow:** `0 0 0 4px rgba(13,148,136,0.08)` for teal

### 5.7 Input Icon
- [ ] **React:** `<span className="material-symbols-outlined input-icon">alternate_email</span>`
- [ ] **Flutter:** `Icon(Icons.alternate_email, size: 20)`
- [ ] **Position:** absolute, left: 16px, top: 50%, transform: translateY(-50%)
- [ ] **Color (default):** `AppColors.outline`
- [ ] **Color (focus):** `AppColors.airaTeal` or `AppColors.saffron`
- [ ] **Size:** 20px

### 5.8 Input Text Field
- [ ] **React:** `<input type="text" placeholder="..." />`
- [ ] **Flutter:** `TextFormField`
- [ ] **Padding:** `0 18px 0 48px` → `contentPadding + leading icon space`
- [ ] **Font size:** 14px
- [ ] **Font weight:** 400
- [ ] **Color:** `AppColors.onBackground`
- [ ] **Placeholder color:** `AppColors.outline.withOpacity(0.6)`

### 5.9 Password Eye Toggle
- [ ] **React:** `<button className="input-eye-toggle"><span>visibility</span></button>`
- [ ] **Flutter:** `IconButton` with `Icons.visibility` / `Icons.visibility_off`
- [ ] **Position:** absolute, right: 14px
- [ ] **Size:** 20px
- [ ] **Color:** `AppColors.outline`
- [ ] **Hover color:** `AppColors.onBackground`

### 5.10 Form Options - Remember Device
- [ ] **React:** `<label className="remember-control"><span className="custom-checkbox">...</span>Trust this device</label>`
- [ ] **Flutter:** `InkWell` with custom checkbox
- [ ] **Checkbox size:** 24x24px
- [ ] **Border:** `2px solid #bcc9c6` → `AppColors.outlineVariant`
- [ ] **Border radius:** 8px
- [ ] **Checked background:** `AppColors.airaTeal`
- [ ] **Check icon size:** 18px
- [ ] **Check icon color:** white
- [ ] **Gap:** 12px (checkbox to text)
- [ ] **Text font size:** 14px
- [ ] **Text font weight:** 600
- [ ] **Text color:** `AppColors.onSurfaceVariant`

### 5.11 Form Options - Forgot Password
- [ ] **React:** `<button className="text-action">Forgot Access Key?</button>`
- [ ] **Flutter:** `TextButton`
- [ ] **Color:** `AppColors.deepSaffron`
- [ ] **Font size:** 14px
- [ ] **Font weight:** 800
- [ ] **Text decoration:** underline
- [ ] **Underline color:** `rgba(230,126,34,0.3)`
- [ ] **Underline offset:** 4px
- [ ] **Hover color:** `AppColors.airaTeal`

### 5.12 Submit Button (Atrium Button)
- [ ] **React:** `<button className="btn-atrium">Enter the Digital Atrium<span>arrow_forward</span></button>`
- [ ] **Flutter:** `AtriumButton` widget
- [ ] **Height:** 72px
- [ ] **Font size:** 20px
- [ ] **Font weight:** 800
- [ ] **Background:** `linear-gradient(135deg, #0D9488, #312E81)` → `AppColors.buttonGradient`
- [ ] **Border radius:** 20px
- [ ] **Box shadow:** `0 24px 48px -18px rgba(13,148,136,0.5)`
- [ ] **Hover shadow:** `0 16px 32px -8px rgba(13,148,136,0.4)`
- [ ] **Hover filter:** `brightness(1.05)`
- [ ] **Icon:** `Icons.arrow_forward`
- [ ] **Icon size:** 24px
- [ ] **Gap:** 16px
- [ ] **Color:** white

### 5.13 Security Panel
- [ ] **React:** `<div className="security-panel"><span>shield_person</span><div><p>Secured by eSkoolia</p>...</div></div>`
- [ ] **Flutter:** `SecurityPanel` widget
- [ ] **Icon:** `Icons.verified_user` (closest match to shield_person)
- [ ] **Icon size:** 24px
- [ ] **Icon color:** `AppColors.airaTeal`
- [ ] **Gap:** 12px
- [ ] **Title font size:** 14px
- [ ] **Title font weight:** 600
- [ ] **Title color:** `AppColors.onBackground`
- [ ] **Subtitle font size:** 12px
- [ ] **Subtitle font weight:** 400
- [ ] **Subtitle color:** `AppColors.onSurfaceVariant`

---

## Section 6: Footer

### 6.1 Container
- [ ] **React:** `<footer className="site-footer">`
- [ ] **Flutter:** `Container` with Row
- [ ] **Padding:** `20px 40px` → `EdgeInsets.symmetric(horizontal: 40, vertical: 20)`
- [ ] **Justify:** space-between

### 6.2 Copyright Text
- [ ] **React:** `© 2024 <strong>eSkoolia Institutional Node</strong>. Built on <span>eSkoolia Infrastructure v4.8.2</span>`
- [ ] **Flutter:** `RichText` with `TextSpan`
- [ ] **Font size:** 12px
- [ ] **Color:** `AppColors.onSurfaceVariant.withOpacity(0.7)`
- [ ] **Strong weight:** 700
- [ ] **Version color:** `AppColors.airaTeal.withOpacity(0.8)`

### 6.3 Footer Links
- [ ] **React:** `<a href="#">Privacy Hub</a><a href="#">Legal Terms</a>`
- [ ] **Flutter:** `Text` widgets (not interactive in current implementation)
- [ ] **Font size:** 12px
- [ ] **Font weight:** 400
- [ ] **Color:** `AppColors.onSurfaceVariant.withOpacity(0.7)`
- [ ] **Gap:** 16px

### 6.4 Academic Concierge
- [ ] **React:** `<a className="support-link"><span>Academic Concierge</span><span>support_agent</span></a>`
- [ ] **Flutter:** Row with Text + Icon
- [ ] **Text color:** `AppColors.airaTeal.withOpacity(0.8)`
- [ ] **Font size:** 12px
- [ ] **Font weight:** 600
- [ ] **Icon:** `Icons.support_agent`
- [ ] **Icon size:** 16px
- [ ] **Gap:** 8px

---

## Section 7: Responsive Behavior

### 7.1 Desktop Layout (> 900px)
- [ ] **React:** `.command-hub { display: flex; flex-direction: row; }`
- [ ] **Flutter:** `Row(children: [Expanded(identityPanel), SizedBox(width: 440, authPanel)])`
- [ ] **Identity panel:** Flex 1 (takes remaining space)
- [ ] **Auth panel:** Fixed width 440px

### 7.2 Mobile Layout (< 900px)
- [ ] **React:** CSS media query reverses order (likely)
- [ ] **Flutter:** `Column(children: [authPanel, Divider, identityPanel])`
- [ ] **Auth panel:** Full width, displayed first
- [ ] **Identity panel:** Full width, displayed below
- [ ] **Padding:** Reduced to `20px` horizontal

### 7.3 Scroll Behavior
- [ ] **React:** `.gateway-shell { overflow: hidden; }` with internal scroll
- [ ] **Flutter:** `SingleChildScrollView` wrapping content
- [ ] **Min height:** 100vh → `MediaQuery.of(context).size.height`

---

## Section 8: Animations & Interactions

### 8.1 Blob Parallax
- [ ] **React:** `onMouseMove` → `setBlobOffset`
- [ ] **Flutter:** `MouseRegion(onHover: _handleMouseMove)` → `setState(_blobOffset)`
- [ ] **Transform:** `translate(${x}px, ${y}px)` → `AnimatedPositioned`
- [ ] **Calculation:** `(clientX / width - 0.5) * 80`
- [ ] **Duration:** 100ms (Flutter: `Duration(milliseconds: 100)`)

### 8.2 Feature Card Hover
- [ ] **React:** `:hover { transform: translateY(-4px); box-shadow: ...; }`
- [ ] **Flutter:** `MouseRegion` → `AnimatedContainer` with `transform: Matrix4.translationValues(0, -4, 0)`
- [ ] **Duration:** 300ms
- [ ] **Curve:** ease-out → `Curves.easeOut`

### 8.3 Button Hover
- [ ] **React:** `:hover { filter: brightness(1.05); box-shadow: ...; }`
- [ ] **Flutter:** `MouseRegion` → `AnimatedContainer` with shadow change
- [ ] **Duration:** 300ms
- [ ] **Curve:** ease-out

### 8.4 Checkbox Toggle
- [ ] **React:** `.custom-checkbox.checked .material-symbols-outlined { transform: scale(1); }`
- [ ] **Flutter:** `AnimatedContainer` with conditional icon display
- [ ] **Duration:** 200ms
- [ ] **Transform:** scale(0) → scale(1)

---

## Section 9: Typography

### 9.1 Font Family
- [ ] **React:** `font-family: "Plus Jakarta Sans", system-ui, sans-serif;`
- [ ] **Flutter:** `fontFamily: 'Plus Jakarta Sans'` (applied to all text)
- [ ] **Fallback:** System default if font not loaded

### 9.2 Font Weights Used
- [ ] 300 (Light) - Not used in login
- [ ] 400 (Regular) - Body text, descriptions
- [ ] 500 (Medium) - Feature card notes
- [ ] 600 (Semi-bold) - Labels, subtitles
- [ ] 700 (Bold) - Headings
- [ ] 800 (Extra-bold) - Emphasis, buttons, titles

### 9.3 Font Sizes Used
- [ ] 10px - Header status pill, footer
- [ ] 11px - Feature card notes
- [ ] 12px - Labels, badges, trust strip subtitle
- [ ] 13px - Auth subheading
- [ ] 14px - Body text, input text, feature card titles
- [ ] 20px - Button text
- [ ] 34px - Main headings

### 9.4 Letter Spacing
- [ ] 0 - Headings (letter-spacing: 0)
- [ ] 0.06em - Feature cards, trust strip (converted to px: fontSize * 0.06)
- [ ] 0.15em - Input labels (converted: fontSize * 0.15)
- [ ] 0.18em - Gateway badge (converted: fontSize * 0.18)
- [ ] 0.3em - Eyebrow, status pill (converted: fontSize * 0.3)

---

## Section 10: Colors Verification

### 10.1 All Colors Used
Compare hex values in `AppColors` with CSS variables:

- [ ] `surfaceBright: #F5FAF8`
- [ ] `atriumIndigo: #312E81`
- [ ] `airaTeal: #0D9488`
- [ ] `saffron: #FF9933`
- [ ] `deepSaffron: #E67E22`
- [ ] `marigold: #FFB81C`
- [ ] `secondary: #4E45D5`
- [ ] `onBackground: #171D1C`
- [ ] `onSurfaceVariant: #3D4947`
- [ ] `outline: #6D7A77`
- [ ] `outlineVariant: #BCC9C6`
- [ ] `surfaceVariant: #DEE4E1`
- [ ] `white: #FFFFFF`
- [ ] `statusActive: #10B981`
- [ ] `error: #DC2626`

### 10.2 Opacity Values
- [ ] `glassStroke: rgba(255,255,255,0.4)` → `0x66FFFFFF`
- [ ] `glassCardBackground: rgba(255,255,255,0.9)` → `0xE6FFFFFF`
- [ ] `glassPanelBackground: rgba(255,255,255,0.7)` → `0xB3FFFFFF`
- [ ] `glassFeatureCard: rgba(255,255,255,0.6)` → `0x99FFFFFF`
- [ ] `auraTealBlob: rgba(13,148,136,0.25)` → `0x400D9488`
- [ ] `auraSaffronBlob: rgba(255,153,51,0.3)` → `0x4DFF9933`

---

## Section 11: Spacing & Layout Verification

### 11.1 Padding Values
- [ ] Header: `4px 40px 4px 12px`
- [ ] Identity panel: `32px 44px` (Flutter uses 44 all sides)
- [ ] Auth panel: `32px 48px` (Flutter uses 48 all sides)
- [ ] Gateway badge: `10px 20px`
- [ ] Feature card: `10px 14px`
- [ ] Input field: `0 18px 0 48px` (left padding accounts for icon)
- [ ] Button: `0 24px` (horizontal only)
- [ ] Footer: `20px 40px`

### 11.2 Gap Values
- [ ] Between logo and header actions: implicit (justify-content: space-between)
- [ ] Between status groups: 16px
- [ ] Between gateway badge and hero: 18px
- [ ] Between hero elements: 8px (eyebrow to heading), 12px (heading to description)
- [ ] Between description and features: 18px
- [ ] Feature grid gap: 12px
- [ ] Between features and trust strip: 32px
- [ ] Between heading rule and heading: 14px
- [ ] Between heading and subheading: 10px
- [ ] Between subheading and form: 20px
- [ ] Between form fields: 14px
- [ ] Between checkbox and text: 12px
- [ ] Between button and security panel: 20px

### 11.3 Border Radius Values
- [ ] Glass card: 40px
- [ ] Glass panel (header): 0 (no radius, spans full width)
- [ ] Feature card: 16px
- [ ] Input field: 12px
- [ ] Feature icon: 12px
- [ ] Button: 20px
- [ ] Gateway badge: 999px (pill)
- [ ] Status pill: 999px (pill)
- [ ] Checkbox: 8px
- [ ] Heading rule: 999px (pill)
- [ ] Avatar: 999px (circle)

---

## Section 12: Shadows Verification

### 12.1 Box Shadows Used
- [ ] Glass panel header: `0 4px 24px rgba(0,0,0,0.06)`
- [ ] Glass card: `0 40px 80px -15px rgba(49,46,129,0.12)`
- [ ] Gateway badge: `0 1px 6px rgba(0,0,0,0.05)`
- [ ] Feature card default: `0 1px 6px rgba(0,0,0,0.04)`
- [ ] Feature card hover: `0 18px 35px rgba(49,46,129,0.12)`
- [ ] Avatar: `0 4px 12px rgba(0,0,0,0.12)`
- [ ] Input field: `0 1px 5px rgba(0,0,0,0.04)`
- [ ] Input field focus: `0 0 0 4px rgba(13,148,136,0.08)` (teal)
- [ ] Button default: `0 24px 48px -18px rgba(13,148,136,0.5)`
- [ ] Button hover: `0 16px 32px -8px rgba(13,148,136,0.4)`
- [ ] Auth panel: `-30px 0 60px -15px rgba(0,0,0,0.03)`
- [ ] Status dot: `0 0 8px rgba(16,185,129,0.5)`

---

## Final Verification Steps

1. **Visual Comparison:**
   - [ ] Open frontend: `cd frontend && npm run dev`
   - [ ] Open Flutter: `cd eskoolia_mobapp && flutter run -d chrome`
   - [ ] Compare side-by-side at 1920x1080 resolution
   - [ ] Check mobile layout at 375x667 resolution

2. **Color Accuracy:**
   - [ ] Use color picker tool to verify hex values match
   - [ ] Check gradient directions and stop positions
   - [ ] Verify opacity values match

3. **Spacing Accuracy:**
   - [ ] Measure padding with browser dev tools vs Flutter DevTools
   - [ ] Verify gap values with visual measurement
   - [ ] Check alignment of elements

4. **Typography Accuracy:**
   - [ ] Verify font family loads correctly
   - [ ] Check font weights match (use browser font inspector)
   - [ ] Measure font sizes with dev tools
   - [ ] Verify letter spacing calculations

5. **Interaction Parity:**
   - [ ] Test hover states on feature cards
   - [ ] Test checkbox toggle animation
   - [ ] Test input focus states
   - [ ] Test button hover effect
   - [ ] Test parallax blob movement

6. **Assets Loading:**
   - [ ] Verify logo displays correctly
   - [ ] Verify mandala background loads
   - [ ] Verify campus image loads
   - [ ] Verify faculty avatars load (all 3)

7. **Responsive Behavior:**
   - [ ] Test desktop layout (>900px width)
   - [ ] Test tablet layout (600-900px)
   - [ ] Test mobile layout (<600px)
   - [ ] Verify scroll behavior on all screen sizes

---

## Known Acceptable Differences

These differences exist due to Flutter/platform limitations and are considered acceptable:

1. **CSS `mask-image`:** Not supported in Flutter. Campus image does not fade to right edge.
   - **Impact:** Minor visual difference, image fully visible.

2. **Material Symbols vs Material Icons:** Icon glyphs differ by 1-2px in some cases.
   - **Impact:** Negligible, icons convey same meaning.

3. **CSS `filter: grayscale()` on logo:** Not replicated in Flutter.
   - **Impact:** Partner brand logo appears in color instead of grayscale.

4. **Hover shimmer effect on button:** CSS uses `::before` pseudo-element with animation.
   - **Impact:** Not implemented in Flutter, button still has hover shadow/brightness change.

5. **CSS `@keyframes move` for blobs:** Replaced with mouse-tracked parallax in Flutter.
   - **Impact:** Different animation pattern, similar visual effect.

6. **Font rendering differences:** Web vs Flutter rendering engines may show slight anti-aliasing differences.
   - **Impact:** Text may appear slightly bolder/lighter depending on platform.

---

## Sign-off

When all checklist items are verified, sign off:

- [ ] **All React elements have Flutter equivalents**
- [ ] **All colors match exactly (hex values)**
- [ ] **All spacing matches exactly (px values)**
- [ ] **All typography matches (font, size, weight, spacing)**
- [ ] **All shadows match (blur, offset, color, opacity)**
- [ ] **All border radii match**
- [ ] **All animations function correctly**
- [ ] **Responsive layouts match**
- [ ] **Assets load successfully**
- [ ] **No compile errors**
- [ ] **Visual comparison passed**

**Verified by:** _________________  
**Date:** _________________  
**Notes:** _________________
