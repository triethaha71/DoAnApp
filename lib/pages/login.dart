import 'package:appdatfood/admin/admin_login.dart';
import 'package:appdatfood/pages/bottomnav.dart';
import 'package:appdatfood/pages/forgotpassword.dart';
import 'package:appdatfood/pages/signup.dart';
import 'package:appdatfood/service/auth.dart';
import 'package:appdatfood/widget/widget_support.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String email = "", password = "";

  final _formkey = GlobalKey<FormState>();

  TextEditingController useremailcontroller = TextEditingController();
  TextEditingController userpasswordcontroller = TextEditingController();

  userLogin() async {
    print('LoginPage: userLogin called');
    try {
      print('LoginPage: userLogin - calling signInWithEmailAndPassword');
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      print(
          'LoginPage: userLogin - signInWithEmailAndPassword success, navigating to Bottomnav');
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const Bottomnav()));
    } on FirebaseAuthException catch (e) {
      print('LoginPage: userLogin - FirebaseAuthException : $e');
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
          "Không tìm thấy người dùng Email",
          style: TextStyle(fontSize: 18.0, color: Colors.black),
        )));
      } else if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
          "Bạn nhập sai mật khẩu",
          style: TextStyle(fontSize: 18.0, color: Colors.black),
        )));
      }
    }
  }
  // google
  void googleSignIn() async {
    print("LoginPage: googleSignIn called");
    AuthMethods().signInWithGoogle(context);
  }
  // facebook
  void facebookSignIn() async {
    print("LoginPage: facebookSignIn called");
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2.5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    
                    Color(0xFF1e3c72),
                    Color(0xFF64B5F6),
                  ],
                ),
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0, right: 10.0),
                  child: IconButton(
                    icon: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AdminLogin()),
                      );
                    },
                  ),
                ),
              ),
            ),
            Container(
              margin:
                  EdgeInsets.only(top: MediaQuery.of(context).size.height / 3),
              height: MediaQuery.of(context).size.height / 2,
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: const Text(""),
            ),
            Container(
              margin: const EdgeInsets.only(top: 60.0, left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Image.asset(
                      "images/logo.png",
                      width: MediaQuery.of(context).size.width / 2,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(
                    height: 50.0,
                  ),
                  Material(
                    elevation: 5.0,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height / 2,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Form(
                        key: _formkey,
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 30.0,
                            ),
                            Text(
                              "Đăng nhập",
                              style: AppWidget.HeadlineTextFeildStyle(),
                            ),
                            const SizedBox(
                              height: 20.0,
                            ),
                            TextFormField(
                              controller: useremailcontroller,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập Email';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: AppWidget.semiBooldTextFeildStyle(),
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(
                              height: 30.0,
                            ),
                            TextFormField(
                              controller: userpasswordcontroller,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập mật khẩu';
                                }
                                return null;
                              },
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: 'Mật khẩu',
                                hintStyle: AppWidget.semiBooldTextFeildStyle(),
                                prefixIcon: const Icon(Icons.password_outlined),
                              ),
                            ),
                            const SizedBox(
                              height: 20.0,
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const Forgotpassword()));
                              },
                              child: Container(
                                alignment: Alignment.topRight,
                                child: Text(
                                  "Quên mật khẩu?",
                                  style: AppWidget.semiBooldTextFeildStyle(),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 30.0,
                            ),
                            GestureDetector(
                              onTap: () {
                                if (_formkey.currentState!.validate()) {
                                  setState(() {
                                    email = useremailcontroller.text;
                                    password = userpasswordcontroller.text;
                                  });
                                }
                                userLogin();
                              },
                              child: Material(
                                elevation: 5.0,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10.0),
                                  width: 200,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1e3c72),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "Đăng nhập",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18.0,
                                        fontFamily: 'Poppins1',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    googleSignIn();
                                  },
                                  child: Material(
                                    elevation: 5.0,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Image.asset(
                                        "images/google.png",
                                        width: 35,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 25),
                                GestureDetector(
                                  onTap: () {
                                    facebookSignIn();
                                  },
                                  child: Material(
                                    elevation: 5.0,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Image.asset(
                                        "images/facebook.png",
                                        width: 35,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 50.0,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Signup()));
                    },
                    child: Text(
                      "Bạn chưa có tài khoản? Đăng ký ",
                      style: AppWidget.semiBooldTextFeildStyle(),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}