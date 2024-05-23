class Post {
  String id;
  String uid;
  String username;
  String image;
  String bio;
  DateTime timestamp;
  bool isOwn;
  int likes;
  bool isLiked;

  Post({
    required this.id,
    required this.uid,
    required this.username,
    required this.image,
    required this.bio,
    required this.timestamp,
    required this.isOwn,
    required this.likes,
    required this.isLiked,
  });

  factory Post.fromMap(Map<String, dynamic> data) {
    return Post(
      id: data['_id'],
      uid: data['uid'],
      username: data['username'],
      image: data['image'],
      bio: data['bio'],
      timestamp: DateTime.parse(data['timestamp']),
      isOwn: data['isOwn'],
      likes: data['likes'],
      isLiked: data['isLiked'],
    );
  }

  void setLikes(int newLikes) {
    this.likes = newLikes;
  }

  void setIsLiked(bool newIsLiked) {
    this.isLiked = newIsLiked;
  }
}
