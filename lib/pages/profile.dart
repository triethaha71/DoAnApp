// profile.dart
import 'dart:io';
import 'dart:convert';
import 'package:appdatfood/pages/OrderHistoryPage.dart';
import 'package:appdatfood/service/auth.dart';
import 'package:http/http.dart' as http;
import 'package:appdatfood/service/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appdatfood/service/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  _ProfileState createState() => _ProfileState();
}

// Service for Imgur
class ImgurService {
  static const String clientId =
      "15f738ce9e52f01"; // Replace with your Imgur Client ID
  static Future<String?> uploadImageToImgur(File imageFile) async {
    try {
      final Uri apiUrl = Uri.parse("https://api.imgur.com/3/image");

      final request = http.MultipartRequest("POST", apiUrl);
      request.headers["Authorization"] = "Client-ID $clientId";

      request.files
          .add(await http.MultipartFile.fromPath("image", imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final Map<String, dynamic> jsonResponse =
            json.decode(responseData.body);

        // Get image link from JSON response
        return jsonResponse["data"]["link"];
      } else {
        print("Failed to upload image: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }
}

class _ProfileState extends State<Profile> {
  String? profile, name, email;
  File? _profileImage;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  final _nameController = TextEditingController();
  bool _isEditingName = false;
    final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();


  getthesharedpref() async {
    profile = await SharedPreferenceHelper().getUserProfile();
    name = await SharedPreferenceHelper().getUserName();
    email = await SharedPreferenceHelper().getUserEmail();
    _profileImageUrl = await SharedPreferenceHelper().getUserProfile();
     if (name != null) {
        _nameController.text = name!;
      }
  }

  onthisload() async {
    await getthesharedpref();
    setState(() {});
  }

  Future _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _profileImage = File(pickedFile.path);
    });
    await _uploadProfileImage();
  }

  Future _uploadProfileImage() async {
    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "No image was selected to upload.",
            style: TextStyle(fontSize: 18.0),
          )));
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      String? imageUrl = await ImgurService.uploadImageToImgur(_profileImage!);
      if (imageUrl != null) {
        setState(() {
          _profileImageUrl = imageUrl;
          _isLoading = false;
        });
        await SharedPreferenceHelper().saveUserProfile(imageUrl);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Color.fromARGB(255, 11, 156, 85),
            content: Text(
              "Tải hình lên thành công",
              style: TextStyle(fontSize: 18.0),
            )));
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Failed to upload image",
              style: TextStyle(fontSize: 18.0),
            )));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Error uploading profile image: $e",
            style: const TextStyle(fontSize: 18.0),
          )));
    }
  }

  Future<void> _saveName() async {
    setState(() {
      _isEditingName = false; // Exit editing mode
      name = _nameController.text; // Update name with the edited value
    });

    try {
      await SharedPreferenceHelper().saveUserName(name!); // Save to SharedPref
        // You may need to call a function here to update the name in Firestore as well if it's being stored there
       // await DatabaseMethods().updateName(name!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Color.fromARGB(255, 11, 156, 85),
        content: Text("Tên đã được cập nhật!", style: TextStyle(fontSize: 18.0)),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Lỗi khi cập nhật tên: $e",
            style: const TextStyle(fontSize: 18.0),
          )));
      
    }
  }

    Future<void> _resetPasswordDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Đặt Lại Mật Khẩu'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
               TextField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Mật khẩu hiện tại',
                  ),
                ),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Mật khẩu mới',
                  ),
                ),
                TextField(
                  controller: _confirmNewPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Xác nhận mật khẩu mới',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
             TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
                  _currentPasswordController.clear();
                  _newPasswordController.clear();
                  _confirmNewPasswordController.clear();
              },
            ),
            TextButton(
              child: const Text('Xác nhận'),
              onPressed: () async {
                if (_newPasswordController.text != _confirmNewPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        backgroundColor: Colors.red,
                        content: Text('Mật khẩu mới không khớp', style: TextStyle(fontSize: 18.0)),
                        ));
                    return;
                }
                Navigator.of(context).pop();
                _updatePassword();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updatePassword() async {
    String currentPassword = _currentPasswordController.text;
    String newPassword = _newPasswordController.text;
      User? user = await AuthMethods().getCurrentUser();
    try {
       if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                backgroundColor: Colors.red,
                content: Text("Không có người dùng đăng nhập.", style: TextStyle(fontSize: 18.0)),
              ));
          return;
        }
       await AuthMethods().reauthenticateUser(user, currentPassword);
       await user.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Color.fromARGB(255, 11, 156, 85),
            content: Text(
              "Mật khẩu đã được thay đổi thành công!",
              style: TextStyle(fontSize: 18.0),
            )));
             _currentPasswordController.clear();
                  _newPasswordController.clear();
                  _confirmNewPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Lỗi khi cập nhật mật khẩu: $e",
            style: const TextStyle(fontSize: 18.0),
          )));
    }
  }

  @override
  void initState() {
    onthisload();
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
     _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding:
                    const EdgeInsets.only(top: 45.0, left: 20.0, right: 20.0),
                height: MediaQuery.of(context).size.height / 4.3,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        
                        Color(0xFF1e3c72),
                        Color(0xFF64B5F6),
                      ],
                    ),
                    borderRadius: BorderRadius.vertical(
                        bottom: Radius.elliptical(
                            MediaQuery.of(context).size.width, 105.0))),
              ),
              Center(
                child: Container(
                  margin: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height / 6.5),
                  child: Material(
                    elevation: 10.0,
                    borderRadius: BorderRadius.circular(60),
                    child: Stack(children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: _profileImageUrl == null
                              ? Image.asset("images/boy.jpg",
                                  height: 120, width: 120, fit: BoxFit.cover)
                              : Image.network(_profileImageUrl!,
                                  height: 120, width: 120, fit: BoxFit.cover)),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickProfileImage,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(15)),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      )
                    ]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 70.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name ?? "Không có tên",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Popins'),
                    )
                  ],
                ),
              )
            ],
          ),
          const SizedBox(
            height: 20.0,
          ),
          Container(
             margin: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Material(
             borderRadius: BorderRadius.circular(10),
              elevation: 2.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 15.0,
                  horizontal: 10.0,
                ),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: Colors.black,
                    ),
                    const SizedBox(
                      width: 20.0,
                    ),
                     Expanded(
                      child: _isEditingName
                          ? TextFormField(
                            controller: _nameController,
                              decoration: const InputDecoration(
                                  hintText: 'Nhập tên mới',
                                  border: InputBorder.none
                                  ),
                            
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Họ tên",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  name ?? "Không có tên",
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w600),
                                )
                              ],
                            ),
                    ),
                    if (!_isEditingName)
                    IconButton(
                       icon: const Icon(Icons.edit),
                       onPressed: () {
                         setState(() {
                           _isEditingName = true; // Turn editing on
                         });
                       },
                      ),
                      if (_isEditingName)
                      IconButton(
                      icon: const Icon(Icons.save),
                        onPressed: _saveName,
                      ),

                  ],
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 20.0,
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Material(
              borderRadius: BorderRadius.circular(10),
              elevation: 2.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 15.0,
                  horizontal: 10.0,
                ),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(
                      Icons.email,
                      color: Colors.black,
                    ),
                    const SizedBox(
                      width: 20.0,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Email",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          email ?? "Không có email",
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 30.0,
          ),
          GestureDetector(
            onTap: () async {
              String? userId = await SharedPreferenceHelper().getUserId();
              print(
                  'ProfilePage: userId before navigating to OrderHistoryPage: $userId');
              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderHistoryPage(
                      userId: userId,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text("Lỗi: Không thể xác định thông tin người dùng.")));
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Material(
                borderRadius: BorderRadius.circular(10),
                elevation: 2.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 15.0,
                    horizontal: 10.0,
                  ),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.history,
                        color: Colors.black,
                      ),
                      SizedBox(
                        width: 30.0,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Lịch sử mua hàng",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 20.0,
                                fontWeight: FontWeight.w600),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 30.0,
          ),
           GestureDetector(
            onTap: () {
             _resetPasswordDialog(context);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Material(
                borderRadius: BorderRadius.circular(10),
                elevation: 2.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 15.0,
                    horizontal: 10.0,
                  ),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.lock_reset,
                        color: Colors.black,
                      ),
                      SizedBox(
                        width: 30.0,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Đặt lại mật khẩu",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 20.0,
                                fontWeight: FontWeight.w600),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 30.0,
          ),
          GestureDetector(
            onTap: () {
              print('ProfilePage: delete account button tapped');
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Xóa tài khoản"),
                      content: const Text(
                        "Bạn có chắc muốn xóa tài khoản này?",
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false); // Cancel
                          },
                          child: const Text("Hủy"),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop(true); // Confirm
                            if (context != null) {
                              await AuthMethods().deleteuser(context);
                              print(
                                  'ProfilePage: AuthMethods().deleteuser() called');
                            }
                          },
                          child: const Text("Xóa"),
                        ),
                      ],
                    );
                  }).then((value) {
                if (value == true) {
                  AuthMethods().deleteuser(context);
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Material(
                borderRadius: BorderRadius.circular(10),
                elevation: 2.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 15.0,
                    horizontal: 10.0,
                  ),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.delete,
                        color: Colors.black,
                      ),
                      SizedBox(
                        width: 30.0,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Xóa tài khoản",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 20.0,
                                fontWeight: FontWeight.w600),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 30.0,
          ),
          GestureDetector(
            onTap: () {
              print('ProfilePage: log out button tapped');
              AuthMethods().SignOut(context);
              print('ProfilePage: AuthMethods().signOut() called');
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Material(
                borderRadius: BorderRadius.circular(10),
                elevation: 2.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 15.0,
                    horizontal: 10.0,
                  ),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.logout,
                        color: Colors.black,
                      ),
                      SizedBox(
                        width: 30.0,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Đăng xuất",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 20.0,
                                fontWeight: FontWeight.w600),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }
}