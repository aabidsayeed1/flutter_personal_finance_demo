// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_personal_finance_demo/data/provider/auth/auth_manager.dart';
import 'package:flutter_personal_finance_demo/data/provider/auth/firebase_auth/apple_auth.dart';
import 'package:flutter_personal_finance_demo/data/provider/auth/firebase_auth/email_auth.dart';
import 'package:flutter_personal_finance_demo/data/provider/auth/firebase_auth/firebase_user_provider.dart';
import 'package:flutter_personal_finance_demo/data/provider/auth/firebase_auth/google_auth.dart';
import 'package:flutter_personal_finance_demo/data/provider/auth/firebase_auth/jwt_token_auth.dart';

import 'anonymous_auth.dart';

class FirebaseAuthManager extends AuthManager
    with
        EmailSignInManager,
        AnonymousSignInManager,
        AppleSignInManager,
        GoogleSignInManager,
        JwtSignInManager,
        PhoneSignInManager {
  // Set when using phone verification (after phone number is provided).
  String? _phoneAuthVerificationCode;
  ConfirmationResult? _webPhoneAuthConfirmationResult;

  @override
  Future deleteUser(BuildContext context) async {
    try {
      if (!loggedIn) {
        print('Error : delete user attempted with no logged in user!');
        return;
      }
      await currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Too long since most recent sign in. Sign in again before deleting your account.')),
        );
      }
    }
  }

  @override
  Future resetPassword(
      {required String email, required BuildContext context}) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message!}')),
      );
      return null;
    }
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent')));
  }

  @override
  Future signOut() {
    return FirebaseAuth.instance.signOut();
  }

  @override
  Future beginPhoneAuth(
      {required BuildContext context,
      required String phoneNumber,
      required VoidCallback onCodeSent}) async {
    if (kIsWeb) {
      _webPhoneAuthConfirmationResult =
          await FirebaseAuth.instance.signInWithPhoneNumber(phoneNumber);
      onCodeSent();
      return;
    }
    final completer = Completer<bool>();
    // If you'd like auto-verification, without the user having to enter the SMS
    // code manually. Follow these instructions:
    // * For Android: https://firebase.google.com/docs/auth/android/phone-auth?authuser=0#enable-app-verification (SafetyNet set up)
    // * For iOS: https://firebase.google.com/docs/auth/ios/phone-auth?authuser=0#start-receiving-silent-notifications
    // * Finally modify verificationCompleted below as instructed.
    await FirebaseAuth.instance.verifyPhoneNumber(
      verificationCompleted: (phoneAuthCredential) async {
        await FirebaseAuth.instance.signInWithCredential(phoneAuthCredential);
        // If you've implemented auto-verification, navigate to home page or
        // onboarding page here manually. Uncomment the lines below and replace
        // DestinationPage() with the desired widget.
        // await Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (_) => DestinationPage()),
        // );
      },
      verificationFailed: (e) {
        completer.complete(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error : ${e.message!}'),
          ),
        );
      },
      codeSent: (verificationId, _) {
        _phoneAuthVerificationCode = verificationId;
        completer.complete(true);
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (_) {},
    );
    return completer.future;
  }

  @override
  Future verifySmsCode(
      {required BuildContext context, required String smsCode}) {
    if (kIsWeb) {
      return _signInOrCreateAccount(
        context,
        () => _webPhoneAuthConfirmationResult!.confirm(smsCode),
        'PHONE',
      );
    } else {
      final authCredential = PhoneAuthProvider.credential(
        verificationId: _phoneAuthVerificationCode!,
        smsCode: smsCode,
      );
      return _signInOrCreateAccount(
          context,
          () => FirebaseAuth.instance.signInWithCredential(authCredential),
          'PHONE');
    }
  }

  @override
  Future<BaseAuthUser?> signInWithEmail(
      BuildContext context, String email, String password) {
    return _signInOrCreateAccount(
        context, () => emailSignInFunc(email, password), 'EMAIL');
  }

  @override
  Future<BaseAuthUser?> createAccountWithEmail(
      BuildContext context, String email, String password) {
    return _signInOrCreateAccount(
        context, () => emailCreateAccountFunc(email, password), 'EMAIL');
  }

  @override
  Future<BaseAuthUser?> signInAnonymously(BuildContext context) {
    return _signInOrCreateAccount(context, anonymousSignInFunc, 'ANONYMOUS');
  }

  @override
  Future<BaseAuthUser?> signInWithApple(BuildContext context) {
    return _signInOrCreateAccount(context, appleSignIn, 'APPLE');
  }

  @override
  Future<BaseAuthUser?> signInWithGoogle(BuildContext context) {
    return _signInOrCreateAccount(context, googleSignInFunc, 'GOOGLE');
  }

  @override
  Future<BaseAuthUser?> signInWithJwtToken(
      BuildContext context, String jwtToken) {
    return _signInOrCreateAccount(
        context, () => jwtTokenSignIn(jwtToken), 'JWT');
  }

  /// Tries to sign in or create an account using Firebase Auth.
  /// Returns the User object if sign in was successful.
  Future<BaseAuthUser?> _signInOrCreateAccount(
    BuildContext context,
    Future<UserCredential?> Function() signInFunc,
    String authProvider,
  ) async {
    try {
      final userCredential = await signInFunc();
      return userCredential == null
          ? null
          : AppFirebaseUser.fromUserCredential(userCredential);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
      return null;
    }
  }
}
