import 'package:flutter/material.dart';
import '../models/birth_record.dart';
import '../models/death_record.dart';
import '../models/payment.dart';
import '../models/abn_application.dart';
import '../providers/records_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/abn_provider.dart';

/// Advanced Analytics Provider
/// Provides detailed analytics including payment trends, processing times, success rates, etc.
class AnalyticsProvider extends ChangeNotifier {
  final RecordsProvider _recordsProvider;
  final PaymentProvider _paymentProvider;
  final ABNProvider _abnProvider;

  AnalyticsProvider({
    required RecordsProvider recordsProvider,
    required PaymentProvider paymentProvider,
    required ABNProvider abnProvider,
  })  : _recordsProvider = recordsProvider,
        _paymentProvider = paymentProvider,
        _abnProvider = abnProvider;

  // Revenue Analytics
  Map<String, dynamic> getRevenueAnalytics({DateTime? startDate, DateTime? endDate}) {
    final payments = _paymentProvider.completedPayments;
    final filteredPayments = _filterByDateRange(payments, startDate, endDate);

    final totalRevenue = filteredPayments.fold<double>(0.0, (sum, p) => sum + p.amount);
    final averagePayment = filteredPayments.isEmpty ? 0.0 : totalRevenue / filteredPayments.length;

    // Revenue by payment type
    final revenueByType = <String, double>{};
    for (final payment in filteredPayments) {
      revenueByType[payment.paymentType] = (revenueByType[payment.paymentType] ?? 0.0) + payment.amount;
    }

    // Revenue by payment method
    final revenueByMethod = <String, double>{};
    for (final payment in filteredPayments) {
      revenueByMethod[payment.paymentMethod] = (revenueByMethod[payment.paymentMethod] ?? 0.0) + payment.amount;
    }

    // Monthly revenue trend
    final monthlyRevenue = <String, double>{};
    for (final payment in filteredPayments) {
      if (payment.paymentDate != null) {
        final monthKey = '${payment.paymentDate!.year}-${payment.paymentDate!.month.toString().padLeft(2, '0')}';
        monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] ?? 0.0) + payment.amount;
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'averagePayment': averagePayment,
      'totalPayments': filteredPayments.length,
      'revenueByType': revenueByType,
      'revenueByMethod': revenueByMethod,
      'monthlyRevenue': monthlyRevenue,
    };
  }

  // Application Success Rate (Birth Records)
  Map<String, dynamic> getApplicationSuccessRate({DateTime? startDate, DateTime? endDate}) {
    final births = _recordsProvider.births;
    final deaths = _recordsProvider.deaths;
    final filteredBirths = _filterBirthsByDateRange(births, startDate, endDate);
    final filteredDeaths = _filterDeathsByDateRange(deaths, startDate, endDate);

    // Birth records with approval workflow
    final totalBirthApplications = filteredBirths.length;
    final approvedBirthApplications = filteredBirths.where((b) => b.approvalStatus == 'approved').length;
    final rejectedBirthApplications = filteredBirths.where((b) => b.approvalStatus == 'rejected').length;
    final pendingBirthApplications = filteredBirths.where((b) => b.approvalStatus == 'pending').length;

    // Death records (all are considered registered)
    final totalDeathRecords = filteredDeaths.length;

    // Combined totals
    final totalApplications = totalBirthApplications + totalDeathRecords;
    final approvedApplications = approvedBirthApplications + totalDeathRecords; // Death records are auto-approved
    final rejectedApplications = rejectedBirthApplications;
    final pendingApplications = pendingBirthApplications;

    final successRate = totalApplications > 0
        ? (approvedApplications / totalApplications) * 100
        : 0.0;

    return {
      'totalApplications': totalApplications,
      'totalBirthApplications': totalBirthApplications,
      'totalDeathRecords': totalDeathRecords,
      'approved': approvedApplications,
      'approvedBirths': approvedBirthApplications,
      'rejected': rejectedApplications,
      'pending': pendingApplications,
      'successRate': successRate,
      'rejectionRate': totalApplications > 0 ? (rejectedApplications / totalApplications) * 100 : 0.0,
    };
  }

  // Average Processing Time
  Map<String, dynamic> getAverageProcessingTime({DateTime? startDate, DateTime? endDate}) {
    final births = _recordsProvider.births;
    final filteredBirths = _filterBirthsByDateRange(births, startDate, endDate);

    final processingTimes = <int>[]; // in days

    for (final birth in filteredBirths) {
      if (birth.approvedAt != null && birth.registrationDate != null) {
        final days = birth.approvedAt!.difference(birth.registrationDate!).inDays;
        if (days >= 0) {
          processingTimes.add(days);
        }
      }
    }

    if (processingTimes.isEmpty) {
      return {
        'averageDays': 0.0,
        'minDays': 0,
        'maxDays': 0,
        'medianDays': 0,
      };
    }

    processingTimes.sort();
    final average = processingTimes.reduce((a, b) => a + b) / processingTimes.length;
    final median = processingTimes[processingTimes.length ~/ 2];

    return {
      'averageDays': average,
      'minDays': processingTimes.first,
      'maxDays': processingTimes.last,
      'medianDays': median,
      'totalProcessed': processingTimes.length,
    };
  }

  // Peak Registration Periods
  Map<String, dynamic> getPeakRegistrationPeriods({DateTime? startDate, DateTime? endDate}) {
    final births = _recordsProvider.births;
    final deaths = _recordsProvider.deaths;
    final filteredBirths = _filterBirthsByDateRange(births, startDate, endDate);
    final filteredDeaths = _filterDeathsByDateRange(deaths, startDate, endDate);

    // By month
    final birthsByMonth = <String, int>{};
    final deathsByMonth = <String, int>{};

    for (final birth in filteredBirths) {
      final monthKey = '${birth.dateOfBirth.year}-${birth.dateOfBirth.month.toString().padLeft(2, '0')}';
      birthsByMonth[monthKey] = (birthsByMonth[monthKey] ?? 0) + 1;
    }

    for (final death in filteredDeaths) {
      final monthKey = '${death.dateOfDeath.year}-${death.dateOfDeath.month.toString().padLeft(2, '0')}';
      deathsByMonth[monthKey] = (deathsByMonth[monthKey] ?? 0) + 1;
    }

    // By day of week
    final birthsByDay = <String, int>{};
    final deathsByDay = <String, int>{};
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    for (final birth in filteredBirths) {
      final dayName = days[birth.dateOfBirth.weekday - 1];
      birthsByDay[dayName] = (birthsByDay[dayName] ?? 0) + 1;
    }

    for (final death in filteredDeaths) {
      final dayName = days[death.dateOfDeath.weekday - 1];
      deathsByDay[dayName] = (deathsByDay[dayName] ?? 0) + 1;
    }

    return {
      'birthsByMonth': birthsByMonth,
      'deathsByMonth': deathsByMonth,
      'birthsByDay': birthsByDay,
      'deathsByDay': deathsByDay,
    };
  }

  // Certificate Completion Rate (Birth & Death Records)
  Map<String, dynamic> getCertificateCompletionRate({DateTime? startDate, DateTime? endDate}) {
    final births = _recordsProvider.births;
    final deaths = _recordsProvider.deaths;
    final filteredBirths = _filterBirthsByDateRange(births, startDate, endDate);
    final filteredDeaths = _filterDeathsByDateRange(deaths, startDate, endDate);

    // Birth records
    final totalApprovedBirths = filteredBirths.where((b) => b.approvalStatus == 'approved').length;
    final birthCertificatesIssued = filteredBirths.where((b) => b.certificateIssued).length;
    final birthCertificatesCompleted = filteredBirths.where((b) => b.certificateApplicationCompleted).length;

    // Death records
    final totalDeathRecords = filteredDeaths.length;
    final deathCertificatesIssued = filteredDeaths.where((d) => d.certificateIssued).length;

    // Combined totals
    final totalApproved = totalApprovedBirths + totalDeathRecords;
    final certificatesIssued = birthCertificatesIssued + deathCertificatesIssued;
    final certificatesCompleted = birthCertificatesCompleted;

    return {
      'totalApproved': totalApproved,
      'totalApprovedBirths': totalApprovedBirths,
      'totalDeathRecords': totalDeathRecords,
      'certificatesIssued': certificatesIssued,
      'birthCertificatesIssued': birthCertificatesIssued,
      'deathCertificatesIssued': deathCertificatesIssued,
      'certificatesCompleted': certificatesCompleted,
      'completionRate': totalApproved > 0 ? (certificatesIssued / totalApproved) * 100 : 0.0,
      'applicationCompletionRate': totalApprovedBirths > 0 ? (certificatesCompleted / totalApprovedBirths) * 100 : 0.0,
    };
  }

  // Payment Completion Rate (Birth Records - Death records may not have payment workflow)
  Map<String, dynamic> getPaymentCompletionRate({DateTime? startDate, DateTime? endDate}) {
    final births = _recordsProvider.births;
    final filteredBirths = _filterBirthsByDateRange(births, startDate, endDate);

    final totalRequiringPayment = filteredBirths.where((b) => b.paymentRequired).length;
    final paymentsCompleted = filteredBirths.where((b) => b.paymentCompleted).length;

    return {
      'totalRequiringPayment': totalRequiringPayment,
      'paymentsCompleted': paymentsCompleted,
      'completionRate': totalRequiringPayment > 0 ? (paymentsCompleted / totalRequiringPayment) * 100 : 0.0,
    };
  }

  // Overall Records Statistics (Birth & Death Combined)
  Map<String, dynamic> getOverallRecordsStatistics({DateTime? startDate, DateTime? endDate}) {
    final births = _recordsProvider.births;
    final deaths = _recordsProvider.deaths;
    final filteredBirths = _filterBirthsByDateRange(births, startDate, endDate);
    final filteredDeaths = _filterDeathsByDateRange(deaths, startDate, endDate);

    final totalRecords = filteredBirths.length + filteredDeaths.length;
    final totalBirths = filteredBirths.length;
    final totalDeaths = filteredDeaths.length;

    // Gender distribution
    final maleBirths = filteredBirths.where((b) => b.gender?.toLowerCase() == 'male').length;
    final femaleBirths = filteredBirths.where((b) => b.gender?.toLowerCase() == 'female').length;
    final maleDeaths = filteredDeaths.where((d) => d.gender?.toLowerCase() == 'male').length;
    final femaleDeaths = filteredDeaths.where((d) => d.gender?.toLowerCase() == 'female').length;

    return {
      'totalRecords': totalRecords,
      'totalBirths': totalBirths,
      'totalDeaths': totalDeaths,
      'maleBirths': maleBirths,
      'femaleBirths': femaleBirths,
      'maleDeaths': maleDeaths,
      'femaleDeaths': femaleDeaths,
      'totalMales': maleBirths + maleDeaths,
      'totalFemales': femaleBirths + femaleDeaths,
    };
  }

  // Helper methods
  List<Payment> _filterByDateRange(List<Payment> items, DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) return items;

    return items.where((item) {
      if (item.paymentDate == null) return false;
      if (startDate != null && item.paymentDate!.isBefore(startDate)) return false;
      if (endDate != null && item.paymentDate!.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  List<BirthRecord> _filterBirthsByDateRange(List<BirthRecord> items, DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) return items;

    return items.where((item) {
      if (startDate != null && item.dateOfBirth.isBefore(startDate)) return false;
      if (endDate != null && item.dateOfBirth.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  List<DeathRecord> _filterDeathsByDateRange(List<DeathRecord> items, DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) return items;

    return items.where((item) {
      if (startDate != null && item.dateOfDeath.isBefore(startDate)) return false;
      if (endDate != null && item.dateOfDeath.isAfter(endDate)) return false;
      return true;
    }).toList();
  }
}
