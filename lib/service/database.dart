import 'package:appdatfood/admin/add_food.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  Future addUserDetail(Map<String, dynamic> userInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .set(userInfoMap);
  }

  UpdateUserwallet(String id, String amount) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .update({"Wallet": amount});
  }

  Future AddFoodItem(Map<String, dynamic> foodInfoMap, String category) async {
    // Firestore API để lưu trữ dữ liệu trong danh mục (collection)
    // Đảm bảo đã thêm Firebase và Firestore vào dự án
    // Lưu ý: Sử dụng tên collection là danh mục
    return await FirebaseFirestore.instance
        .collection(category)
        .add(foodInfoMap);
  }
}
