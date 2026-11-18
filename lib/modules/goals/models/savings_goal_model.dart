class SavingsGoalModel {
  final int? id;
  final String name;
  final double targetAmount;

  /// Optional deadline (ISO date). Null = no deadline.
  final String? targetDate;
  final String createdAt;

  const SavingsGoalModel({
    this.id,
    required this.name,
    required this.targetAmount,
    this.targetDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'target_amount': targetAmount,
    'target_date': targetDate,
    'created_at': createdAt,
  };

  factory SavingsGoalModel.fromMap(Map<String, dynamic> map) =>
      SavingsGoalModel(
        id: map['id'] as int?,
        name: (map['name'] ?? '') as String,
        targetAmount: (map['target_amount'] as num).toDouble(),
        targetDate: map['target_date'] as String?,
        createdAt: (map['created_at'] ?? '') as String,
      );
}

/// A goal together with how much has been saved towards it.
class GoalProgress {
  final SavingsGoalModel goal;
  final double saved;

  const GoalProgress({required this.goal, required this.saved});

  double get remaining => (goal.targetAmount - saved).clamp(0, double.infinity);

  /// 0.0 - 1.0 (for the progress bar).
  double get fraction => goal.targetAmount <= 0
      ? 0
      : (saved / goal.targetAmount).clamp(0.0, 1.0).toDouble();

  bool get isReached => saved >= goal.targetAmount;

  DateTime? get deadline =>
      goal.targetDate == null ? null : DateTime.tryParse(goal.targetDate!);

  /// Whole months left until the deadline (at least 1), or null if the goal
  /// has no deadline or the deadline has passed.
  int? get monthsLeft {
    final d = deadline;
    if (d == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = d.difference(today).inDays;
    if (days < 0) return null;
    final months = (days / 30.4).ceil();
    return months < 1 ? 1 : months;
  }

  bool get isOverdue {
    final d = deadline;
    if (d == null || isReached) return false;
    final now = DateTime.now();
    return d.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// How much to put aside every month to reach the goal on time.
  double? get monthlyNeeded {
    final months = monthsLeft;
    if (months == null || isReached) return null;
    return remaining / months;
  }
}

class GoalContributionModel {
  final int? id;
  final int goalId;

  /// Positive = money added, negative = money taken out.
  final double amount;
  final String date;
  final String? notes;
  final String createdAt;

  const GoalContributionModel({
    this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'goal_id': goalId,
    'amount': amount,
    'date': date,
    'notes': notes,
    'created_at': createdAt,
  };

  factory GoalContributionModel.fromMap(Map<String, dynamic> map) =>
      GoalContributionModel(
        id: map['id'] as int?,
        goalId: map['goal_id'] as int,
        amount: (map['amount'] as num).toDouble(),
        date: (map['date'] ?? '') as String,
        notes: map['notes'] as String?,
        createdAt: (map['created_at'] ?? '') as String,
      );
}
