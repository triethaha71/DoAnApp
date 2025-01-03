import 'package:appdatfood/admin/add_food.dart';
import 'package:appdatfood/admin/edit_food.dart';
import 'package:appdatfood/service/database.dart';
import 'package:appdatfood/widget/widget_support.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({Key? key}) : super(key: key);

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  // List of food categories
  final List<String> foodCategories = ['Ice-cream', 'Burger', 'Salad', 'Pizza'];
 final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        margin: const EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0),
        child: Column(
          children: [
            Center(
              child: Text(
                "Danh sách quan lí",
                style: AppWidget.HeadlineTextFeildStyle(),
              ),
            ),
            const SizedBox(height: 50.0),
            GestureDetector(
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => AddFood()));
              },
              child: Material(
                elevation: 10.0,
                borderRadius: BorderRadius.circular(10),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Image.asset(
                            "images/food.jpg",
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 30.0),
                        const Text(
                          "Thêm sản phẩm",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Expanded(
              child: ListView.builder(
                itemCount: foodCategories.length,
                itemBuilder: (context, index) {
                  return _buildCategoryCard(foodCategories[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String category) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            StreamBuilder<QuerySnapshot>(
              stream: DatabaseMethods().getFoodItem(category),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Something went wrong: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No items found in this category.');
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                     childAspectRatio: 0.8,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot document = snapshot.data!.docs[index];
                    Map<String, dynamic> foodItemData =
                        document.data() as Map<String, dynamic>;
                    return _buildFoodItemCard(
                        document.id, foodItemData, category);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItemCard(
      String documentId, Map<String, dynamic> foodItemData, String category) {
    return Card(
        elevation: 3.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                  child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          foodItemData['Image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.error_outline, size: 50);
                          },
                        ),
                      )
                  )
              ),
              const SizedBox(height: 8.0),
              Text(
                foodItemData['Name'],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${foodItemData['Price']}đ',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      _navigateToEditScreen(documentId, foodItemData, category);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _deleteFoodItem(documentId, category);
                    },
                  ),
                ],
              )
            ],
          ),
        )
    );
  }

  void _navigateToEditScreen(
      String documentId, Map<String, dynamic> foodItemData, String category) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditFood(
                documentId: documentId,
                foodItemData: foodItemData,
                category: category)));
  }

  void _deleteFoodItem(String documentId, String category) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: const Text("Xóa món ăn")),
          content: const Text("Bạn có chăc muốn xóa không"),
          actions: <Widget>[
            TextButton(
              child: const Text("Không"),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss dialog
              },
            ),
            TextButton(
              child: const Text("Có"),
              onPressed: () async {
                Navigator.of(context).pop(); // Dismiss dialog
                try {
                  await FirebaseFirestore.instance
                      .collection(category)
                      .doc(documentId)
                      .delete();
                  ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(const SnackBar(
                      backgroundColor: Colors.green,
                      content: Text("Món ăn đã được xóa thành cồn")));
                } catch (e) {
                  ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(SnackBar(
                      backgroundColor: Colors.red,
                      content: Text("Failed to delete: $e")));
                }
              },
            ),
          ],
        );
      },
    );
  }
}