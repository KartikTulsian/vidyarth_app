class ProfileModel {
  final String id;
  final String userId;
  final String fullName;
  final String? displayName;
  final String? phone;
  final String? avatarUrl;
  final String? schoolCollegeId;
  final String? created_at;
  final String? updated_at;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String? bio;
  final int? trust_score;
  final String? gender;

  ProfileModel({
    required this.id,
    required this.userId,
    required this.fullName,
    this.displayName,
    this.phone,
    this.avatarUrl,
    this.schoolCollegeId,
    this.created_at,
    this.updated_at,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.bio,
    this.trust_score,
    this.gender,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['profile_id']?.toString() ?? '', // Fix: provide fallback
      userId: map['user_id']?.toString() ?? '', // Fix: provide fallback
      fullName: map['full_name']?.toString() ?? 'New User', // Critical Fix
      displayName: map['display_name'],
      phone: map['phone'],
      avatarUrl: map['avatar_url'],
      schoolCollegeId: map['school_college_id'],
      created_at: map['created_at'],
      updated_at: map['updated_at'],
      address: map['address'],
      city: map['city'],
      state: map['state'],
      pincode: map['pincode'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      bio: map['bio'],
      trust_score: map['trust_score'] != null ? (map['trust_score'] as num).toInt() : 0,
      gender: map['gender'],
    );
  }

  Map<String, dynamic> toMap() => {
    'profile_id': id,
    'user_id': userId,
    'full_name': fullName,
    'display_name': displayName,
    'phone': phone,
    'avatar_url': avatarUrl,
    'school_college_id': schoolCollegeId,
    // 'created_at': created_at,
    // 'updated_at': updated_at,
    'address': address,
    'city': city,
    'state': state,
    'pincode': pincode,
    'latitude': latitude,
    'longitude': longitude,
    'bio': bio,
    'trust_score': trust_score,
    'gender': gender,
  };
}