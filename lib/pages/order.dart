import 'dart:async';

import 'package:appdatfood/pages/PaymentOptionsPage.dart';
import 'package:appdatfood/service/database.dart';
import 'package:appdatfood/service/shared_pref.dart';
import 'package:appdatfood/widget/widget_support.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Order extends StatefulWidget {
  const Order({Key? key}) : super(key: key);

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  String? id, wallet;
  int total = 0;
  Timer? _timer;
  Stream? foodStream;
  List<DocumentSnapshot> cartItems = [];

  void startTimer() {
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> getthesharedpref() async {
    id = await SharedPreferenceHelper().getUserId();
    wallet = await SharedPreferenceHelper().getUserWallet();
    print('OrderPage: userId from shared pref: $id'); // Log userId
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> ontheload() async {
    await getthesharedpref();
    if (id == null) {
      print('OrderPage: Error - userId is null from shared pref');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Lỗi: Không thể xác định thông tin người dùng.")));
      return;
    }
    if (id != null) {
      // Check if id is not null
      foodStream = await DatabaseMethods().getFoodCart(id!);
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void initState() {
    ontheload();
    startTimer();
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _updateCartItemQuantity(DocumentSnapshot ds, int change) async {
    int currentQuantity = int.parse(ds["Quanlity"] ?? '1');
    int newQuantity = currentQuantity + change;

    if (newQuantity < 1) return;
    try {
      print(
          "OrderPage: _updateCartItemQuantity - Updating quantity for item ${ds.id}, currentQuantity: $currentQuantity, newQuantity: $newQuantity");
      await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .collection('Cart')
          .doc(ds.id)
          .update({
        "Quanlity": newQuantity.toString(),
      });
      print(
          "OrderPage: _updateCartItemQuantity - Quantity updated successfully for item ${ds.id}, newQuantity: $newQuantity");
      setState(() {
        total = cartItems.fold(
            0,
                (sum, doc) {
              int totalValue = int.tryParse(doc["Total"] ?? "0") ?? 0;
              int quantity = int.tryParse(doc["Quanlity"] ?? '1') ?? 1;
               return sum + totalValue * quantity;
            }
        );
      });
    } catch (e) {
      print('OrderPage: Error updating quantity $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error updating quantity")));
    }
  }

  Future<void> _deleteCartItem(DocumentSnapshot ds) async{
    print('OrderPage: _deleteCartItem called for item ${ds.id}');
     try{
        await FirebaseFirestore.instance.collection('users').doc(id).collection("Cart").doc(ds.id).delete();
        print('OrderPage: _deleteCartItem - Item ${ds.id} has been deleted successfully');
        setState(() {
          cartItems.remove(ds);
          total = cartItems.fold(
              0,
                  (sum, doc) {
                int totalValue = int.tryParse(doc["Total"] ?? "0") ?? 0;
                int quantity = int.tryParse(doc["Quanlity"] ?? '1') ?? 1;
                 return sum + totalValue * quantity;
              }
        );
      });
    } catch (e){
      print('OrderPage: Error deleting item $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error deleting item")));
    }

  }

  Widget foodCart() {
    return StreamBuilder(
      stream: foodStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        cartItems = snapshot.data.docs;
        
        // Calculate total price after data is available
        total = cartItems.fold(
            0,
                (sum, doc) {
              int totalValue = int.tryParse(doc["Total"] ?? "0") ?? 0;
              int quantity = int.tryParse(doc["Quanlity"] ?? '1') ?? 1;
               return sum + totalValue * quantity;
            }
        );
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
                  padding: EdgeInsets.only(right: 20.0),
                  child: Icon(Icons.delete, color: Colors.white,)),
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
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Text(ds["Quanlity"] ?? '1', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
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
                                "\$" + ds["Total"],
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
      appBar: AppBar(
        title: Text(
            "Food Cart",
          style: AppWidget.HeadlineTextFeildStyle(),
        ),
        centerTitle: true,
        elevation: 2.0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: (){
            print("OrderPage: IconButton - calling Navigator.pop()");
            Navigator.of(context).pop();
            print("OrderPage: IconButton - Navigator.pop() called");
          },
        ),
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
                    "Total Price",
                    style: AppWidget.semiBooldTextFeildStyle(),
                  ),
                  Text(
                    "\$" + total.toString(),
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
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10)),
                margin:
                    const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 30.0),
                child: const Center(
                    child: Text(
                  "Mua Hàng",
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