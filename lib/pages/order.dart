import 'dart:async';

import 'package:appdatfood/pages/PaymentOptionsPage.dart';
import 'package:appdatfood/service/database.dart';
import 'package:appdatfood/service/shared_pref.dart';
import 'package:appdatfood/widget/widget_support.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Order extends StatefulWidget {
  const Order({Key? key}) : super(key: key);

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  String? id, wallet;
  int total = 0;
  Stream<QuerySnapshot>? foodStream;
  List<DocumentSnapshot> cartItems = [];
  final currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 3);
  StreamSubscription? _cartSubscription;

  Future<void> getthesharedpref() async {
    id = await SharedPreferenceHelper().getUserId();
    wallet = await SharedPreferenceHelper().getUserWallet();
    print('Userid được lấy từ: $id');
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> ontheload() async {
    print('OrderPage: ontheload được gọi');
    await getthesharedpref();
    if (id == null) {
      print('OrderPage: Error - userId is null from shared pref');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Lỗi: Không thể xác định thông tin người dùng.")));
      return;
    }
      if (id != null) {
           foodStream = await DatabaseMethods().getFoodCart(id!);
        _cartSubscription = foodStream?.listen((snapshot) {
          if (snapshot != null && snapshot.docs != null) {
               print("OrderPage: ontheload - dữ liệu được nhận từ firestore, cập nhật UI");
              setState(() {
                 cartItems = snapshot.docs;
                  _calculateTotalPrice();
              });
          }
            else {
                  print("OrderPage: ontheload - Snapshot hoặc snapshot.docs là null.");
               }
            }, onError: (e) {
              print("OrderPage: ontheload - Đã xảy ra lỗi: $e");
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Đã có lỗi xảy ra: $e"),
                     backgroundColor: Colors.red,
                 ));
            });
      }
    }



  @override
  void initState() {
      super.initState();
      print('OrderPage: initState được gọi');
    ontheload();
  }

  @override
  void dispose() {
      print('OrderPage: xử lý được gọi');
    _cartSubscription?.cancel();
    super.dispose();
  }


  Future<void> _updateCartItemQuantity(DocumentSnapshot ds, int change) async {
    int currentQuantity = int.tryParse(ds["Quanlity"] ?? '1') ?? 1;
    int newQuantity = currentQuantity + change;

    if (newQuantity < 1) return;
    try {
      print(
          "OrderPage: _updateCartItemQuantity - Cập nhật số lượng cho mặt hàng ${ds.id}, currentQuantity: $currentQuantity, newQuantity: $newQuantity");
      await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .collection('Cart')
          .doc(ds.id)
          .update({
        "Quanlity": newQuantity.toString(),
      });
      print(
          "OrderPage: _updateCartItemQuantity - Số lượng đã được cập nhật thành công cho mặt hàng ${ds.id}, newQuantity: $newQuantity");
    } catch (e) {
      print('Trang đặt hàng: Lỗi cập nhật số lượng $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text("lỗi update số lượng")));
    }
  }

  Future<void> _deleteCartItem(DocumentSnapshot ds) async {
    print('OrderPage: _deleteCartItem được gọi cho mục ${ds.id}');
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .collection("Cart")
          .doc(ds.id)
          .delete();
      print(
          'Trang đặt hàng: _deleteCartItem - Mặt hàng ${ds.id} đã được xóa thành công');
    } catch (e) {
      print('OrderPage: Error deleting item $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error deleting item")));
    }
  }


   void _calculateTotalPrice() {
     int newTotal = 0;
     if (cartItems.isNotEmpty) {
        for (var doc in cartItems) {
           int price = int.tryParse(doc["Price"] ?? "0") ?? 0;
           int quantity = int.tryParse(doc["Quanlity"] ?? '1') ?? 1;
           newTotal += price * quantity;
       }
      }
    if (mounted) {
        setState(() {
          total = newTotal;
        });
      }
  }


  Widget foodCart() {
        return StreamBuilder<QuerySnapshot>(
          stream: foodStream,
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
             if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
             }
            if (snapshot.hasError) {
              print("OrderPage: foodCart - Ảnh chụp có lỗi ${snapshot.error}");
              return const Center(child: Text("Đã có lỗi xảy ra khi load giỏ hàng"));
            }
               if (cartItems.isEmpty) {
                  return const Center(child: Text("Giỏ hàng của bạn đang trống!"));
               }
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: cartItems.length,
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (context, index) {
                    DocumentSnapshot ds = cartItems[index];
                    return Dismissible(
                      key: Key(ds.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          child: const Icon(Icons.delete, color: Colors.white)),
                      onDismissed: (direction) {
                        _deleteCartItem(ds);
                      },
                      child: Container(
                        margin:
                        const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 10.0),
                        child: Material(
                          elevation: 5.0,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration:
                            BoxDecoration(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        _updateCartItemQuantity(ds, -1);
                                      },
                                      child: Container(
                                          height: 30,
                                          width: 30,
                                          decoration: BoxDecoration(
                                              border: Border.all(),
                                              borderRadius: BorderRadius.circular(8)),
                                          child: const Center(child: Text("-"))),
                                    ),
                                    Padding(
                                      padding:
                                      const EdgeInsets.symmetric(horizontal: 10.0),
                                      child: Text(
                                        ds["Quanlity"] ?? '1',
                                        style: const TextStyle(
                                            fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        _updateCartItemQuantity(ds, 1);
                                      },
                                      child: Container(
                                          height: 30,
                                          width: 30,
                                          decoration: BoxDecoration(
                                              border: Border.all(),
                                              borderRadius: BorderRadius.circular(8)),
                                          child: const Center(child: Text("+"))),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20.0),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: Image.network(
                                    ds["Image"],
                                    height: 90,
                                    width: 90,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 20.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ds["Name"],
                                        style: AppWidget.semiBooldTextFeildStyle(),
                                      ),
                                       Text(
                                        currencyFormat.format((int.tryParse(ds["Price"] ?? "0") ?? 0) * (int.tryParse(ds["Quanlity"] ?? '1') ?? 1)),
                                        style: AppWidget.semiBooldTextFeildStyle(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
             },
        );
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( //Nút back tự động các trang
        title: Text(
          "Giỏ Hàng",
          style: AppWidget.HeadlineTextFeildStyle(),
        ),
        centerTitle: true,
        elevation: 2.0,
        backgroundColor: Colors.white,
        //iconTheme: const IconThemeData(color: Colors.black),
         
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                height: MediaQuery.of(context).size.height / 2,
                child: foodCart()),
            const Spacer(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Tổng giá",
                    style: AppWidget.semiBooldTextFeildStyle(),
                  ),
                  Text(
                    currencyFormat.format(total),
                    style: AppWidget.semiBooldTextFeildStyle(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
            GestureDetector(
              onTap: () {
                if (id == null || wallet == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text("Lỗi: Không thể xác định thông tin người dùng.")));
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentOptionsPage(
                      cartItems: cartItems,
                      total: total,
                      userId: id!,
                      wallet: wallet!,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: const Color(0xFF1e3c72),
                    borderRadius: BorderRadius.circular(10)),
                margin:
                    const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 30.0),
                child: const Center(
                    child: Text(
                  "Thanh Toán",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold),
                )),
              ),
            )
          ],
        ),
      ),
    );
  }
}