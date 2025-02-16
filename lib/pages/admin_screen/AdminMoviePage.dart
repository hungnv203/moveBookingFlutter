import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_app/pages/admin_screen/AdminScreenPage.dart';
import 'package:my_app/pages/customer_screen/detail_page_film.dart';

class AdminMoviepage extends StatefulWidget {
  @override
  State<AdminMoviepage> createState() => _AdminMoivePageState();
}

class _AdminMoivePageState extends State<AdminMoviepage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController genreController = TextEditingController();

  // Thêm rạp phim vào Firestore
  Future<void> addCinema() async {
    await FirebaseFirestore.instance.collection('movies').add({
      'name': nameController.text,
      'duration': durationController.text,
      'imageUrl': imageUrlController.text,
      'genre': genreController.text,
      'fullDescription': descriptionController.text,
    });
    nameController.clear();
    durationController.clear();
    imageUrlController.clear();
    genreController.clear();
    descriptionController.clear();
    setState(() {});
  }

  // Cập nhật rạp phim
  Future<void> updateCinema(String id, String name, String duration,
      String imageUrl, String description, String genre) async {
    await FirebaseFirestore.instance.collection('movies').doc(id).update({
      'name': name,
      'duration': duration,
      'imageUrl': imageUrl,
      'fullDescription': description,
      'genre': genre,
    });
  }

  // Xóa rạp phim
  Future<void> deleteCinema(String id) async {
    await FirebaseFirestore.instance.collection('movies').doc(id).delete();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quản lý Rạp Phim")),
      body: Column(
        children: [
          // Form nhập thông tin rạp phim
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: "Tên phim")),
                TextField(
                    controller: durationController,
                    decoration: InputDecoration(labelText: "thời lượng")),
                TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: "Mô tả phim")),
                TextField(
                    controller: genreController,
                    decoration: InputDecoration(labelText: "Thể loại")),
                TextField(
                    controller: imageUrlController,
                    decoration: InputDecoration(labelText: "Link ảnh")),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: addCinema,
                  child: Text("Thêm Phim"),
                ),
              ],
            ),
          ),

          // Hiển thị danh sách rạp phim từ Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('movies').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                var movies = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    var movie = movies[index];
                    var id = movie.id;
                    var name = movie['name'] ?? 'null';
                    var genre = movie['genre'] ?? 'null';
                    var description = movie['fullDescription'] ?? 'null';
                    var duration = movie['duration'] ?? 'null';

                    return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailFilmPage(movieId: id),
                            ),
                          );
                        },
                        child: ListTile(
                          title: Text(name),
                          subtitle: Text(
                              "thời lượng: $duration - phòng chiếu : $genre "),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  nameController.text = name;
                                  genreController.text = genre;
                                  duration.text = duration;
                                  descriptionController.text = description;
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text("Chỉnh sửa Rạp"),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                              controller: nameController,
                                              decoration: InputDecoration(
                                                  labelText: "Tên phim")),
                                          TextField(
                                              controller: durationController,
                                              decoration: InputDecoration(
                                                  labelText: "thời lượng")),
                                          TextField(
                                              controller: descriptionController,
                                              decoration: InputDecoration(
                                                  labelText: "Mô tả phim")),
                                          TextField(
                                              controller: genreController,
                                              decoration: InputDecoration(
                                                  labelText: "Thể loại")),
                                          TextField(
                                              controller: imageUrlController,
                                              decoration: InputDecoration(
                                                  labelText: "Link ảnh")),
                                        ],
                                      ),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () {
                                            updateCinema(
                                                id,
                                                nameController.text,
                                                genreController.text,
                                                imageUrlController.text,
                                                descriptionController.text,
                                                durationController.text);
                                            Navigator.pop(context);
                                          },
                                          child: Text("Lưu"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deleteCinema(id),
                              ),
                            ],
                          ),
                        ));
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
