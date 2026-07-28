import 'package:flutter/material.dart';

/// Exact hex values of the design tokens AIBot.tsx references via CSS
/// variables (`var(--pu)`, `var(--ink-1)`, etc.) — copied verbatim from
/// frontend/styles/tokens.css's light-mode (`:root`) block, since that's
/// the theme this app always runs in (`main.dart`'s `themeMode:
/// ThemeMode.light`).
const aiPurple = Color(0xFF6D4AFF);
const aiPurpleSoft = Color(0xFFEEEAFF);
const aiInk1 = Color(0xFF0F1222);
const aiInk2 = Color(0xFF5A607A);
const aiInk3 = Color(0xFF9197AE);
const aiBg0 = Color(0xFFFAFAFC);
const aiBg1 = Color(0xFFFFFFFF);
const aiBg2 = Color(0xFFF4F4F8);
const aiBorder = Color(0xFFECECF2);
