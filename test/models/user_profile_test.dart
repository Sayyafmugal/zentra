import 'package:flutter_test/flutter_test.dart';
import 'package:zentra_0/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    final profile = UserProfile(
      uid: 'u1',
      fullName: 'Jordan Lee',
      email: 'jordan@example.com',
      phone: '5551234',
      role: UserRole.admin,
      createdAt: DateTime(2026, 1, 1),
    );

    test('round-trips through toMap/fromMap including role', () {
      final restored = UserProfile.fromMap(profile.toMap());
      expect(restored, equals(profile));
      expect(restored.role, UserRole.admin);
    });

    test('isAdmin reflects the role field', () {
      expect(profile.isAdmin, isTrue);
      final regular = profile.copyWith(role: UserRole.user);
      expect(regular.isAdmin, isFalse);
    });

    test('fromMap defaults role to user when missing or unrecognized', () {
      final map = profile.toMap();
      map.remove('role');
      final restored = UserProfile.fromMap(map);
      expect(restored.role, UserRole.user);
      expect(restored.isAdmin, isFalse);
    });
  });
}
