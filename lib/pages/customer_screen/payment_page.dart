import 'package:flutter/material.dart';

class PaymentPage extends StatefulWidget {
  final String bookingId;
  final double amount;
  const PaymentPage({super.key,required this.bookingId,required this.amount});
  @override
  State<PaymentPage> createState() => _PaymentPage();
   
}
class _PaymentPage extends State<PaymentPage>{

  @override
  Widget build(BuildContext context) {
    String qrData = "https://img.vietqr.io/image/MB-0334035492-compact.png?amount=${widget.amount}&addInfo=${widget.bookingId}";
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(title: Text("Thanh toán qua VietQR")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Quét mã QR để thanh toán"),
            SizedBox(height: 20),
            Image.network(qrData),
            SizedBox(height: 20),
            Text("Số tiền: ${widget.amount} VNĐ"),
            Text("Nội dung: ${widget.bookingId}"),
          ],
        ),
      ),
    );
  }
}