/// Notification service — morning/evening trip reminders,
/// low fuel alerts, and service due notifications.
///
/// Schedule from the plan:
///   Morning: 7:30 AM weekdays (skip if trip already logged)
///   Evening: 6:00 PM (if Going logged but Return not)
///   Evening escalation: every 10 min until 10 PM
///   Low fuel: when estimated range < 40 km
///   Service: per type when km threshold approached
class NotificationService {
  // TODO: Implement in Phase 4 using flutter_local_notifications
  //
  // - Morning trip reminder
  // - Evening return reminder
  // - Evening escalation
  // - Low fuel alert
  // - Service due alerts (all 5 types)
  // - Boot receiver rescheduling
}
