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
    return await FirebaseFirestore.instance
        .collection(category)
        .add(foodInfoMap);
  }

  Future<Stream<QuerySnapshot>> getFoodItem(String name) async {
    return await FirebaseFirestore.instance.collection(name).snapshots();
  }

  Future addFoodToCart(Map<String, dynamic> userInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .collection("Cart")
        .add(userInfoMap);
  }

  Future<Stream<QuerySnapshot>> getFoodCart(String id) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .collection("Cart")
        .snapshots();
  }

  CardUserwallet(String id, String amount) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .update({"Wallet": amount});
  }

  Future<Stream<QuerySnapshot>> getUserWallet(String id) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .collection("Wallet")
        .snapshots();
  }

  // Method to clear the cart
  Future<void> clearCart(String userId) async {
    print("DatabaseMethods: clearCart called for user $userId");
    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('Cart');
    final cartSnapshot = await cartRef.get();

    // Delete each document in the cart
    for (final doc in cartSnapshot.docs) {
      await doc.reference.delete();
    }
    print("DatabaseMethods: clearCart completed for user $userId");
  }
  
   // Method to save order history
  Future<void> saveOrderHistory(String userId, List<Map<String, dynamic>> items, String total, String paymentMethod) async {
    print("DatabaseMethods: saveOrderHistory called for user $userId");
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('orders').add({
        "items": items,
        "total": total,
        "paymentMethod": paymentMethod,
         "orderTime": DateTime.now(),
      });
       print("DatabaseMethods: saveOrderHistory completed for user $userId");
  }

  // Method to get order history
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