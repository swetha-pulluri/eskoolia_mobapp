# eSkoolia Flutter Mobile Conversion - Project Context

## PROJECT OBJECTIVE

Convert the existing eSkoolia web application into a Flutter mobile application.

The existing web frontend and backend are already implemented.

The web frontend and backend are the SOURCE OF TRUTH and must be used as REFERENCE ONLY.

This is a WEB TO FLUTTER MOBILE CONVERSION.

Do not create a new product.
Do not redesign the business application.
Do not invent new features.

---

## ABSOLUTE FOLDER RULE

ONLY modify files inside:

eskoolia-mobapp

NEVER modify, create, delete, rename, or touch files outside eskoolia-mobapp.

The web frontend and backend must NEVER be modified.

All Flutter implementation must be done inside eskoolia-mobapp.

---

## TECHNOLOGY AND ARCHITECTURE

Flutter and Dart are used for the mobile application.

Use Riverpod for state management.

Follow clean, scalable Flutter architecture.

Maintain a clear separation between:

- presentation
- providers/state
- domain/models
- data/repositories/services

Reuse the existing Flutter architecture whenever it already exists.

Do not create duplicate or parallel architecture unnecessarily.

Do not introduce Provider unless an existing implementation requires it for a strong technical reason.

---

## WEB AND BACKEND REFERENCE RULE

Before implementing any screen or feature:

1. Inspect the relevant web frontend.
2. Inspect the relevant backend/API implementation.
3. Inspect the current Flutter implementation.
4. Understand the existing API contract and business flow.

Use the web application as the source of truth for:

- screen structure
- module names
- labels
- UI behavior
- navigation
- colors
- spacing
- typography hierarchy
- icons
- business logic

Use the backend as reference for existing API behavior.

Do not modify the backend.

---

## UI RULES

The Flutter mobile UI must match the existing eSkoolia web application as closely as possible.

Do not create a generic Flutter design.

Do not randomly change colors, labels, icons, or module names.

Do not invent or rename modules.

Do not shorten existing module names.

The mobile design must be:

- mobile-first
- responsive
- scrollable where required
- free from overflow errors
- suitable for different mobile screen sizes

Use reusable widgets wherever appropriate.

---

## FUNCTIONALITY RULES

Only convert existing eSkoolia web functionality to Flutter mobile.

Do not add features that do not exist in the web application.

Do not hardcode data when existing API/backend data is available.

If an API already exists, use the existing API contract.

Do not change backend logic to make Flutter work.

---

## GIT RULES

NEVER run git push.

NEVER automatically commit code.

Do not push or commit unless Archana explicitly asks.

---

## IMPLEMENTATION WORKFLOW

For every new screen or feature:

1. Inspect the relevant web frontend.
2. Inspect the relevant backend/API.
3. Inspect eskoolia-mobapp.
4. Understand the existing Flutter architecture.
5. Identify reusable code.
6. Plan the minimum required changes.
7. Modify only necessary files inside eskoolia-mobapp.

Do not rewrite unrelated files.

Do not refactor the entire project unnecessarily.

Do not make unrelated changes.

---

## CLAUDE WORKING STYLE

Before implementing a new screen, briefly state:

- what existing web screen/API was inspected
- what Flutter files are relevant
- what files will be modified

Then implement ONLY the requested task.

If a requirement is unclear, inspect the web implementation first instead of guessing.

Never invent missing product behavior without checking the existing web application.

---

## TEAM CONTEXT FILE

Maintain:

teamcontextfile.md

inside eskoolia-mobapp.

This file must preserve important project context, architecture decisions, completed work, current work, and next steps.

At the end of each working day, add a DAILY UPDATE.

Each daily update must contain:

Name: Archana
Date: [actual date]
Git Branch: [actual branch]
Work Done Today: [actual work completed today]

Do not create fake work updates.

---

## FINAL RULE

Always remember:

ONLY eskoolia-mobapp can be modified.

The task is ONLY to convert eSkoolia web to Flutter mobile.

Do not touch anything else.