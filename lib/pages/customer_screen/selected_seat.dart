import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/pages/customer_screen/ticketPage.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String cinemaId;
  final String screenId;
  final String showtimeId;
  final String movieId;
  const SeatSelectionScreen({
    super.key,
    required this.cinemaId,
    required this.screenId,
    required this.showtimeId,
    required this.movieId
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  List<Map<String, dynamic>> seats = [];
  Set<String> selectedSeats = {}; // Ghế được chọn
  double totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSeats();
  }

  Future<void> _loadSeats() async {
    var seatDocs = await FirebaseFirestore.instance
        .collection("cinemas")
        .doc(widget.cinemaId)
        .collection("screens")
        .doc(widget.screenId)
        .collection("showtimes")
        .doc(widget.showtimeId)
        .collection("seats")
        .get();

    List<Map<String, dynamic>> loadedSeats = seatDocs.docs.map((doc) {
      return {
        "seatId": doc.id,
        "seatNumber": doc["seatNumber"], // Ex: "A1", "B2"
        "isBooked": doc["isBooked"],
      };
    }).toList();

    // 🔹 **Sắp xếp ghế theo hàng và số**
    loadedSeats.sort((a, b) {
      String seatA = a["seatNumber"];
      String seatB = b["seatNumber"];

      String rowA = seatA.substring(0, 1); // Lấy chữ cái đầu (A, B, C...)
      String rowB = seatB.substring(0, 1);

      int numA = int.parse(seatA.substring(1)); // Lấy số ghế (1, 2, 3...)
      int numB = int.parse(seatB.substring(1));

      if (rowA == rowB) {
        return numA.compareTo(numB); // Nếu cùng hàng, sắp xếp theo số
      }
      return rowA.compareTo(rowB); // Sắp xếp theo chữ cái
    });

    setState(() {
      seats = loadedSeats;
    });
  }

  void _toggleSeatSelection(String seatId) async {
    var seatdocs = await FirebaseFirestore.instance
        .collection('cinemas')
        .doc(widget.cinemaId)
        .collection('screens')
        .doc(widget.screenId)
        .collection('showtimes')
        .doc(widget.showtimeId)
        .collection('seats')
        .doc(seatId)
        .get();
    double seatPrice = seatdocs["price"];
    setState(() {
      if (selectedSeats.contains(seatId)) {
        selectedSeats.remove(seatId);
        totalPrice -= seatPrice;
      } else {
        totalPrice += seatPrice;
        selectedSeats.add(seatId);
      }
    });
  }

  void _confirmBooking() async {
    if (selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn ít nhất một ghế!")),
      );
      return;
    }

    var firestore = FirebaseFirestore.instance;

    // 🔹 Lấy thông tin chi tiết về rạp, phòng, suất chiếu
    var cinemaDoc =
        await firestore.collection("cinemas").doc(widget.cinemaId).get();
    var screenDoc = await firestore
        .collection("cinemas")
        .doc(widget.cinemaId)
        .collection("screens")
        .doc(widget.screenId)
        .get();
    var showtimeDoc = await firestore
        .collection("cinemas")
        .doc(widget.cinemaId)
        .collection("screens")
        .doc(widget.screenId)
        .collection("showtimes")
        .doc(widget.showtimeId)
        .get();
      var movieDoc=await firestore.collection("movies").doc(widget.movieId).get();
    String movieName = movieDoc["name"];
    String cinemaName = cinemaDoc["name"]; // Tên rạp
    String screenName = screenDoc["name"]; // Tên phòng
    String showtime = showtimeDoc["time"]; // Giờ chiếu
    String showDate = showtimeDoc["date"]; // Ngày chiếu

    // 🔹 Lấy danh sách số ghế đã chọn thay vì ID ghế
    List<String> selectedSeatNumbers = [];
    for (var seatId in selectedSeats) {
      var seatDoc = await firestore
          .collection("cinemas")
          .doc(widget.cinemaId)
          .collection("screens")
          .doc(widget.screenId)
          .collection("showtimes")
          .doc(widget.showtimeId)
          .collection("seats")
          .doc(seatId)
          .get();

      selectedSeatNumbers.add(seatDoc["seatNumber"]); // Lấy số ghế
    }

    // 🔹 Cập nhật trạng thái ghế trong Firestore
    for (var seatId in selectedSeats) {
      await firestore
          .collection("cinemas")
          .doc(widget.cinemaId)
          .collection("screens")
          .doc(widget.screenId)
          .collection("showtimes")
          .doc(widget.showtimeId)
          .collection("seats")
          .doc(seatId)
          .update({"isBooked": true});
    }

    // 🔹 Lưu thông tin đặt vé vào collection "bookings"
    await firestore.collection("bookings").add({
      "movieName":movieName,
      "cinemaName": cinemaName,
      "screenName": screenName,
      "showtime": showtime,
      "showDate": showDate,
      "seats": selectedSeatNumbers,
      "totalPrice": totalPrice,
      "paymentStatus": "Chưa thanh toán",
      "userId": FirebaseAuth.instance.currentUser!.uid, 
      "timestamp": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đặt vé thành công!")),
    );

    // 🔹 Chuyển hướng sau khi đặt vé
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chọn ghế")),
      body: seats.isEmpty
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.only(top: 150, left: 5, right: 5),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10, // Số ghế mỗi hàng
                crossAxisSpacing: 2,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: seats.length,
              itemBuilder: (context, index) {
                var seat = seats[index];
                bool isBooked = seat["isBooked"];
                bool isSelected = selectedSeats.contains(seat["seatId"]);

                return GestureDetector(
                  onTap: isBooked
                      ? null
                      : () => _toggleSeatSelection(seat["seatId"]),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isBooked
                          ? Colors.grey
                          : (isSelected ? Colors.blue : Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      seat["seatNumber"],
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _confirmBooking,
          child: Row(
            children: [
              Text("$totalPrice đ"),
              SizedBox(
                width: 100,
              ),
              Text("Xác nhận")
            ],
          ),
        ),
      ),
    );
  }
}
