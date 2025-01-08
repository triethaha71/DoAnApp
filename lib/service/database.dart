import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {

  
  Future addUserDetail(Map<String, dynamic> userInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .set(userInfoMap);
  }

  Future UpdateUserwallet(String id, String amount) async {
    print(
        'DatabaseMethods: UpdateUserwallet được gọi cho userId: $id with amount $amount');
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .get();
      if (userDoc.exists) {
        print('DatabaseMethods: UpdateUserwallet - người dùng tồn tại, cập nhật ví');
        return await FirebaseFirestore.instance
            .collection("users")
            .doc(id)
            .update({"Wallet": amount});
      } else {
        print(
            'DatabaseMethods: UpdateUserwallet - người dùng không tồn tại, đang tạo tài liệu mới');
        return await FirebaseFirestore.instance
            .collection('users')
            .doc(id)
            .set({'Wallet': amount});
      }
    } on FirebaseException catch (e) {
      print('DatabaseMethods: UpdateUserwallet - Lỗi: $e');
      throw e;
    }
  }

  Future AddFoodItem(Map<String, dynamic> foodInfoMap, String category) async {
    return await FirebaseFirestore.instance
        .collection(category)
        .add(foodInfoMap);
  }

  Stream<QuerySnapshot> getFoodItem(String name) {
    return FirebaseFirestore.instance.collection(name).snapshots();
  }

  Future addFoodToCart(Map<String, dynamic> userInfoMap, String id) async {
    print(
        "DatabaseMethods: addFoodToCart được gọi cho người dùng $id with item ${userInfoMap["Name"]}");
    try {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .collection('Cart');
      final querySnapshot =
          await cartRef.where('Name', isEqualTo: userInfoMap['Name']).get();

      if (querySnapshot.docs.isNotEmpty) {
        print(
            'DatabaseMethods: addFoodToCart - Sản phẩm đã tồn tại trong giỏ hàng, đang cập nhật số lượng.');
        final doc = querySnapshot.docs.first;
        int currentQuantity = int.tryParse(doc['Quanlity'] ?? '1') ?? 1;
        int newQuantity =
            currentQuantity + int.tryParse(userInfoMap['Quanlity'] ?? '1')!;
        return await cartRef.doc(doc.id).update({'Quanlity': newQuantity.toString()});
      } else {
        print(
            'DatabaseMethods: addFoodToCart - Sản phẩm không tồn tại trong giỏ hàng, đang tạo tài liệu mới.');
        return await cartRef.add(userInfoMap);
      }
    } on FirebaseException catch (e) {
      print('DatabaseMethods: addFoodToCart - Lỗi: $e');
      throw e;
    }
  }

  Future<Stream<QuerySnapshot>> getFoodCart(String id) async {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .collection("Cart")
        .snapshots();
  }

  Future CardUserwallet(String id, String amount) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .update({"Wallet": amount});
  }

  Future<Stream<DocumentSnapshot>> getUserWallet(String id) async {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .snapshots();
  }

  // Phương thức xóa giỏ hàng
  Future<void> clearCart(String userId) async {
    print("DatabaseMethods: clearCart được gọi cho người dùng $userId");
    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('Cart');
    final cartSnapshot = await cartRef.get();

    // Delete each document in the cart
    for (final doc in cartSnapshot.docs) {
      await doc.reference.delete();
    }
    print("DatabaseMethods: clearCart đã hoàn tất cho người dùng $userId");
  }

    // Phương pháp lưu lịch sử đơn hàng
  Future<void> saveOrderHistory(
      String userId,
      List<Map<String, dynamic>> items,
      String total,
      String paymentMethod,
      String deliveryAddress) async {
    print("DatabaseMethods: saveOrderHistory được gọi cho người dùng $userId");
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('orders')
        .add({
      "items": items,
      "total": total,
      "paymentMethod": paymentMethod,
      "orderTime": DateTime.now(),
      "deliveryAddress": deliveryAddress,
    });
    print("DatabaseMethods: saveOrderHistory đã hoàn tất cho người dùng $userId");
  }

  // Phương pháp để lấy lịch sử đơn hàng
  Future<Stream<QuerySnapshot>> getOrderHistory(String userId) async {
    print("DatabaseMethods: getOrderHistory called for user $userId");
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('orders')
        .orderBy('orderTime', descending: true)
        .snapshots();
  }
}