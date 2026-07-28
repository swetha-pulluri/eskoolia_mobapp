/// Mirrors frontend components/AIBot.tsx's `PARENT_FAQ` dict and
/// `findFAQAnswer` helper verbatim.
const Map<String, String> parentFaq = {
  'fees due':
      'You can check outstanding fees by going to **Fees → Fees Due**. You can also generate a statement from the Fees Collection page. For urgent queries, please contact the accounts office.',
  'fee':
      'Fees can be paid online or at the school office. Visit **Fees → Fees Collection** to check payment status. For fee structure details, see **Fees → Fees Master**.',
  'attendance':
      "Your child's attendance can be viewed under **Reports → Student Attendance**. For today's attendance, check with the class teacher or visit the attendance section.",
  'exam':
      'Upcoming exam schedules are listed under **Examination → Exam Schedule**. Results are published under **Examination → Result Publish** once available.',
  'result':
      'Exam results are published under **Examination → Result Publish**. You can also view historical results in **Reports → Exam Result**.',
  'homework':
      'Assigned homework is listed under **Academics → Homework List**. Completed homework evaluations are in **Academics → Homework Evaluation**.',
  'school timing':
      'Please visit **Settings → General Settings** for official school timings. You can also contact the school office for the latest schedule.',
  'holiday':
      'Holiday lists are published under **Academics → Class Routine**. Please check the school notice board or contact administration for updates.',
  'transport':
      'Bus routes and vehicle assignments are in **Transport → Routes** and **Transport → Assign Vehicles**. For live bus tracking, visit **Transport → Live Tracking**.',
  'library':
      'Library books and issue status can be checked under **Library → Book Issues**. Contact the librarian for book reservations.',
  'certificate':
      'Certificates (bonafide, character, etc.) can be generated from **Administration → Generate Certificate**. Submit a request to the school office.',
  'id card':
      'Student ID cards can be generated from **Administration → Generate ID Card**. Contact administration if your child has lost their ID card.',
  'complaint':
      'Complaints can be registered at **Administration → Complaint**. You can also contact the school principal directly.',
  'admission':
      'Admission queries can be submitted at **Admissions → Admission Query**. Our team typically responds within 2 business days.',
};

String? findFaqAnswer(String q) {
  final lower = q.toLowerCase();
  for (final entry in parentFaq.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return null;
}
