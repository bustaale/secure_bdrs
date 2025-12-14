import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../providers/records_provider.dart';
import '../models/birth_record.dart';
import '../models/death_record.dart';
import '../app_router.dart';

class GlobalSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context, query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context, query);
  }

  Widget _buildSearchResults(BuildContext context, String searchQuery) {
    if (searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Search Records',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a name to search birth and death records',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Consumer<RecordsProvider>(
      builder: (context, recordsProvider, child) {
        final birthResults = recordsProvider.births
            .where((record) => record.childName.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();
        
        final deathResults = recordsProvider.deaths
            .where((record) => record.name.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

        if (birthResults.isEmpty && deathResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No results found',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try searching with a different name',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (birthResults.isNotEmpty) ...[
              Text(
                'Birth Records',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
              const SizedBox(height: 8),
              ...birthResults.map((record) => _buildCompactRecordItem(
                type: 'Birth',
                name: record.childName,
                date: record.dateOfBirth,
                place: record.placeOfBirth,
                color: Colors.blue[600]!,
                icon: Icons.child_care,
                photoPath: record.photoPath,
                onTap: () {
                  close(context, null);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.birthDetail,
                    arguments: record,
                  );
                },
              )),
              const SizedBox(height: 16),
            ],
            if (deathResults.isNotEmpty) ...[
              Text(
                'Death Records',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[600],
                ),
              ),
              const SizedBox(height: 8),
              ...deathResults.map((record) => _buildCompactRecordItem(
                type: 'Death',
                name: record.name,
                date: record.dateOfDeath,
                place: record.placeOfDeath,
                color: Colors.red[600]!,
                icon: Icons.airline_seat_flat,
                photoPath: '',
                onTap: () {
                  close(context, null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Death detail screen coming soon",
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red[600],
                    ),
                  );
                },
              )),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCompactRecordItem({
    required String type,
    required String name,
    required DateTime date,
    required String place,
    required Color color,
    required IconData icon,
    required String photoPath,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Photo or icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                  ),
                  child: photoPath.isNotEmpty && File(photoPath).existsSync()
                      ? ClipOval(
                          child: Image.file(
                            File(photoPath),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              type,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${date.toLocal().toString().split(' ')[0]} • $place',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
