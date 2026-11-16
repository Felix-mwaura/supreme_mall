import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_profile.dart';
import '../utils/auth_errors.dart';

/// Thrown for anything the UI must show as a friendly message.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// One place for every authentication call.
///
/// Rules enforced here:
/// - credentials never touch our own tables (`profiles` holds no password);
/// - the role is decided by sign-up metadata and validated by a database
///   trigger, never by client input at read time;
/// - business records are only created while a session exists, because the RLS
///   insert policy requires `owner_id = auth.uid()`.
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  Session? get session => _auth.currentSession;
  User? get user => _auth.currentUser;
  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  Future<AppProfile?> loadProfile() async {
    final User? current = _auth.currentUser;
    if (current == null) {
      return null;
    }
    try {
      final Map<String, dynamic>? row = await _client
          .from('profiles')
          .select('id, full_name, phone, role')
          .eq('id', current.id)
          .maybeSingle();
      if (row == null) {
        return null;
      }
      return AppProfile.fromMap(row);
    } on PostgrestException catch (error) {
      throw AuthFailure(AuthErrorMapper.describe(pgCode: error.code, message: error.message));
    } catch (error) {
      throw AuthFailure(AuthErrorMapper.describe(message: error.toString()));
    }
  }

  /// Creates a customer account. Returns true when a session is active (the
  /// project auto-confirms email); false when email confirmation is required.
  Future<bool> signUpCustomer({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: <String, dynamic>{
          'full_name': fullName.trim(),
          'phone': phone,
          'account_type': 'customer',
        },
      );
      return response.session != null;
    } on AuthException catch (error) {
      throw AuthFailure(AuthErrorMapper.describe(code: error.code, message: error.message));
    } catch (error) {
      throw AuthFailure(AuthErrorMapper.describe(message: error.toString()));
    }
  }

  /// Creates the auth user for a business and, when a session is available,
  /// inserts the business row plus its department. The row always starts as
  /// `pending` — approval is an administrator action (Milestone 6).
  Future<BusinessSignupOutcome> signUpBusiness({
    required String businessName,
    required String contactName,
    required String phone,
    required String email,
    required String password,
    required String area,
    required List<String> departmentIds,
  }) async {
    try {
      final AuthResponse response = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: <String, dynamic>{
          'full_name': contactName.trim(),
          'phone': phone,
          'account_type': 'business',
        },
      );

      final User? created = response.user;
      if (created == null) {
        throw const AuthFailure('We could not create your account. Please try again.');
      }

      if (response.session == null) {
        // Email confirmation is enabled on the project: the business record
        // needs an authenticated owner, so it is submitted after first sign-in.
        return BusinessSignupOutcome.awaitingEmailConfirmation;
      }

      final Map<String, dynamic> business = await _client
          .from('businesses')
          .insert(<String, dynamic>{
        'owner_id': created.id,
        'name': businessName.trim(),
        'contact_name': contactName.trim(),
        'phone': phone,
        'email': email.trim().toLowerCase(),
        'area': area.trim(),
        // status is omitted on purpose: the default 'pending' applies and the
        // insert policy rejects anything else.
      })
          .select('id')
          .single();

      if (departmentIds.isNotEmpty) {
        await _client.from('business_departments').insert(
              departmentIds
                  .map((String id) => <String, dynamic>{
                        'business_id': business['id'],
                        'department_id': id,
                      })
                  .toList(),
            );
      }

      return BusinessSignupOutcome.submitted;
    } on AuthException catch (error) {
      throw AuthFailure(AuthErrorMapper.describe(code: error.code, message: error.message));
    } on PostgrestException catch (error) {
      throw AuthFailure(AuthErrorMapper.describe(pgCode: error.code, message: error.message));
    } catch (error) {
      throw AuthFailure(AuthErrorMapper.describe(message: error.toString()));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
    } on AuthException catch (error) {
      throw AuthFailure(AuthErrorMapper.describe(code: error.code, message: error.message));
    } catch (error) {
      throw AuthFailure(AuthErrorMapper.describe(message: error.toString()));
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on AuthException catch (error) {
      throw AuthFailure(AuthErrorMapper.describe(code: error.code, message: error.message));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'com.suprememall.app://login-callback',
      );
    } on AuthException catch (error) {
      throw AuthFailure(AuthErrorMapper.describe(code: error.code, message: error.message));
    } catch (error) {
      throw AuthFailure(AuthErrorMapper.describe(message: error.toString()));
    }
  }

  /// Business row for the signed-in owner, with its departments embedded.
  Future<Map<String, dynamic>?> loadOwnBusiness() async {
    final User? current = _auth.currentUser;
    if (current == null) {
      return null;
    }
    try {
      return await _client
          .from('businesses')
          .select('id, name, status, area, rejection_reason, '
              'business_departments(departments(name))')
          .eq('owner_id', current.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
    } on PostgrestException catch (error) {
      throw AuthFailure(AuthErrorMapper.describe(pgCode: error.code, message: error.message));
    }
  }
}

enum BusinessSignupOutcome {
  /// Business row + departments written; awaiting administrator review.
  submitted,

  /// Project has email confirmation on, so the record is written after the
  /// first sign-in.
  awaitingEmailConfirmation,
}
