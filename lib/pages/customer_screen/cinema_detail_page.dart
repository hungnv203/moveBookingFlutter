import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_app/pages/customer_screen/detail_page_film.dart';

class CinemaDetailPage extends StatefulWidget {
  final String cinemaId;

  const CinemaDetailPage({Key? key, required this.cinemaId,}) : super(key: key);

  @override
  State<CinemaDetailPage> createState() => _CinemaDetailPageState();
}

class _CinemaDetailPageState extends State<CinemaDetailPage> {
  bool isLoading = true;
  List<String> availableDates = [];
  String selectedDate = ""; // Ngày được chọn
  List<String> showtimeHours = [];
  String selectedHour = ""; // Giờ chiếu được chọn
  List<Map<String, dynamic>> moviesList = [];

  @override
  void initState() {
    super.initState();
    fetchShowtimes();
  }

  Future<void> fetchShowtimes() async {
    try {
      var screensSnapshot = await FirebaseFirestore.instance
          .collection('cinemas')
          .doc(widget.cinemaId)
          .collection('screens')
          .get();

      Set<String> dates = {}; // Lưu danh sách ngày
      List<Map<String, dynamic>> tempMovies = [];

      for (var screen in screensSnapshot.docs) {
        var showtimesSnapshot = await screen.reference.collection('showtimes').get();

        for (var showtime in showtimesSnapshot.docs) {
          var date = showtime['date']; // Lấy ngày chiếu (vd: "2025-02-12")
          var hour = showtime['time']; // Lấy giờ chiếu (vd: "18:00")
          dates.add(date);

          var movieId = showtime['movieId'];
          var movieDoc = await FirebaseFirestore.instance.collection('movies').doc(movieId).get();

          if (movieDoc.exists) {
            tempMovies.add({
              'showtimeId': showtime.id,
              'time': hour,
              'date': date,
              'movieId': movieId,
              'movieName': movieDoc['name'],
              'posterUrl': movieDoc['imageUrl'],
            });
          }
        }
      }

      setState(() {
        availableDates = dates.toList()..sort(); // Sắp xếp ngày theo thứ tự
        selectedDate = availableDates.isNotEmpty ? availableDates.first : ""; // Mặc định chọn ngày đầu tiên
        moviesList = tempMovies;
        updateShowtimes(); // Cập nhật danh sách giờ chiếu
        isLoading = false;
      });
    } catch (e) {
      print("Lỗi khi tải suất chiếu: $e");
    }
  }

  void updateShowtimes() {
    setState(() {
      showtimeHours = moviesList
          .where((movie) => movie['date'] == selectedDate)
          .map((movie) => movie['time'] as String)
          .toSet()
          .toList()
        ..sort();
      selectedHour = showtimeHours.isNotEmpty ? showtimeHours.first : "";
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredMovies = moviesList
        .where((movie) => movie['date'] == selectedDate && movie['time'] == selectedHour)
        .toList(); // Lọc phim theo ngày & giờ

    return Scaffold(
      appBar: AppBar(title: Text("Chi tiết Rạp Phim")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Danh sách ngày chiếu
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
                            updateShowtimes(); // Cập nhật giờ chiếu khi đổi ngày
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedDate == date ? Colors.blueAccent : Colors.grey[800],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              date,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 10),

                // 🔹 Danh sách khung giờ
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: showtimeHours.length,
                    itemBuilder: (context, index) {
                      String hour = showtimeHours[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedHour = hour;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedHour == hour ? Colors.redAccent : Colors.grey[800],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              hour,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 10),

                // 🔹 Danh sách phim theo ngày & giờ
                Expanded(
                  child: filteredMovies.isEmpty
                      ? Center(child: Text("Không có phim nào cho thời gian này!", style: TextStyle(color: Colors.white)))
                      : ListView.builder(
                          itemCount: filteredMovies.length,
                          itemBuilder: (context, index) {
                            var movie = filteredMovies[index];
                            return Card(
                              margin: EdgeInsets.all(10),
                              child: ListTile(
                                leading: Image.network(
                                  movie['posterUrl'],
                                  width: 50,
                                  height: 75,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.broken_image, size: 50, color: Colors.grey);
                                  },
                                ),
                                title: Text(movie['movieName']),
                                subtitle: Text("Giờ: ${movie['time']} - Ngày: ${movie['date']}"),
                                trailing: Icon(Icons.arrow_forward),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailFilmPage(movieId: movie['movieId']),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
