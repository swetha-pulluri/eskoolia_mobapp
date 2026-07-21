# Eskoolia Mobile Project Instructions

## Project Goal

Convert the existing React/Next.js frontend into a Flutter mobile application.

The React frontend is the ONLY source of truth for UI and UX.

Do not redesign any screen.

The Flutter UI should match the frontend as closely as possible while being responsive for mobile devices.

---

## Project Structure

### READ ONLY

frontend/

backend/

Eskoolia-Mobile/

Never modify these folders.

They are reference projects only.

---

### WRITABLE

eskoolia_mobapp/

Only this project may be modified.

All Flutter code must be created here.

---

## Development Workflow

Step 1

Analyze the React frontend.

Step 2

Recreate the UI in Flutter.

Step 3

Ensure responsiveness.

Step 4

Fix all overflow issues.

Step 5

Only after UI is complete, connect the backend.

---

## UI Rules

Frontend is the source of truth.

Do not redesign.

Do not invent layouts.

Do not invent colors.

Do not invent typography.

Do not invent spacing.

Do not invent widgets.

If something exists in the frontend,
Flutter should contain it.

If it does not exist,
do not create it.

---

## Responsiveness

Support:

- Small Android phones
- Medium Android phones
- Large Android phones

There must be:

- No Bottom Overflow
- No RenderFlex overflow
- No clipped widgets
- No hidden text

Prefer:

- LayoutBuilder
- MediaQuery
- Expanded
- Flexible
- Wrap
- FractionallySizedBox

Do not use OverflowBox to hide problems.

---

## Backend

Do not connect backend APIs until instructed.

During UI implementation use mock data that matches the frontend.

---

## Architecture

Reuse existing widgets.

Avoid duplicate code.

Keep the existing project structure.

Do not move unrelated files.

---

## Before Finishing Any Task

- Run flutter analyze
- Fix all warnings
- Fix all errors
- Verify responsiveness
- Verify Flutter matches the frontend