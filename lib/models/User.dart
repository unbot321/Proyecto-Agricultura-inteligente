class User {
  String id;
  String name;
  String userName;
  String email;
  String? password;

  User(
      {required this.id,
      required this.name,
      required this.userName,
      required this.email,
      this.password});

  void setId(String id) {
    this.id = id;
  }

  void setName(String name) {
    this.name = name;
  }

  void setUserName(String userName) {
    this.userName = userName;
  }

  void setEmail(String email) {
    this.email = email;
  }

  void setPassword(String? password) {
    this.password = password;
  }

  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      id: data['id'],
      name: data['name'],
      userName: data['userName'],
      email: data['email'],
    );
  }
}
