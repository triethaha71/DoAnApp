import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:appdatfood/service/database.dart';
import 'package:appdatfood/widget/widget_support.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';

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

class AddFood extends StatefulWidget {
  const AddFood({super.key});

  @override
  State<AddFood> createState() => _AddFoodState();
}

class _AddFoodState extends State<AddFood> {
  final List<String> items = ['Ice-cream', 'Burger', 'Salad', 'Pizza'];
  String? value;
  TextEditingController namecontroller = TextEditingController();
  TextEditingController pricecontroller = TextEditingController();
  TextEditingController detailcontroller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;

  Future getImage() async {
    var image = await _picker.pickImage(source: ImageSource.gallery);
    selectedImage = File(image!.path);
    setState(() {});
  }

  // Hàm upload dữ liệu lên Firestore
  uploadItem() async {
    if (selectedImage != null &&
        namecontroller.text != "" &&
        pricecontroller.text != "" &&
        detailcontroller.text != "") {
      if (value == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Vui lòng chọn danh mục",
              style: TextStyle(fontSize: 18.0),
            )));
        return;
      }

      String? imageUrl = await ImgurService.uploadImageToImgur(selectedImage!);

      if (imageUrl != null) {
        String addId = randomAlphaNumeric(10);

        Map<String, dynamic> addItem = {
          "Image": imageUrl,
          "Name": namecontroller.text,
          "Price": pricecontroller.text,
          "Detail": detailcontroller.text,
          "Category": value, // Thêm trường Category
        };

        await DatabaseMethods().AddFoodItem(addItem, value!).then((_) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              backgroundColor: Color.fromARGB(255, 11, 156, 85),
              content: Text(
                "Đã thêm món ăn thành công",
                style: TextStyle(fontSize: 18.0),
              )));
          setState(() {
            namecontroller.clear();
            pricecontroller.clear();
            detailcontroller.clear();
            selectedImage = null;
            value = null;
          });
        }).catchError((e) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                "Không thể thêm món ăn",
                style: TextStyle(fontSize: 18.0),
              )));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Upload hình ảnh thất bại",
              style: TextStyle(fontSize: 18.0),
            )));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Vui lòng điền đầy đủ thông tin",
            style: TextStyle(fontSize: 18.0),
          )));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back_ios_new_outlined,
              color: Color(0xFF373866),
            )),
        centerTitle: true,
        title: Text(
          "Thêm sản phẩm",
          style: AppWidget.HeadlineTextFeildStyle(),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin:
              const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 50.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tải hình ảnh lên",
                style: AppWidget.semiBooldTextFeildStyle(),
              ),
              const SizedBox(
                height: 20.0,
              ),
              selectedImage == null
                  ? GestureDetector(
                      onTap: () {
                        getImage();
                      },
                      child: Center(
                        child: Material(
                          elevation: 4.0,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.black, width: 1.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 1.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(
                              selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
              const SizedBox(
                height: 30.0,
              ),
              Text(
                "Tên món ăn",
                style: AppWidget.semiBooldTextFeildStyle(),
              ),
              const SizedBox(
                height: 10.0,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: const Color(0xFFececf8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: namecontroller,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      //hintText: "Enter item name",
                      hintStyle: AppWidget.LightTextFeildStyle()),
                ),
              ),
              const SizedBox(
                height: 30.0,
              ),
              Text(
                "Giá",
                style: AppWidget.semiBooldTextFeildStyle(),
              ),
              const SizedBox(
                height: 10.0,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: const Color(0xFFececf8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: pricecontroller,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      //hintText: "Enter item price",
                      hintStyle: AppWidget.LightTextFeildStyle()),
                ),
              ),
              const SizedBox(
                height: 30.0,
              ),
              Text(
                "Mô tả",
                style: AppWidget.semiBooldTextFeildStyle(),
              ),
              const SizedBox(
                height: 10.0,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: const Color(0xFFececf8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  maxLines: 6,
                  controller: detailcontroller,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      //hintText: "Enter item detail",
                      hintStyle: AppWidget.LightTextFeildStyle()),
                ),
              ),
              const SizedBox(
                height: 20.0,
              ),
              Text(
                "Chọn danh mục",
                style: AppWidget.semiBooldTextFeildStyle(),
              ),
              const SizedBox(
                height: 20.0,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: const Color(0xFFececf8),
                    borderRadius: BorderRadius.circular(10)),
                child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                  items: items
                      .map((item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            style:
                                const TextStyle(fontSize: 18.0, color: Colors.black),
                          )))
                      .toList(),
                  onChanged: ((value) => setState(() {
                        this.value = value;
                      })),
                  dropdownColor: Colors.white,
                  hint: const Text("danh mục"),
                  iconSize: 36,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.black,
                  ),
                  value: value,
                )),
              ),
              const SizedBox(
                height: 30.0,
              ),
              GestureDetector(
                onTap: () {
                  uploadItem();
                },
                child: Center(
                  child: Material(
                    elevation: 5.0,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      width: 150,
                      decoration: BoxDecoration(
                        color: Color(0xFF1e3c72),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          "Thêm",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.0,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
