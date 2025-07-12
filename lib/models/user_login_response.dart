class UserLoginResponse {
  final String token;
  final String id;
  final String name;
  final String email;

  UserLoginResponse({
    required this.token,
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserLoginResponse.fromJson(Map<String, dynamic> json) {
    return UserLoginResponse(
      token: json['token'],
      id: json['user']['id'],
      name: json['user']['name'],
      email: json['user']['email'],
    );
  }
}
