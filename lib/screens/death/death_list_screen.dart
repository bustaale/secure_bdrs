import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:google_fonts/google_fonts.dart";
import "package:flutter_animate/flutter_animate.dart";
import "dart:io";
import "../../providers/records_provider.dart";
import "../../widgets/record_card.dart";
import "../../app_router.dart";
import "../../models/death_record.dart";

class DeathListScreen extends StatelessWidget {
  const DeathListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final records = Provider.of<RecordsProvider>(context);
    final deaths = records.deaths;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Death Records',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Search functionality coming soon",
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: const Color(0xFF3B82F6),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'filter':
                  // TODO: Implement filter functionality
                  break;
                case 'export':
                  // TODO: Implement export functionality
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Text('Filter Records', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Text('Export Data', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: deaths.isEmpty
          ? _buildEmptyState()
          : _buildDeathList(deaths),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.deathForm),
        backgroundColor: const Color(0xFF3B82F6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Death',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ).animate().scale(delay: 200.ms),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.red[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.airline_seat_flat,
              size: 60,
              color: Colors.red[600],
            ),
          ).animate().scale(delay: 200.ms),
          const SizedBox(height: 24),
          Text(
            'No Death Records Yet',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 8),
          Text(
            'Start by registering a new death record',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[600]!, Colors.orange[600]!],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              'Tap the + button to get started',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ).animate().slideY(delay: 800.ms),
        ],
      ),
    );
  }
  
  Widget _buildDeathList(List<DeathRecord> deaths) {
    return Column(
      children: [
        // Header with stats
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Death Records',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${deaths.length}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.airline_seat_flat,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ).animate().slideY(delay: 200.ms),
        
        // Death records list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: deaths.length,
            itemBuilder: (context, index) {
              final record = deaths[index];
              return _buildDeathCard(record, index, context);
            },
              ),
      ),
      ],
    );
  }
  
  Widget _buildDeathCard(DeathRecord record, int index, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.deathDetail,
              arguments: record,
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Deceased photo placeholder
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF3B82F6).withOpacity(0.1),
                        const Color(0xFF8B5CF6).withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 18,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                
                const SizedBox(width: 10),
                
                // Death details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.name,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (record.gender != null && record.gender!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: record.gender == 'Male'
                                    ? const Color(0xFF3B82F6).withOpacity(0.1)
                                    : const Color(0xFFEC4899).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                record.gender == 'Male' ? 'M' : 'F',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: record.gender == 'Male'
                                      ? const Color(0xFF3B82F6)
                                      : const Color(0xFFEC4899),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          if (record.age != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: record.age! < 18
                                    ? const Color(0xFF10B981).withOpacity(0.1)
                                    : const Color(0xFFEF4444).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${record.age}y',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: record.age! < 18
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              'Died: ${record.dateOfDeath.toLocal().toString().split(' ')[0]} • ${record.placeOfDeath}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (record.cause.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF3B82F6).withOpacity(0.1),
                                const Color(0xFF8B5CF6).withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            record.cause,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF3B82F6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red[600],
                  iconSize: 22,
                  onPressed: () => _showDeleteDialog(context, record),
                  tooltip: 'Delete',
                ),

                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideX(delay: (200 + (index * 100)).ms);
  }

  void _showDeleteDialog(BuildContext context, DeathRecord record) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Delete Death Record',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "${record.name}"? This action cannot be undone.',
            style: GoogleFonts.poppins(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await Provider.of<RecordsProvider>(context, listen: false)
                      .deleteDeath(record.id ?? '');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Death record deleted successfully',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.green[600],
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error deleting record: $e',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.red[600],
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
