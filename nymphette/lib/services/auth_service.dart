import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<bool> sendOTP({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
    required Function() onTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage = 'Verification failed';

          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'The phone number is not valid.';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many requests. Please try again later.';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota exceeded. Please try again later.';
              break;
            default:
              errorMessage = e.message ?? 'Verification failed';
          }

          onError(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSent('OTP sent successfully');
        },
        timeout: const Duration(seconds: 60),
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          onTimeout();
        },
      );
      return true;
    } catch (e) {
      onError('Failed to send OTP: ${e.toString()}');
      return false;
    }
  }

  Future<bool> verifyOTP({
    required String otp,
    required Function(String) onError,
    required Function() onSuccess,
  }) async {
    if (_verificationId == null) {
      onError('Verification ID not found. Please request OTP again.');
      return false;
    }

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      UserCredential result = await _signInWithCredential(credential);

      if (result.user != null) {
        onSuccess();
        return true;
      } else {
        onError('Sign in failed');
        return false;
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Invalid OTP';

      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP. Please check and try again.';
          break;
        case 'invalid-verification-id':
          errorMessage =
              'Verification session expired. Please request new OTP.';
          break;
        case 'session-expired':
          errorMessage = 'OTP expired. Please request a new one.';
          break;
        default:
          errorMessage = e.message ?? 'Verification failed';
      }

      onError(errorMessage);
      return false;
    } catch (e) {
      onError('An unexpected error occurred: ${e.toString()}');
      return false;
    }
  }

  Future<UserCredential> _signInWithCredential(
    PhoneAuthCredential credential,
  ) async {
    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _verificationId = null;
  }

  bool get isSignedIn => _auth.currentUser != null;
  String? get userPhoneNumber => _auth.currentUser?.phoneNumber;

  Future<bool> resendOTP({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
    required Function() onTimeout,
  }) async {
    return await sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
      onTimeout: onTimeout,
    );
  }
}
