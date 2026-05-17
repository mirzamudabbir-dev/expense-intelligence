class Expense {
  const Expense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    this.note,
    required this.date,
    required this.paymentMethod,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final double amount;
  final String category;
  final String? note;
  final DateTime date;
  final String paymentMethod;
  final DateTime createdAt;

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        note: json['note'] as String?,
        date: DateTime.parse(json['date'] as String),
        paymentMethod: json['payment_method'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'amount': amount,
        'category': category,
        'note': note,
        'date': date.toIso8601String(),
        'payment_method': paymentMethod,
        'created_at': createdAt.toIso8601String(),
      };
}
