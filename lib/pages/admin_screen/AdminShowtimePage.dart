import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_app/pages/admin_screen/AdminSeatPage.dart';

class AdminShowtimePage extends StatefulWidget {
  final String cinemaId;
  final String screenId;
  const AdminShowtimePage(
      {Key? key, required this.cinemaId, required this.screenId})
      : super(key: key);

  @override
  _AdminShowtimePageState createState() => _AdminShowtimePageState();
}

class _AdminShowtimePageState extends State<AdminShowtimePage> {
  final TextEditingController timeController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  String? selectedMovieId;
  List<Map<String, dynamic>> movies = [];
  @override
  void initState() {
    super.initState();
    fetchMovies();
  }
  Future<void> fetchMovies() async {
    var moviesSnapshot = await FirebaseFirestore.instance.collection('movies').get();
    for (var movie in moviesSnapshot.docs) {
      movies.add({
        'id': movie.id,
        'name': movie['name'],
      });
    }
    setState(() {
    });
  }



  // Thêm suất chiếu mới
  Future<void> addShowtime() async {
  
    if (selectedMovieId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Vui lòng chọn phim"),
      ));
      return;
    }
    var showtimeRef = FirebaseFirestore.instance
        .collection('cinemas')
        .doc(widget.cinemaId)
        .collection('screens')
        .doc(widget.screenId)
        .collection('showtimes')
        .doc();

    await showtimeRef.set({
      'time': timeController.text,
      'date': dateController.text,
      'movieId': selectedMovieId,
    });
    var numSeatsSnapshot = await FirebaseFirestore.instance.collection('cinemas').doc(widget.cinemaId).collection('screens').doc(widget.screenId).get();
    var numSeats = numSeatsSnapshot.data()?['seats'] ?? 0;
    // Tạo ghế ngồi cho suất chiếu
    for (var row in ['A', 'B', 'C', 'D']) {
      for (int num = 1; num <= numSeats/5; num++) {
        await showtimeRef.collection('seats').add({
          'seatNumber': "$row$num",
          'isBooked': false,
          'price': 50000.0,
        });
      }
    }

    timeController.clear();
    dateController.clear();
    setState(() {
      selectedMovieId = null;
    });
  }

  // Xóa suất chiếu
  Future<void> deleteShowtime(String showtimeId) async {
    var showtimeRef = FirebaseFirestore.instance
        .collection('cinemas')
        .doc(widget.cinemaId)
        .collection('screens')
        .doc(widget.screenId)
        .collection('showtimes')
        .doc(showtimeId);

    // Xóa tất cả ghế ngồi trước
    var seatsSnapshot = await showtimeRef.collection('seats').get();
    for (var seat in seatsSnapshot.docs) {
      await seat.reference.delete();
    }

    // Xóa suất chiếu
    await showtimeRef.delete();
    setState(() {
      
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quản lý Suất Chiếu")),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              
              children: [
                TextField(
                    controller: timeController,
                    decoration: InputDecoration(labelText: "Giờ chiếu")),
                TextField(
                    controller: dateController,
                    decoration: InputDecoration(labelText: "Ngày chiếu")),
                DropdownButtonFormField<String>(
                  value: selectedMovieId,
                  hint: Text("Chọn phim"),
                  onChanged: (String? value) {
                    setState(() {
                      selectedMovieId = value;
                    });
                  },
                  items: movies.map((movie) {
                    return DropdownMenuItem<String>(
                      value: movie['id'],
                      child: Row(
                        children: [
                          Text(movie['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                    onPressed: addShowtime, child: Text("Thêm Suất Chiếu")),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cinemas')
                  .doc(widget.cinemaId)
                  .collection('screens')
                  .doc(widget.screenId)
                  .collection('showtimes')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                var showtimes = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: showtimes.length,
                  itemBuilder: (context, index) {
                    var showtime = showtimes[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminSeatPage(
                              cinemaId: widget.cinemaId,
                              screenId: widget.screenId,
                              showtimeId: showtime.id,
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        title: Text(
                            "Giờ: ${showtime['time']} - Ngày: ${showtime['date']}"),
                        subtitle: Text("Phim ID: ${showtime['movieId']}"),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteShowtime(showtime.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
