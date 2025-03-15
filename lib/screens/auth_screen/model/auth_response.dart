class AuthResponse {
  String? accessToken;
  int? expiresIn;
  String? tokenType;
  String? message;
   int? id;
   int? branchId;
  String? branchName;


  AuthResponse({
    this.accessToken,
    this.expiresIn,
    this.tokenType,
    this.message,
    this.id, this.branchId, this.branchName});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      expiresIn: json['expires_in'],
      tokenType: json['token_type'],
      id: json['id'] ?? json['user_id'],
      branchId: json['branchId'] ?? json['branch_id'],
      branchName: json['branchName'] ?? json['branch_name'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'expires_in': expiresIn,
      'token_type': tokenType,
      'id': id,
      'branchId': branchId,
      'branchName': branchName,
    };
  }

  @override
  String toString() {
    return 'AuthResponse{accessToken: $accessToken, expiresIn: $expiresIn, tokenType: $tokenType}';
  }
}