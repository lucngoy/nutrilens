class SpendingEntry {
  final int id;
  final String description;
  final double amount;
  final String category;
  final DateTime date;
  final DateTime createdAt;

  SpendingEntry({
    required this.id,
    required this.description,
    required this.amount,
    this.category = 'groceries',
    required this.date,
    required this.createdAt,
  });

  factory SpendingEntry.fromJson(Map<String, dynamic> json) => SpendingEntry(
        id: json['id'],
        description: json['description'],
        amount: double.parse(json['amount'].toString()),
        category: (json['category'] as String?) ?? 'groceries',
        date: DateTime.parse(json['date']),
        createdAt: DateTime.parse(json['created_at']),
      );
}

class MonthlyBudget {
  final int id;
  final String month;
  final double amount;
  final double totalSpent;
  final double remaining;
  final double percentageUsed;
  final double dailyBudget;
  final double avgDailySpent;
  final double projectedSpent;
  final String paceStatus; // on_track | warning | exceeded
  final List<SpendingEntry> entries;

  MonthlyBudget({
    required this.id,
    required this.month,
    required this.amount,
    required this.totalSpent,
    required this.remaining,
    required this.percentageUsed,
    this.dailyBudget = 0,
    this.avgDailySpent = 0,
    this.projectedSpent = 0,
    this.paceStatus = 'on_track',
    required this.entries,
  });

  factory MonthlyBudget.fromJson(Map<String, dynamic> json) => MonthlyBudget(
        id: json['id'],
        month: json['month'],
        amount: double.parse(json['amount'].toString()),
        totalSpent: double.parse(json['total_spent'].toString()),
        remaining: double.parse(json['remaining'].toString()),
        percentageUsed: double.parse(json['percentage_used'].toString()),
        dailyBudget: double.parse((json['daily_budget'] ?? 0).toString()),
        avgDailySpent: double.parse((json['avg_daily_spent'] ?? 0).toString()),
        projectedSpent: double.parse((json['projected_spent'] ?? 0).toString()),
        paceStatus: (json['pace_status'] as String?) ?? 'on_track',
        entries: (json['entries'] as List)
            .map((e) => SpendingEntry.fromJson(e))
            .toList(),
      );
}
