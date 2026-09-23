import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/profile_screen.dart';

void main() {
  const base = 'http://10.0.2.2:8000/api';

  test('returns null when no avatar', () {
    expect(ProfileScreen.resolveAvatarUrl(base, {}), isNull);
    expect(ProfileScreen.resolveAvatarUrl(base, {'avatar': ''}), isNull);
  });

  test('prefers absolute avatar_url', () {
    expect(
      ProfileScreen.resolveAvatarUrl(
          base, {'avatar_url': 'https://cdn.example.com/a.png'}),
      'https://cdn.example.com/a.png',
    );
  });

  test('builds storage url from avatar path', () {
    expect(
      ProfileScreen.resolveAvatarUrl(base, {'avatar': 'avatars/a.png'}),
      'http://10.0.2.2:8000/storage/avatars/a.png',
    );
  });

  test('does not duplicate storage prefix', () {
    expect(
      ProfileScreen.resolveAvatarUrl(base, {'avatar': 'storage/avatars/a.png'}),
      'http://10.0.2.2:8000/storage/avatars/a.png',
    );
  });

  test('passes through absolute avatar path', () {
    expect(
      ProfileScreen.resolveAvatarUrl(
          base, {'avatar': 'https://cdn.example.com/a.png'}),
      'https://cdn.example.com/a.png',
    );
  });
}
