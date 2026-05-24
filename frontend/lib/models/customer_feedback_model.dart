// QR menü müşteri geri bildirim modelidir.
class CustomerFeedbackModel {
  final int id;
  final String feedbackType;
  final String? customerName;
  final String? customerPhone;
  final int? tableNumber;
  final String message;
  final String status;
  final String? managerNote;
  final String createdAt;
  final String updatedAt;

  const CustomerFeedbackModel({
    required this.id,
    required this.feedbackType,
    this.customerName,
    this.customerPhone,
    this.tableNumber,
    required this.message,
    required this.status,
    this.managerNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerFeedbackModel.fromJson(Map<String, dynamic> json) {
    return CustomerFeedbackModel(
      id: int.parse(json['id'].toString()),
      feedbackType: json['feedback_type'].toString(),
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      tableNumber: json['table_number'] != null
          ? int.tryParse(json['table_number'].toString())
          : null,
      message: json['message'].toString(),
      status: json['status'].toString(),
      managerNote: json['manager_note']?.toString(),
      createdAt: json['created_at'].toString(),
      updatedAt: json['updated_at'].toString(),
    );
  }
}
