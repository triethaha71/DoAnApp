import 'package:appdatfood/service/database.dart';
import 'package:appdatfood/widget/widget_support.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderHistoryPage extends StatefulWidget {
  final String userId;
  const OrderHistoryPage({Key? key, required this.userId}) : super(key: key);

  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  Stream<QuerySnapshot>? orderStream;
  final currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 3);

  @override
  void initState() {
    print("OrderHistoryPage: initState được gọi cho người dùng ${widget.userId}");
    print('OrderHistoryPage: userId trong initState: ${widget.userId}');
    onthisload();
    super.initState();
  }

  Future<void> onthisload() async {
    print("OrderHistoryPage: onthisload được gọi cho người dùng ${widget.userId}");
    print('OrderHistoryPage: userId trong tải này: ${widget.userId}');
    orderStream = await DatabaseMethods().getOrderHistory(widget.userId);
    if (mounted) {
      print("OrderHistoryPage: onthisload - setState được gọi");
      setState(() {});
    }
  }

  Widget orderHistoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: orderStream,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        print("OrderHistoryPage: StreamBuilder - ảnh chụp nhanh: ${snapshot.toString()}");

        if (!snapshot.hasData) {
          print("OrderHistoryPage: StreamBuilder - Không có dữ liệu");
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print("OrderHistoryPage: StreamBuilder - Lỗi: ${snapshot.error}");
          return const Center(child: Text("Lỗi khi tải lịch sử đơn hàng"));
        }
        print("OrderHistoryPage: StreamBuilder - Dữ liệu có sẵn - ${snapshot.data!.docs.length} document(s)");
        final orderDocs = snapshot.data!.docs;
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: orderDocs.length,
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemBuilder: (context, index) {
            print("OrderHistoryPage: ListView.builder - Xử lý đơn hàng tại chỉ mục $index");
            final ds = orderDocs[index];
            final List<dynamic> items = ds["items"] as List;
            final String deliveryAddress = (ds.data() as Map<String, dynamic>)["deliveryAddress"] as String? ?? "Không có địa chỉ giao hàng";
            return Container(
              margin:
                  const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 10.0),
              child: Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hóa đơn",
                        style: AppWidget.semiBooldTextFeildStyle(),
                      ),
                      ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: items.length,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index1) {
                          print("OrderHistoryPage: ListView.builder(items) - index1 : $index1");
                          final item = items[index1];
                          //Get Quantity here
                          String quantity = item["Quanlity"] ?? "0";
                          int price = int.tryParse(item['Price'] ?? "0") ?? 0;
                          return Container(
                            margin: const EdgeInsets.only(top: 5.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: Image.network(
                                    item['Image'],
                                    height: 50,
                                    width: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 20.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(item["Name"] ?? "Tên không có",
                                              style:
                                                  AppWidget.semiBooldTextFeildStyle()),
                                          Text(
                                            "x$quantity",
                                            style: AppWidget.semiBooldTextFeildStyle(),
                                          ),
                                        ]
                                      ),
                                      Text(
                                          currencyFormat.format(price * (int.tryParse(quantity) ?? 1)),
                                          style: AppWidget.LightTextFeildStyle()
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                       RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: <TextSpan>[
                              TextSpan(text: 'Tổng: ', style: AppWidget.semiBooldTextFeildStyle()),
                              TextSpan(text: '${ds["total"]}', style:  AppWidget.LightTextFeildStyle()),
                            ],
                          ),
                        ),
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: <TextSpan>[
                            TextSpan(text: 'Địa chỉ giao hàng: ', style: AppWidget.semiBooldTextFeildStyle()),
                            TextSpan(text: deliveryAddress, style: AppWidget.LightTextFeildStyle()),
                          ],
                        ),
                      ),
                       RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: <TextSpan>[
                              TextSpan(text: 'Phương thức thanh toán: ', style: AppWidget.semiBooldTextFeildStyle()),
                              TextSpan(text: '${ds["paymentMethod"]}', style: AppWidget.LightTextFeildStyle()),
                            ],
                          ),
                        ),
                      
                    ],
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
        title: Center(child: Text("Lịch sử mua hàng", style: AppWidget.boldTextFeildStyle(),),),
      ),
      body: Container(
        padding: EdgeInsets.only(top: 20.0),
        child: orderHistoryList(),
      ),
    );
  }
}