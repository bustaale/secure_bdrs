import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/records_provider.dart';
import '../models/birth_record.dart';
import '../models/death_record.dart';
import '../app_router.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _regNumberController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  
  String _selectedType = 'All'; // All, Birth, Death
  String _selectedStatus = 'All'; // All, Issued, Pending
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedGender;
  String? _selectedPlace;

  List<BirthRecord> _filteredBirths = [];
  List<DeathRecord> _filteredDeaths = [];

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regNumberController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final recordsProvider = Provider.of<RecordsProvider>(context, listen: false);
    
    setState(() {
      // Filter births
      _filteredBirths = recordsProvider.births.where((record) {
        // Name filter
        if (_nameController.text.isNotEmpty) {
          if (!record.childName.toLowerCase().contains(_nameController.text.toLowerCase()) &&
              !record.fatherName.toLowerCase().contains(_nameController.text.toLowerCase()) &&
              !record.motherName.toLowerCase().contains(_nameController.text.toLowerCase())) {
            return false;
          }
        }
        
        // Registration number filter
        if (_regNumberController.text.isNotEmpty) {
          if (!record.registrationNumber.toLowerCase().contains(_regNumberController.text.toLowerCase())) {
            return false;
          }
        }
        
        // Place filter
        if (_placeController.text.isNotEmpty) {
          if (!record.placeOfBirth.toLowerCase().contains(_placeController.text.toLowerCase())) {
            return false;
          }
        }
        
        // Date range filter
        if (_startDate != null && record.dateOfBirth.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && record.dateOfBirth.isAfter(_endDate!.add(const Duration(days: 1)))) {
          return false;
        }
        
        // Gender filter
        if (_selectedGender != null && _selectedGender != 'All') {
          if (record.gender.toLowerCase() != _selectedGender!.toLowerCase()) {
            return false;
          }
        }
        
        // Status filter
        if (_selectedStatus != 'All') {
          if (_selectedStatus == 'Issued' && !record.certificateIssued) {
            return false;
          }
          if (_selectedStatus == 'Pending' && record.certificateIssued) {
            return false;
          }
        }
        
        return true;
      }).toList();
      
      // Filter deaths
      _filteredDeaths = recordsProvider.deaths.where((record) {
        // Name filter
        if (_nameController.text.isNotEmpty) {
          if (!record.name.toLowerCase().contains(_nameController.text.toLowerCase()) &&
              (record.familyName == null || !record.familyName!.toLowerCase().contains(_nameController.text.toLowerCase()))) {
            return false;
          }
        }
        
        // Registration number filter
        if (_regNumberController.text.isNotEmpty) {
          if (!record.registrationNumber.toLowerCase().contains(_regNumberController.text.toLowerCase())) {
            return false;
          }
        }
        
        // Place filter
        if (_placeController.text.isNotEmpty) {
          if (!record.placeOfDeath.toLowerCase().contains(_placeController.text.toLowerCase())) {
            return false;
          }
        }
        
        // Date range filter
        if (_startDate != null && record.dateOfDeath.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && record.dateOfDeath.isAfter(_endDate!.add(const Duration(days: 1)))) {
          return false;
        }
        
        // Gender filter
        if (_selectedGender != null && _selectedGender != 'All') {
          if (record.gender == null || record.gender!.toLowerCase() != _selectedGender!.toLowerCase()) {
            return false;
          }
        }
        
        // Status filter
        if (_selectedStatus != 'All') {
          if (_selectedStatus == 'Issued' && !record.certificateIssued) {
            return false;
          }
          if (_selectedStatus == 'Pending' && record.certificateIssued) {
            return false;
          }
        }
        
        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _nameController.clear();
      _regNumberController.clear();
      _placeController.clear();
      _selectedType = 'All';
      _selectedStatus = 'All';
      _startDate = null;
      _endDate = null;
      _selectedGender = null;
      _selectedPlace = null;
    });
    _performSearch();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
      _performSearch();
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
      _performSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Advanced Search',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearFilters,
            tooltip: 'Clear all filters',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          Flexible(
            child: SingleChildScrollView(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                // Search by Name
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Search by Name',
                    hintText: 'Enter name to search',
                    prefixIcon: const Icon(Icons.person),
                    suffixIcon: _nameController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _nameController.clear();
                              _performSearch();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => _performSearch(),
                ),
                const SizedBox(height: 12),
                
                // Registration Number
                TextField(
                  controller: _regNumberController,
                  decoration: InputDecoration(
                    labelText: 'Registration Number',
                    hintText: 'Enter registration number',
                    prefixIcon: const Icon(Icons.badge),
                    suffixIcon: _regNumberController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _regNumberController.clear();
                              _performSearch();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => _performSearch(),
                ),
                const SizedBox(height: 12),
                
                // Place
                TextField(
                  controller: _placeController,
                  decoration: InputDecoration(
                    labelText: 'Place',
                    hintText: 'Enter place of birth/death',
                    prefixIcon: const Icon(Icons.location_on),
                    suffixIcon: _placeController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _placeController.clear();
                              _performSearch();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => _performSearch(),
                ),
                const SizedBox(height: 12),
                
                // Type, Status, Gender filters in a row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Type',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All')),
                          DropdownMenuItem(value: 'Birth', child: Text('Birth')),
                          DropdownMenuItem(value: 'Death', child: Text('Death')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                          _performSearch();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          prefixIcon: const Icon(Icons.verified),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All')),
                          DropdownMenuItem(value: 'Issued', child: Text('Issued')),
                          DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                          _performSearch();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Gender filter
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: const Icon(Icons.wc),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                    _performSearch();
                  },
                ),
                const SizedBox(height: 12),
                
                // Date Range
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectStartDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _startDate == null
                                      ? 'Start Date'
                                      : DateFormat('yyyy-MM-dd').format(_startDate!),
                                  style: GoogleFonts.poppins(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _selectEndDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _endDate == null
                                      ? 'End Date'
                                      : DateFormat('yyyy-MM-dd').format(_endDate!),
                                  style: GoogleFonts.poppins(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                  ],
                ),
              ),
            ),
          ),
          
          // Results Section
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final totalResults = (_selectedType == 'All' || _selectedType == 'Birth' ? _filteredBirths.length : 0) +
                         (_selectedType == 'All' || _selectedType == 'Death' ? _filteredDeaths.length : 0);

    if (totalResults == 0) {
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
              'Try adjusting your filters',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Icon(Icons.filter_list, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                'Found $totalResults result${totalResults > 1 ? 's' : ''}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if ((_selectedType == 'All' || _selectedType == 'Birth') && _filteredBirths.isNotEmpty) ...[
                Text(
                  'Birth Records (${_filteredBirths.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
                const SizedBox(height: 12),
                ..._filteredBirths.map((record) => _buildRecordCard(
                  type: 'Birth',
                  name: record.childName,
                  date: record.dateOfBirth,
                  place: record.placeOfBirth,
                  regNumber: record.registrationNumber,
                  color: Colors.blue[600]!,
                  icon: Icons.child_care,
                  issued: record.certificateIssued,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.birthDetail,
                      arguments: record,
                    );
                  },
                )),
                const SizedBox(height: 24),
              ],
              if ((_selectedType == 'All' || _selectedType == 'Death') && _filteredDeaths.isNotEmpty) ...[
                Text(
                  'Death Records (${_filteredDeaths.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 12),
                ..._filteredDeaths.map((record) => _buildRecordCard(
                  type: 'Death',
                  name: record.name,
                  date: record.dateOfDeath,
                  place: record.placeOfDeath,
                  regNumber: record.registrationNumber,
                  color: Colors.red[600]!,
                  icon: Icons.airline_seat_flat,
                  issued: record.certificateIssued,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.deathDetail,
                      arguments: record,
                    );
                  },
                )),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecordCard({
    required String type,
    required String name,
    required DateTime date,
    required String place,
    required String regNumber,
    required Color color,
    required IconData icon,
    required bool issued,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[900],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: issued ? Colors.green[100] : Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              issued ? 'Issued' : 'Pending',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: issued ? Colors.green[700] : Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('yyyy-MM-dd').format(date)} • $place',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Reg: $regNumber',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideX();
  }
}

