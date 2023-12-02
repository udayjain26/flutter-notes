import 'package:flutter_test/flutter_test.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';

void main() {
  group('Mock Authentication', () {
    final provider = MockAuthProvider();

    test('provider should not be initialized to begin with', () {
      expect(provider.isInitialized, false);
    });
    test('cannot log out if not initialized', () {
      expect(
        provider.logOut(),
        throwsA(const TypeMatcher<NotInitializedException>()),
      );
    });

    test('shold be able to initialize', () async {
      await provider.initialize();
      expect(provider.isInitialized, true);
    });

    test('user should be null to begin with', () {
      expect(provider.currentuser, null);
    });

    test(
      'should be able to initialize in less than 2 seconds',
      () async {
        await provider.initialize();
        expect(provider._isInitialized, true);
      },
      timeout: const Timeout(Duration(seconds: 2)),
    );
    test('create user should be able to delegate login', () async {
      await provider.initialize();
      expect(provider.isInitialized, true);

      final badEmailUser =
          provider.createUser(email: 'foo@bar.com', password: 'password');
      expect(badEmailUser, throwsA(const TypeMatcher<UserNotFoundException>()));

      final badUserPassword = provider.createUser(
        email: 'someone@bar.com',
        password: 'foobar',
      );
      expect(badUserPassword,
          throwsA(const TypeMatcher<InvalidCredentialAuthException>()));

      final user = await provider.createUser(
        email: 'foo',
        password: 'bar',
      );
      expect(provider.currentuser, user);
      expect(user.isEmailVerified, false);
    });
    test('logged in user should be able to get verified', () async {
      provider.sendEmailVerification();
      final user = provider.currentuser;
      expect(user!.isEmailVerified, true);
    });
    test('should be able to log out and log in again', () async {
      await provider.logOut();
      expect(provider.currentuser, null);
      await provider.logIn(email: 'foo', password: 'bar');
      final user = provider.currentuser;
      expect(user, isNotNull);
    });
  });
}

class NotInitializedException implements Exception {}

class MockAuthProvider implements AuthProvider {
  var _isInitialized = false;

  AuthUser? _user;

  bool get isInitialized => _isInitialized;

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized) throw NotInitializedException();
    await Future.delayed(const Duration(seconds: 1));
    return logIn(email: email, password: password);
  }

  @override
  AuthUser? get currentuser => _user;

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 1));
    _isInitialized = true;
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized) throw NotInitializedException();
    if (email == 'foo@bar.com') throw UserNotFoundException();
    if (password == 'foobar') throw InvalidCredentialAuthException();
    const user = AuthUser(isEmailVerified: false, email: 'foo@bar.com');
    _user = user;
    return await Future.value(user);
  }

  @override
  Future<void> logOut() async {
    if (!_isInitialized) throw NotInitializedException();
    if (_user == null) throw UserNotFoundException();
    await Future.delayed(const Duration(seconds: 1));
    _user = null;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!_isInitialized) throw NotInitializedException();
    final user = _user;
    if (user == null) throw UserNotFoundException();
    const newUser = AuthUser(isEmailVerified: true, email: 'foo@bar.com');
    _user = newUser;
  }
}
