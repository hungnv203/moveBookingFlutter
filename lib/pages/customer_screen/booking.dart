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

  @override
  void initState() {
    super.initState();
    _loadShowtimes();
  }

  Future<void> _loadShowtimes() async {
    var cinemas = await FirebaseFirestore.instance.collection("cinemas").get();

    Set<String> dates = {};
    Map<String, List<Map<String, dynamic>>> showtimeMap = {};

    for (var cinema in cinemas.docs) {
      var cinemaId = cinema.id;
      var screens = await FirebaseFirestore.instance
          .collection("cinemas")
          .doc(cinemaId)
          .collection("screens")
          .get();

      for (var screen in screens.docs) {
        var showtimes = await FirebaseFirestore.instance
            .collection("cinemas")
            .doc(cinemaId)
            .collection("screens")
            .doc(screen.id)
            .collection("showtimes")
            .where("movieId", isEqualTo: widget.movieId)
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
      appBar: AppBar(title: Text("Đặt vé")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hiển thị danh sách ngày chiếu
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
                      color: selectedDate == date ? Colors.blue : Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(date, style: TextStyle(color: Colors.white)),
                  ),
                );
              },
            ),
          ),

          // Hiển thị danh sách rạp chiếu theo ngày
          if (selectedDate != null)
            Expanded(
              child: ListView(
                children: cinemaShowtimes[selectedDate]!
                    .map((cinema) => Card(
                          margin: EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(cinema["cinemaName"]),
                            subtitle: Text(cinema["location"]),
                            onTap: () {
                              setState(() {
                                selectedCinema = cinema["cinemaId"];
                                selectedShowtime = null;
                              });
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),

          // Hiển thị danh sách giờ chiếu của rạp đã chọn
          if (selectedCinema != null)
            Wrap(
              children: cinemaShowtimes[selectedDate]!
                  .where((cinema) => cinema["cinemaId"] == selectedCinema)
                  .map((cinema) => Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedShowtime = cinema["showtimeId"];
                            });
                            // Chuyển sang màn hình chọn ghế
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SeatSelectionScreen(
                                  cinemaId: selectedCinema!,
                                  screenId: cinema["screenId"],
                                  showtimeId: selectedShowtime!,
                                  movieId: widget.movieId,
                                ),
                              ),
                            );
                          },
                          child: Text(cinema["time"]),
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}
