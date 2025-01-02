import 'package:appdatfood/pages/login.dart';
import 'package:appdatfood/pages/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;

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
         print("AuthMethods: deleteuser - getting current user: ${user?.uid}");
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
}