import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/api_client.dart';

void main() {
  group('ApiClient.shouldAutoLogout', () {
    test('401 di endpoint auth tidak memicu logout', () {
      expect(
        ApiClient.shouldAutoLogout(path: '/dashboard', statusCode: 401),
        isTrue,
      );
      expect(
        ApiClient.shouldAutoLogout(path: '/dashboard', statusCode: 419),
        isTrue,
      );
      expect(
        ApiClient.shouldAutoLogout(path: '/v1/app/config', statusCode: 401),
        isTrue,
      );
    });

    test('401 login/register (salah password) tidak memicu logout', () {
      expect(
        ApiClient.shouldAutoLogout(path: '/login', statusCode: 401),
        isFalse,
      );
      expect(
        ApiClient.shouldAutoLogout(path: '/register', statusCode: 401),
        isFalse,
      );
    });

    test('status selain 401/419 tidak memicu logout', () {
      expect(
        ApiClient.shouldAutoLogout(path: '/dashboard', statusCode: 200),
        isFalse,
      );
      expect(
        ApiClient.shouldAutoLogout(path: '/dashboard', statusCode: 500),
        isFalse,
      );
      expect(
        ApiClient.shouldAutoLogout(path: '/dashboard', statusCode: null),
        isFalse,
      );
    });
  });
}
