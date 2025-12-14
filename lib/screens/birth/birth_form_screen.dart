import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/records_provider.dart';
import '../../models/birth_record.dart';
import '../../widgets/primary_button.dart';
import '../../services/document_storage_service.dart';

class BirthFormScreen extends StatefulWidget {
  final BirthRecord? recordToEdit;
  const BirthFormScreen({super.key, this.recordToEdit});

  @override
  State<BirthFormScreen> createState() => _BirthFormScreenState();
}

class _BirthFormScreenState extends State<BirthFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _childController = TextEditingController();
  final _placeController = TextEditingController();
  final _motherController = TextEditingController();
  final _fatherController = TextEditingController();
  final _motherIdController = TextEditingController();
  final _fatherIdController = TextEditingController();
  final _motherPhoneController = TextEditingController();
  final _fatherPhoneController = TextEditingController();
  final _motherEmailController = TextEditingController();

  // Helper function to generate document ID with child's name
  String _generateDocumentIdWithName(String childName) {
    // Sanitize the name: remove special characters, convert to lowercase, replace spaces with underscores
    String sanitizedName = childName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), '_'); // Replace spaces with underscores
    
    // Limit length to 30 characters
    if (sanitizedName.length > 30) {
      sanitizedName = sanitizedName.substring(0, 30);
    }
    
    // Remove trailing underscores
    sanitizedName = sanitizedName.replaceAll(RegExp(r'_+$'), '');
    
    // If name is empty after sanitization, use a default
    if (sanitizedName.isEmpty) {
      sanitizedName = 'child';
    }
    
    // Add a short UUID for uniqueness (first 8 characters)
    final shortUuid = const Uuid().v4().substring(0, 8);
    
    // Combine: name_uuid
    return '${sanitizedName}_$shortUuid';
  }
  final _fatherEmailController = TextEditingController();
  final _motherCitizenshipController = TextEditingController();
  final _fatherCitizenshipController = TextEditingController();
  final _declarationController = TextEditingController();

  DateTime? _dob;
  File? _imageFile;
  File? _fatherIdDocument;
  File? _motherIdDocument;
  String? _fatherDocumentType; // 'ID' or 'Passport'
  String? _motherDocumentType; // 'ID' or 'Passport'
  String? _gender;
  bool _bornOutsideRegion = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.recordToEdit != null;
    if (_isEditing && widget.recordToEdit != null) {
      final record = widget.recordToEdit!;
      _childController.text = record.childName;
      _placeController.text = record.placeOfBirth;
      _motherController.text = record.motherName;
      _fatherController.text = record.fatherName;
      _motherIdController.text = record.motherNationalId;
      _fatherIdController.text = record.fatherNationalId;
      _motherPhoneController.text = record.motherPhone;
      _fatherPhoneController.text = record.fatherPhone;
      _motherEmailController.text = record.motherEmail;
      _fatherEmailController.text = record.fatherEmail;
      _motherCitizenshipController.text = record.motherCitizenship;
      _fatherCitizenshipController.text = record.fatherCitizenship;
      _declarationController.text = record.declaration;
      _dob = record.dateOfBirth;
      _gender = record.gender;
      _bornOutsideRegion = record.bornOutsideRegion;
      if (record.photoPath.isNotEmpty && File(record.photoPath).existsSync()) {
        _imageFile = File(record.photoPath);
      }
      if (record.fatherIdDocumentPath != null && record.fatherIdDocumentPath!.isNotEmpty && File(record.fatherIdDocumentPath!).existsSync()) {
        _fatherIdDocument = File(record.fatherIdDocumentPath!);
      }
      if (record.motherIdDocumentPath != null && record.motherIdDocumentPath!.isNotEmpty && File(record.motherIdDocumentPath!).existsSync()) {
        _motherIdDocument = File(record.motherIdDocumentPath!);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _pickDocument({required bool isFather}) async {
    if (!mounted) return;
    
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      // Show dialog to select document type (ID or Passport)
      final documentType = await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Select Document Type',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Please select the type of document you are uploading:',
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, 'ID'),
                  icon: const Icon(Icons.badge, color: Colors.white),
                  label: Text(
                    'National ID',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, 'Passport'),
                  icon: const Icon(Icons.book, color: Colors.white),
                  label: Text(
                    'Passport',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

      // Only set the document if user selected ID or Passport
      if (mounted) {
        if (documentType != null && (documentType == 'ID' || documentType == 'Passport')) {
          setState(() {
            if (isFather) {
              _fatherIdDocument = File(picked.path);
              _fatherDocumentType = documentType;
            } else {
              _motherIdDocument = File(picked.path);
              _motherDocumentType = documentType;
            }
          });
        } else if (documentType != null && mounted) {
          // User cancelled - show message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please select either ID or Passport. Only these documents are accepted.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.orange[600],
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select Date of Birth")),
      );
      return;
    }
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      final recordId = _isEditing 
          ? widget.recordToEdit!.id 
          : _generateDocumentIdWithName(_childController.text.trim());
      
      // Save documents to permanent storage
      String? savedPhotoPath;
      String? savedFatherDocPath;
      String? savedMotherDocPath;
      
      // Save photo if new one is selected
      if (_imageFile != null) {
        // Check if it's already in permanent storage (starts with app documents path)
        final isPermanentPath = _imageFile!.path.contains('birth_photos') || 
                                _imageFile!.path.contains('birth_documents');
        if (!isPermanentPath) {
          // Save to permanent storage
          savedPhotoPath = await DocumentStorageService.savePhoto(
            sourceFile: _imageFile!,
            recordId: recordId,
          );
        } else {
          // Already in permanent storage, use existing path
          savedPhotoPath = _imageFile!.path;
        }
      } else if (_isEditing && widget.recordToEdit!.photoPath.isNotEmpty) {
        // Use existing photo path
        savedPhotoPath = widget.recordToEdit!.photoPath;
      }
      
      // Save father's ID document if new one is selected
      if (_fatherIdDocument != null) {
        // Check if it's already in permanent storage
        final isPermanentPath = _fatherIdDocument!.path.contains('birth_documents');
        if (!isPermanentPath) {
          // Save to permanent storage
          savedFatherDocPath = await DocumentStorageService.saveDocument(
            sourceFile: _fatherIdDocument!,
            recordId: recordId,
            documentType: 'father_id',
          );
        } else {
          // Already in permanent storage, use existing path
          savedFatherDocPath = _fatherIdDocument!.path;
        }
      } else if (_isEditing && widget.recordToEdit!.fatherIdDocumentPath != null && 
                 widget.recordToEdit!.fatherIdDocumentPath!.isNotEmpty) {
        // Use existing document path
        savedFatherDocPath = widget.recordToEdit!.fatherIdDocumentPath;
      }
      
      // Save mother's ID document if new one is selected
      if (_motherIdDocument != null) {
        // Check if it's already in permanent storage
        final isPermanentPath = _motherIdDocument!.path.contains('birth_documents');
        if (!isPermanentPath) {
          // Save to permanent storage
          savedMotherDocPath = await DocumentStorageService.saveDocument(
            sourceFile: _motherIdDocument!,
            recordId: recordId,
            documentType: 'mother_id',
          );
        } else {
          // Already in permanent storage, use existing path
          savedMotherDocPath = _motherIdDocument!.path;
        }
      } else if (_isEditing && widget.recordToEdit!.motherIdDocumentPath != null && 
                 widget.recordToEdit!.motherIdDocumentPath!.isNotEmpty) {
        // Use existing document path
        savedMotherDocPath = widget.recordToEdit!.motherIdDocumentPath;
      }
      
      final record = BirthRecord(
        id: recordId,
        childName: _childController.text.trim(),
        dateOfBirth: _dob!,
        placeOfBirth: _placeController.text.trim(),
        motherName: _motherController.text.trim(),
        fatherName: _fatherController.text.trim(),
        registrationNumber: _isEditing 
            ? widget.recordToEdit!.registrationNumber 
            : "BR-${DateTime.now().millisecondsSinceEpoch}",
        gender: _gender ?? "Not Specified",
        motherId: _motherIdController.text.trim(),
        fatherId: _fatherIdController.text.trim(),
        motherPhone: _motherPhoneController.text.trim(),
        fatherPhone: _fatherPhoneController.text.trim(),
        motherEmail: _motherEmailController.text.trim(),
        fatherEmail: _fatherEmailController.text.trim(),
        motherCitizenship: _motherCitizenshipController.text.trim(),
        fatherCitizenship: _fatherCitizenshipController.text.trim(),
        bornOutsideRegion: _bornOutsideRegion,
        declaration: _declarationController.text.trim(),
        imagePath: savedPhotoPath ?? "",
        declarationStatement: '',
        fatherNationalId: _fatherIdController.text.trim(),
        motherNationalId: _motherIdController.text.trim(),
        photoPath: savedPhotoPath ?? '',
        certificateIssued: _isEditing ? widget.recordToEdit!.certificateIssued : false,
        certificateIssuedDate: _isEditing ? widget.recordToEdit!.certificateIssuedDate : null,
        certificateIssuedBy: _isEditing ? widget.recordToEdit!.certificateIssuedBy : null,
        fatherIdDocumentPath: savedFatherDocPath,
        motherIdDocumentPath: savedMotherDocPath,
        approvalStatus: _isEditing ? widget.recordToEdit!.approvalStatus : 'pending',
        approvedBy: _isEditing ? widget.recordToEdit!.approvedBy : null,
        approvedAt: _isEditing ? widget.recordToEdit!.approvedAt : null,
        rejectionReason: _isEditing ? widget.recordToEdit!.rejectionReason : null,
      );
      
      final provider = Provider.of<RecordsProvider>(context, listen: false);
      if (_isEditing) {
        provider.updateBirth(record);
        if (context.mounted) {
          // Close loading dialog
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Birth record updated successfully")));
          // Close form screen using microtask to avoid navigation lock
          Future.microtask(() {
            if (context.mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          });
        }
      } else {
        provider.addBirth(record);
        if (context.mounted) {
          // Close loading dialog
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Birth registered successfully")));
          // Close form screen using microtask to avoid navigation lock
          Future.microtask(() {
            if (context.mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          });
        }
      }
    } catch (e) {
      // Close loading dialog on error
      if (context.mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving record: $e"),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _isEditing ? "Edit Birth Record" : "Register Birth",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Fill all required fields to register a birth",
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: Colors.blue[600],
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
                      colors: [Colors.blue[600]!, Colors.purple[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _isEditing ? "Edit Birth Record" : "Birth Registration",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 8),
                      Text(
                        _isEditing 
                            ? "Update birth record information"
                            : "Register a new birth in the system",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                    ],
                  ),
                ),
                
                // Form Content
                // Remove all Card/Container code except for top gradient header.
                // Instead, use only spacing, Section titles, and Divider where needed.
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
                                  colors: [Colors.blue[100]!, Colors.purple[100]!],
                                ),
                                border: Border.all(color: Colors.blue[300]!, width: 3),
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
                                          Icons.camera_alt,
                                          size: 40,
                                          color: Colors.blue[600],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Tap to add photo",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.blue[600],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Child Photo",
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
                    
                    // Child Information Section
                    _buildSectionHeader("Child Information", Icons.child_care),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _childController,
                      label: "Child Full Name",
                      icon: Icons.person,
                      validator: (v) => v == null || v.isEmpty ? "Required" : null,
                    ).animate().slideX(delay: 800.ms),
                    
                    const SizedBox(height: 16),
                    
                    _buildDropdown(
                      value: _gender,
                      label: "Gender",
                      icon: Icons.wc,
                      items: const [
                        DropdownMenuItem(value: "Male", child: Text("Male")),
                        DropdownMenuItem(value: "Female", child: Text("Female")),
                      ],
                      onChanged: (v) => setState(() => _gender = v),
                    ).animate().slideX(delay: 1000.ms),
                    
                    const SizedBox(height: 16),
                    
                    _buildDateField(
                      label: "Date of Birth",
                      value: _dob,
                      onTap: _pickDob,
                      icon: Icons.calendar_today,
                    ).animate().slideX(delay: 1200.ms),
                    
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _placeController,
                      label: "Place of Birth",
                      icon: Icons.location_on,
                      validator: (v) => v == null || v.isEmpty ? "Required" : null,
                    ).animate().slideX(delay: 1400.ms),
                    
                    const SizedBox(height: 32),
                    
                    // Document Collection Helper
                    _buildDocumentChecklist().animate().slideX(delay: 1500.ms),
                    
                    const SizedBox(height: 32),
                    
                    // Parents Information Section
                    _buildSectionHeader("Parents Information", Icons.family_restroom),
                    const SizedBox(height: 16),
                    
                    // Mother Information
                    _buildSubSectionHeader("Mother's Information", Icons.woman),
                    const SizedBox(height: 12),
                    
                    _buildTextField(
                      controller: _motherController,
                      label: "Mother's Full Name",
                      icon: Icons.person,
                      validator: (v) => v == null || v.isEmpty ? "Required" : null,
                    ).animate().slideX(delay: 1600.ms),
                    
                    const SizedBox(height: 12),
                    
                    _buildTextField(
                      controller: _motherIdController,
                      label: "Mother National ID",
                      icon: Icons.credit_card,
                    ).animate().slideX(delay: 1800.ms),
                    
                    const SizedBox(height: 12),
                    
                    // Mother's ID Document Upload
                    _buildDocumentUpload(
                      label: "Mother's ID/LP Document",
                      file: _motherIdDocument,
                      onTap: () => _pickDocument(isFather: false),
                      icon: Icons.upload_file,
                      documentType: _motherDocumentType,
                    ).animate().slideX(delay: 1900.ms),
                    
                    const SizedBox(height: 12),
                    
                    _buildTextField(
                      controller: _motherPhoneController,
                      label: "Mother Phone Number",
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ).animate().slideX(delay: 2000.ms),
                    
                    const SizedBox(height: 12),
                    
                    _buildTextField(
                      controller: _motherEmailController,
                      label: "Mother Email",
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return null; // Optional field
                        }
                        final email = v.trim().toLowerCase();
                        if (!email.endsWith('@gmail.com')) {
                          return 'Email must be @gmail.com only';
                        }
                        // Basic email format validation
                        if (!RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$').hasMatch(email)) {
                          return 'Please enter a valid Gmail address';
                        }
                        return null;
                      },
                    ).animate().slideX(delay: 2200.ms),
                    
                    const SizedBox(height: 12),
                    
                    _buildTextField(
                      controller: _motherCitizenshipController,
                      label: "Mother Citizenship",
                      icon: Icons.flag,
                    ).animate().slideX(delay: 2400.ms),
                    
                    const SizedBox(height: 24),
                    
                    // Father Information
                    _buildSubSectionHeader("Father's Information", Icons.man),
                    const SizedBox(height: 12),
                    
                    _buildTextField(
                      controller: _fatherController,
                      label: "Father's Full Name",
                      icon: Icons.person,
                      validator: (v) => v == null || v.isEmpty ? "Required" : null,
                    ).animate().slideX(delay: 2600.ms),
                    
                    const SizedBox(height: 12),
                    
                    _buildTextField(
                      controller: _fatherIdController,
                      label: "Father National ID",
                      icon: Icons.credit_card,
                    ).animate().slideX(delay: 2800.ms),
                    
                    const SizedBox(height: 12),
                    
                    // Father's ID Document Upload
                    _buildDocumentUpload(
                      label: "Father's ID/LP Document",
                      file: _fatherIdDocument,
                      onTap: () => _pickDocument(isFather: true),
                      icon: Icons.upload_file,
                      documentType: _fatherDocumentType,
                    ).animate().slideX(delay: 2900.ms),
                    
                    const SizedBox(height: 12),
                    
                    _buildTextField(
                      controller: _fatherPhoneController,
                      label: "Father Phone Number",
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ).animate().slideX(delay: 3000.ms),
                    
                    const SizedBox(height: 12),
                    
                    _buildTextField(
                      controller: _fatherEmailController,
                      label: "Father Email",
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return null; // Optional field
                        }
                        final email = v.trim().toLowerCase();
                        if (!email.endsWith('@gmail.com')) {
                          return 'Email must be @gmail.com only';
                        }
                        // Basic email format validation
                        if (!RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$').hasMatch(email)) {
                          return 'Please enter a valid Gmail address';
                        }
                        return null;
                      },
                    ).animate().slideX(delay: 3200.ms),
                    
                    const SizedBox(height: 12),
                    
                    _buildTextField(
                      controller: _fatherCitizenshipController,
                      label: "Father Citizenship",
                      icon: Icons.flag,
                    ).animate().slideX(delay: 3400.ms),
                    
                    const SizedBox(height: 32),
                    
                    // Declaration Section
                    _buildSectionHeader("Declaration", Icons.description),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          "Was the child born outside the region?",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                        ),
                        value: _bornOutsideRegion,
                        onChanged: (val) => setState(() => _bornOutsideRegion = val),
                        activeColor: Colors.orange[600],
                      ),
                    ).animate().slideX(delay: 3600.ms),
                    
                    if (_bornOutsideRegion) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _declarationController,
                        label: "Declaration Details",
                        icon: Icons.edit_note,
                        maxLines: 3,
                        hintText: "Explain the reason and location of birth",
                      ).animate().slideX(delay: 3800.ms),
                    ],
                    
                    const SizedBox(height: 40),
                    
                    // Submit Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[600]!, Colors.purple[600]!],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
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
                          _isEditing ? "Update Record" : "Register Birth",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ).animate().scale(delay: 4000.ms),
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
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue[600], size: 20),
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
  
  Widget _buildSubSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
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
        prefixIcon: Icon(icon, color: Colors.blue[600]),
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
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }
  
  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(),
        prefixIcon: Icon(icon, color: Colors.blue[600]),
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
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items,
      onChanged: onChanged,
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
            Icon(icon, color: Colors.blue[600]),
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
                        ? "Select Date of Birth"
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

  Widget _buildDocumentUpload({
    required String label,
    required File? file,
    required VoidCallback onTap,
    required IconData icon,
    String? documentType,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file != null ? Colors.green[300]! : Colors.grey[300]!,
            width: file != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: file != null ? Colors.green[100] : Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                file != null ? Icons.check_circle : icon,
                color: file != null ? Colors.green[700] : Colors.blue[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    file != null 
                        ? documentType != null 
                            ? "$documentType uploaded ✓"
                            : "Document uploaded ✓"
                        : "Tap to upload (ID or Passport only)",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: file != null ? Colors.green[700] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (file != null)
              Icon(Icons.check_circle, color: Colors.green[600], size: 20)
            else
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentChecklist() {
    final hasFatherDoc = _fatherIdDocument != null;
    final hasMotherDoc = _motherIdDocument != null;
    final allDocumentsReady = hasFatherDoc && hasMotherDoc;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: allDocumentsReady 
              ? [Colors.green[50]!, Colors.green[100]!]
              : [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allDocumentsReady ? Colors.green[300]! : Colors.blue[300]!,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: allDocumentsReady ? Colors.green[600] : Colors.blue[600],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  allDocumentsReady ? Icons.checklist_rtl : Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Required Documents Checklist",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              if (allDocumentsReady)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Complete ✓",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildChecklistItem(
            label: "Father's ID/LP Document",
            isCompleted: hasFatherDoc,
            documentType: _fatherDocumentType,
            onTap: () => _pickDocument(isFather: true),
          ),
          const SizedBox(height: 12),
          _buildChecklistItem(
            label: "Mother's ID/LP Document",
            isCompleted: hasMotherDoc,
            documentType: _motherDocumentType,
            onTap: () => _pickDocument(isFather: false),
          ),
          if (!allDocumentsReady) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Please upload all required documents (ID or Passport only) to proceed with registration",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChecklistItem({
    required String label,
    required bool isCompleted,
    required VoidCallback onTap,
    String? documentType,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCompleted ? Colors.green[300]! : Colors.grey[300]!,
            width: isCompleted ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? Colors.green[600] : Colors.grey[300],
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : const Icon(Icons.radio_button_unchecked, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w500,
                      color: isCompleted ? Colors.green[700] : Colors.grey[700],
                      decoration: isCompleted ? TextDecoration.none : null,
                    ),
                  ),
                  if (isCompleted && documentType != null)
                    Text(
                      "Type: $documentType",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            if (!isCompleted)
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16)
            else
              Icon(Icons.check_circle, color: Colors.green[600], size: 20),
          ],
        ),
      ),
    );
  }
}
