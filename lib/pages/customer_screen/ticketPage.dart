import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_app/pages/customer_screen/payment_page.dart';

class TicketPage extends StatefulWidget {
  const TicketPage({super.key});
  @override
  State<TicketPage> createState() => _TicketPage();
}

class _TicketPage extends State<TicketPage> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: AppBar(
          title: Text("Danh sách vé"),
        ),
        body: StreamBuilder(
            stream:
                FirebaseFirestore.instance.collection("bookings").snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text("bạn chưa đặt vé nào "),
                );
              }
              var bookings = snapshot.data!.docs;
              return ListView.builder(
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  var booking = bookings[index];
                  return Card(
                      margin: EdgeInsets.all(16),
                      child: GestureDetector(
                        child: ListTile(
                          leading: Icon(
                            Icons.movie,
                            color: Colors.blue,
                          ),
                          title: Text(
                            booking["movieName"],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Ghế ${booking["seats"]}"),
                              Text("Số tiền ${booking["totalPrice"]} VNĐ"),
                              Text(
                                "Thanh toán ${booking["paymentStatus"]}",
                                style: TextStyle(
                                    color: booking["paymentStatus"] ==
                                            "Chưa thanh toán"
                                        ? Colors.red
                                        : Colors.green),
                              ),
                              Text(
                                  "Thời gian : ${booking["showtime"]} ${booking["showDate"]}")
                            ],
                          ),
                          trailing: booking['paymentStatus'] ==
                                  "Chưa thanh toán"
                              ? ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context)=>PaymentPage(bookingId: booking.id, amount: booking["totalPrice"])));
                                  },
                                  child: Text("Thanh toán"),
                                )
                              : Icon(Icons.check_circle, color: Colors.green),
                        ),
                      ));
                },
              );
            }));
  }
}
