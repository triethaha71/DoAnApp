import 'dart:convert';
import 'package:appdatfood/service/database.dart';
import 'package:appdatfood/service/shared_pref.dart';
import 'package:appdatfood/widget/app_constant.dart';
import 'package:appdatfood/widget/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  String? wallet, id;
  int? add;
  TextEditingController amountcontroller = TextEditingController();
  final formatCurrency = NumberFormat.currency(locale: 'en_US', symbol: '\$');
  final formatCurrencyVND = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

// phương thức thanh toán đã chọn
  String? _selectedPaymentMethod;

  getthesharedpref() async {
    wallet = await SharedPreferenceHelper().getUserWallet();
    id = await SharedPreferenceHelper().getUserId();
    setState(() {});
  }

  ontheload() async {
    await getthesharedpref();
    setState(() {});
  }

  @override
  void initState() {
    ontheload();
    super.initState();
  }

  Map<String, dynamic>? paymentIntent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( ///Nút back về 1 cách tự động
        title: Center(
            child: const Text(
          'Ví của tôi',
          style: TextStyle(fontWeight: FontWeight.bold),
        )),
      ),
      body: wallet == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WalletBalanceCard(
                      balance: wallet!,
                      formatCurrency: formatCurrency,
                      formatCurrencyVND: formatCurrencyVND),
                  const SizedBox(height: 30),
                  Text(
                    "Lựa chọn",
                    style: AppTheme.getSemiBoldTextStyle(),
                  ),
                  const SizedBox(height: 20),
                  _buildOptionButtons(context),
                  const SizedBox(height: 30),
                  PaymentMethodSection(
                      selectedPaymentMethod: _selectedPaymentMethod,
                      onPaymentMethodChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value;
                        });
                      }),
                  const SizedBox(height: 30),
                  _buildDepositButton(context),
                ],
              ),
            ),
    );
  }


  Widget _buildOptionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildOptionButton(context, "50"),
        _buildOptionButton(context, "100"),
        _buildOptionButton(context, "500"),
        _buildOptionButton(context, "1000"),
      ],
    );
  }

  Widget _buildOptionButton(BuildContext context, String amount) {
    final formatCurrency =
        NumberFormat.currency(locale: 'en_US', symbol: '\$');
    return GestureDetector(
      onTap: () {
        _handlePayment(amount);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
            ),
          ],
        ),
        child: Text(
          formatCurrency.format(int.parse(amount)).replaceAll(".00", ""),
          style: AppTheme.getSemiBoldTextStyle(),
        ),
      ),
    );
  }

  Widget _buildDepositButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        openEdit();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
            color: const Color(0xFF1e3c72),
            borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.only(bottom: 0),
        child: const Center(
            child: Text(
          "Nạp tiền",
          style: TextStyle(
              color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
        )),
      ),
    );
  }

  void _handlePayment(String amount) {
    if (_selectedPaymentMethod == 'master_card') {
      makePayment(amount);
    } else if (_selectedPaymentMethod == 'zalo_pay') {
      makeZaloPayPayment(amount);
    } else {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          content: Text("Vui lòng chọn phương thức thanh toán"),
        ),
      );
    }
  }

  Future<void> makePayment(String amount) async {
    try {
      // Tạo ý định thanh toán
      paymentIntent = await createPaymentIntent(amount, 'USD');
      // Khởi tạo Bảng thanh toán
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent!['client_secret'],
          style: ThemeMode.dark,
          merchantDisplayName: 'Adnan',
        ),
      );
      // Hiển thị Bảng thanh toán
      await displayPaymentSheet(amount);
    } catch (e, s) {
      print('Exception in makePayment: $e$s');
    }
  }

  Future<void> makeZaloPayPayment(String amount) async {
    try {
      print("Zalo pay is clicked: $amount");
      add = int.parse(wallet!) + int.parse(amount);
      await SharedPreferenceHelper().saveUserWallet(add.toString());
      await DatabaseMethods().UpdateUserwallet(id!, add.toString());
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Text("Nạp tiền thành công!!"),
                ],
              ),
            ],
          ),
        ),
      );
      await getthesharedpref();
    } catch (e, s) {
      print('Exception in makeZaloPayPayment: $e$s');
    }
  }

  Future<void> displayPaymentSheet(String amount) async {
    try {
      await Stripe.instance.presentPaymentSheet();

      add = int.parse(wallet!) + int.parse(amount);
      await SharedPreferenceHelper().saveUserWallet(add.toString());
      await DatabaseMethods().UpdateUserwallet(id!, add.toString());

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Text("Nạp tiền thành công!!"),
                ],
              ),
            ],
          ),
        ),
      );

      await getthesharedpref();
      // Reset trạng thái
      paymentIntent = null; 
    } on StripeException catch (e) {
      print('Ngoại lệ Stripe: $e');
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          content: Text("Thanh toán đã bị hủy"),
        ),
      );
    } catch (e) {
      print('Ngoại lệ không xác định: $e');
    }
  }

  Future<Map<String, dynamic>> createPaymentIntent(
      String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currency,
        'payment_method_types[]': 'card',
      };

      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Không tạo được Ý định thanh toán');
      }
    } catch (err) {
      print('Lỗi khi tạo Ý định thanh toán: $err');
      throw Exception('Lỗi khi tạo Ý định thanh toán');
    }
  }

  String calculateAmount(String amount) {
    return (int.parse(amount) * 100).toString();
  }

  Future openEdit() => showDialog(
      context: context,
      builder: (context) => AlertDialog(
            content: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Icon(Icons.cancel,
                              size: 30, color: AppTheme.primaryColor),
                        ),
                        const Text("Nạp tiền",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: AppTheme.primaryColor)),
                        const SizedBox(width: 30),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text("Nhập mệnh giá", style: AppTheme.getSemiBoldTextStyle()),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountcontroller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          hintText: "Nhập số tiền muốn nạp"),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _handlePayment(amountcontroller.text);
                        },
                        child: const Text("Xác nhận"),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ));
}

class WalletBalanceCard extends StatefulWidget {
  const WalletBalanceCard({
    super.key,
    required this.balance,
    required this.formatCurrency,
    required this.formatCurrencyVND,
  });

  final String balance;
  final NumberFormat formatCurrency;
  final NumberFormat formatCurrencyVND;

  @override
  State<WalletBalanceCard> createState() => _WalletBalanceCardState();
}

class _WalletBalanceCardState extends State<WalletBalanceCard> {
  bool _showUSD = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wallet,
            size: 60,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(
            width: 20,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Số dư",
                  style: AppTheme.getLightTextStyle(),
                ),
                const SizedBox(
                  height: 5.0,
                ),
                Row(
                  children: [
                    Text(
                      _showUSD
                          ? widget.formatCurrency
                          .format(int.tryParse(widget.balance) ?? 0)
                          .replaceAll(".00", "")
                          : widget.formatCurrencyVND.format((int.tryParse(widget.balance) ?? 0) * 24000),
                      style: AppTheme.getBoldTextStyle(),
                    ),
                     const SizedBox(width: 5.0),
                    GestureDetector(
                        onTap: () {
                            setState(() {
                              _showUSD = !_showUSD;
                            });
                        },
                        child: const Text("≈",
                            style: TextStyle(
                                fontSize: 20.0
                            )
                        ),
                    ),
                    const SizedBox(width: 5.0),
                   if(_showUSD == true)
                      Text(
                        widget.formatCurrencyVND.format((int.tryParse(widget.balance) ?? 0) * 24000),
                        style: AppTheme.getLightTextStyle(),
                      )
                   else
                      Text(
                        widget.formatCurrency
                            .format(int.tryParse(widget.balance) ?? 0)
                            .replaceAll(".00", ""),
                        style: AppTheme.getLightTextStyle(),
                      )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class PaymentMethodSection extends StatelessWidget {
  const PaymentMethodSection({
    super.key,
    required String? selectedPaymentMethod,
    required this.onPaymentMethodChanged,
  }) : _selectedPaymentMethod = selectedPaymentMethod;

  final String? _selectedPaymentMethod;
  final Function(String?) onPaymentMethodChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Chọn phương thức thanh toán:",
              style: AppTheme.getSemiBoldTextStyle()),
          Row(
            children: [
              Radio<String>(
                value: 'zalo_pay',
                groupValue: _selectedPaymentMethod,
                onChanged: onPaymentMethodChanged,
                activeColor: AppTheme.primaryColor,
              ),
              const Text('Zalo Pay', style: TextStyle(fontSize: 17)),
              const SizedBox(width: 50),
               Image.asset('images/zalo_pay.png', width: 30, height: 30),
            ],
          ),
          SizedBox(height: 10,),
          Row(
            children: [
              Radio<String>(
                value: 'master_card',
                groupValue: _selectedPaymentMethod,
                onChanged: onPaymentMethodChanged,
                activeColor: AppTheme.primaryColor,
              ),
              const Text('Master Card', style: TextStyle(fontSize: 17)),
               const SizedBox(width: 20),
               Image.asset('images/master_card.png', width: 30, height: 30),
            ],
          ),
        ],
      ),
    );
  }
}