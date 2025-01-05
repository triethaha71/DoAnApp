import 'package:appdatfood/pages/bottomnav.dart';
import 'package:appdatfood/pages/login.dart';
import 'package:appdatfood/pages/signup.dart';
import 'package:appdatfood/service/shared_pref.dart';
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

  Future<void> _showSnackBar(BuildContext context, String message,
      {bool isError = true}) async{
       if (context != null && context.mounted){
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: isError ? Colors.red : Colors.green,
            content: Text(message),
          ),
        );
       }
  }


  Future<void> SignOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      print('AuthMethods: SignOut - User has signed out successfully');
      _showSnackBar(context, 'Đăng xuất thành công!', isError: false); // Use helper method
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
      print('AuthMethods: SignOut - Navigated to Login Page');
    } on FirebaseAuthException catch (e) {
      print('AuthMethods: SignOut - error: $e');
      _showSnackBar(context, "Lỗi khi đăng xuất. $e");
    }
  }

  Future<void> deleteuser(BuildContext context) async {
    try {
      User? user = await FirebaseAuth.instance.currentUser;
      if (user != null) {
        print("AuthMethods: deleteuser - deleting user in Firestore with id ${user.uid}");
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();
        await user.delete();
        print("AuthMethods: deleteuser successfully - deleted user ${user.uid} on firestore and auth");
        if (context != null && context.mounted) {
          _showSnackBar(context, "Tài khoản đã được xóa thành công!", isError: false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Signup()),
          );
          print('AuthMethods: deleteuser - Navigated to Signup Page');
        } else {
           print("AuthMethods: deleteuser - context is invalid, cannot navigate to signup page");
           _showSnackBar(context,"Lỗi: Không thể điều hướng đến trang đăng ký.", isError: true );
        }
      } else {
         print("AuthMethods: deleteuser - No user logged in, cannot delete");
         _showSnackBar(context,"Không có người dùng đăng nhập, không thể xóa.", isError: true);
      }
    } on FirebaseAuthException catch (e) {
      print("AuthMethods: Error delete user $e");
      if (e.code == 'user-not-found') {
        print('AuthMethods: deleteuser - user not found, cannot delete');
        _showSnackBar(context,"Người dùng không tồn tại, không thể xóa.", isError: true);
      } else {
          _showSnackBar(context, "Lỗi khi xóa tài khoản. $e",);
      }
    }
  }

    Future<void> signInWithGoogle(BuildContext context) async {
    print("AuthMethods: signInWithGoogle called");
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("AuthMethods: signInWithGoogle - user cancel google signin");
        _showSnackBar(context,"Đăng nhập Google bị hủy.", isError: true);
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
      final UserCredential userCredential =
          await auth.signInWithCredential(credential);
       print("AuthMethods: signInWithGoogle - signed in successfully, user = ${userCredential.user?.uid}");
        User? user = userCredential.user;
      if (user != null) {
          // Save user info
          await SharedPreferenceHelper().saveUserId(user.uid);
          await SharedPreferenceHelper().saveUserName(user.displayName ?? 'Name');
          await SharedPreferenceHelper().saveUserEmail(user.email ?? 'Email');
          await SharedPreferenceHelper().saveUserProfile(user.photoURL ?? '');


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
         } else {
           print("AuthMethods: signInWithGoogle - user already existed on firestore, user = ${user.uid}");
        }

       if (context != null && context.mounted){
           Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Bottomnav()),
            );
           print("AuthMethods: signInWithGoogle - Navigated to HomePage");
       }

      } else {
          print("AuthMethods: signInWithGoogle - User from firebase auth is null, cannot log in with google");
           _showSnackBar(context,"User từ Firebase Auth là null, không thể đăng nhập với Google.", isError: true);
      }
     } on FirebaseAuthException catch (e) {
      print("AuthMethods: signInWithGoogle - FirebaseAuthException: $e");
      _showSnackBar(context, "Lỗi khi đăng nhập Google, $e",);
    }
  }
}