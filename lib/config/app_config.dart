/// Business rules that are the same everywhere in the app.
///
/// Rates and fees stay in the database (never hard-coded, per the brief); this
/// class only holds the labels and review windows the UI must state.
class AppConfig {
  const AppConfig._();

  static const String appName = 'Supreme Mall';

  /// Stated on the business application result screen. The admin dashboard
  /// (Milestone 6) is what actually moves the status.
  static const String businessReviewWindow = '1–2 business days';

  /// Currency formatting is shared through `utils/money.dart`.
  static const String supportEmail = 'support@suprememall.co.ke';
}
