import 'dart:convert';

class User {
  String user;
  String password;
  List<List<dynamic>> modelData;

  User({
    required this.user,
    required this.password,
    required this.modelData,
  });

  static User fromMap(Map<String, dynamic> user) {
    final decodedData = jsonDecode(user['model_data']) as List<dynamic>;
    final modelData = decodedData.map((item) => item as List<dynamic>).toList();
    return User(
      user: user['user'],
      password: user['password'],
      modelData: modelData,
    );
  }

  toMap() {
    return {
      'user': user,
      'password': password,
      'model_data': jsonEncode(modelData),
    };
  }
}
