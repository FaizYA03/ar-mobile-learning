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

  test('keeps host intact when subdomain starts with "api"', () {
    expect(
      ProfileScreen.resolveAvatarUrl(
          'https://api.domain.com/api', {'avatar': 'avatars/a.png'}),
      'https://api.domain.com/storage/avatars/a.png',
    );
    expect(
      ProfileScreen.resolveAvatarUrl(
          'https://api.sekolah.sch.id/api', {'avatar': '/avatars/a.png'}),
      'https://api.sekolah.sch.id/storage/avatars/a.png',
    );
    expect(
      ProfileScreen.resolveAvatarUrl(
          'https://apiclient.myapi.co.id/api', {'avatar': 'a.png'}),
      'https://apiclient.myapi.co.id/storage/a.png',
    );
  });

  test('handles trailing slash and base without /api suffix', () {
    expect(
      ProfileScreen.resolveAvatarUrl(
          'https://api.domain.com/api/', {'avatar': 'a.png'}),
      'https://api.domain.com/storage/a.png',
    );
    expect(
      ProfileScreen.resolveAvatarUrl(
          'https://api.domain.com', {'avatar': 'a.png'}),
      'https://api.domain.com/storage/a.png',
    );
  });
}
