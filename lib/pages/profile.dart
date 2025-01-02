import 'dart:io';
import 'dart:convert';
import 'package:appdatfood/service/auth.dart';
import 'package:http/http.dart' as http;
import 'package:appdatfood/service/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

// Service for Imgur
class ImgurService {
  static const String clientId =
      "15f738ce9e52f01"; // Thay bằng Client ID của bạn
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

        // Lấy link ảnh từ JSON response
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


  getthesharedpref() async {
    profile = await SharedPreferenceHelper().getUserProfile();
    name = await SharedPreferenceHelper().getUserName();
    email = await SharedPreferenceHelper().getUserEmail();
    _profileImageUrl = await SharedPreferenceHelper().getUserProfile();
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: const Color.fromARGB(255, 11, 156, 85),
                  content: Text(
                    "Profile image has been updated successfully",
                    style: TextStyle(fontSize: 18.0),
                  )));
          } else {
              setState(() {
                  _isLoading = false;
                });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
                style: TextStyle(fontSize: 18.0),
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
        // Hủy các controller nếu có
      super.dispose();
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: EdgeInsets.only(top: 45.0, left: 20.0, right: 20.0),
                height: MediaQuery.of(context).size.height / 4.3,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Colors.black,
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
                    child: Stack(
                        children: [
                           ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                            child: _profileImageUrl == null
                              ? Image.asset("images/boy.jpg",
                                  height: 120, width: 120, fit: BoxFit.cover)
                              :Image.network(
                                    _profileImageUrl!,
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover
                                )
                             ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _pickProfileImage,
                                child: Container(
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(15)
                                  ),
                                  child: _isLoading ? CircularProgressIndicator(color: Colors.white,) : Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20,),
                                ),
                              ),
                            )
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 70.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name?? "Không có tên",
                      style: TextStyle(
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
          SizedBox(
            height: 20.0,
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20.0),
            child: Material(
              borderRadius: BorderRadius.circular(10),
              elevation: 2.0,
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: 15.0,
                  horizontal: 10.0,
                ),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: Colors.black,
                    ),
                    SizedBox(
                      width: 20.0,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Name",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          name ?? "Không có tên",
                          style: TextStyle(
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
          SizedBox(
            height: 20.0,
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20.0),
            child: Material(
              borderRadius: BorderRadius.circular(10),
              elevation: 2.0,
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: 15.0,
                  horizontal: 10.0,
                ),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Icon(
                      Icons.email,
                      color: Colors.black,
                    ),
                    SizedBox(
                      width: 20.0,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Email",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                           email ?? "Không có email",
                          style: TextStyle(
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
          SizedBox(
            height: 30.0,
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20.0),
            child: Material(
              borderRadius: BorderRadius.circular(10),
              elevation: 2.0,
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: 15.0,
                  horizontal: 10.0,
                ),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Icon(
                      Icons.description,
                      color: Colors.black,
                    ),
                    SizedBox(
                      width: 30.0,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Terms and Condition",
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
          SizedBox(
            height: 30.0,
          ),
          GestureDetector(
            onTap: (){
              AuthMethods().deleteuser();
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20.0),
              child: Material(
                borderRadius: BorderRadius.circular(10),
                elevation: 2.0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 15.0,
                    horizontal: 10.0,
                  ),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
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
                            "Delete Account",
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
          SizedBox(
            height: 30.0,
          ),
          GestureDetector(
            onTap: (){
              AuthMethods().SignOut();
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20.0),
              child: Material(
                borderRadius: BorderRadius.circular(10),
                elevation: 2.0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 15.0,
                    horizontal: 10.0,
                  ),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
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
                            "Log out",
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