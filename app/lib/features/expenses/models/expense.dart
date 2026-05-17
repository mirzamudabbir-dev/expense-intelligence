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
  final String category; // maps to category_id in DB
  final String? note;
  final DateTime date;
  final String paymentMethod; // 'cash', 'upi', 'card'
  final DateTime createdAt;

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category_id'] as String,
        note: json['note'] as String?,
        date: DateTime.parse(json['date'] as String),
        paymentMethod: json['payment_method'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  // Excludes id and created_at — both are DB-generated.
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'amount': amount,
        'category_id': category,
        'note': note,
        'date':
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'payment_method': paymentMethod,
      };

  Expense copyWith({
    String? id,
    String? userId,
    double? amount,
    String? category,
    Object? note = _sentinel,
    DateTime? date,
    String? paymentMethod,
    DateTime? createdAt,
  }) =>
      Expense(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        note: note == _sentinel ? this.note : note as String?,
        date: date ?? this.date,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        createdAt: createdAt ?? this.createdAt,
      );
}

const Object _sentinel = Object();
