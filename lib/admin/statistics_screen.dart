import 'package:appdatfood/service/database.dart';
import 'package:appdatfood/widget/widget_support.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final List<String> foodCategories = ['Ice-cream', 'Burger', 'Salad', 'Pizza'];
  Map<String, int> categoryCounts = {};
  int totalFoodCount = 0;
  bool _isLoading = true; // Added loading state

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
       _isLoading = true;  // Start loading
     });
     Map<String, int> tempCounts = {};
    int total = 0;
  
    for (var category in foodCategories) {
      QuerySnapshot querySnapshot = await DatabaseMethods().getFoodItem(category).first;
      int count = querySnapshot.docs.length;
      tempCounts[category] = count;
      total += count;
    }
    setState(() {
      categoryCounts = tempCounts;
      totalFoodCount = total;
      _isLoading = false; // End loading
    });
  }


  @override
  Widget build(BuildContext context) {
      return Scaffold(
      appBar: AppBar(title: const Text("Statistics")),
        body: _isLoading ? const Center(child: CircularProgressIndicator()) : // Show loading indicator
         SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
              child: Text(
                "Thống kê",
                style: AppWidget.HeadlineTextFeildStyle(),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
                'Tổng số món ăn: $totalFoodCount',
                 style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold
                ),
            ),
            const SizedBox(height: 20),
            ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                itemCount: foodCategories.length,
                  itemBuilder: (context, index) {
                     final category = foodCategories[index];
                     final count = categoryCounts[category] ?? 0;

                   return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                   child: Padding(
                    padding: const EdgeInsets.all(16.0),
                   child:Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text(category,
                          style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500
                        ),
                      ),
                      Text('$count món',
                           style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500
                          ),
                      )
                    ],
                    )
                   )
                   );
              },
           ),
           const SizedBox(height: 20.0),
           const Text("Thống kê doanh thu",
             style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 20.0),
             StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('Orders').snapshots(),
                 builder: (context, snapshot) {
                   if (snapshot.hasError) {
                      return const Text('Có lỗi xảy ra');
                  }

                   if (snapshot.connectionState == ConnectionState.waiting) {
                   return const Center(child: CircularProgressIndicator());
                  }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text('Không có đơn đặt hàng');
                      }
                  return _buildRevenueSection(snapshot.data!.docs);
                 }
              ),
            ]
          ),
        )
    );
  }


  Widget _buildRevenueSection(List<DocumentSnapshot> orderDocs) {
    double totalRevenue = 0;
    
   for (var doc in orderDocs) {
     Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
     totalRevenue += data['totalPrice'];
   }
   
   return Column(
      children: [
          Text(
            'Tổng doanh thu: ${NumberFormat("#,###", "vi_VN").format(totalRevenue)} VNĐ',
            style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold,
            ),
        ),
        const SizedBox(height: 20.0),
        _buildMonthlyRevenueChart(orderDocs),
      ],
   );
  }


    Widget _buildMonthlyRevenueChart(List<DocumentSnapshot> orderDocs) {
        Map<String, double> monthlyRevenue = {};

       for(var doc in orderDocs){
          Map<String, dynamic> orderData = doc.data() as Map<String, dynamic>;
             Timestamp timeStamp = orderData["date"] as Timestamp;
             DateTime orderDate = timeStamp.toDate();
              String monthYear = DateFormat('MM-yyyy').format(orderDate);

              if (monthlyRevenue.containsKey(monthYear)) {
                 monthlyRevenue[monthYear] =  monthlyRevenue[monthYear]! + orderData["totalPrice"];
             } else {
                  monthlyRevenue[monthYear] = orderData["totalPrice"];
              }
       }

    if (monthlyRevenue.isEmpty) {
      return const Text('Không có dữ liệu doanh thu hàng tháng');
    }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: monthlyRevenue.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                       entry.key,
                       style: const TextStyle(
                       fontSize: 16, fontWeight: FontWeight.w500
                        ),
                    ),
                    Text(
                      '${NumberFormat("#,###", "vi_VN").format(entry.value)} VNĐ',
                         style: const TextStyle(
                       fontSize: 16, fontWeight: FontWeight.w500
                        ),
                    ),
                 ],
              ),
            );
          }).toList(),
    );
 }
}