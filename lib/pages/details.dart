import 'package:appdatfood/service/database.dart';
import 'package:appdatfood/service/shared_pref.dart';
import 'package:appdatfood/widget/widget_support.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Model for review data
class Review {
  String userId;
  String userName;
  String comment;
  double rating;
  Timestamp timestamp;
  String id;


  Review({
    required this.userId,
    required this.userName,
    required this.comment,
    required this.rating,
    required this.timestamp,
    required this.id,
  });

  factory Review.fromMap(Map<String, dynamic> data, String id) {
    return Review(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      comment: data['comment'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
        timestamp: data['timestamp'],
      id: id,
    );
  }
}


class Details extends StatefulWidget {
  String image, name, detail, price;
  Details(
      {required this.detail,
        required this.image,
        required this.name,
        required this.price});

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  int a = 1;
  double total = 0.0;
  String? id;
  final currencyFormat =
  NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 3);
  double numericalPrice = 0.0;

  final TextEditingController _commentController = TextEditingController();
  double _rating = 0.0;

  // Giữ các đánh giá
  List<Review> _reviews = [];
  final ScrollController _scrollController = ScrollController();

  //Xem lại cập nhật
  late Stream<QuerySnapshot> _reviewStream;

  getthesharepref() async {
    id = await SharedPreferenceHelper().getUserId();
    setState(() {});
  }

  ontheload() async {
    await getthesharepref();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    ontheload();
    try {
      numericalPrice = double.parse(widget.price);
      total = numericalPrice;
    } catch (e) {
      print('Error parsing price: $e');
      numericalPrice = 0.0;
      total = 0.0;
    }
    //Khởi tạo đáng giá
    _reviewStream = FirebaseFirestore.instance
        .collection('food_reviews')
        .doc(widget.name)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots();

  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  void _submitReview() async {
    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text(
            "Vui lòng nhập bình luận",
            style: TextStyle(fontSize: 18.0),
          )),
      );
      return;
    }

    try {
      String? userName = await SharedPreferenceHelper().getUserName();
      await FirebaseFirestore.instance.collection('food_reviews').doc(widget.name).collection('reviews').add({
        'userId': id,
        'userName': userName,
        'comment': _commentController.text,
        'rating': _rating,
        'timestamp': Timestamp.now()

      });

      _commentController.clear();
      setState(() {
        _rating = 0.0; // Reset sao
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              backgroundColor: Colors.green,
              content: Text(
                "Đã thêm bình luận thành công",
                style: TextStyle(fontSize: 18.0),
              )));

    } catch (e) {
      print('Error submitting review: $e');
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
                "Có lỗi xảy ra khi gửi đánh giá",
                style: TextStyle(fontSize: 18.0),
              )),
      );
    }
  }
    Future<void> _editReview(Review review) async {
      _commentController.text = review.comment;
      setState(() {
        _rating = review.rating;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Chỉnh sửa bình luận"),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('Đánh giá: ', style: AppWidget.semiBooldTextFeildStyle()),
                    //Đánh giá sao
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return IconButton(
                            onPressed: () {
                              setState(() {
                                _rating = (index + 1).toDouble();
                              });
                            },
                            icon: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: Colors.orange,
                            ),
                          );
                        }),
                      ),
                    ),

                  ],
                ),
                 TextField(
            controller: _commentController,
            decoration: const InputDecoration(hintText: "Nhập bình luận của bạn"),
            maxLines: 3,
          ),
          ]),
          actions: [
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                _commentController.clear();
                Navigator.of(context).pop();
                  setState(() {
                    _rating = 0;
                  });
              },
            ),
            TextButton(
              child: const Text('Cập nhật'),
              onPressed: () async {
                  try{
                    await FirebaseFirestore.instance.collection('food_reviews').doc(widget.name).collection('reviews').doc(review.id).update({
                      'comment': _commentController.text,
                      'rating': _rating,

                    });
                    _commentController.clear();
                      setState(() {
                        _rating = 0;
                      });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        backgroundColor: Colors.green,
                        content: Text(
                          "Đã chỉnh sửa bình luận thành công",
                          style: TextStyle(fontSize: 18.0),
                        )));
                  }catch(e){
                      print('Error update review: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              backgroundColor: Colors.redAccent,
                              content: Text(
                                "Có lỗi xảy ra khi chỉnh sửa đánh giá",
                                style: TextStyle(fontSize: 18.0),
                              )));
                  }
              },
            )
          ],
        ),
      );
    }
  void _deleteReview(String reviewId) async {
    showDialog(context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa bình luận'),
        content: const Text('Bạn có chắc muốn xóa bình luận này?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () async {
                try{
                  await FirebaseFirestore.instance.collection('food_reviews').doc(widget.name).collection('reviews').doc(reviewId).delete();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      backgroundColor: Colors.green,
                      content: Text(
                        "Đã xóa bình luận thành công",
                        style: TextStyle(fontSize: 18.0),
                      )));
                }catch(e){
                  print('Error delete review: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            backgroundColor: Colors.redAccent,
                            content: Text(
                              "Có lỗi xảy ra khi xóa đánh giá",
                              style: TextStyle(fontSize: 18.0),
                            )));
                }

              },
              child: const Text('Xóa')),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Scrollable content
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
                child: Container(
                margin: const EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0, bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                          onTap: () {
                            {
                              Navigator.pop(context);
                            }
                          },
                          child: const Icon(
                            Icons.arrow_back_ios_new_outlined,
                            color: Colors.black,
                          )),
                      ClipRRect(
                        //Added ClipRRect to round corners
                        borderRadius: BorderRadius.circular(10),
                        // border radius of 10
                        child: Image.network(
                          widget.image,
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height / 2.5,
                          fit: BoxFit.fill,
                        ),
                      ),
                      const SizedBox(
                        height: 15.0,
                      ),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.name,
                                style: AppWidget.semiBooldTextFeildStyle(),
                              ),
                            ],
                          ),
                          const Spacer(), // khoang cach
                          GestureDetector(
                            onTap: () {
                              if (a > 1) {
                                --a;
                                total = total - numericalPrice;
                              }
                              setState(() {});
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Color(0xFF1e3c72),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(
                                Icons.remove,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 20.0,
                          ),
                          Text(
                            a.toString(),
                            style: AppWidget.semiBooldTextFeildStyle(),
                          ),
                          const SizedBox(
                            width: 20.0,
                          ),
                          GestureDetector(
                            onTap: () {
                              ++a;
                              total = total + numericalPrice;
                              setState(() {});
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Color(0xFF1e3c72),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20.0,
                      ),
                      Text(
                        widget.detail,
                        maxLines: 4,
                        style: AppWidget.LightTextFeildStyle(),
                      ),
                      const SizedBox(
                        height: 30.0,
                      ),
                      Row(
                        children: [
                          Text(
                            "Thời gian giao hàng",
                            style: AppWidget.semiBooldTextFeildStyle(),
                          ),
                          const SizedBox(
                            width: 25.0,
                          ),
                          const Icon(
                            Icons.alarm,
                            color: Colors.black54,
                          ),
                          const SizedBox(
                            height: 5.0,
                          ),
                          Text(
                            "30 phút",
                            style: AppWidget.semiBooldTextFeildStyle(),
                          )
                        ],
                      ),
                      const SizedBox(height: 20.0),

                      // Rating
                      Row(
                        children: [
                          Text('Đánh giá: ', style: AppWidget.semiBooldTextFeildStyle()),
                          // Rating Stars
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (index) {
                                return IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _rating = (index + 1).toDouble();
                                    });
                                  },
                                  icon: Icon(
                                    index < _rating ? Icons.star : Icons.star_border,
                                    color: Colors.orange,
                                  ),
                                );
                              }),
                            ),
                          ),

                        ],
                      ),

                      // Comment Input
                      TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(hintText: "Nhập bình luận của bạn"),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 10.0),
                      // Button to submit review
                      ElevatedButton(onPressed: _submitReview,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1e3c72),
                          ),
                          child: const Text('Gửi bình luận',style: TextStyle(color: Colors.white),)),
                      const SizedBox(height: 10.0),

                      // Existing Reviews
                      StreamBuilder<QuerySnapshot>(
                        stream: _reviewStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Text("Có lỗi khi tải bình luận");
                          }
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          // Get the documents
                          _reviews = snapshot.data!.docs
                              .map((doc) => Review.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                              .toList();


                          return  ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _reviews.length,
                              itemBuilder: (context, index) {
                                final review = _reviews[index];
                                return _buildReviewItem(review);
                              });
                        }
                      ),

                       const SizedBox(height: 10),
                  ],
                  ),
                ),

              ),
          ),
          // Fixed add to cart button
        Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Giá tiền",
                        style: AppWidget.semiBooldTextFeildStyle(),
                      ),
                      Text(
                        currencyFormat.format(total),
                        style: AppWidget.HeadlineTextFeildStyle(),
                      )
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      Map<String, dynamic> addFoodtoCart = {
                        "Name": widget.name,
                        "Quanlity": a.toString(),
                        "Price": widget.price,
                        "Image": widget.image
                      };
                      await DatabaseMethods().addFoodToCart(addFoodtoCart, id!);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          backgroundColor: Colors.orangeAccent,
                          content: Text(
                            "Đã thêm vào giỏi hàng",
                            style: TextStyle(fontSize: 18.0),
                          )));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF1e3c72),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Thêm vào giỏ hàng",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )
        )
        ],
      ),
    );
  }
  // Widget to build single review item
  Widget _buildReviewItem(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(
          children: [
            Text(
              review.userName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
             const SizedBox(width: 5,),
           Text(DateFormat('dd/MM/yyyy, hh:mm a').format(review.timestamp.toDate()), style: const TextStyle(color: Colors.grey),),
             const Spacer(),
            // Three-dot Menu
            PopupMenuButton<String>(
              onSelected: (String result) {
                if (result == 'edit') {
                  _editReview(review);
                } else if (result == 'delete') {
                  _deleteReview(review.id);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Sửa'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Xóa'),
                ),
              ],
            ),
          ],
        ),
          const SizedBox(height: 5),
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < review.rating ? Icons.star : Icons.star_border,
              color: Colors.orange,
              size: 18,
            );
          }),
        ),

          const SizedBox(height: 5),
          Text(review.comment,
            style: const TextStyle(fontSize: 15.0),
          )
        ],
      ),
    );
  }

}