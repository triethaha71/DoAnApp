import 'package:appdatfood/pages/bottomnav.dart';
import 'package:appdatfood/pages/login.dart';
import 'package:appdatfood/pages/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  Future<User?> getCurrentUser() async {
    return auth.currentUser;
  }

  Future<void> SignOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      print('AuthMethods: SignOut - User has signed out successfully');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
      print('AuthMethods: SignOut - Navigated to Login Page');
    } on FirebaseAuthException catch (e) {
      print('AuthMethods: SignOut - error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error in signout. $e")));
    }
  }

   Future<void> deleteuser(BuildContext context) async {
    try {
      User? user = await FirebaseAuth.instance.currentUser;
        if (user != null){
            print("AuthMethods: deleteuser - deleting user in Firestore with id ${user.uid}");
             await FirebaseFirestore.instance
                 .collection('users')
                 .doc(user.uid)
                 .delete();
              await user.delete();
              print("AuthMethods: deleteuser successfully - deleted user ${user.uid} on firestore and auth");
               if (context != null && context.mounted){
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const Signup()),
                           );
                     print('AuthMethods: deleteuser - Navigated to Signup Page');
                    } else {
                      print("AuthMethods: deleteuser - context is invalid, cannot navigate to signup page");
                    }
        }
         else{
          print("AuthMethods: deleteuser - No user logged in, cannot delete");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.red,
              content: Text("No user logged in, cannot delete")));
         }
    } on FirebaseAuthException catch (e) {
      print("AuthMethods: Error delete user $e");
          if (e.code == 'user-not-found') {
             print('AuthMethods: deleteuser - user not found, cannot delete');
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.red,
              content: Text("User not found, cannot delete user.")));
           }  else if (context != null && context.mounted){
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.red,
              content: Text("Error in delete user. $e")));
          }
        }
  }
     Future<void> signInWithGoogle(BuildContext context) async {
    print("AuthMethods: signInWithGoogle called");
     try {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
            if (googleUser == null){
                print("AuthMethods: signInWithGoogle - user cancel google signin");
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Colors.red,
                content: Text(
                  "User cancel Google signin",
                )));
              return;
           }
        print("AuthMethods: signInWithGoogle - get Google auth");
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
        print("AuthMethods: signInWithGoogle - get Firebase auth credential");
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
         print("AuthMethods: signInWithGoogle - Sign in to Firebase Auth");
      final UserCredential userCredential = await auth.signInWithCredential(credential);
      print("AuthMethods: signInWithGoogle - signed in successfully, user = ${userCredential.user?.uid}");
       User? user = userCredential.user;
        if (user != null) {
        // Check if user exists
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
             if (!userDoc.exists) {
              print("AuthMethods: signInWithGoogle - user does not exist on firestore, adding information");
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .set({
                   'Email': user.email,
                   'Id': user.uid,
                   'Name': user.displayName,
                   'Wallet': "0",
                 });
                 print("AuthMethods: signInWithGoogle - user information has been added on firestore, user = ${user.uid}");
            }
           else{
             print("AuthMethods: signInWithGoogle - user already existed on firestore, user = ${user.uid}");
           }

        if (context != null && context.mounted){
             Navigator.pushReplacement(
                    context,
                     MaterialPageRoute(builder: (context) => Bottomnav()),
                  );
            print("AuthMethods: signInWithGoogle - Navigated to HomePage");
        }
      } else{
        print("AuthMethods: signInWithGoogle - User from firebase auth is null, cannot log in with google");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Colors.red,
                content: Text(
                  "User from firebase auth is null, cannot log in with google",
                )));
      }
      }on FirebaseAuthException catch (e) {
      print("AuthMethods: signInWithGoogle - FirebaseAuthException: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Colors.red,
                content: Text(
                  "Error in Google signin, $e",
                )));
     }
  }
}