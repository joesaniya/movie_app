class User {
  final int? id;
  final String email;
  final String firstName;
  final String lastName;
  final String avatar;
  final String? localId; // UUID for offline-created users

  User({
    this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.avatar,
    this.localId,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int?,
    email: json['email'] as String? ?? '',
    firstName: json['first_name'] as String? ?? '',
    lastName: json['last_name'] as String? ?? '',
    avatar: json['avatar'] as String? ?? '',
    localId: json['localId'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'avatar': avatar,
    'localId': localId,
  };

  String get fullName => '$firstName $lastName';
}

class CreateUserRequest {
  final String name;
  final String job;

  CreateUserRequest({required this.name, required this.job});

  factory CreateUserRequest.fromJson(Map<String, dynamic> json) =>
      CreateUserRequest(
        name: json['name'] as String,
        job: json['job'] as String,
      );

  Map<String, dynamic> toJson() => {'name': name, 'job': job};
}

class CreateUserResponse {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? avatar;
  final String? id;
  final String? createdAt;

  CreateUserResponse({
    this.firstName,
    this.lastName,
    this.email,
    this.avatar,
    this.id,
    this.createdAt,
  });

  factory CreateUserResponse.fromJson(Map<String, dynamic> json) =>
      CreateUserResponse(
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
        email: json['email'] as String?,
        avatar: json['avatar'] as String?,
        id: json['id'] as String?,
        createdAt: json['createdAt'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'avatar': avatar,
    'id': id,
    'createdAt': createdAt,
  };
}

class UsersResponse {
  final List<User> data;
  final int page;
  final int perPage;
  final int total;
  final int totalPages;

  UsersResponse({
    required this.data,
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });

  factory UsersResponse.fromJson(Map<String, dynamic> json) => UsersResponse(
    data:
        (json['data'] as List?)
            ?.map((e) => User.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    page: json['page'] as int? ?? 1,
    perPage: json['per_page'] as int? ?? 6,
    total: json['total'] as int? ?? 0,
    totalPages: json['total_pages'] as int? ?? 1,
  );

  Map<String, dynamic> toJson() => {
    'data': data.map((e) => e.toJson()).toList(),
    'page': page,
    'per_page': perPage,
    'total': total,
    'total_pages': totalPages,
  };
}
