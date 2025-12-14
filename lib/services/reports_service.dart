import '../models/birth_record.dart';
import '../models/death_record.dart';
import 'package:intl/intl.dart';

class ReportData {
  final Map<String, int> monthlyBirths;
  final Map<String, int> monthlyDeaths;
  final Map<String, int> yearlyBirths;
  final Map<String, int> yearlyDeaths;
  final int totalBirths;
  final int totalDeaths;
  final Map<String, int> genderDistribution;
  final Map<String, int> causeDistribution;

  ReportData({
    required this.monthlyBirths,
    required this.monthlyDeaths,
    required this.yearlyBirths,
    required this.yearlyDeaths,
    required this.totalBirths,
    required this.totalDeaths,
    required this.genderDistribution,
    required this.causeDistribution,
  });
}

class ReportsService {
  // Generate monthly report
  static ReportData generateMonthlyReport({
    required List<BirthRecord> births,
    required List<DeathRecord> deaths,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month - 11, 1);
    final end = endDate ?? now;

    // Filter records by date range
    final filteredBirths = births.where((b) =>
        b.dateOfBirth.isAfter(start.subtract(const Duration(days: 1))) &&
        b.dateOfBirth.isBefore(end.add(const Duration(days: 1)))).toList();

    final filteredDeaths = deaths.where((d) =>
        d.dateOfDeath.isAfter(start.subtract(const Duration(days: 1))) &&
        d.dateOfDeath.isBefore(end.add(const Duration(days: 1)))).toList();

    // Monthly statistics
    final monthlyBirths = <String, int>{};
    final monthlyDeaths = <String, int>{};

    for (final birth in filteredBirths) {
      final monthKey = DateFormat('yyyy-MM').format(birth.dateOfBirth);
      monthlyBirths[monthKey] = (monthlyBirths[monthKey] ?? 0) + 1;
    }

    for (final death in filteredDeaths) {
      final monthKey = DateFormat('yyyy-MM').format(death.dateOfDeath);
      monthlyDeaths[monthKey] = (monthlyDeaths[monthKey] ?? 0) + 1;
    }

    // Yearly statistics
    final yearlyBirths = <String, int>{};
    final yearlyDeaths = <String, int>{};

    for (final birth in filteredBirths) {
      final yearKey = birth.dateOfBirth.year.toString();
      yearlyBirths[yearKey] = (yearlyBirths[yearKey] ?? 0) + 1;
    }

    for (final death in filteredDeaths) {
      final yearKey = death.dateOfDeath.year.toString();
      yearlyDeaths[yearKey] = (yearlyDeaths[yearKey] ?? 0) + 1;
    }

    // Gender distribution
    final genderDistribution = <String, int>{};
    for (final birth in filteredBirths) {
      genderDistribution[birth.gender] = (genderDistribution[birth.gender] ?? 0) + 1;
    }

    // Cause distribution (for deaths)
    final causeDistribution = <String, int>{};
    for (final death in filteredDeaths) {
      causeDistribution[death.cause] = (causeDistribution[death.cause] ?? 0) + 1;
    }

    return ReportData(
      monthlyBirths: monthlyBirths,
      monthlyDeaths: monthlyDeaths,
      yearlyBirths: yearlyBirths,
      yearlyDeaths: yearlyDeaths,
      totalBirths: filteredBirths.length,
      totalDeaths: filteredDeaths.length,
      genderDistribution: genderDistribution,
      causeDistribution: causeDistribution,
    );
  }

  // Generate annual report
  static ReportData generateAnnualReport({
    required List<BirthRecord> births,
    required List<DeathRecord> deaths,
    int? year,
  }) {
    final reportYear = year ?? DateTime.now().year;
    final startDate = DateTime(reportYear, 1, 1);
    final endDate = DateTime(reportYear, 12, 31, 23, 59, 59);

    return generateMonthlyReport(
      births: births,
      deaths: deaths,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Generate statistics report
  static Map<String, dynamic> generateStatisticsReport({
    required List<BirthRecord> births,
    required List<DeathRecord> deaths,
  }) {
    final report = generateMonthlyReport(
      births: births,
      deaths: deaths,
    );

    return {
      'totalBirths': report.totalBirths,
      'totalDeaths': report.totalDeaths,
      'totalRecords': report.totalBirths + report.totalDeaths,
      'monthlyBirths': report.monthlyBirths,
      'monthlyDeaths': report.monthlyDeaths,
      'yearlyBirths': report.yearlyBirths,
      'yearlyDeaths': report.yearlyDeaths,
      'genderDistribution': report.genderDistribution,
      'causeDistribution': report.causeDistribution,
    };
  }
}

