import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_app/pages/customer_screen/selected_seat.dart';

class BookingScreen extends StatefulWidget {
  final String movieId;

  const BookingScreen({super.key, required this.movieId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String? selectedDate;
  String? selectedCinema;
  String? selectedShowtime;
  List<String> availableDates = [];
  Map<String, List<Map<String, dynamic>>> cinemaShowtimes = {};
  String movieName = "Đang tải...";

  @override
  void initState() {
    super.initState();
    _loadShowtimes();
    fetchMovieName();
  }

  Future<void> fetchMovieName() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('movies')
          .doc(widget.movieId)
          .get();
      if (doc.exists) {
        setState(() {
          movieName = doc["name"];
        });
      }
    } catch (e) {
      print("Lỗi khi lấy dữ liệu: $e");
    }
  }

  Future<void> _loadShowtimes() async {
    var cinemas = await FirebaseFirestore.instance.collection("cinemas").get();

    Set<String> dates = {};
    Map<String, List<Map<String, dynamic>>> showtimeMap = {};

    for (var cinema in cinemas.docs) {
      var cinemaId = cinema.id;
      var screens = await FirebaseFirestore.instance
          .collection("screens")
          .where('cinemaId', isEqualTo: cinemaId)
          .get();

      for (var screen in screens.docs) {
        var showtimes = await FirebaseFirestore.instance
            .collection("showtimes")
            .where("movieId", isEqualTo: widget.movieId)
            .where("screenId", isEqualTo: screen.id)
            .get();

        for (var showtime in showtimes.docs) {
          String date = showtime["date"];
          dates.add(date);

          showtimeMap.putIfAbsent(date, () => []);
          showtimeMap[date]!.add({
            "cinemaId": cinemaId,
            "cinemaName": cinema["name"],
            "location": cinema["location"],
            "showtimeId": showtime.id,
            "time": showtime["time"],
            "screenId": screen.id,
          });
        }
      }
    }

    setState(() {
      availableDates = dates.toList();
      cinemaShowtimes = showtimeMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(movieName, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: availableDates.isEmpty
          ? Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Danh sách ngày chiếu
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: availableDates.length,
                    itemBuilder: (context, index) {
                      String date = availableDates[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDate = date;
                            selectedCinema = null;
                            selectedShowtime = null;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.all(8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selectedDate == date
                                ? Colors.blueAccent
                                : Colors.grey[800],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            date,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Danh sách rạp chiếu theo ngày
                
                if (selectedDate != null)
                  Expanded(
                    child: ListView(
                      children: cinemaShowtimes[selectedDate]!
                          .map((cinema) => Card(
                                color: Colors.grey[850],
                                margin: EdgeInsets.all(8),
                                child: ExpansionTile(
                                  title: Text(
                                    cinema["cinemaName"],
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    cinema["location"],
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  iconColor: Colors.white,
                                  collapsedIconColor: Colors.white,
                                  children: [
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: cinemaShowtimes[selectedDate]!
                                          .where((item) =>
                                              item["cinemaId"] ==
                                              cinema["cinemaId"])
                                          .map((showtime) => ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.blueAccent,
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 10),
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          SeatSelectionScreen(
                                                        cinemaId: showtime[
                                                            "cinemaId"],
                                                        screenId: showtime[
                                                            "screenId"],
                                                        showtimeId: showtime[
                                                            "showtimeId"],
                                                        movieId: widget.movieId,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Text(showtime["time"],
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                              ))
                                          .toList(),
                                    ),
                                    SizedBox(
                                        height: 10), // Tạo khoảng cách dưới
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
              ],
            ),
    );
  }
}
