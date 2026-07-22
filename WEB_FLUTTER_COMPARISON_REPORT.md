# SCHOOL TENANCY WEB vs FLUTTER COMPARISON REPORT

**Date:** 2026-07-17  
**Status:** ❌ CRITICAL - Flutter UI does NOT match web frontend

---

## EXECUTIVE SUMMARY

The current Flutter School Tenancy implementation is **fundamentally incorrect**. It does NOT match the actual eSkoolia web frontend structure, layout, or visual design.

**Problem:** The Flutter UI looks like a **newly designed generic dashboard**, NOT a conversion of the actual web frontend.

**Required Action:** **COMPLETE REBUILD** of all 5 School Tenancy pages using the ACTUAL web frontend as the ONLY source of truth.

---

## 1. DASHBOARD PAGE COMPARISON

### ❌ ACTUAL WEB FRONTEND (CORRECT)

**Location:** `frontend/app/(dashboard)/super-admin/dashboard/page.tsx`

**Structure:**
```
┌─ PAGE HEADER ───────────────────────────────────────────┐
│ Title: "Super Admin" (34px, 600, #0F1222) +            │
│        "Dashboard" (38px, italic, serif, #6D4AFF)      │
│                                                         │
│ Description: "Cross-tenant overview of every school... │
│  · 48 schools · 12,547 students served across India    │
│  · GST-compliant billing & full data isolation."       │
│                                                         │
│ Actions: [Export] [Add school]                         │
└─────────────────────────────────────────────────────────┘

┌─ KPI ROW (4 columns) ───────────────────────────────────┐
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌───┐  │
│ │Total Schools│ │Students     │ │Monthly      │ │   │  │
│ │             │ │Served       │ │Recurring    │ │   │  │
│ │[Sparkline]  │ │[Sparkline]  │ │[Sparkline]  │ │   │  │
│ │    48       │ │   12.5K     │ │  ₹5.89L     │ │ 4 │  │
│ │● 42 active  │ │12,547 active│ │  +8.3%      │ │   │  │
│ │Telangana·AP │ │516 inactive │ │GST·₹1.06L   │ │   │  │
│ └─────────────┘ └─────────────┘ └─────────────┘ └───┘  │
└─────────────────────────────────────────────────────────┘

┌─ SECTION: Schools by board + Geographic distribution ───┐
│ ┌─ Schools by board ────┐ ┌─ Geographic distribution ─┐ │
│ │ Title + subtitle      │ │ Title + subtitle          │ │
│ │ ● CBSE  [████████] 24 │ │ Telangana [████████] 18  │ │
│ │ ● ICSE  [████░░░░] 12 │ │ AP        [████░░░░] 12  │ │
│ │ ● SSC AP[██░░░░░░]  8 │ │ Karnataka [██░░░░░░]  8  │ │
│ │ Pills: CBSE·24 ICSE·12│ │ GST: 36-TG · 37-AP       │ │
│ └───────────────────────┘ └──────────────────────────┘ │
└─────────────────────────────────────────────────────────┘

┌─ SECTION: Plan revenue (MRR) + Recent activity ─────────┐
│ ┌─ Plan revenue ────────┐ ┌─ Recent activity ────────┐ │
│ │ [+8.3% MoM badge]     │ │ [View all →]             │ │
│ │ Premium [████████] 24  │ │ 4m ago ⚪ School prov... │ │
│ │ Standard[████░░░░] 12  │ │ 18m ago ⚪ Invoice gen..│ │
│ │ Basic   [██░░░░░░]  8  │ │ 45m ago ⚠️ Admin imp... │ │
│ └───────────────────────┘ └──────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

**Key Visual Elements:**
- **Sparklines**: 118x32px SVG polyline charts in each KPI card
- **Serif font**: `var(--font-instrument-serif)` for large numbers (50px)
- **Colored dots**: Before board names (CBSE=#5836E0, ICSE=#0369A1, etc.)
- **Progress bars**: 7px height, rounded, colored fills matching board colors
- **Activity icons**: 28px circle backgrounds with icon (green/purple/yellow/red based on severity)
- **Pills**: Small rounded tags for board summary at bottom
- **Typography**: 
  - Section titles: 15px, 600 weight, -0.1px letter spacing
  - Subtitles: 12px, #9CA3AF
  - Numbers: 50px serif, 400 weight, -1.5px letter spacing
  - KPI labels: 10.5px uppercase, 0.1em tracking, #9CA3AF

### ❌ CURRENT FLUTTER (WRONG)

**File:** `lib/features/school_tenancy/presentation/pages/dashboard_tab.dart`

**Problems:**
1. ❌ **Page header**: Uses RichText but doesn't match web typography exactly
2. ❌ **Description**: Missing the full web description with school count
3. ❌ **Action buttons**: Missing Export and Add school buttons
4. ❌ **KPI cards**: Simplified layout, missing sparklines visual accuracy
5. ❌ **Board section**: Progress bars exist but layout doesn't match web
6. ❌ **Recent activity**: Layout doesn't match web timeline structure
7. ❌ **Overall layout**: Generic 2-column grid instead of web's specific sections

---

## 2. SCHOOLS PAGE COMPARISON

### ✅ ACTUAL WEB FRONTEND (CORRECT)

**Location:** `frontend/app/(dashboard)/super-admin/schools/page.tsx`

**Structure:**
```
┌─ TITLE ROW ─────────────────────────────────────────────┐
│ "School" (34px, 600, #ink-1) +                         │
│ "Management" (38px, italic, serif, #pu)                │
│                                                         │
│ Description: "Provision, monitor & manage every school │
│  tenant. · Each school has its own tenant ID..."       │
│                                                         │
│ Actions: [Export] [Add school]                         │
└─────────────────────────────────────────────────────────┘

┌─ KPI GRID (4 cards) ────────────────────────────────────┐
│ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │
│ │ Total    │ │ Active   │ │ Students │ │ MRR      │   │
│ │ Schools  │ │ Schools  │ │ Served   │ │          │   │
│ │[Spark]   │ │[Spark]   │ │[Spark]   │ │[Spark]   │   │
│ │   48     │ │   42     │ │  12.5K   │ │ ₹5.89L   │   │
│ │ +12%     │ │ +8%      │ │ +15%     │ │ +8.3%    │   │
│ │Pan-India │ │87% active│ │Total...  │ │Exclud... │   │
│ └──────────┘ └──────────┘ └──────────┘ └──────────┘   │
└─────────────────────────────────────────────────────────┘

┌─ FILTER PILLS ──────────────────────────────────────────┐
│ [All schools 48] [Active 42] [Trial 3] [Onboarding 2]  │
└─────────────────────────────────────────────────────────┘

┌─ ACCORDION LIST ────────────────────────────────────────┐
│ ┌─────────────────────────────────────────────────────┐ │
│ │ [01] 🟣[DPS] Delhi Public School                    │ │
│ │            Ten: dps_noida                      [▼]  │ │
│ │ ┌─ EXPANDED ────────────────────────────────────┐   │ │
│ │ │ Plan: Premium | Students: 1,245 | MRR: ₹9,999 │   │ │
│ │ │ [Impersonate] [Edit] [View logs] [Actions ▼]  │   │ │
│ │ └──────────────────────────────────────────────────┘ │ │
│ └─────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ [02] 🟠[RI] Ryan International                      │ │
│ │            Ten: ryan_intl                      [▶]  │ │
│ └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

**Key Visual Elements:**
- **Numbered badges**: `[01]`, `[02]`, etc. in mono font, 11px, with border
- **Gradient avatars**: 8 predefined gradients, circular, with initials
- **Accordion**: Featured border for active schools (purple), shadow on open
- **Filter pills**: Rounded, with count badges in mono font
- **Status dots**: 7px circles (green/yellow/red) before status label
- **Board chips**: Colored backgrounds (indigo/info/warn based on board)
- **Plan chips**: ok/indigo/ghost variants

### ❌ CURRENT FLUTTER (WRONG)

**File:** `lib/features/school_tenancy/presentation/pages/schools_tab.dart`

**Problems:**
1. ❌ **Title**: Doesn't match web "School" + italic "Management" structure
2. ❌ **KPI cards**: Partially implemented but layout doesn't match web grid
3. ❌ **Filter pills**: Implemented but styling doesn't match web exactly
4. ❌ **Accordion**: Numbered badges added but accordion structure wrong
5. ❌ **Gradient avatars**: Colors don't match web gradient classes
6. ❌ **Layout**: Generic cards instead of web's specific accordion

---

## 3. BILLING PAGE COMPARISON

### ✅ ACTUAL WEB FRONTEND (CORRECT)

**Location:** `frontend/app/(dashboard)/super-admin/billing/page.tsx`

**Structure:**
```
┌─ HEADER ────────────────────────────────────────────────┐
│ Super Admin · Billing                                   │
│ Billing & Revenue                                       │
│ GST-compliant billing & financial metrics               │
│                                                         │
│ Actions: [Refresh] [Export] [New invoice]              │
└─────────────────────────────────────────────────────────┘

┌─ KPI CARDS ─────────────────────────────────────────────┐
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐       │
│ │Current  │ │ GST     │ │ Outst.  │ │ Active  │       │
│ │MRR      │ │ Collect.│ │ Amount  │ │ Plans   │       │
│ │[Spark]  │ │[Spark]  │ │[Spark]  │ │[Spark]  │       │
│ │ ₹5.89L  │ │ ₹1.06L  │ │ ₹89K    │ │   48    │       │
│ │ +8.3%   │ │ 18% GST │ │ 4 overdx│ │ +12%    │       │
│ └─────────┘ └─────────┘ └─────────┘ └─────────┘       │
└─────────────────────────────────────────────────────────┘

┌─ INVOICES TABLE ────────────────────────────────────────┐
│ INV-2026-0045 | Delhi Public School | ₹9,999 | 📄     │
│ Due: 15 Aug 2026 | ● Paid                              │
│ ─────────────────────────────────────────────────────── │
│ INV-2026-0044 | Ryan International | ₹7,500 | 📄      │
│ Due: 10 Aug 2026 | ● Pending                           │
└─────────────────────────────────────────────────────────┘

┌─ SUBSCRIPTION PLANS ────────────────────────────────────┐
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │
│ │ Premium     │ │ Standard    │ │ Basic       │       │
│ │ ₹9,999/mo   │ │ ₹7,500/mo   │ │ ₹4,999/mo   │       │
│ │ 24 schools  │ │ 12 schools  │ │ 8 schools   │       │
│ │ ₹2.40L MRR  │ │ ₹90K MRR    │ │ ₹40K MRR    │       │
│ └─────────────┘ └─────────────┘ └─────────────┘       │
└─────────────────────────────────────────────────────────┘
```

**Key Visual Elements:**
- **Status chips**: Paid (green dot + emerald text), Pending (amber), Overdue (red)
- **Plan cards**: Rounded, border, with popular badge for featured plan
- **Sparklines**: 68x22px in KPI cards
- **Tax logic pills**: Purple/default backgrounds with mono font
- **INR formatting**: Indian Lakh/Crore abbreviations (₹5.89L, not $5.89K)

### ❌ CURRENT FLUTTER (WRONG)

**File:** `lib/features/school_tenancy/presentation/pages/billing_tab.dart`

**Problems:**
1. ❌ **KPI cards**: Implemented but layout doesn't match web structure
2. ❌ **Invoices**: List structure doesn't match web table layout
3. ❌ **Plans**: Grid doesn't match web card structure
4. ❌ **Typography**: Doesn't use serif font for large numbers
5. ❌ **Colors**: Status colors don't exactly match web theme

---

## 4. AUDIT PAGE COMPARISON

### ✅ ACTUAL WEB FRONTEND (CORRECT)

**Location:** `frontend/app/(dashboard)/super-admin/audit/page.tsx`

**Structure:**
```
┌─ HEADER ────────────────────────────────────────────────┐
│ Super Admin · Audit                                     │
│ Audit Log                                               │
│ Immutable record of all platform-level actions         │
│                                                         │
│ Actions: [Demo data badge] [Refresh] [Export CSV]      │
└─────────────────────────────────────────────────────────┘

┌─ KPI ROW ───────────────────────────────────────────────┐
│ ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌──────┐ │
│ │Total Events│ │Critical/Err│ │Unique Actor│ │Last  │ │
│ │    1,247   │ │     12     │ │     8      │ │24h   │ │
│ │in loaded..│ │failed act..│ │distinct... │ │ 156  │ │
│ └────────────┘ └────────────┘ └────────────┘ └──────┘ │
└─────────────────────────────────────────────────────────┘

┌─ FILTERS ───────────────────────────────────────────────┐
│ Search: [____________________________]                  │
│ Action: [All actions ▼] Severity: [All ▼]              │
│                                                         │
│ Quick filters: [All] [Info] [Warning] [Error]          │
└─────────────────────────────────────────────────────────┘

┌─ EVENTS TABLE ──────────────────────────────────────────┐
│ 4m  ⚪ [school.provision] ● Info                       │
│     Provisioned Delhi Public School (schema: dps_noi...)│
│     superadmin@eskoolia.com · 103.27.8.14              │
│ ─────────────────────────────────────────────────────── │
│ 18m ⚠️ [auth.impersonate] ⚠ Warning                    │
│     Super admin impersonated school admin at Ryan...   │
│     admin@ryan.edu · 49.207.193.22                     │
└─────────────────────────────────────────────────────────┘
```

**Key Visual Elements:**
- **Action badges**: Rounded pills with colored backgrounds (purple/red/amber/sky)
- **Severity chips**: Dots + labels (Info=blue, Warning=amber, Error=red)
- **KPI cards**: Icon + value + subtitle structure
- **Filter buttons**: Rounded, border, purple when active
- **Timestamps**: Relative time (4m, 18m, 2h, 3d)

### ❌ CURRENT FLUTTER (WRONG)

**File:** `lib/features/school_tenancy/presentation/pages/audit_tab.dart`

**Problems:**
1. ❌ **KPI cards**: Implemented but icons/layout don't match web
2. ❌ **Filters**: FilterChip doesn't match web button styling
3. ❌ **Event cards**: Layout doesn't match web table structure
4. ❌ **Action badges**: Colors don't exactly match web palette
5. ❌ **Typography**: Missing serif font usage

---

## 5. POLICIES PAGE COMPARISON

### ✅ ACTUAL WEB FRONTEND (CORRECT)

**Location:** `frontend/app/(dashboard)/super-admin/policies/page.tsx`

**Structure:**
```
┌─ HEADER ────────────────────────────────────────────────┐
│ Super Admin · Config                                    │
│ Policies & Settings                                     │
│ Platform-wide configuration and feature controls        │
│                                                         │
│ Actions: [Demo badge] [Refresh] [JSON] [YAML]          │
└─────────────────────────────────────────────────────────┘

┌─ CATEGORY TABS ─────────────────────────────────────────┐
│ [🛡️ Security] [💾 Data Isolation] [⚡ Billing] [⚙️ Sys]│
└─────────────────────────────────────────────────────────┘

┌─ POLICIES (Security selected) ──────────────────────────┐
│ ┌─────────────────────────────────────────────────────┐ │
│ │ password.min_length                    [locked] [10]│ │
│ │ Minimum password length for super-admin accounts    │ │
│ └─────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ session.timeout_minutes                         [30]│ │
│ │ Session timeout before re-authentication required  │ │
│ └─────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ mfa.required                                   [ON] │ │
│ │ Require MFA for super-admin accounts               │ │
│ └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘

┌─ SETTINGS SECTIONS ─────────────────────────────────────┐
│ ▼ SYSTEM                                                │
│   name: eSkoolia Platform                               │
│   version: 1.0.0                                        │
│   environment: production                               │
│ ─────────────────────────────────────────────────────── │
│ ▶ NOTIFICATION                                          │
│ ▶ INTEGRATIONS                                          │
└─────────────────────────────────────────────────────────┘
```

**Key Visual Elements:**
- **Category tabs**: Icon + label, colored backgrounds per category
- **Policy rows**: Rounded borders, purple tint when modified (unsaved badge)
- **Toggle switches**: Purple when on, with sliding circle
- **Number inputs**: 80px width, right-aligned, mono font
- **Lock badge**: Gray rounded pill for non-overridable policies
- **Unsaved badge**: Purple pill showing "unsaved" for dirty fields

### ❌ CURRENT FLUTTER (WRONG)

**File:** `lib/features/school_tenancy/presentation/pages/policies_tab.dart`

**Problems:**
1. ❌ **Category cards**: Implemented but doesn't match web tab structure
2. ❌ **Policy sections**: Layout doesn't match web grouped structure
3. ❌ **Toggle switches**: Flutter Switch widget doesn't match web custom toggle
4. ❌ **Number inputs**: TextEdit styling doesn't match web
5. ❌ **Badges**: Missing "locked" and "unsaved" state indicators
6. ❌ **Settings sections**: Missing collapsible settings sections

---

## ROOT CAUSE ANALYSIS

### Why the Flutter UI is Wrong:

1. **❌ Source of truth misidentification**: 
   - Developer used ASSUMPTIONS instead of ACTUAL web code
   - Created a "generic dashboard" instead of converting the web UI

2. **❌ Missing web-specific elements**:
   - Sparklines (118x32px polyline SVG charts)
   - Instrument Serif font for large numbers
   - Exact color palette from web CSS variables
   - Specific spacing and rounded corner values
   - Web's card shadow and border patterns

3. **❌ Layout structure mismatch**:
   - Flutter uses generic Column/Row grids
   - Web has specific section dividers and grouping
   - Web has more sophisticated responsive breakpoints

4. **❌ Typography mismatch**:
   - Web: 50px serif numbers, 10.5px uppercase labels, -1.5px letter spacing
   - Flutter: Generic text sizes without exact matching

5. **❌ Component structure mismatch**:
   - Web uses sophisticated accordion with numbered badges
   - Web has specific KPI card structure (sparkline + value + trend + footnote)
   - Web has filter pills with mono font count badges

---

## REQUIRED ACTIONS

### 1. DASHBOARD PAGE (dashboard_tab.dart)

**MUST IMPLEMENT:**
- [ ] Exact page header with "Super Admin" + italic serif "Dashboard"
- [ ] Full description paragraph with school/student counts
- [ ] Export and Add school action buttons
- [ ] 4 KPI cards with:
  - [ ] 118x32px sparkline SVGs (CustomPaint)
  - [ ] 50px serif font numbers (-1.5px letter spacing)
  - [ ] 10.5px uppercase labels (0.1em tracking)
  - [ ] Trend indicators and footnotes
- [ ] Schools by board section:
  - [ ] 8px colored dots before board names
  - [ ] 7px progress bars with exact board colors
  - [ ] Pills row at bottom
- [ ] Geographic distribution:
  - [ ] State names + bars + counts
  - [ ] GST state codes at bottom
- [ ] Plan revenue (MRR):
  - [ ] MoM badge (green background)
  - [ ] Progress bars for plans
- [ ] Recent activity:
  - [ ] Timeline layout with icons
  - [ ] Relative timestamps (4m, 18m, 2h)
  - [ ] "View all →" link

### 2. SCHOOLS PAGE (schools_tab.dart)

**MUST IMPLEMENT:**
- [ ] "School" + italic serif "Management" title
- [ ] Description + Export/Add school buttons
- [ ] 4 KPI cards with sparklines
- [ ] Filter pills with count badges (mono font)
- [ ] Accordion list with:
  - [ ] Numbered badges [01], [02], [03]...
  - [ ] Gradient avatar circles (8 gradients)
  - [ ] School name + tenant ID
  - [ ] Status dot (green/yellow/red)
  - [ ] Board and plan chips
  - [ ] Expand/collapse animation
  - [ ] Featured purple border for active

### 3. BILLING PAGE (billing_tab.dart)

**MUST IMPLEMENT:**
- [ ] Header with Refresh/Export/New invoice buttons
- [ ] 4 MRR KPI cards with sparklines
- [ ] Invoices table:
  - [ ] Invoice number + school + amount + due date
  - [ ] Status chips (Paid/Pending/Overdue)
  - [ ] GST breakdown
- [ ] Plans grid:
  - [ ] Plan cards with popular badge
  - [ ] Price + MRR + school count
  - [ ] Edit/Delete hover actions

### 4. AUDIT PAGE (audit_tab.dart)

**MUST IMPLEMENT:**
- [ ] Header with Refresh/Export CSV buttons
- [ ] 4 KPI cards (Total Events, Critical, Actors, Last 24h)
- [ ] Search bar + action/severity dropdowns
- [ ] Quick filter buttons (All/Info/Warning/Error)
- [ ] Events table:
  - [ ] Relative timestamp
  - [ ] Action badge (colored)
  - [ ] Severity chip
  - [ ] Event detail
  - [ ] Actor + IP

### 5. POLICIES PAGE (policies_tab.dart)

**MUST IMPLEMENT:**
- [ ] Header with Refresh/JSON/YAML buttons
- [ ] Category tabs (4 tabs with icons)
- [ ] Policy rows per category:
  - [ ] Policy key (mono font)
  - [ ] Locked badge for non-overridable
  - [ ] Unsaved badge when modified
  - [ ] Toggle switch OR number input
  - [ ] Description text
- [ ] Settings sections (collapsible)
- [ ] Save button (disabled when no changes)

---

## MOBILE CONVERSION RULES

### ✅ ALLOWED:
- Stack horizontal sections vertically
- Make cards responsive (100% width on mobile)
- Reduce column count (4-col → 2-col → 1-col)
- Make wide tables scrollable

### ❌ NOT ALLOWED:
- Redesign the page structure
- Invent new cards or components
- Change visual hierarchy
- Remove sections
- Simplify into generic dashboard
- Change color scheme
- Remove sparklines or visual indicators

---

## TYPOGRAPHY SPECIFICATION

From web CSS:

```css
--font-instrument-serif: 'Instrument Serif', Georgia, serif;

/* Large numbers in KPI cards */
font-family: var(--font-instrument-serif);
font-size: 50px;
font-weight: 400;
line-height: 0.95;
letter-spacing: -1.5px;

/* Page titles */
font-size: 34px;
font-weight: 600;
letter-spacing: -1px;

/* Italic accent (Dashboard, Management) */
font-family: var(--font-instrument-serif);
font-size: 38px;
font-weight: 400;
font-style: italic;
letter-spacing: -0.5px;
color: #6D4AFF;

/* Section titles */
font-size: 15px;
font-weight: 600;
letter-spacing: -0.1px;

/* KPI labels */
font-size: 10.5px;
font-weight: 600;
letter-spacing: 0.1em;
text-transform: uppercase;
```

---

## COLOR PALETTE

From web CSS variables:

```css
--pu: #6D28D9;           /* Primary purple */
--pu-deep: #5B21B6;       /* Deep purple */
--pu-soft: #EDE9FE;       /* Soft purple */
--pu-tint: #F6F3FF;       /* Tint purple */

--ok: #059669;            /* Success green */
--ok-soft: #D1FAE5;       /* Soft green */

--warn: #D97706;          /* Warning amber */
--warn-soft: #FEF3C7;     /* Soft amber */

--danger: #DC2626;        /* Danger red */
--danger-soft: #FEE2E2;   /* Soft red */

--info: #0369A1;          /* Info blue */
--info-soft: #DCEFFE;     /* Soft blue */

--ink-1: #111827;         /* Primary text */
--ink-2: #6B7280;         /* Secondary text */
--ink-3: #9CA3AF;         /* Tertiary text */

--bg-1: #FFFFFF;          /* Primary background */
--bg-2: #F9FAFB;          /* Secondary background */
--bg-3: #F3F4F6;          /* Tertiary background */

--bd: #E5E7EB;            /* Primary border */
--bd-2: #D1D5DB;          /* Secondary border */
```

Board-specific colors:
```css
CBSE: #5836E0
ICSE: #0369A1
SSC_AP: #A65D08
SSC_TG: #B42318
```

---

## IMPLEMENTATION CHECKLIST

### Phase 1: Infrastructure
- [ ] Add Instrument Serif font to Flutter (Google Fonts)
- [ ] Create color constants matching web CSS variables
- [ ] Create SparklinePainter CustomPainter class
- [ ] Create reusable KPI card widget
- [ ] Create reusable progress bar widget
- [ ] Create reusable status chip widget

### Phase 2: Dashboard
- [ ] Rebuild page header
- [ ] Rebuild 4 KPI cards
- [ ] Rebuild Schools by board section
- [ ] Rebuild Geographic distribution section
- [ ] Rebuild Plan revenue section
- [ ] Rebuild Recent activity section

### Phase 3: Schools
- [ ] Rebuild title row
- [ ] Rebuild 4 KPI cards
- [ ] Rebuild filter pills
- [ ] Rebuild accordion list

### Phase 4: Billing
- [ ] Rebuild header
- [ ] Rebuild 4 MRR KPI cards
- [ ] Rebuild invoices table
- [ ] Rebuild plans grid

### Phase 5: Audit
- [ ] Rebuild header
- [ ] Rebuild 4 KPI cards
- [ ] Rebuild filters
- [ ] Rebuild events table

### Phase 6: Policies
- [ ] Rebuild header
- [ ] Rebuild category tabs
- [ ] Rebuild policy rows
- [ ] Rebuild settings sections

### Phase 7: Verification
- [ ] Side-by-side comparison with web frontend
- [ ] Typography audit (fonts, sizes, spacing)
- [ ] Color audit (exact hex matching)
- [ ] Layout audit (spacing, alignment, borders)
- [ ] Animation audit (transitions, hover states)

---

## FINAL ACCEPTANCE CRITERIA

The Flutter implementation will be considered **COMPLETE** only when:

1. ✅ **Visual comparison**: Flutter UI looks like the web UI when viewed side-by-side
2. ✅ **Typography match**: Fonts, sizes, weights, letter-spacing all match web
3. ✅ **Color match**: All colors exactly match web CSS variables
4. ✅ **Layout match**: Sections, spacing, borders, shadows all match web
5. ✅ **Component match**: All web components converted to Flutter equivalents
6. ✅ **No invention**: Zero new UI elements not present in web
7. ✅ **No simplification**: No "simplified" or "generic" versions of web components

---

**Status:** ⚠️ **READY FOR REBUILD**

**Next Action:** Begin Phase 1 implementation with proper web frontend inspection and exact conversion.
