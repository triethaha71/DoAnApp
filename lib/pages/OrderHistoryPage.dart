import 'package:appdatfood/service/database.dart';
import 'package:appdatfood/widget/widget_support.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderHistoryPage extends StatefulWidget {
  final String userId;
  const OrderHistoryPage({Key? key, required this.userId}) : super(key: key);

  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  Stream? orderStream;

  @override
  void initState() {
     print("OrderHistoryPage: initState called for user ${widget.userId}");
     print('OrderHistoryPage: userId in initState: ${widget.userId}');
    onthisload();
    super.initState();
  }

  Future<void> onthisload() async {
     print("OrderHistoryPage: onthisload called for user ${widget.userId}");
     print('OrderHistoryPage: userId in onthisload: ${widget.userId}');
    orderStream = await DatabaseMethods().getOrderHistory(widget.userId);
    if (mounted) {
       print("OrderHistoryPage: onthisload - setState called");
      setState(() {});
    }
  }

  Widget orderHistoryList() {
    return StreamBuilder(
      stream: orderStream,
      builder: (context, AsyncSnapshot snapshot) {
           print("OrderHistoryPage: StreamBuilder - snapshot: ${snapshot.toString()}");

        if (!snapshot.hasData) {
           print("OrderHistoryPage: StreamBuilder - No data");
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError){
          print("OrderHistoryPage: StreamBuilder - Error: ${snapshot.error}");
           return Center(child: Text("Error loading order history"));
        }
          print("OrderHistoryPage: StreamBuilder - Data available - ${snapshot.data!.docs.length} document(s)");
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: snapshot.data!.docs.length,
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemBuilder: (context, index) {
               print("OrderHistoryPage: ListView.builder - Processing order at index $index");
            DocumentSnapshot ds = snapshot.data!.docs[index];
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
                        itemCount: (ds["items"] as List).length,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index1) {
                           print("OrderHistoryPage: ListView.builder(items) - index1 : $index1");
                          var item = (ds["items"] as List)[index1];
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
                                      Text(item["Name"] ?? "Tên không có",
                                          style:
                                              AppWidget.semiBooldTextFeildStyle()),
                                      Text((item["Total"] ?? "0"),
                                          style:
                                              AppWidget.semiBooldTextFeildStyle()),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Text(
                        "Total: ${ds["total"]}",
                        style: AppWidget.semiBooldTextFeildStyle(),
                      ),
                       Text("Phương thức thanh toán: ${ds["paymentMethod"]}",
                        style: AppWidget.semiBooldTextFeildStyle(),
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