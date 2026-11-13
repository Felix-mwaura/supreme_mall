/// The two account types a visitor can create from the Supreme Mall home
/// screen. Business accounts cover merchants, restaurants, produce vendors and
/// (in later phases) service providers — all of which follow the same
/// approval-before-going-live rule described in the brief, section 5.
enum AccountRole {
  customer,
  business;

  String get label => this == AccountRole.customer ? 'Customer' : 'Business';

  /// Where the account lands after successful sign-up / approval.
  String get destination => this == AccountRole.customer ? 'Home screen' : 'Merchant dashboard';
}
