import 'package:firebase_auth/firebase_auth.dart';

Future<UserCredential?> emailSignInFunc(String email, password) =>
    FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email.trim(), password: password);

Future<UserCredential?> emailCreateAccountFunc(String email, password) =>
    FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
