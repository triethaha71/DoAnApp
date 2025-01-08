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
  //xác thực lại người dùng
  Future<void> reauthenticateUser(User user, String currentPassword) async {
    try {
      final AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  Future<void> _showSnackBar(BuildContext context, String message,
      {bool isError = true}) async {
    if (context != null && context.mounted) {
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
      print('AuthMethods: SignOut - Người dùng đã đăng xuất thành công');
      _showSnackBar(context, 'Đăng xuất thành công!', isError: false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
      print('AuthMethods: SignOut - Đã điều hướng đến Trang đăng nhập');
    } on FirebaseAuthException catch (e) {
      print('AuthMethods: Đăng xuất - lỗi: $e');
      _showSnackBar(context, "Lỗi khi đăng xuất. $e");
    }
  }


  Future<void> resetPassword(BuildContext context, String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
      if (context != null && context.mounted) {
        _showSnackBar(context, "Đã gửi liên kết đặt lại mật khẩu đến email của bạn.",
            isError: false);
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(context, "Lỗi khi gửi email đặt lại mật khẩu: $e");
    }
  }

  Future<void> deleteuser(BuildContext context) async {
    try {
      User? user = await FirebaseAuth.instance.currentUser;
      if (user != null) {
        print(
            "AuthMethods: deleteuser - xóa người dùng trong Firestore có id ${user.uid}");
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();
        await user.delete();
        print(
            "AuthMethods: deleteuser thành công - người dùng đã bị xóa ${user.uid} trên firebase và autho");
        if (context != null && context.mounted) {
          _showSnackBar(context, "Tài khoản đã được xóa thành công!",
              isError: false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Signup()),
          );
          print('AuthMethods: deleteuser - Đã điều hướng đến Trang đăng ký');
        } else {
          print(
              "AuthMethods: deleteuser - context is invalid, cannot navigate to signup page");
          _showSnackBar(
              context, "Lỗi: Không thể điều hướng đến trang đăng ký.",
              isError: true);
        }
      } else {
        print("AuthMethods: deleteuser - Không có người dùng nào đăng nhập, không thể xóa");
        _showSnackBar(context, "Không có người dùng đăng nhập, không thể xóa.",
            isError: true);
      }
    } on FirebaseAuthException catch (e) {
      print("AuthMethods: Error delete user $e");
      if (e.code == 'user-not-found') {
        print('AuthMethods: deleteuser - không tìm thấy người dùng, không thể xóa');
        _showSnackBar(context, "Người dùng không tồn tại, không thể xóa.",
            isError: true);
      } else {
        _showSnackBar(context, "Lỗi khi xóa tài khoản. $e");
      }
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    print("AuthMethods: signInWithGoogle called");
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("AuthMethods: signInWithGoogle - người dùng hủy đăng nhập google");
        _showSnackBar(context, "Đăng nhập Google bị hủy.", isError: true);
        return;
      }
      print("AuthMethods: signInWithGoogle - nhận xác thực Google");
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print("AuthMethods: signInWithGoogle - nhận xác thực Google");
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print("AuthMethods: signInWithGoogle - Đăng nhập vào Firebase Auth");
      final UserCredential userCredential =
          await auth.signInWithCredential(credential);
      print(
          "AuthMethods: signInWithGoogle - đã đăng nhập thành công, người dùng = ${userCredential.user?.uid}");
      User? user = userCredential.user;
      if (user != null) {
        // Lưu thông tin người dùng
        await SharedPreferenceHelper().saveUserId(user.uid);
        await SharedPreferenceHelper()
            .saveUserName(user.displayName ?? 'Name');
        await SharedPreferenceHelper().saveUserEmail(user.email ?? 'Email');
        await SharedPreferenceHelper().saveUserProfile(user.photoURL ?? '');

        // Kiểm tra xem người dùng có tồn tại không
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (!userDoc.exists) {
          print(
              "AuthMethods: signInWithGoogle - người dùng không tồn tại trên firestore, đang thêm thông tin");
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'Email': user.email,
            'Id': user.uid,
            'Name': user.displayName,
            'Wallet': "0",
          });
          print(
              "AuthMethods: signInWithGoogle - thông tin người dùng đã được thêm vào firestore, user = ${user.uid}");
        } else {
          print(
              "AuthMethods: signInWithGoogle - người dùng đã tồn tại trên firestore, người dùng = ${user.uid}");
        }

        if (context != null && context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Bottomnav()),
          );
          print("AuthMethods: signInWithGoogle - Đã điều hướng đến Trang chủ");
        }
      } else {
        print(
            "AuthMethods: signInWithGoogle - Người dùng từ xác thực firebase là null, không thể đăng nhập bằng google");
        _showSnackBar(context,
            "Người dùng từ Firebase Auth là null, không thể đăng nhập vào Google.",
            isError: true);
      }
    } on FirebaseAuthException catch (e) {
      print("Phương pháp xác thực: signInWithGoogle - FirebaseAuthException: $e");
      _showSnackBar(context, "Lỗi khi đăng nhập Google, $e");
    }
  }
}