// models/payslip_model.dart

class PayslipModel {
  final Map<String, dynamic> employeeInfo;
  final Map<String, dynamic> earnings;
  final Map<String, dynamic> deductions;
  final String netSalary;

  PayslipModel({
    required this.employeeInfo,
    required this.earnings,
    required this.deductions,
    required this.netSalary,
  });

  factory PayslipModel.fromJson(Map<String, dynamic> json) {
    return PayslipModel(
      employeeInfo: json['employeeInfo'] ?? {},
      earnings: json['earnings'] ?? {},
      deductions: json['deductions'] ?? {},
      netSalary: json['net_salary'] ?? '0',
    );
  }
}
