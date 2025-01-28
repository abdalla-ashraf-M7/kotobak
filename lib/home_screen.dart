import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BookController extends GetxController {
  var books = <Map<String, dynamic>>[
    {'id': '1', 'title': 'To Kill a Mockingbird', 'author': 'Harper Lee', 'progress': 0.75},
    {'id': '2', 'title': '1984', 'author': 'George Orwell', 'progress': 0.3},
    {'id': '3', 'title': 'Pride and Prejudice', 'author': 'Jane Austen', 'progress': 0.5},
  ].obs;

  void addBook(Map<String, dynamic> book) {
    books.add(book);
  }
}

final BookController bookController = Get.put(BookController());

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Library'),
      ),
      body: ListView.builder(
        itemCount: bookController.books.length,
        itemBuilder: (context, index) {
          final book = bookController.books[index];
          return GestureDetector(
            onTap: () => Get.toNamed('/reader', arguments: {'bookId': book['id']}),
            child: Card(
              margin: EdgeInsets.all(8.0),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Center(
                        child: Text(
                          book['title'][0],
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book['title'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            book['author'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          LinearProgressIndicator(
                            value: book['progress'],
                            backgroundColor: Colors.grey[300],
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/upload'),
        child: Icon(Icons.add),
      ),
    );
  }
}
