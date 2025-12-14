import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/records_provider.dart';
import '../providers/analytics_provider.dart';
import '../models/birth_record.dart';
import '../models/death_record.dart';
import '../app_router.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  String _selectedPeriod = 'Year'; // Year, Month, Week

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Consumer<RecordsProvider>(
        builder: (context, recordsProvider, child) {
          final birthStats = _calculateBirthStats(
            recordsProvider.births,
            _selectedPeriod,
          );
          final deathStats = _calculateDeathStats(
            recordsProvider.deaths,
            _selectedPeriod,
          );

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180.0,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF3B82F6),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 50,
                          bottom: -30,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Statistics Dashboard',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ).animate().fadeIn(delay: 100.ms),
                                const SizedBox(height: 8),
                                Text(
                                  'Birth & Death Records Analytics',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ).animate().fadeIn(delay: 200.ms),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  title: const SizedBox.shrink(),
                  centerTitle: false,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Period Selector
                    _buildPeriodSelector(),
                    const SizedBox(height: 16),

                    // Overall Stats Cards
                    _buildOverallStats(
                      recordsProvider.births.length, // All time total
                      recordsProvider.deaths.length, // All time total
                      birthStats['total'] ?? 0, // Period filtered
                      deathStats['total'] ?? 0, // Period filtered
                    ),
                    const SizedBox(height: 24),

                    // Birth Charts
                    _buildSectionTitle('Birth Records', Icons.child_care, Colors.blue),
                    const SizedBox(height: 24),
                    _buildBirthCharts(birthStats),
                    const SizedBox(height: 32),

                    // Male/Female Birth Analysis
                    _buildSectionTitle('Gender Analysis - Births', Icons.people, const Color(0xFF8B5CF6)),
                    const SizedBox(height: 24),
                    _buildGenderAnalysis(recordsProvider.births, _selectedPeriod),
                    const SizedBox(height: 32),

                    // Death Charts
                    _buildSectionTitle('Death Records', Icons.airline_seat_flat, Colors.red),
                    const SizedBox(height: 24),
                    _buildDeathCharts(deathStats),
                    const SizedBox(height: 32),

                    // Male/Female Death Analysis
                    _buildSectionTitle('Gender Analysis - Deaths', Icons.people_alt, const Color(0xFFEF4444)),
                    const SizedBox(height: 24),
                    _buildDeathGenderAnalysis(recordsProvider.deaths, _selectedPeriod),
                    const SizedBox(height: 32),

                    // Age-based Death Analysis
                    _buildSectionTitle('Age Analysis - Deaths', Icons.calendar_today, const Color(0xFFF59E0B)),
                    const SizedBox(height: 24),
                    _buildAgeAnalysis(recordsProvider.deaths, _selectedPeriod),
                    const SizedBox(height: 32),

                    // Advanced Analytics Preview
                    _buildSectionTitle('Advanced Analytics', Icons.insights, const Color(0xFF0EA5E9)),
                    const SizedBox(height: 16),
                    _buildAdvancedAnalyticsPreview(context),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdvancedAnalyticsPreview(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, analyticsProvider, child) {
        final revenue = analyticsProvider.getRevenueAnalytics();
        final success = analyticsProvider.getApplicationSuccessRate();
        final processing = analyticsProvider.getAverageProcessingTime();
        final certificate = analyticsProvider.getCertificateCompletionRate();

        final totalRevenue = (revenue['totalRevenue'] as double?) ?? 0.0;
        final successRate = (success['successRate'] as double?) ?? 0.0;
        final avgDays = (processing['averageDays'] as double?) ?? 0.0;
        final certCompletion = (certificate['completionRate'] as double?) ?? 0.0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0EA5E9).withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.insights,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Insights',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'View revenue, success rates, and processing time in one advanced dashboard.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // KPI Row
              Row(
                children: [
                  Expanded(
                    child: _buildKpiChip(
                      label: 'Total Revenue',
                      value: 'KES ${totalRevenue.toStringAsFixed(0)}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiChip(
                      label: 'Success Rate',
                      value: '${successRate.toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildKpiChip(
                      label: 'Avg. Processing',
                      value: '${avgDays.toStringAsFixed(1)} days',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKpiChip(
                      label: 'Cert. Completion',
                      value: '${certCompletion.toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // CTA Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.advancedAnalytics);
                  },
                  icon: const Icon(Icons.open_in_new, color: Colors.white, size: 18),
                  label: Text(
                    'Open Advanced Analytics',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.18),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildKpiChip({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPeriodButton('Year', Icons.calendar_today),
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          Expanded(
            child: _buildPeriodButton('Month', Icons.calendar_month),
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          Expanded(
            child: _buildPeriodButton('Week', Icons.calendar_view_week),
          ),
        ],
      ),
    ).animate().slideY(delay: 100.ms);
  }

  Widget _buildPeriodButton(String period, IconData icon) {
    final isSelected = _selectedPeriod == period;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      borderRadius: period == 'Year'
          ? const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16))
          : period == 'Week'
              ? const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16))
              : BorderRadius.circular(0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              period,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStats(
    int totalBirths,
    int totalDeaths,
    int periodBirths,
    int periodDeaths,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Births',
            '$periodBirths', // Show filtered period count as main number
            totalBirths, // Show all time total as subtitle
            Icons.child_care,
            Colors.blue,
            const LinearGradient(
              colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
            ),
          ).animate().slideX(delay: 100.ms),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Total Deaths',
            '$periodDeaths', // Show filtered period count as main number
            totalDeaths, // Show all time total as subtitle
            Icons.airline_seat_flat,
            Colors.red,
            const LinearGradient(
              colors: [Color(0xFFF87171), Color(0xFFEF4444)],
            ),
          ).animate().slideX(delay: 200.ms),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    int periodCount,
    IconData icon,
    Color color,
    LinearGradient gradient,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'All Time: $periodCount', // Show all time total as subtitle
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildBirthCharts(Map<String, dynamic> stats) {
    return Column(
      children: [
        // Birth Bar Chart
        Container(
          height: 350,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.blue.shade50,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.trending_up, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Birth Trends',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                        Text(
                          'Recorded births over time',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceBetween,
                    maxY: (stats['max'] ?? 10).toDouble(),
                    groupsSpace: 8,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipRoundedRadius: 12,
                        tooltipBgColor: Colors.blue.shade700,
                        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            rod.toY.toInt().toString(),
                            GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            children: [
                                TextSpan(
                                  text: ' ${stats['labels'][group.x.toInt()]}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() % 2 == 0) {
                              return Text(
                                value.toInt().toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < (stats['labels'] as List).length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  stats['labels'][index],
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              );
                            }
                            return const Text('');
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
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.blue.withOpacity(0.1),
                          strokeWidth: 1.5,
                          dashArray: [5, 3],
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        left: BorderSide(color: Colors.blue.withOpacity(0.3), width: 2),
                        bottom: BorderSide(color: Colors.blue.withOpacity(0.3), width: 2),
                      ),
                    ),
                    barGroups: stats['barGroups'] ?? [],
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0, delay: 200.ms),
      ],
    );
  }

  Widget _buildDeathCharts(Map<String, dynamic> stats) {
    return Column(
      children: [
        // Death Bar Chart
        Container(
          height: 350,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.red.shade50,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.trending_down, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Death Trends',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                        Text(
                          'Recorded deaths over time',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: (stats['barGroups'] as List).isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bar_chart, size: 48, color: Colors.red[300]),
                            const SizedBox(height: 12),
                            Text(
                              'No death data available',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceBetween,
                          maxY: ((stats['max'] ?? 10).toDouble() < 5) ? 5.0 : (stats['max'] ?? 10).toDouble(),
                          groupsSpace: 8,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              tooltipRoundedRadius: 12,
                              tooltipBgColor: Colors.red.shade700,
                              tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              tooltipMargin: 8,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final labels = stats['labels'] as List? ?? [];
                                final labelText = group.x.toInt() < labels.length 
                                    ? ' ${labels[group.x.toInt()]}'
                                    : '';
                                return BarTooltipItem(
                                  rod.toY.toInt().toString(),
                                  GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: labelText,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() % 2 == 0) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  final labels = stats['labels'] as List? ?? [];
                                  if (index >= 0 && index < labels.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        labels[index],
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red[900],
                                        ),
                                      ),
                                    );
                                  }
                                  return const Text('');
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
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.red.withOpacity(0.1),
                                strokeWidth: 1.5,
                                dashArray: [5, 3],
                              );
                            },
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              left: BorderSide(color: Colors.red.withOpacity(0.3), width: 2),
                              bottom: BorderSide(color: Colors.red.withOpacity(0.3), width: 2),
                            ),
                          ),
                          barGroups: stats['barGroups'] ?? [],
                        ),
                      ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0, delay: 200.ms),
      ],
    );
  }

  Widget _buildComparisonChart(
    Map<String, dynamic> birthStats,
    Map<String, dynamic> deathStats,
  ) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFFF472B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 12),
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: const Icon(Icons.compare_arrows, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Birth vs Death',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Comparative analysis over time',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _buildComparisonBarGroups(birthStats, deathStats).isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.compare_arrows, size: 48, color: Colors.white.withOpacity(0.7)),
                        const SizedBox(height: 12),
                        Text(
                          'No data available for comparison',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceBetween,
                      maxY: ((birthStats['max'] ?? deathStats['max'] ?? 10).toDouble() < 5) ? 5.0 : (birthStats['max'] ?? deathStats['max'] ?? 10).toDouble(),
                      groupsSpace: 8,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 12,
                    tooltipBgColor: Colors.white.withOpacity(0.95),
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    tooltipMargin: 8,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 2 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        final labels = birthStats['labels'] as List? ?? [];
                        if (index >= 0 && index < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              labels[index],
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          );
                        }
                        return const Text('');
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
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.15),
                      strokeWidth: 2,
                      dashArray: [8, 4],
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.white.withOpacity(0.3), width: 2),
                    bottom: BorderSide(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                ),
                barGroups: _buildComparisonBarGroups(birthStats, deathStats),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Birth',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Death',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0, delay: 400.ms);
  }

  List<BarChartGroupData> _buildComparisonBarGroups(
    Map<String, dynamic> birthStats,
    Map<String, dynamic> deathStats,
  ) {
    final birthBars = birthStats['barGroups'] as List<BarChartGroupData>? ?? [];
    final deathBars = deathStats['barGroups'] as List<BarChartGroupData>? ?? [];

    if (birthBars.isEmpty && deathBars.isEmpty) {
      return [];
    }

    final maxLength = birthBars.length > deathBars.length ? birthBars.length : deathBars.length;
    final combined = <BarChartGroupData>[];

    for (int i = 0; i < maxLength; i++) {
      double birthValue = 0;
      double deathValue = 0;

      if (i < birthBars.length && birthBars[i].barRods.isNotEmpty) {
        birthValue = birthBars[i].barRods.first.toY;
      }

      if (i < deathBars.length && deathBars[i].barRods.isNotEmpty) {
        deathValue = deathBars[i].barRods.first.toY;
      }

      combined.add(
        BarChartGroupData(
          x: i,
          barsSpace: 4,
          barRods: [
            BarChartRodData(
              toY: birthValue,
              color: _getBirthColor(i),
              width: 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
            BarChartRodData(
              toY: deathValue,
              color: _getDeathColor(i),
              width: 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        ),
      );
    }

    return combined;
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItemEnhanced(String label, Color textColor, Color dotColor) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  // Birth Colors: Blue/Green/Cyan tones (Life & Growth)
  List<Color> get _birthColorPalette => [
    const Color(0xFF2563EB), // Vibrant Blue - Jan
    const Color(0xFF3B82F6), // Bright Blue - Feb
    const Color(0xFF60A5FA), // Sky Blue - Mar
    const Color(0xFF06B6D4), // Cyan - Apr
    const Color(0xFF10B981), // Emerald Green - May
    const Color(0xFF22D3EE), // Light Cyan - Jun
    const Color(0xFF0EA5E9), // Ocean Blue - Jul
    const Color(0xFF34D399), // Mint Green - Aug
    const Color(0xFF6366F1), // Indigo - Sep
    const Color(0xFF8B5CF6), // Purple - Oct
    const Color(0xFFA855F7), // Vibrant Purple - Nov
    const Color(0xFF9333EA), // Deep Purple - Dec
  ];

  // Death Colors: Rich Red/Orange/Coral tones (Warning & Alert)
  List<Color> get _deathColorPalette => [
    const Color(0xFFDC2626), // Deep Red - Jan
    const Color(0xFFEF4444), // Bright Red - Feb
    const Color(0xFFF87171), // Coral Red - Mar
    const Color(0xFFE11D48), // Rose Red - Apr
    const Color(0xFFBE185D), // Dark Rose - May
    const Color(0xFFF43F5E), // Vibrant Pink - Jun
    const Color(0xFFFF5722), // Deep Orange - Jul
    const Color(0xFFF97316), // Orange - Aug
    const Color(0xFFFB923C), // Light Orange - Sep
    const Color(0xFFEC4899), // Hot Pink - Oct
    const Color(0xFFF472B6), // Pink - Nov
    const Color(0xFFDB2777), // Magenta - Dec
  ];

  Color _getBirthColor(int index) {
    return _birthColorPalette[index % _birthColorPalette.length];
  }

  Color _getDeathColor(int index) {
    return _deathColorPalette[index % _deathColorPalette.length];
  }

  // Helper function to normalize date (remove time component) - converts to local time
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Helper function to check if date is in range (inclusive of start, exclusive of end)
  bool _isDateInRange(DateTime date, DateTime start, DateTime end) {
    final normalizedDate = _normalizeDate(date);
    final normalizedStart = _normalizeDate(start);
    final normalizedEnd = _normalizeDate(end);
    
    // Simple comparison: date >= start AND date < end
    final dateCompare = normalizedDate.compareTo(normalizedStart);
    final endCompare = normalizedDate.compareTo(normalizedEnd);
    
    return dateCompare >= 0 && endCompare < 0;
  }

  Map<String, dynamic> _calculateBirthStats(List<BirthRecord> births, String period) {
    final now = DateTime.now();
    Map<String, int> data = {};
    List<String> labels = [];
    int total = 0;
    int max = 5;

    List<BirthRecord> filteredBirths;
    if (period == 'Year') {
      final startOfYear = DateTime(now.year, 1, 1);
      final endOfYear = DateTime(now.year + 1, 1, 1);
      filteredBirths = births.where((b) => _isDateInRange(b.dateOfBirth, startOfYear, endOfYear)).toList();
      data = _groupByMonth(filteredBirths);
      labels = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    } else if (period == 'Month') {
      final startOfMonth = DateTime(now.year, now.month, 1);
      final nextMonth = now.month == 12 ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
      filteredBirths = births.where((b) => _isDateInRange(b.dateOfBirth, startOfMonth, nextMonth)).toList();
      data = _groupByWeek(filteredBirths, now);
      labels = List.generate(data.length, (i) => 'Week ${i + 1}');
    } else { // Week
      final startOfWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      filteredBirths = births.where((b) => _isDateInRange(b.dateOfBirth, startOfWeek, endOfWeek)).toList();
      data = _groupByDay(filteredBirths, startOfWeek);
      labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    }

    total = filteredBirths.length;
    if (data.isNotEmpty) {
      max = data.values.reduce((a, b) => a > b ? a : b);
      if (max < 5) max = 5;
    }

    List<BarChartGroupData> barGroups = [];
    final sortedKeys = data.keys.toList()..sort((a, b) {
      if (period == 'Year') {
        final months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
        return months.indexOf(a).compareTo(months.indexOf(b));
      } else if (period == 'Week') {
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days.indexOf(a).compareTo(days.indexOf(b));
      }
      return a.compareTo(b);
    });
    
    sortedKeys.asMap().forEach((index, key) {
      final value = data[key] ?? 0;
      final color = _getBirthColor(index);
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value.toDouble(),
              color: color,
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.85),
                  color,
                  color.withOpacity(0.92),
                ],
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 20,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
          ],
        ),
      );
    });

    return {
      'total': total,
      'max': max,
      'labels': labels,
      'barGroups': barGroups,
    };
  }

  Map<String, dynamic> _calculateDeathStats(List<DeathRecord> deaths, String period) {
    final now = DateTime.now();
    final today = _normalizeDate(now);
    Map<String, int> data = {};
    List<String> labels = [];
    int total = 0;
    int max = 5;

    List<DeathRecord> filteredDeaths;
    if (period == 'Year') {
      final startOfYear = DateTime(now.year, 1, 1);
      final endOfYear = DateTime(now.year + 1, 1, 1);
      filteredDeaths = deaths.where((d) => _isDateInRange(d.dateOfDeath, startOfYear, endOfYear)).toList();
      data = _groupDeathsByMonth(filteredDeaths);
      labels = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    } else if (period == 'Month') {
      final startOfMonth = DateTime(now.year, now.month, 1);
      final nextMonth = now.month == 12 ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
      filteredDeaths = deaths.where((d) => _isDateInRange(d.dateOfDeath, startOfMonth, nextMonth)).toList();
      data = _groupDeathsByWeek(filteredDeaths, now);
      labels = List.generate(data.length, (i) => 'Week ${i + 1}');
    } else { // Week
      final startOfWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      filteredDeaths = deaths.where((d) => _isDateInRange(d.dateOfDeath, startOfWeek, endOfWeek)).toList();
      data = _groupDeathsByDay(filteredDeaths, startOfWeek);
      labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    }

    total = filteredDeaths.length;
    if (data.isNotEmpty) {
      max = data.values.reduce((a, b) => a > b ? a : b);
      if (max < 5) max = 5;
    }

    List<BarChartGroupData> barGroups = [];
    final sortedKeys = data.keys.toList()..sort((a, b) {
      if (period == 'Year') {
        final months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
        return months.indexOf(a).compareTo(months.indexOf(b));
      } else if (period == 'Week') {
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days.indexOf(a).compareTo(days.indexOf(b));
      }
      return a.compareTo(b);
    });
    
    sortedKeys.asMap().forEach((index, key) {
      final value = data[key] ?? 0;
      final color = _getDeathColor(index);
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value.toDouble(),
              color: color,
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.85),
                  color,
                  color.withOpacity(0.92),
                ],
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 20,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
          ],
        ),
      );
    });

    return {
      'total': total,
      'max': max,
      'labels': labels,
      'barGroups': barGroups,
    };
  }

  Map<String, int> _groupByMonth(List<BirthRecord> births) {
    Map<String, int> data = {
      'Jan': 0, 'Feb': 0, 'Mar': 0, 'Apr': 0, 'May': 0, 'Jun': 0,
      'Jul': 0, 'Aug': 0, 'Sep': 0, 'Oct': 0, 'Nov': 0, 'Dec': 0,
    };
    for (var birth in births) {
      final month = DateFormat('MMM').format(birth.dateOfBirth);
      if (data.containsKey(month)) {
        data[month] = data[month]! + 1;
      }
    }
    return data;
  }

  Map<String, int> _groupByWeek(List<BirthRecord> births, DateTime now) {
    final weeksInMonth = (now.day / 7).ceil();
    Map<String, int> data = {};
    for (int i = 0; i < weeksInMonth; i++) {
      data['Week ${i + 1}'] = 0;
    }
    for (var birth in births) {
      final week = ((birth.dateOfBirth.day - 1) / 7).floor() + 1;
      final key = 'Week $week';
      if (data.containsKey(key)) {
        data[key] = data[key]! + 1;
      }
    }
    return data;
  }

  Map<String, int> _groupByDay(List<BirthRecord> births, DateTime startOfWeek) {
    Map<String, int> data = {
      'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0,
    };
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (var birth in births) {
      final dayIndex = birth.dateOfBirth.weekday - 1;
      final key = days[dayIndex];
      if (data.containsKey(key)) {
        data[key] = data[key]! + 1;
      }
    }
    return data;
  }

  Map<String, int> _groupDeathsByMonth(List<DeathRecord> deaths) {
    Map<String, int> data = {
      'Jan': 0, 'Feb': 0, 'Mar': 0, 'Apr': 0, 'May': 0, 'Jun': 0,
      'Jul': 0, 'Aug': 0, 'Sep': 0, 'Oct': 0, 'Nov': 0, 'Dec': 0,
    };
    for (var death in deaths) {
      final month = DateFormat('MMM').format(death.dateOfDeath);
      if (data.containsKey(month)) {
        data[month] = data[month]! + 1;
      }
    }
    return data;
  }

  Map<String, int> _groupDeathsByWeek(List<DeathRecord> deaths, DateTime now) {
    final weeksInMonth = (now.day / 7).ceil();
    Map<String, int> data = {};
    for (int i = 0; i < weeksInMonth; i++) {
      data['Week ${i + 1}'] = 0;
    }
    for (var death in deaths) {
      final week = ((death.dateOfDeath.day - 1) / 7).floor() + 1;
      final key = 'Week $week';
      if (data.containsKey(key)) {
        data[key] = data[key]! + 1;
      }
    }
    return data;
  }

  Map<String, int> _groupDeathsByDay(List<DeathRecord> deaths, DateTime startOfWeek) {
    Map<String, int> data = {
      'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0,
    };
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (var death in deaths) {
      final dayIndex = death.dateOfDeath.weekday - 1;
      final key = days[dayIndex];
      if (data.containsKey(key)) {
        data[key] = data[key]! + 1;
      }
    }
    return data;
  }

  // Gender Analysis for Births (Male/Female)
  Widget _buildGenderAnalysis(List<BirthRecord> births, String period) {
    final now = DateTime.now();
    List<BirthRecord> filteredBirths;
    
    if (period == 'Year') {
      final startOfYear = DateTime(now.year, 1, 1);
      final endOfYear = DateTime(now.year + 1, 1, 1);
      filteredBirths = births.where((b) => _isDateInRange(b.dateOfBirth, startOfYear, endOfYear)).toList();
    } else if (period == 'Month') {
      final startOfMonth = DateTime(now.year, now.month, 1);
      final nextMonth = now.month == 12 ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
      filteredBirths = births.where((b) => _isDateInRange(b.dateOfBirth, startOfMonth, nextMonth)).toList();
    } else {
      final startOfWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      filteredBirths = births.where((b) => _isDateInRange(b.dateOfBirth, startOfWeek, endOfWeek)).toList();
    }

    int maleCount = filteredBirths.where((b) => b.gender.toLowerCase() == 'male' || b.gender.toLowerCase() == 'm').length;
    int femaleCount = filteredBirths.where((b) => b.gender.toLowerCase() == 'female' || b.gender.toLowerCase() == 'f').length;
    int total = maleCount + femaleCount;

    if (total == 0) {
      return Container(
        height: 280,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8B5CF6).withOpacity(0.1),
              const Color(0xFFA78BFA).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2), width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No birth data available',
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

    return Container(
      height: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withOpacity(0.1),
            const Color(0xFFA78BFA).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: (maleCount / total * 100),
                    color: const Color(0xFF3B82F6), // Blue for Male
                    title: '${(maleCount / total * 100).toStringAsFixed(1)}%',
                    radius: 60,
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: (femaleCount / total * 100),
                    color: const Color(0xFFEC4899), // Pink for Female
                    title: '${(femaleCount / total * 100).toStringAsFixed(1)}%',
                    radius: 60,
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                centerSpaceRadius: 50,
                sectionsSpace: 6,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGenderLegendItem('Male', const Color(0xFF3B82F6), maleCount, total),
                  const SizedBox(height: 12),
                  _buildGenderLegendItem('Female', const Color(0xFFEC4899), femaleCount, total),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total Births',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$total',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0, delay: 200.ms);
  }

  Widget _buildDeathGenderAnalysis(List<DeathRecord> deaths, String period) {
    final now = DateTime.now();
    List<DeathRecord> filteredDeaths;

    if (period == 'Year') {
      final startOfYear = DateTime(now.year, 1, 1);
      final endOfYear = DateTime(now.year + 1, 1, 1);
      filteredDeaths = deaths.where((d) => _isDateInRange(d.dateOfDeath, startOfYear, endOfYear)).toList();
    } else if (period == 'Month') {
      final startOfMonth = DateTime(now.year, now.month, 1);
      final nextMonth = now.month == 12 ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
      filteredDeaths = deaths.where((d) => _isDateInRange(d.dateOfDeath, startOfMonth, nextMonth)).toList();
    } else {
      final startOfWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      filteredDeaths = deaths.where((d) => _isDateInRange(d.dateOfDeath, startOfWeek, endOfWeek)).toList();
    }

    int maleCount = filteredDeaths.where((d) {
      final gender = d.gender?.toLowerCase() ?? '';
      return gender == 'male' || gender == 'm';
    }).length;

    int femaleCount = filteredDeaths.where((d) {
      final gender = d.gender?.toLowerCase() ?? '';
      return gender == 'female' || gender == 'f';
    }).length;

    int total = maleCount + femaleCount;

    if (total == 0) {
      return Container(
        height: 280,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFEF4444).withOpacity(0.1),
              const Color(0xFFF87171).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2), width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No death data available',
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

    return Container(
      height: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEF4444).withOpacity(0.1),
            const Color(0xFFF87171).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: (maleCount / total * 100),
                    color: const Color(0xFF3B82F6),
                    title: '${(maleCount / total * 100).toStringAsFixed(1)}%',
                    radius: 60,
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: (femaleCount / total * 100),
                    color: const Color(0xFFEC4899),
                    title: '${(femaleCount / total * 100).toStringAsFixed(1)}%',
                    radius: 60,
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                centerSpaceRadius: 50,
                sectionsSpace: 6,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGenderLegendItem('Male', const Color(0xFF3B82F6), maleCount, total),
                  const SizedBox(height: 12),
                  _buildGenderLegendItem('Female', const Color(0xFFEC4899), femaleCount, total),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total Deaths',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$total',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0, delay: 200.ms);
  }

  Widget _buildGenderLegendItem(String label, Color color, int count, int total) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$count (${percentage.toStringAsFixed(1)}%)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Age Analysis for Deaths (1-18, 19+)
  Widget _buildAgeAnalysis(List<DeathRecord> deaths, String period) {
    final now = DateTime.now();
    List<DeathRecord> filteredDeaths;
    
    if (period == 'Year') {
      final startOfYear = DateTime(now.year, 1, 1);
      final endOfYear = DateTime(now.year + 1, 1, 1);
      filteredDeaths = deaths.where((d) => _isDateInRange(d.dateOfDeath, startOfYear, endOfYear)).toList();
    } else if (period == 'Month') {
      final startOfMonth = DateTime(now.year, now.month, 1);
      final nextMonth = now.month == 12 ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
      filteredDeaths = deaths.where((d) => _isDateInRange(d.dateOfDeath, startOfMonth, nextMonth)).toList();
    } else {
      final startOfWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      filteredDeaths = deaths.where((d) => _isDateInRange(d.dateOfDeath, startOfWeek, endOfWeek)).toList();
    }

    // Calculate age groups using actual age field
    int ageGroup1_18 = 0;
    int ageGroup19Plus = 0;

    for (var death in filteredDeaths) {
      if (death.age != null) {
        if (death.age! < 18) {
          ageGroup1_18++;
        } else {
          ageGroup19Plus++;
        }
      }
    }

    int total = ageGroup1_18 + ageGroup19Plus;

    if (total == 0) {
      return Container(
        height: 280,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF59E0B).withOpacity(0.1),
              const Color(0xFFFBBF24).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2), width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No death data available',
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

    return Container(
      height: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF59E0B).withOpacity(0.1),
            const Color(0xFFFBBF24).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: (ageGroup1_18 / total * 100),
                    color: const Color(0xFF10B981), // Green for 1-18
                    title: '${(ageGroup1_18 / total * 100).toStringAsFixed(1)}%',
                    radius: 60,
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: (ageGroup19Plus / total * 100),
                    color: const Color(0xFFEF4444), // Red for 19+
                    title: '${(ageGroup19Plus / total * 100).toStringAsFixed(1)}%',
                    radius: 60,
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                centerSpaceRadius: 50,
                sectionsSpace: 6,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAgeLegendItem('Under Age', const Color(0xFF10B981), ageGroup1_18, total),
                  const SizedBox(height: 12),
                  _buildAgeLegendItem('Adult', const Color(0xFFEF4444), ageGroup19Plus, total),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total Deaths',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$total',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0, delay: 200.ms);
  }

  Widget _buildAgeLegendItem(String label, Color color, int count, int total) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$count (${percentage.toStringAsFixed(1)}%)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

