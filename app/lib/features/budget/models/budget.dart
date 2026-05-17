class Budget {
  const Budget({
    required this.id,
    required this.userId,
    required this.monthlyLimit,
    required this.month,
    required this.year,
  });

  final String id;
  final String userId;
  final double monthlyLimit;
  final int month;
  final int year;

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        monthlyLimit: (json['monthly_limit'] as num).toDouble(),
        month: json['month'] as int,
        year: json['year'] as int,
      );
}
