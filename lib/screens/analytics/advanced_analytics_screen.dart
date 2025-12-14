import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/records_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/abn_provider.dart';

class AdvancedAnalyticsScreen extends StatefulWidget {
  const AdvancedAnalyticsScreen({super.key});

  @override
  State<AdvancedAnalyticsScreen> createState() => _AdvancedAnalyticsScreenState();
}

class _AdvancedAnalyticsScreenState extends State<AdvancedAnalyticsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPeriod = 'All Time'; // All Time, This Year, This Month, This Week

  @override
  void initState() {
    super.initState();
    _setDateRange();
  }

  void _setDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'This Week':
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = now;
        break;
      case 'This Month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case 'This Year':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
        break;
      default:
        _startDate = null;
        _endDate = null;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Advanced Analytics',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer4<AnalyticsProvider, RecordsProvider, PaymentProvider, ABNProvider>(
        builder: (context, analyticsProvider, recordsProvider, paymentProvider, abnProvider, child) {
          final revenueAnalytics = analyticsProvider.getRevenueAnalytics(
            startDate: _startDate,
            endDate: _endDate,
          );
          final successRate = analyticsProvider.getApplicationSuccessRate(
            startDate: _startDate,
            endDate: _endDate,
          );
          final processingTime = analyticsProvider.getAverageProcessingTime(
            startDate: _startDate,
            endDate: _endDate,
          );
          final peakPeriods = analyticsProvider.getPeakRegistrationPeriods(
            startDate: _startDate,
            endDate: _endDate,
          );
          final certificateRate = analyticsProvider.getCertificateCompletionRate(
            startDate: _startDate,
            endDate: _endDate,
          );
          final paymentRate = analyticsProvider.getPaymentCompletionRate(
            startDate: _startDate,
            endDate: _endDate,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Selector
                _buildPeriodSelector(),
                const SizedBox(height: 24),

                // Revenue Analytics Section
                _buildSectionTitle('Revenue Analytics', Icons.attach_money, Colors.green),
                const SizedBox(height: 16),
                _buildRevenueCards(revenueAnalytics),
                const SizedBox(height: 24),
                _buildRevenueChart(revenueAnalytics),
                const SizedBox(height: 32),

                // Application Success Rate
                _buildSectionTitle('Application Success Rate', Icons.trending_up, Colors.blue),
                const SizedBox(height: 16),
                _buildSuccessRateCards(successRate),
                const SizedBox(height: 24),
                _buildSuccessRateChart(successRate),
                const SizedBox(height: 32),

                // Processing Time
                _buildSectionTitle('Processing Time', Icons.access_time, Colors.orange),
                const SizedBox(height: 16),
                _buildProcessingTimeCards(processingTime),
                const SizedBox(height: 32),

                // Certificate Completion
                _buildSectionTitle('Certificate Completion', Icons.verified, Colors.purple),
                const SizedBox(height: 16),
                _buildCertificateCards(certificateRate),
                const SizedBox(height: 32),

                // Payment Completion
                _buildSectionTitle('Payment Completion', Icons.payment, Colors.teal),
                const SizedBox(height: 16),
                _buildPaymentCards(paymentRate),
                const SizedBox(height: 32),

                // Peak Periods
                _buildSectionTitle('Peak Registration Periods', Icons.calendar_today, Colors.red),
                const SizedBox(height: 16),
                _buildPeakPeriodsChart(peakPeriods),
                const SizedBox(height: 32),

                // Overall Records Statistics
                _buildSectionTitle('Overall Records Statistics', Icons.assessment, Colors.indigo),
                const SizedBox(height: 16),
                _buildOverallRecordsStats(analyticsProvider),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              value: _selectedPeriod,
              isExpanded: true,
              underline: const SizedBox(),
              items: ['All Time', 'This Year', 'This Month', 'This Week']
                  .map((period) => DropdownMenuItem(
                        value: period,
                        child: Text(period, style: GoogleFonts.poppins()),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPeriod = value;
                    _setDateRange();
                  });
                }
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueCards(Map<String, dynamic> analytics) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Revenue',
            'KES ${(analytics['totalRevenue'] as double).toStringAsFixed(2)}',
            Icons.attach_money,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Average Payment',
            'KES ${(analytics['averagePayment'] as double).toStringAsFixed(2)}',
            Icons.trending_up,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Payments',
            '${analytics['totalPayments']}',
            Icons.receipt,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    ).animate().slideY(delay: 200.ms);
  }

  Widget _buildRevenueChart(Map<String, dynamic> analytics) {
    final monthlyRevenue = analytics['monthlyRevenue'] as Map<String, double>;
    if (monthlyRevenue.isEmpty) {
      return _buildEmptyChart('No revenue data available');
    }

    final sortedKeys = monthlyRevenue.keys.toList()..sort();
    final maxRevenue = monthlyRevenue.values.isEmpty
        ? 1000.0
        : monthlyRevenue.values.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxRevenue * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < sortedKeys.length) {
                    final key = sortedKeys[value.toInt()];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        key.split('-')[1], // Month number
                        style: GoogleFonts.poppins(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    'KES ${value.toInt()}',
                    style: GoogleFonts.poppins(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          barGroups: sortedKeys.asMap().entries.map((entry) {
            final index = entry.key;
            final key = entry.value;
            final value = monthlyRevenue[key] ?? 0.0;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: value,
                  color: Colors.green,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildSuccessRateCards(Map<String, dynamic> successRate) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Success Rate',
            '${(successRate['successRate'] as double).toStringAsFixed(1)}%',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Approved',
            '${successRate['approved']}',
            Icons.verified,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Rejected',
            '${successRate['rejected']}',
            Icons.cancel,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessRateChart(Map<String, dynamic> successRate) {
    final approved = successRate['approved'] as int;
    final rejected = successRate['rejected'] as int;
    final pending = successRate['pending'] as int;
    final total = approved + rejected + pending;

    if (total == 0) {
      return _buildEmptyChart('No application data available');
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: approved.toDouble(),
              color: Colors.green,
              title: '${((approved / total) * 100).toStringAsFixed(1)}%',
              radius: 60,
            ),
            PieChartSectionData(
              value: rejected.toDouble(),
              color: Colors.red,
              title: '${((rejected / total) * 100).toStringAsFixed(1)}%',
              radius: 60,
            ),
            PieChartSectionData(
              value: pending.toDouble(),
              color: Colors.orange,
              title: '${((pending / total) * 100).toStringAsFixed(1)}%',
              radius: 60,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildProcessingTimeCards(Map<String, dynamic> processingTime) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Average Days',
            '${(processingTime['averageDays'] as double).toStringAsFixed(1)}',
            Icons.timer,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Min Days',
            '${processingTime['minDays']}',
            Icons.arrow_downward,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Max Days',
            '${processingTime['maxDays']}',
            Icons.arrow_upward,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildCertificateCards(Map<String, dynamic> certificateRate) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Completion Rate',
            '${(certificateRate['completionRate'] as double).toStringAsFixed(1)}%',
            Icons.verified,
            Colors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Issued',
            '${certificateRate['certificatesIssued']}',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Approved',
            '${certificateRate['totalApproved']}',
            Icons.approval,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCards(Map<String, dynamic> paymentRate) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Completion Rate',
            '${(paymentRate['completionRate'] as double).toStringAsFixed(1)}%',
            Icons.payment,
            Colors.teal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Completed',
            '${paymentRate['paymentsCompleted']}',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Required',
            '${paymentRate['totalRequiringPayment']}',
            Icons.pending,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildPeakPeriodsChart(Map<String, dynamic> peakPeriods) {
    final birthsByMonth = peakPeriods['birthsByMonth'] as Map<String, int>;
    final deathsByMonth = peakPeriods['deathsByMonth'] as Map<String, int>;
    
    // Combine all months from both maps
    final allMonths = <String>{};
    allMonths.addAll(birthsByMonth.keys);
    allMonths.addAll(deathsByMonth.keys);
    
    if (allMonths.isEmpty) {
      return _buildEmptyChart('No peak period data available');
    }

    final sortedKeys = allMonths.toList()..sort();
    final maxBirthValue = birthsByMonth.values.isEmpty ? 0 : birthsByMonth.values.reduce((a, b) => a > b ? a : b);
    final maxDeathValue = deathsByMonth.values.isEmpty ? 0 : deathsByMonth.values.reduce((a, b) => a > b ? a : b);
    final maxValue = maxBirthValue > maxDeathValue ? maxBirthValue : maxDeathValue;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Births', Colors.blue),
              const SizedBox(width: 24),
              _buildLegendItem('Deaths', Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.2,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < sortedKeys.length) {
                          final key = sortedKeys[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              key.split('-')[1], // Month number
                              style: GoogleFonts.poppins(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: GoogleFonts.poppins(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                barGroups: sortedKeys.asMap().entries.map((entry) {
                  final index = entry.key;
                  final key = entry.value;
                  final birthValue = birthsByMonth[key] ?? 0;
                  final deathValue = deathsByMonth[key] ?? 0;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: birthValue.toDouble(),
                        color: Colors.blue,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: deathValue.toDouble(),
                        color: Colors.red,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallRecordsStats(AnalyticsProvider analyticsProvider) {
    final stats = analyticsProvider.getOverallRecordsStatistics(
      startDate: _startDate,
      endDate: _endDate,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Total Records Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Records',
                  '${stats['totalRecords']}',
                  Icons.assessment,
                  Colors.indigo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Births',
                  '${stats['totalBirths']}',
                  Icons.child_care,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Deaths',
                  '${stats['totalDeaths']}',
                  Icons.airline_seat_flat,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Gender Distribution Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Male Births',
                  '${stats['maleBirths']}',
                  Icons.male,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Female Births',
                  '${stats['femaleBirths']}',
                  Icons.female,
                  Colors.pink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Male Deaths',
                  '${stats['maleDeaths']}',
                  Icons.male,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Female Deaths',
                  '${stats['femaleDeaths']}',
                  Icons.female,
                  Colors.deepOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }
}

