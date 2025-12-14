import "dart:io";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "package:provider/provider.dart";
import "package:uuid/uuid.dart";
import "package:google_fonts/google_fonts.dart";
import "package:flutter_animate/flutter_animate.dart";
import "../../providers/records_provider.dart";
import "../../models/death_record.dart";
import "../../widgets/primary_button.dart";

class DeathFormScreen extends StatefulWidget {
  final DeathRecord? recordToEdit;
  const DeathFormScreen({super.key, this.recordToEdit});

  @override
  State<DeathFormScreen> createState() => _DeathFormScreenState();
}

class _DeathFormScreenState extends State<DeathFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _placeController = TextEditingController();
  final _causeController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _familyRelationController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _familyPhoneController = TextEditingController();
  final _ageController = TextEditingController();
  DateTime? _dod;
  File? _imageFile;
  String? _selectedGender; // 'Male' or 'Female'
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.recordToEdit != null;
    final rec = widget.recordToEdit;
    if (rec != null) {
      _nameController.text = rec.name;
      _placeController.text = rec.placeOfDeath;
      _causeController.text = rec.cause;
      _idNumberController.text = rec.idNumber ?? '';
      _hospitalController.text = rec.hospital ?? '';
      _familyRelationController.text = rec.familyRelation ?? '';
      _familyNameController.text = rec.familyName ?? '';
      _familyPhoneController.text = rec.familyPhone ?? '';
      _ageController.text = rec.age?.toString() ?? '';
      _selectedGender = rec.gender;
      _dod = rec.dateOfDeath;
      // If you have image support, populate _imageFile as well.
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _pickDod() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dod = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_dod == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please select Date of Death")));
      return;
    }
    final record = DeathRecord(
      id: _isEditing ? widget.recordToEdit!.id : const Uuid().v4(),
      name: _nameController.text.trim(),
      dateOfDeath: _dod!,
      placeOfDeath: _placeController.text.trim(),
      cause: _causeController.text.trim(),
      registrationNumber: _isEditing
          ? widget.recordToEdit!.registrationNumber
          : "DR-${DateTime.now().millisecondsSinceEpoch}",
      idNumber: _idNumberController.text.trim().isNotEmpty ? _idNumberController.text.trim() : null,
      hospital: _hospitalController.text.trim().isNotEmpty ? _hospitalController.text.trim() : null,
      familyRelation: _familyRelationController.text.trim().isNotEmpty ? _familyRelationController.text.trim() : null,
      familyName: _familyNameController.text.trim().isNotEmpty ? _familyNameController.text.trim() : null,
      familyPhone: _familyPhoneController.text.trim().isNotEmpty ? _familyPhoneController.text.trim() : null,
      gender: _selectedGender,
      age: _ageController.text.trim().isNotEmpty ? int.tryParse(_ageController.text.trim()) : null,
      certificateIssued: _isEditing ? widget.recordToEdit!.certificateIssued : false,
      certificateIssuedDate: _isEditing ? widget.recordToEdit!.certificateIssuedDate : null,
      certificateIssuedBy: _isEditing ? widget.recordToEdit!.certificateIssuedBy : null,
    );
    final provider = Provider.of<RecordsProvider>(context, listen: false);
    if (_isEditing) {
      provider.updateDeath(record);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Death record updated successfully")));
    } else {
      provider.addDeath(record);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Death registered successfully")));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Register Death",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.red[600],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Fill all required fields to register a death",
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: Colors.red[600],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red[600]!, Colors.orange[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Death Registration",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 8),
                      Text(
                        "Register a death in the system",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                    ],
                  ),
                ),
                
                // Form Content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo Section
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.red[100]!, Colors.orange[100]!],
                                ),
                                border: Border.all(color: Colors.red[300]!, width: 3),
                              ),
                              child: _imageFile != null
                                  ? ClipOval(
                                      child: Image.file(
                                        _imageFile!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Colors.red[600],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Tap to add photo",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.red[600],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Deceased Photo",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ).animate().scale(delay: 600.ms),
                    
                    const SizedBox(height: 32),
                    
                    // Death Information Section
                    _buildSectionHeader("Death Information", Icons.airline_seat_flat),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _nameController,
                      label: "Full Name of Deceased",
                      icon: Icons.person,
                      validator: (v) => v == null || v.isEmpty ? "Required" : null,
                    ).animate().slideX(delay: 800.ms),
                    
                    const SizedBox(height: 16),
                    
                    _buildDateField(
                      label: "Date of Death",
                      value: _dod,
                      onTap: _pickDod,
                      icon: Icons.calendar_today,
                    ).animate().slideX(delay: 1000.ms),
                    
                    const SizedBox(height: 16),
                    
                    // Gender Selection
                    _buildGenderSelector().animate().slideX(delay: 1100.ms),
                    
                    const SizedBox(height: 16),
                    
                    // Age Field
                    _buildTextField(
                      controller: _ageController,
                      label: "Age (optional)",
                      icon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      hintText: "Enter age at time of death",
                    ).animate().slideX(delay: 1150.ms),
                    
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _placeController,
                      label: "Place of Death",
                      icon: Icons.location_on,
                      validator: (v) => v == null || v.isEmpty ? "Required" : null,
                    ).animate().slideX(delay: 1200.ms),
                    
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _causeController,
                      label: "Cause of Death",
                      icon: Icons.medical_services,
                      maxLines: 3,
                      hintText: "Enter the cause of death (optional)",
                    ).animate().slideX(delay: 1400.ms),
                    
                    const SizedBox(height: 16),

                    // ADDITIONAL FIELDS
                    _buildTextField(
                      controller: _idNumberController,
                      label: "ID Number (optional)",
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                    ).animate().slideX(delay: 1500.ms),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _hospitalController,
                      label: "Hospital (optional)",
                      icon: Icons.local_hospital,
                    ).animate().slideX(delay: 1600.ms),
                    const SizedBox(height: 24),

                    Text("Family / Next of Kin / Relative Info", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.grey[800])),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _familyRelationController,
                      label: "Relation to Deceased (optional)",
                      icon: Icons.group,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _familyNameController,
                      label: "Next of Kin/Relative Name (optional)",
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _familyPhoneController,
                      label: "Family Phone (optional)",
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red[600]!, Colors.orange[600]!],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          "Register Death",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ).animate().scale(delay: 1600.ms),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.red[600], size: 20),
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
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: GoogleFonts.poppins(),
        prefixIcon: Icon(icon, color: Colors.red[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[600]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }
  
  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.red[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value == null
                        ? "Select Date of Death"
                        : value.toLocal().toIso8601String().split("T")[0],
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: value == null ? Colors.grey[500] : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people, color: Colors.red[600], size: 20),
            const SizedBox(width: 8),
            Text(
              "Gender",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedGender = 'Male';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _selectedGender == 'Male' 
                        ? const Color(0xFF3B82F6).withOpacity(0.1)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedGender == 'Male'
                          ? const Color(0xFF3B82F6)
                          : Colors.grey[300]!,
                      width: _selectedGender == 'Male' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.male,
                        color: _selectedGender == 'Male'
                            ? const Color(0xFF3B82F6)
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Male',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: _selectedGender == 'Male'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedGender == 'Male'
                              ? const Color(0xFF3B82F6)
                              : Colors.grey[700],
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
                onTap: () {
                  setState(() {
                    _selectedGender = 'Female';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _selectedGender == 'Female'
                        ? const Color(0xFFEC4899).withOpacity(0.1)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedGender == 'Female'
                          ? const Color(0xFFEC4899)
                          : Colors.grey[300]!,
                      width: _selectedGender == 'Female' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.female,
                        color: _selectedGender == 'Female'
                            ? const Color(0xFFEC4899)
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Female',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: _selectedGender == 'Female'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedGender == 'Female'
                              ? const Color(0xFFEC4899)
                              : Colors.grey[700],
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
    );
  }
}
