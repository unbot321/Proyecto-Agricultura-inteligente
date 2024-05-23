import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:app_semestre/models/Post.dart';
import 'package:flutter/material.dart';

class LikesScreen extends StatefulWidget {
  @override
  _LikesScreenState createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  List<Post> posts = [];
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    String? token = await storage.read(key: 'token');
    final postsResponse = await http.get(
      Uri.parse('http://10.0.2.2:8000/getLikedPosts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (postsResponse.statusCode == 200) {
      Map<String, dynamic> responseBody = jsonDecode(postsResponse.body);
      List<dynamic> fetchedPosts = responseBody['posts'];

      setState(() {
        posts = fetchedPosts.map((post) => Post.fromMap(post)).toList();
      });
    } else {
      print('Error al obtener los posts: ${postsResponse.body}');
    }
  }

  Future<void> toggleLike(String postId) async {
    String? token = await storage.read(key: 'token');
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/toggleLike/$postId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      fetchPosts();
    } else {
      print('Error al dar like: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: fetchPosts,
        child: posts.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: 400,
                  ),
                  Center(child: Text('Aun no le has dado like a ningun post')),
                ],
              )
            : ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  Uint8List imageBytes = base64Decode(post.image);
                  return Card(
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                "${post.username} ${post.isOwn ? '(Tú)' : ''} ",
                                style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                post.timestamp.toString(),
                                style: TextStyle(fontSize: 14.0),
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15.0),
                          child: Image.memory(imageBytes, fit: BoxFit.cover),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(post.bio),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            IconButton(
                              icon: Icon(Icons.thumb_up),
                              color: post.isLiked ? Colors.blue : Colors.grey,
                              onPressed: () {
                                toggleLike(post.id);
                              },
                            ),
                            Text(post.likes.toString()),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
