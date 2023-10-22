import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import '../base_auth_user_provider.dart';

export '../base_auth_user_provider.dart';

class AppFirebaseUser extends BaseAuthUser {
  AppFirebaseUser(this.user);
  User? user;

  @override
  AuthUserInfo get authUserInfo => AuthUserInfo(user?.uid, user?.email,
      user?.displayName, user?.photoURL, user?.phoneNumber);

  @override
  Future? delete() => user?.delete();

  @override
  bool get emailVerified {
    // Reloads the user when checking in order to get the most up to date
    // email verified status.
    if (loggedIn && !user!.emailVerified) {
      FirebaseAuth.instance.currentUser
          ?.reload()
          .then((value) => user = FirebaseAuth.instance.currentUser);
    }
    return user?.emailVerified ?? false;
  }

  @override
  bool get loggedIn => user != null;

  @override
  Future? sendEmailVerification() => user?.sendEmailVerification();

  static BaseAuthUser fromUserCredential(UserCredential userCredential) =>
      fromFirebaseUser(userCredential.user);

  static BaseAuthUser fromFirebaseUser(User? user) => AppFirebaseUser(user);
}

Stream<BaseAuthUser> appFirebaseUserStream() => FirebaseAuth.instance
        .authStateChanges()
        .debounce((user) => user == null && !loggedIn
            ? TimerStream(true, const Duration(seconds: 1))
            : Stream.value(user))
        .map<BaseAuthUser>((user) {
      currentUser = AppFirebaseUser(user);
      return currentUser!;
    });
