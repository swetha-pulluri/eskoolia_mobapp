/// Mirrors the real web's `STEP_GROUPS` constant exactly
/// (`hr/onboard/page.tsx` on `demo`/`BugFix`, lines 43-73).
class OnboardStepInfo {
  final int num;
  final String label;
  final String sub;
  const OnboardStepInfo(this.num, this.label, this.sub);
}

class OnboardStepGroup {
  final String group;
  final List<OnboardStepInfo> steps;
  const OnboardStepGroup(this.group, this.steps);
}

const onboardStepGroups = <OnboardStepGroup>[
  OnboardStepGroup('Personal', [
    OnboardStepInfo(1, 'Staff identity', 'Basic profile, DOB, photo'),
    OnboardStepInfo(2, 'Role & placement', 'Department, role, joining'),
    OnboardStepInfo(3, 'Contact & address', 'Phone, email, location'),
    OnboardStepInfo(4, 'Family & emergency', 'Nominees and contacts'),
  ]),
  OnboardStepGroup('Compliance', [
    OnboardStepInfo(5, 'Government identity', 'Aadhaar, PAN, etc.'),
    OnboardStepInfo(6, 'Qualifications', 'Education and experience'),
    OnboardStepInfo(7, 'Medical & fitness', 'Health, transport, fitness'),
  ]),
  OnboardStepGroup('Payroll & Files', [
    OnboardStepInfo(8, 'Payroll setup', 'CTC and deductions'),
    OnboardStepInfo(9, 'Documents', 'Tally-based checklist'),
    OnboardStepInfo(10, 'Review & onboard', 'Confirm and create'),
  ]),
];

const onboardTotalSteps = 10;

OnboardStepInfo onboardStepByNum(int num) {
  for (final g in onboardStepGroups) {
    for (final s in g.steps) {
      if (s.num == num) return s;
    }
  }
  return const OnboardStepInfo(1, 'Staff identity', 'Basic profile, DOB, photo');
}
