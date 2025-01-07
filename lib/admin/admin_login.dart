import 'package:appdatfood/pages/login.dart';
import 'package:appdatfood/admin/home_admin.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLogin extends StatefulWidget {
  const AdminLogin({Key? key}) : super(key: key);

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final TextEditingController usernamecontroller = TextEditingController();
  final TextEditingController userpasswordcontroller = TextEditingController();
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0f2f5), // Light grey background
      body: SingleChildScrollView( // Make the screen scrollable
        child: SizedBox(
          height: MediaQuery.of(context).size.height, // Occupy the full screen height
          child: Stack(
            children: [
              // Background Gradient
              Container(
                height: MediaQuery.of(context).size.height * 0.4, // Adjust the height as desired
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1e3c72), Color(0xFF2a5298)], // Blue shades
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                ),
              ),

               Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 30.0, right: 10.0),
                child: Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.person, color: Colors.white, size: 30,),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Login()),
                        );
                      },
                    ),
                    const SizedBox(height: 30), // Khoảng cách giữa icon và phần tử bên dưới
                  ],
                ),
              ),
            ),


              // Main Content
              Center(
                child: Container(
                    margin: const EdgeInsets.only(top: 100), // Adjusted margin
                    padding: const EdgeInsets.all(20.0),
                    width: MediaQuery.of(context).size.width * 0.85,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]),
                    child: Form(
                      key: _formkey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: const Text(
                              "Admin ",
                              style: TextStyle(
                                fontSize: 28.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1e3c72), // Dark blue color
                              ),
                            ),
                          ),
                          const SizedBox(height: 30.0),
                          _buildTextField(
                            controller: usernamecontroller,
                            hintText: "Tài khoản",
                            icon: Icons.person_outline,
                             validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập tài khoản';
                                  }
                                  return null;
                                },
                          ),
                          const SizedBox(height: 20.0),
                          _buildTextField(
                            controller: userpasswordcontroller,
                            hintText: "Mật khẩu",
                            icon: Icons.lock_outline,
                            obscureText: _obscureText,
                            suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureText = !_obscureText;
                                    });
                                  },
                                ),
                             validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập mật khẩu';
                                  }
                                  return null;
                                },
                          ),
                          const SizedBox(height: 30.0),
                          _buildLoginButton(),
                        ],
                      ),
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // Reusable text field widget
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
      Widget? suffixIcon,
    FormFieldValidator<String>? validator,
  }) {
    return Material(
      elevation: 2.0,
      borderRadius: BorderRadius.circular(15),
      child: TextFormField(
          controller: controller,
           validator: validator,
        obscureText: obscureText,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF1e3c72)),
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFF1e3c72), width: 1.2)), // Border color when focused
            filled: true,
            fillColor: Colors.white,
           suffixIcon: suffixIcon,
        ),
      ),
    );
  }


  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: () {
        if (_formkey.currentState!.validate()) {
             LoginAdmin();
           }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1e3c72),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text(
            "Đăng nhập",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  LoginAdmin() {
     FirebaseFirestore.instance.collection("Admin").get().then((snapshot) {
      bool idFound = false; // Flag to check if the ID was found

      snapshot.docs.forEach((result) {
        if (result.data()['id'] == usernamecontroller.text.trim()) {
            idFound = true;

              if (result.data()['password'] != userpasswordcontroller.text.trim()) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  backgroundColor: Colors.orangeAccent,
                  content: Text(
                    "Your password is not correct",
                    style: TextStyle(fontSize: 18.0),
                  ),
                ));
              } else {
                Route route =
                    MaterialPageRoute(builder: (context) => const HomeAdmin());
                Navigator.pushReplacement(context, route);
              }
            }
          });

         if(!idFound) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                backgroundColor: Color.fromARGB(255, 9, 134, 28),
                content: Text(
                  "Your id is incorrect",
                  style: TextStyle(fontSize: 18.0),
                ),
              ));
          }

        });
    }
}