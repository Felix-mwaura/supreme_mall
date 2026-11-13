import 'package:flutter/foundation.dart';

/// Request payloads + a single seam for account creation.
///
/// Everything currently resolves locally after a short delay so the screens can
/// be reviewed without a backend. The two methods below are the only places
/// that need to change when Supabase auth is wired in (planned tables:
/// `profiles` for customers and `businesses` for merchant applications).
class CustomerSignupRequest {
  const CustomerSignupRequest({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.password,
  });

  final String fullName;
  final String phone;
  final String email;
  final String password;

  String get firstName => fullName.trim().split(' ').first;
}

class BusinessSignupRequest {
  const BusinessSignupRequest({
    required this.businessName,
    required this.contactName,
    required this.departmentId,
    required this.phone,
    required this.email,
    required this.area,
    required this.password,
  });

  final String businessName;
  final String contactName;
  /// One of the ids in `supremeDepartments`.
  final String departmentId;
  final String phone;
  final String email;
  final String area;
  final String password;
}

class AccountResult {
  const AccountResult({required this.referenceId, required this.status});

  final String referenceId;

  /// `active` for customers, `pending_verification` for businesses.
  final String status;
}

abstract class AccountService {
  static final AccountService instance = _LocalAccountService();

  Future<AccountResult> createCustomerAccount(CustomerSignupRequest request);

  Future<AccountResult> submitBusinessApplication(BusinessSignupRequest request);

  /// Businesses must wait for document checks before they can accept paid
  /// orders (brief, section 5), so this is stated on the UI as 1–2 days.
  static const String businessReviewWindow = '1–2 business days';
}

class _LocalAccountService implements AccountService {
  const _LocalAccountService();

  static int _sequence = 1000;

  String _nextReference(String prefix) {
    _sequence += 1;
    return 'SM-$prefix-${_sequence.toString().padLeft(4, '0')}';
  }

  @override
  Future<AccountResult> createCustomerAccount(CustomerSignupRequest request) async {
    debugPrint('[AccountService] customer sign-up (local preview): ${request.firstName}');
    await Future<void>.delayed(const Duration(milliseconds: 900));
    // TODO(supabase): create the auth user, then insert into `profiles`
    // (full_name, phone, role: 'customer') and send the SMS OTP.
    return AccountResult(referenceId: _nextReference('CUS'), status: 'active');
  }

  @override
  Future<AccountResult> submitBusinessApplication(BusinessSignupRequest request) async {
    debugPrint('[AccountService] business application (local preview): ${request.businessName}');
    await Future<void>.delayed(const Duration(milliseconds: 900));
    // TODO(supabase): insert into `businesses` with status 'pending' plus the
    // department id, then notify the admin dashboard for document review.
    return AccountResult(referenceId: _nextReference('BIZ'), status: 'pending_verification');
  }
}
