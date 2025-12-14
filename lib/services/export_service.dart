import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/birth_record.dart';
import '../models/death_record.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class ExportService {
  // Export birth records to CSV
  static Future<String> exportBirthsToCSV(List<BirthRecord> records) async {
    try {
      final buffer = StringBuffer();
      
      // Header
      buffer.writeln('ID,Child Name,Gender,Date of Birth,Place of Birth,'
          'Father Name,Father National ID,Mother Name,Mother National ID,'
          'Registration Number,Registration Date,Registrar');
      
      // Data rows
      final dateFormat = DateFormat('yyyy-MM-dd');
      for (final record in records) {
        buffer.writeln([
          record.id,
          record.childName,
          record.gender,
          dateFormat.format(record.dateOfBirth),
          record.placeOfBirth,
          record.fatherName,
          record.fatherNationalId,
          record.motherName,
          record.motherNationalId,
          record.registrationNumber,
          record.registrationDate != null ? dateFormat.format(record.registrationDate!) : '',
          record.registrar ?? '',
        ].map((e) => '"${e.toString().replaceAll('"', '""')}"').join(','));
      }
      
      return buffer.toString();
    } catch (e) {
      throw Exception('Error exporting births to CSV: $e');
    }
  }

  // Export death records to CSV
  static Future<String> exportDeathsToCSV(List<DeathRecord> records) async {
    try {
      final buffer = StringBuffer();
      
      // Header
      buffer.writeln('ID,Name,Date of Death,Place of Death,Cause of Death,'
          'Registration Number,ID Number,Hospital');
      
      // Data rows
      final dateFormat = DateFormat('yyyy-MM-dd');
      for (final record in records) {
        buffer.writeln([
          record.id,
          record.name,
          dateFormat.format(record.dateOfDeath),
          record.placeOfDeath,
          record.cause,
          record.registrationNumber,
          record.idNumber ?? '',
          record.hospital ?? '',
        ].map((e) => '"${e.toString().replaceAll('"', '""')}"').join(','));
      }
      
      return buffer.toString();
    } catch (e) {
      throw Exception('Error exporting deaths to CSV: $e');
    }
  }

  // Export all records to CSV
  static Future<String> exportAllToCSV({
    required List<BirthRecord> births,
    required List<DeathRecord> deaths,
  }) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('BIRTH RECORDS');
      buffer.writeln('=' * 80);
      buffer.writeln(await exportBirthsToCSV(births));
      buffer.writeln('');
      buffer.writeln('DEATH RECORDS');
      buffer.writeln('=' * 80);
      buffer.writeln(await exportDeathsToCSV(deaths));
      return buffer.toString();
    } catch (e) {
      throw Exception('Error exporting all records: $e');
    }
  }

  // Save file and share
  static Future<void> saveAndShareFile(String content, String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content);
      
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Exported data from Secure BDRS');
    } catch (e) {
      throw Exception('Error saving file: $e');
    }
  }

  // Export births to CSV file
  static Future<void> exportBirthsToCSVFile(List<BirthRecord> records) async {
    final content = await exportBirthsToCSV(records);
    final filename = 'birth_records_${DateTime.now().millisecondsSinceEpoch}.csv';
    await saveAndShareFile(content, filename);
  }

  // Export deaths to CSV file
  static Future<void> exportDeathsToCSVFile(List<DeathRecord> records) async {
    final content = await exportDeathsToCSV(records);
    final filename = 'death_records_${DateTime.now().millisecondsSinceEpoch}.csv';
    await saveAndShareFile(content, filename);
  }

  // Export all to CSV file
  static Future<void> exportAllToCSVFile({
    required List<BirthRecord> births,
    required List<DeathRecord> deaths,
  }) async {
    final content = await exportAllToCSV(births: births, deaths: deaths);
    final filename = 'all_records_${DateTime.now().millisecondsSinceEpoch}.csv';
    await saveAndShareFile(content, filename);
  }

  // Filter records by date range
  static List<BirthRecord> filterBirthsByDateRange(
    List<BirthRecord> records,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (startDate == null && endDate == null) return records;
    
    return records.where((record) {
      final recordDate = record.dateOfBirth;
      if (startDate != null && recordDate.isBefore(startDate)) return false;
      if (endDate != null && recordDate.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  static List<DeathRecord> filterDeathsByDateRange(
    List<DeathRecord> records,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (startDate == null && endDate == null) return records;
    
    return records.where((record) {
      final recordDate = record.dateOfDeath;
      if (startDate != null && recordDate.isBefore(startDate)) return false;
      if (endDate != null && recordDate.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  // Generate monthly report
  static Future<String> generateMonthlyReport({
    required List<BirthRecord> births,
    required List<DeathRecord> deaths,
    required int year,
    required int month,
  }) async {
    try {
      final buffer = StringBuffer();
      final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));
      
      buffer.writeln('MONTHLY REGISTRATION REPORT');
      buffer.writeln('=' * 80);
      buffer.writeln('Period: $monthName');
      buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
      buffer.writeln('');
      
      // Filter records for the month
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
      
      final monthBirths = filterBirthsByDateRange(births, startDate, endDate);
      final monthDeaths = filterDeathsByDateRange(deaths, startDate, endDate);
      
      // Statistics
      buffer.writeln('STATISTICS');
      buffer.writeln('-' * 80);
      buffer.writeln('Total Births: ${monthBirths.length}');
      buffer.writeln('  - Male: ${monthBirths.where((b) => b.gender.toLowerCase() == 'male').length}');
      buffer.writeln('  - Female: ${monthBirths.where((b) => b.gender.toLowerCase() == 'female').length}');
      buffer.writeln('Total Deaths: ${monthDeaths.length}');
      buffer.writeln('  - Male: ${monthDeaths.where((d) => d.gender?.toLowerCase() == 'male').length}');
      buffer.writeln('  - Female: ${monthDeaths.where((d) => d.gender?.toLowerCase() == 'female').length}');
      buffer.writeln('');
      
      // Birth details
      buffer.writeln('BIRTH RECORDS');
      buffer.writeln('-' * 80);
      buffer.writeln(await exportBirthsToCSV(monthBirths));
      buffer.writeln('');
      
      // Death details
      buffer.writeln('DEATH RECORDS');
      buffer.writeln('-' * 80);
      buffer.writeln(await exportDeathsToCSV(monthDeaths));
      
      return buffer.toString();
    } catch (e) {
      throw Exception('Error generating monthly report: $e');
    }
  }

  // Generate yearly report
  static Future<String> generateYearlyReport({
    required List<BirthRecord> births,
    required List<DeathRecord> deaths,
    required int year,
  }) async {
    try {
      final buffer = StringBuffer();
      
      buffer.writeln('YEARLY REGISTRATION REPORT');
      buffer.writeln('=' * 80);
      buffer.writeln('Year: $year');
      buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
      buffer.writeln('');
      
      // Filter records for the year
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31, 23, 59, 59);
      
      final yearBirths = filterBirthsByDateRange(births, startDate, endDate);
      final yearDeaths = filterDeathsByDateRange(deaths, startDate, endDate);
      
      // Monthly breakdown
      buffer.writeln('MONTHLY BREAKDOWN');
      buffer.writeln('-' * 80);
      for (int month = 1; month <= 12; month++) {
        final monthStart = DateTime(year, month, 1);
        final monthEnd = DateTime(year, month + 1, 0, 23, 59, 59);
        final monthBirths = filterBirthsByDateRange(births, monthStart, monthEnd);
        final monthDeaths = filterDeathsByDateRange(deaths, monthStart, monthEnd);
        final monthName = DateFormat('MMMM').format(DateTime(year, month));
        buffer.writeln('$monthName: ${monthBirths.length} births, ${monthDeaths.length} deaths');
      }
      buffer.writeln('');
      
      // Statistics
      buffer.writeln('YEARLY STATISTICS');
      buffer.writeln('-' * 80);
      buffer.writeln('Total Births: ${yearBirths.length}');
      buffer.writeln('  - Male: ${yearBirths.where((b) => b.gender.toLowerCase() == 'male').length}');
      buffer.writeln('  - Female: ${yearBirths.where((b) => b.gender.toLowerCase() == 'female').length}');
      buffer.writeln('Total Deaths: ${yearDeaths.length}');
      buffer.writeln('  - Male: ${yearDeaths.where((d) => d.gender?.toLowerCase() == 'male').length}');
      buffer.writeln('  - Female: ${yearDeaths.where((d) => d.gender?.toLowerCase() == 'female').length}');
      buffer.writeln('');
      
      // Birth details
      buffer.writeln('BIRTH RECORDS');
      buffer.writeln('-' * 80);
      buffer.writeln(await exportBirthsToCSV(yearBirths));
      buffer.writeln('');
      
      // Death details
      buffer.writeln('DEATH RECORDS');
      buffer.writeln('-' * 80);
      buffer.writeln(await exportDeathsToCSV(yearDeaths));
      
      return buffer.toString();
    } catch (e) {
      throw Exception('Error generating yearly report: $e');
    }
  }

  // Export monthly report to file
  static Future<void> exportMonthlyReportToFile({
    required List<BirthRecord> births,
    required List<DeathRecord> deaths,
    required int year,
    required int month,
  }) async {
    final content = await generateMonthlyReport(
      births: births,
      deaths: deaths,
      year: year,
      month: month,
    );
    final monthName = DateFormat('MMMM_yyyy').format(DateTime(year, month));
    final filename = 'monthly_report_$monthName.txt';
    await saveAndShareFile(content, filename);
  }

  // Export yearly report to file
  static Future<void> exportYearlyReportToFile({
    required List<BirthRecord> births,
    required List<DeathRecord> deaths,
    required int year,
  }) async {
    final content = await generateYearlyReport(
      births: births,
      deaths: deaths,
      year: year,
    );
    final filename = 'yearly_report_$year.txt';
    await saveAndShareFile(content, filename);
  }
}

