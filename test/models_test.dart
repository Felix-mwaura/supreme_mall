import 'package:flutter_test/flutter_test.dart';
import 'package:supreme_mall/models/app_profile.dart';
import 'package:supreme_mall/models/business_application.dart';

void main() {
  group('AppProfile', () {
    test('reads the profiles row', () {
      final AppProfile profile = AppProfile.fromMap(<String, dynamic>{
        'id': 'abc',
        'full_name': 'Wanjiku Kamau',
        'phone': '+254712345678',
        'role': 'customer',
      });

      expect(profile.firstName, 'Wanjiku');
      expect(profile.initials, 'WK');
      expect(profile.isBusiness, isFalse);
    });

    test('detects business owners and admin', () {
      const AppProfile owner = AppProfile(
        id: 'abc',
        fullName: 'Peter Mwangi',
        role: 'business_owner',
      );
      const AppProfile admin = AppProfile(id: 'x', fullName: 'Admin', role: 'admin');

      expect(owner.isBusiness, isTrue);
      expect(admin.isAdmin, isTrue);
      expect(admin.isBusiness, isFalse);
    });

    test('missing name degrades gracefully instead of throwing', () {
      final AppProfile profile = AppProfile.fromMap(<String, dynamic>{'id': 'abc'});

      expect(profile.firstName, 'there');
      expect(profile.initials, 'SM');
      expect(profile.role, 'customer');
    });
  });

  group('BusinessStatus', () {
    test('maps database values', () {
      expect(BusinessStatus.fromDb('pending'), BusinessStatus.pending);
      expect(BusinessStatus.fromDb('approved'), BusinessStatus.approved);
      expect(BusinessStatus.fromDb('rejected'), BusinessStatus.rejected);
      expect(BusinessStatus.fromDb('suspended'), BusinessStatus.suspended);
    });

    test('unknown or null values never look approved', () {
      expect(BusinessStatus.fromDb(null), BusinessStatus.pending);
      expect(BusinessStatus.fromDb('weird'), BusinessStatus.pending);
      expect(BusinessStatus.fromDb('weird').canSell, isFalse);
    });

    test('only approved can sell', () {
      expect(BusinessStatus.approved.canSell, isTrue);
      expect(BusinessStatus.pending.canSell, isFalse);
    });
  });

  group('BusinessApplication', () {
    test('flattens embedded departments from Postgrest', () {
      final BusinessApplication application = BusinessApplication.fromMap(<String, dynamic>{
        'id': 'b1',
        'name': 'Nyeri Fresh Mart',
        'status': 'pending',
        'area': 'Nyeri Town',
        'business_departments': <dynamic>[
          <String, dynamic>{
            'departments': <String, dynamic>{'name': 'Supreme Shopping'},
          },
          <String, dynamic>{
            'departments': <String, dynamic>{'name': 'Supreme Fresh'},
          },
        ],
      });

      expect(application.status, BusinessStatus.pending);
      expect(application.departments, <String>['Supreme Shopping', 'Supreme Fresh']);
    });

    test('tolerates a business with no departments yet', () {
      final BusinessApplication application = BusinessApplication.fromMap(<String, dynamic>{
        'id': 'b2',
        'name': 'Mama Ngina Cafe',
        'status': 'rejected',
        'rejection_reason': 'Permit expired',
      });

      expect(application.departments, isEmpty);
      expect(application.rejectionReason, 'Permit expired');
    });
  });
}
