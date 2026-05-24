// Gider modelidir.
// expenses tablosundan gelen gider kayıtlarını Flutter içinde kullanmak için oluşturuldu.
class ExpenseModel {
  // Gider id değeridir.
  final int id;

  // Gider başlığıdır.
  final String title;

  // Gider tutarıdır.
  final double amount;

  // Gider açıklamasıdır.
  final String? description;

  // Gider tarihidir.
  final String expenseDate;

  // Oluşturulma tarihidir.
  final String createdAt;

  // Constructor yapısıdır.
  const ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.description,
    required this.expenseDate,
    required this.createdAt,
  });

  // Backend'den gelen JSON verisini ExpenseModel nesnesine dönüştürür.
  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      title: json['title'],
      amount: double.parse(json['amount'].toString()),
      description: json['description'],
      expenseDate: json['expense_date'].toString(),
      createdAt: json['created_at'].toString(),
    );
  }
}