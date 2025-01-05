import 'package:appdatfood/service/database.dart';
import 'package:appdatfood/service/shared_pref.dart';
import 'package:appdatfood/widget/widget_support.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentOptionsPage extends StatefulWidget {
  final List<DocumentSnapshot> cartItems;
  final int total;
  final String userId;
  final String wallet;

  const PaymentOptionsPage({
    Key? key,
    required this.cartItems,
    required this.total,
    required this.userId,
    required this.wallet,
  }) : super(key: key);

  @override
  _PaymentOptionsPageState createState() => _PaymentOptionsPageState();
}

class _PaymentOptionsPageState extends State<PaymentOptionsPage> {
  String? selectedPaymentMethod;
  final currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Hóa đơn",
          style: AppWidget.HeadlineTextFeildStyle(),
        ),
        centerTitle: true,
        elevation: 2.0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: widget.cartItems.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = widget.cartItems[index];
                  return _buildCartItemCard(item);
                },
              ),
            ),
            const SizedBox(height: 16.0),
            _buildTotalSection(),
            const SizedBox(height: 24.0),
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                'Chọn phương thức thanh toán:',
                style: AppWidget.semiBooldTextFeildStyle(),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            _buildPaymentOptions(),
            const SizedBox(height: 20),
            _buildPaymentButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard(DocumentSnapshot item) {
    int price = int.tryParse(item["Price"] ?? "0") ?? 0;
    int quantity = int.tryParse(item["Quanlity"] ?? "1") ?? 1;
    return Material(
      elevation: 2.0,
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: Image.network(
                item['Image'],
                height: 80,
                width: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      Expanded(
                      child: Text(
                       item['Name'],
                       style: AppWidget.semiBooldTextFeildStyle(),
                      ),
                      ),
                      Align(
                       alignment: Alignment.centerRight,
                        child: Text(
                          'x$quantity',
                         style: AppWidget.semiBooldTextFeildStyle(),
                        ),
                      )
                    ],
                  ),
                  Text(
                    currencyFormat.format(price * quantity),
                    style: AppWidget.semiBooldTextFeildStyle(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Tổng cộng:",
          style: AppWidget.semiBooldTextFeildStyle(),
        ),
        Text(
          currencyFormat.format(widget.total),
          style: AppWidget.semiBooldTextFeildStyle(),
        ),
      ],
    );
  }

  Widget _buildPaymentOptions() {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('Thanh toán bằng ví'),
          value: 'wallet',
          groupValue: selectedPaymentMethod,
          onChanged: (value) => _updatePaymentMethod(value),
        ),
        RadioListTile<String>(
          title: const Text('Thanh toán khi nhận hàng'),
          value: 'cod',
          groupValue: selectedPaymentMethod,
          onChanged: (value) => _updatePaymentMethod(value),
        ),
      ],
    );
  }

  void _updatePaymentMethod(String? value) {
    setState(() {
      selectedPaymentMethod = value;
    });
  }

  Widget _buildPaymentButton() {
    return Center(
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: selectedPaymentMethod == null ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1e3c72),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Xác nhận',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    print(
        "PaymentOptionsPage: _processPayment called, selectedPaymentMethod: $selectedPaymentMethod");
    String message;
    if (selectedPaymentMethod == 'wallet') {
      int walletAmount = int.parse(widget.wallet);
      if (walletAmount < widget.total) {
        message = "Số tiền trong ví không đủ!";
        print(
            "PaymentOptionsPage: _processPayment - Wallet insufficient: walletAmount=$walletAmount, total=${widget.total}");
      } else {
        int amount = walletAmount - widget.total;
        print(
            "PaymentOptionsPage: _processPayment - Wallet payment processing: previousWallet=$walletAmount, total=${widget.total}, newWallet=$amount");
        await DatabaseMethods()
            .UpdateUserwallet(widget.userId, amount.toString());
        await SharedPreferenceHelper().saveUserWallet(amount.toString());
        print(
            "PaymentOptionsPage: _processPayment - Wallet updated, calling _saveOrderHistory and clearCart");
        // Lưu thông tin order vào Firestore
        await _saveOrderHistory();

        await DatabaseMethods().clearCart(widget.userId);
        Navigator.pop(context);
        message = "Thanh toán thành công bằng ví!";
      }
    } else {
      print(
          "PaymentOptionsPage: _processPayment - COD payment processing, calling _saveOrderHistory and clearCart");
      // Lưu thông tin order vào Firestore
      await _saveOrderHistory();
      await DatabaseMethods().clearCart(widget.userId);
       Navigator.pop(context);
      message = "Thanh toán khi nhận hàng thành công";
    }
    print("PaymentOptionsPage: _processPayment - Payment completed, message: $message");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveOrderHistory() async {
    print("PaymentOptionsPage: _saveOrderHistory called");
    print(
        'PaymentOptionsPage: userId before saveOrderHistory: ${widget.userId}'); // Log userId
    List<Map<String, dynamic>> items = widget.cartItems.map((item) {
      int price = int.tryParse(item["Price"] ?? "0") ?? 0;
      int quantity = int.tryParse(item["Quanlity"] ?? "1") ?? 1;
      return {
        'Name': item['Name'],
        'Total': currencyFormat.format(price * quantity),
        'Image': item['Image'],
        'Quanlity' : (item['Quanlity'] ?? "1").toString(),
         'Price': item['Price'],
      };
    }).toList();
    print("PaymentOptionsPage: _saveOrderHistory - items to be saved: $items");
    await DatabaseMethods().saveOrderHistory(
      widget.userId,
      items,
      currencyFormat.format(widget.total),
      selectedPaymentMethod!,
    );
     print("PaymentOptionsPage: _saveOrderHistory - order history saved");
  }
}