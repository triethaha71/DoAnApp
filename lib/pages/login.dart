import 'package:appdatfood/pages/bottomnav.dart';
import 'package:appdatfood/pages/forgotpassword.dart';
import 'package:appdatfood/pages/signup.dart';
import 'package:appdatfood/service/auth.dart';
import 'package:appdatfood/widget/widget_support.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String email = "", password = "";

  final _formkey = GlobalKey<FormState>();

  TextEditingController useremailcontroller = new TextEditingController();
  TextEditingController userpasswordcontroller = new TextEditingController();

  userLogin() async {
    print('LoginPage: userLogin called');
    try {
      print('LoginPage: userLogin - calling signInWithEmailAndPassword');
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      print(
          'LoginPage: userLogin - signInWithEmailAndPassword success, navigating to Bottomnav');
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => Bottomnav()));
    } on FirebaseAuthException catch (e) {
      print('LoginPage: userLogin - FirebaseAuthException : $e');
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
          "Không tìm thấy người dùng Email",
          style: TextStyle(fontSize: 18.0, color: Colors.black),
        )));
      } else if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
          "Bạn nhập sai mật khẩu",
          style: TextStyle(fontSize: 18.0, color: Colors.black),
        )));
      }
    }
  }

  void googleSignIn() async {
    print("LoginPage: googleSignIn called");
    AuthMethods().signInWithGoogle(context);
  }

  void facebookSignIn() async {
    print("LoginPage: facebookSignIn called");
    // logic đăng nhập facebook
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: Container(
        child: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2.5,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                    Color(0xFFff5c30),
                    Color(0xFFe74b1a),
                  ])),
            ),
            Container(
              margin:
                  EdgeInsets.only(top: MediaQuery.of(context).size.height / 3),
              height: MediaQuery.of(context).size.height / 2,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40))),
              child: Text(""),
            ),
            Container(
              margin: EdgeInsets.only(top: 60.0, left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                      child: Image.asset(
                    "images/logo.png",
                    width: MediaQuery.of(context).size.width / 1.5,
                    fit: BoxFit.cover,
                  )),
                  SizedBox(
                    height: 50.0,
                  ),
                  Material(
                    elevation: 5.0,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: EdgeInsets.only(left: 20.0, right: 20.0),
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height / 2,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20)),
                      child: Form(
                        key: _formkey,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 30.0,
                            ),
                            Text(
                              "Đăng nhập",
                              style: AppWidget.HeadlineTextFeildStyle(),
                            ),
                            SizedBox(
                              height: 20.0,
                            ),
                             TextFormField(
                              controller: useremailcontroller,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter Email';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                  hintText: 'Email',
                                  hintStyle:
                                      AppWidget.semiBooldTextFeildStyle(),
                                  prefixIcon: Icon(Icons.email_outlined)),
                            ),
                            SizedBox(
                              height: 30.0,
                            ),
                            TextFormField(
                              controller: userpasswordcontroller,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter Password';
                                }
                                return null;
                              },
                              obscureText: true,
                              decoration: InputDecoration(
                                  hintText: 'Mật khẩu',
                                  hintStyle:
                                      AppWidget.semiBooldTextFeildStyle(),
                                  prefixIcon: Icon(Icons.password_outlined)),
                            ),
                            SizedBox(
                              height: 20.0,
                            ),
                            GestureDetector(
                              onTap: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context)=>Forgotpassword()));
                              },
                              child: Container(
                                alignment: Alignment.topRight,
                                child: Text(
                                  "Quên mật khẩu?",
                                  style: AppWidget.semiBooldTextFeildStyle(),
                                ),
                              ),
                            ),
                            SizedBox(
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
                                  padding: EdgeInsets.symmetric(vertical: 10.0),
                                  width: 200,
                                  decoration: BoxDecoration(
                                    color: Color(0xffff5722),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                      child: Text(
                                    "Đăng nhập",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18.0,
                                        fontFamily: 'Poppins1',
                                        fontWeight: FontWeight.bold),
                                  )),
                                ),
                              ),
                            ),
                                SizedBox(height: 30),
                             Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: (){
                                      googleSignIn();
                                    },
                                    child: Material(
                                      elevation: 5.0,
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                          padding: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10)
                                          ),
                                          child: Image.asset("images/google.png", width: 35,),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 25),
                                  GestureDetector(
                                    onTap: (){
                                      facebookSignIn();
                                    },
                                    child: Material(
                                      elevation: 5.0,
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                          padding: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10)
                                          ),
                                           child: Image.asset("images/facebook.png", width: 35,),
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
                   SizedBox(
                    height: 50.0,
                  ),
                  GestureDetector(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => Signup()));
                      },
                      child: Text(
                        "Bạn chưa có tài khoản? Đăng ký ngay",
                        style: AppWidget.semiBooldTextFeildStyle(),
                      ))
                ],
              ),
            )
          ],
        ),
      ),
    ));
  }
}