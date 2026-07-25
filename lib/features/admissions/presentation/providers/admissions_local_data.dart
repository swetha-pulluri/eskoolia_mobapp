import '../../domain/entities/campaign_entity.dart';
import '../../domain/entities/message_template_entity.dart';
import '../../domain/entities/marketing_event_entity.dart';

/// ========================================================================
/// MARKETING STATIC CONTENT
/// ========================================================================
/// Command Center and Analytics are now backend-integrated (see
/// `admissions_repository_impl.dart`) — this file now holds only
/// Marketing's content, and deliberately so: the real web
/// `AdmissionsMarketing.tsx` makes ZERO API calls anywhere in the file
/// (confirmed directly against source) — its two demo campaigns, all 15
/// message templates, and its two demo events are hardcoded literal
/// constants in the web source itself (`DEMO_CAMPAIGNS`, `TEMPLATES`, and
/// the inline events array), and saving a new campaign there only ever
/// mutates in-memory React state (lost on refresh) since there is no
/// backing store to persist to. Reproducing those exact values here is
/// not inventing data — it's copying the web's own real constants
/// verbatim, and mirroring its own local-state-only "persistence".
/// ========================================================================
class AdmissionsLocalData {
  AdmissionsLocalData._();

  // ─── Marketing: Campaigns ───────────────────────────────────────────────
  // Verbatim from web's `DEMO_CAMPAIGNS` in AdmissionsMarketing.tsx.
  static final List<CampaignEntity> campaigns = [
    const CampaignEntity(
      id: 'c1',
      name: 'Grade 5 Seat Alert',
      status: 'sent',
      channel: 'WhatsApp',
      audience: 'All Grade 5 inquiries',
      sentCount: 89,
      deliveredPct: 94,
      replies: 12,
      sentAt: '3 May 2026',
    ),
    const CampaignEntity(
      id: 'c2',
      name: 'Open House — 15 May',
      status: 'scheduled',
      channel: 'WhatsApp + Email',
      audience: 'All active inquiries (Grade 1–5)',
      sentCount: 487,
      scheduledFor: '12 May 2026, 9:00 AM',
    ),
  ];

  // ─── Marketing: Message Templates ──────────────────────────────────────
  // Verbatim from web's `TEMPLATES` in AdmissionsMarketing.tsx (15 items).
  static final List<MessageTemplateEntity> templates = [
    const MessageTemplateEntity(
      id: 't1',
      name: 'Thank You for Inquiry',
      category: 'Welcome',
      channel: 'whatsapp',
      useCase: 'Auto-sent on form creation',
      variables: ['{parent_name}', '{school_name}', '{child_name}', '{grade}', '{portal_link}', '{counsellor_name}'],
      body: 'Hi {parent_name} 👋 Thank you for your interest in {school_name}!\n\n'
          "We've received your inquiry for {child_name}'s admission to {grade}. Our team will reach out within 24 hours.\n\n"
          'Track your inquiry status here: {portal_link}\n\n'
          '— {counsellor_name}, {school_name} Admissions',
    ),
    const MessageTemplateEntity(
      id: 't2',
      name: 'First Follow-up Call Confirmation',
      category: 'Follow-up',
      channel: 'whatsapp',
      useCase: 'When reaching out for first time',
      variables: ['{parent_name}', '{counsellor_name}', '{school_name}', '{child_name}', '{grade}'],
      body: 'Hi {parent_name}, this is {counsellor_name} from {school_name}.\n\n'
          "I'm reaching out regarding {child_name}'s admission inquiry for {grade}. Would you be available for a quick 5-minute call today?\n\n"
          'Please reply with a convenient time 🙏',
    ),
    const MessageTemplateEntity(
      id: 't3',
      name: 'Visit Invitation',
      category: 'Visit',
      channel: 'whatsapp',
      useCase: 'Invite parent for campus tour',
      variables: ['{parent_name}', '{school_name}', '{grade}', '{child_name}', '{preferred_visit_date}'],
      body: 'Hi {parent_name} 😊 We\'d love to show you {school_name}!\n\n'
          '{grade} has limited seats this year — a campus visit will help {child_name} see why families love us.\n\n'
          'Can you visit on {preferred_visit_date}? Reply YES to confirm ✅',
    ),
    const MessageTemplateEntity(
      id: 't4',
      name: 'Visit Reminder',
      category: 'Visit',
      channel: 'whatsapp',
      useCase: 'Auto-sent 24 hrs before visit',
      variables: ['{parent_name}', '{child_name}', '{school_name}', '{visit_date}', '{visit_time}'],
      body: "Hi {parent_name}, just a reminder — {child_name}'s school visit at {school_name} is tomorrow ({visit_date}) at {visit_time}.\n\n"
          'Please use the main entrance. Looking forward to meeting you! 🏫\n\n'
          '— {school_name} Team',
    ),
    const MessageTemplateEntity(
      id: 't5',
      name: 'Post-Visit Thank You',
      category: 'Post-Visit',
      channel: 'whatsapp',
      useCase: 'After campus visit',
      variables: ['{parent_name}', '{child_name}', '{school_name}', '{counsellor_phone}', '{portal_link}'],
      body: 'Hi {parent_name}, it was wonderful meeting you and {child_name} today! We hope you loved the campus.\n\n'
          "If you have any questions, I'm here to help: {counsellor_phone}\n\n"
          "To complete {child_name}'s enrollment: {portal_link} 🎒",
    ),
    const MessageTemplateEntity(
      id: 't6',
      name: 'Seat Filling Fast',
      category: 'Urgency',
      channel: 'whatsapp',
      useCase: 'When grade is 80%+ full',
      variables: ['{parent_name}', '{grade}', '{school_name}', '{seats_left}', '{child_name}', '{counsellor_name}'],
      body: 'Hi {parent_name}, a quick update — {grade} at {school_name} has only {seats_left} seats remaining for 2026-27.\n\n'
          "We'd hate for {child_name} to miss out! Should we reserve a spot? Reply YES and I'll guide you 🙏\n\n"
          '— {counsellor_name}',
    ),
    const MessageTemplateEntity(
      id: 't7',
      name: 'Re-engagement (Cold Lead)',
      category: 'Re-engagement',
      channel: 'whatsapp',
      useCase: 'Cold leads 10+ days old',
      variables: ['{parent_name}', '{child_name}', '{school_name}', '{portal_link}'],
      body: "Hi {parent_name} 👋 We noticed {child_name}'s admission inquiry is still open at {school_name}.\n\n"
          "We completely understand if you're still deciding — we're happy to answer any questions.\n\n"
          'Would a quick campus visit help? {portal_link}',
    ),
    const MessageTemplateEntity(
      id: 't8',
      name: 'Sibling Discount Offer',
      category: 'Offer',
      channel: 'whatsapp',
      useCase: 'Families with siblings enrolled',
      variables: ['{parent_name}', '{sibling_name}', '{school_name}', '{child_name}', '{sibling_discount}', '{grade}', '{offer_expiry}', '{school_phone}'],
      body: 'Hi {parent_name} 🎉 Since {sibling_name} is already part of the {school_name} family, {child_name} is eligible for our {sibling_discount}% sibling discount for {grade} admission.\n\n'
          'This offer is valid till {offer_expiry}. Shall we proceed?\n\n'
          'Call us: {school_phone}',
    ),
    const MessageTemplateEntity(
      id: 't9',
      name: 'Enrollment Confirmed',
      category: 'Enrollment',
      channel: 'whatsapp',
      useCase: 'On successful enrollment',
      variables: ['{parent_name}', '{child_name}', '{school_name}', '{grade}'],
      body: '🎊 Congratulations {parent_name}! {child_name} is officially enrolled at {school_name} for {grade}, Academic Year 2026-27.\n\n'
          'Welcome to our school family! Please visit the office to submit documents.\n\n'
          'See you soon! 📚',
    ),
    const MessageTemplateEntity(
      id: 't10',
      name: 'Open House Invite',
      category: 'Event',
      channel: 'whatsapp',
      useCase: 'Open house event promotion',
      variables: ['{parent_name}', '{school_name}', '{event_date}', '{event_time}', '{rsvp_link}', '{child_name}'],
      body: "Hi {parent_name} 🏫 You're invited to {school_name}'s Open House on {event_date} at {event_time}!\n\n"
          'Meet our teachers, tour the campus, and see why 95% of visiting families choose us.\n\n'
          'RSVP here: {rsvp_link} — Limited seats. Bring {child_name}! 🌟',
    ),
    const MessageTemplateEntity(
      id: 't11',
      name: 'Inquiry Acknowledgment',
      category: 'Welcome',
      channel: 'email',
      useCase: 'Detailed acknowledgment on inquiry creation',
      subject: 'Your admission inquiry for {child_name} — {school_name}',
      variables: ['{parent_name}', '{child_name}', '{grade}', '{counsellor_name}', '{portal_link}', '{school_phone}', '{school_name}'],
      body: 'Dear {parent_name},\n\n'
          "Thank you for your interest in {school_name}! We've received your admission inquiry for {child_name} applying to {grade} for the 2026-27 academic year.\n\n"
          "Here's what happens next:\n"
          '1. Our counsellor {counsellor_name} will call you within 24 hours\n'
          "2. We'll invite you for a campus visit — the best way to experience our school\n"
          "3. We'll guide you through the enrollment process step by step\n\n"
          'Track your inquiry status anytime: {portal_link}\n\n'
          'Any questions? Reply to this email or call {school_phone}.\n\n'
          'Warm regards,\n{counsellor_name}\n{school_name} Admissions Team',
    ),
    const MessageTemplateEntity(
      id: 't12',
      name: 'Visit Booking Confirmation',
      category: 'Visit',
      channel: 'email',
      useCase: 'Confirm campus visit details',
      subject: 'Your campus visit is confirmed — {school_name}',
      variables: ['{parent_name}', '{child_name}', '{visit_date}', '{visit_time}', '{school_address}', '{counsellor_name}', '{counsellor_phone}', '{school_name}'],
      body: 'Dear {parent_name},\n\n'
          'Great news! Your campus visit for {child_name} has been confirmed:\n'
          '📅 Date: {visit_date}\n'
          '⏰ Time: {visit_time}\n'
          '📍 Venue: {school_address}\n'
          '👤 Your counsellor: {counsellor_name} ({counsellor_phone})\n\n'
          'Please arrive 5 minutes early. Parking is available at the main gate.\n\n'
          'What to bring: Any school records or transfer certificate (optional)\n\n'
          'Looking forward to meeting you!\n\n'
          'Warm regards,\n{school_name} Admissions Team',
    ),
    const MessageTemplateEntity(
      id: 't13',
      name: 'Monthly Newsletter',
      category: 'Nurture',
      channel: 'email',
      useCase: 'Monthly update to all active inquiries',
      subject: 'Updates from {school_name} — {month_year}',
      variables: ['{parent_name}', '{school_name}', '{month_year}', '{event_date}', '{grade}', '{deadline_date}', '{seats_left}', '{school_phone}', '{school_website}'],
      body: 'Dear {parent_name},\n\n'
          "Here's a quick update for families considering {school_name}:\n\n"
          "🏆 This month's highlights:\n"
          '• [Achievement 1]\n'
          '• [Achievement 2]\n'
          '• [Achievement 3]\n\n'
          '📅 Upcoming:\n'
          '• Open House: {event_date}\n'
          '• Admission deadline for {grade}: {deadline_date}\n\n'
          '💺 Seats remaining in {grade}: {seats_left}\n\n'
          'Questions? Reply to this email or call {school_phone}.\n\n'
          '{school_name} Admissions Team | {school_website}',
    ),
    const MessageTemplateEntity(
      id: 't14',
      name: 'Post-Decline Save Attempt',
      category: 'Save',
      channel: 'email',
      useCase: 'After a lead is marked declined',
      subject: "We understand — and we're here if you change your mind",
      variables: ['{parent_name}', '{school_name}', '{child_name}'],
      body: 'Dear {parent_name},\n\n'
          'Thank you for considering {school_name} for {child_name}.\n\n'
          "We understand you've chosen a different path for now, and we completely respect your decision.\n\n"
          "If circumstances change or you'd like to reconsider, we'd be honoured to welcome {child_name} to our school family. Our doors are always open.\n\n"
          'Wishing {child_name} all the very best 🌟\n\n'
          'Warm regards,\n{school_name} Admissions Team',
    ),
    const MessageTemplateEntity(
      id: 't15',
      name: 'Referral Ask',
      category: 'Referral',
      channel: 'email',
      useCase: 'After enrollment — ask for referrals',
      subject: 'Could you help another family find the right school?',
      variables: ['{parent_name}', '{child_name}', '{school_name}', '{referral_benefit}'],
      body: 'Dear {parent_name},\n\n'
          "It's been wonderful having {child_name} at {school_name}!\n\n"
          "We'd love to welcome more great families like yours. If you know of any families looking for a school, please share our details — we offer a referral benefit for you: {referral_benefit}.\n\n"
          'Simply ask them to mention your name when they enquire!\n\n'
          'With gratitude,\n{school_name} Team',
    ),
  ];

  // ─── Marketing: Events ──────────────────────────────────────────────────
  // Verbatim from web's inline demo events array in AdmissionsMarketing.tsx
  // (mutable list, not const, so New Event / Manage RSVPs can add to and
  // update it in place — same local-only-mock pattern as `campaigns` above).
  static final List<MarketingEventEntity> events = [
    const MarketingEventEntity(id: 'e1', name: 'Open House', date: '15 May 2026', time: '10:00 AM', rsvp: 14, capacity: 40),
    const MarketingEventEntity(id: 'e2', name: 'Campus Tour', date: '22 May 2026', time: '11:00 AM', rsvp: 6, capacity: 20),
  ];
}
