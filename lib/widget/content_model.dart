class UnboardingContent {
  String images;
  String title;
  String desciption;
  UnboardingContent(
      {required this.desciption, required this.images, required this.title});
}

List<UnboardingContent> contents = [
  UnboardingContent(
      desciption: 'Chọn món ăn của bạn theo thực đơn\n                  Hơn 35 loại món ăn',
      images: "images/screen1.png",
      title: '    Menu chất lượng'),
  UnboardingContent(
      desciption: 'Bạn có thể thanh toán khi nhận hàng và\n                    thanh toán bằng thẻ',
      images: "images/screen2.png",
      title: 'Thanh toán dễ dàng và trực tuyến'),
  UnboardingContent(
      desciption: 'Giao hàng nhanh chóng và an toàn',
      images: "images/screen3.png",
      title: 'Giao đồ ăn tận nhà của bạn')
];
