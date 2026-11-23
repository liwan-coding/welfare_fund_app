import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoButton, CupertinoIcons;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../design/design.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../services/student_registration_service.dart';
import '../providers/auth_provider.dart';

class StudentRegistrationScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final bool isReadOnly;

  const StudentRegistrationScreen({
    super.key,
    this.existingData,
    this.isReadOnly = false,
  });

  @override
  State<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  static const int _stepCount = 4;

  // Wizard state. Each step has its own Form so "Continue" validates only
  // that step; the final submit re-validates all of them.
  final _pageController = PageController();
  final _stepKeys = List.generate(_stepCount, (_) => GlobalKey<FormState>());
  int _step = 0;

  // Form Controllers

  // البيانات الشخصية (Personal)
  final _fullNameController = TextEditingController();
  final _civilIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime? _selectedDateOfBirth;
  String _selectedMaritalStatus = 'single';

  // البيانات الأكاديمية (Academic)
  final _institutionController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _collegeController = TextEditingController();
  final _majorController = TextEditingController();
  final _programController = TextEditingController();
  final _gpaController = TextEditingController();
  String? _selectedAcademicYear;

  // بيانات ولي الأمر (Guardian)
  final _guardianNameController = TextEditingController();
  final _guardianJobController = TextEditingController();
  final _guardianIncomeController = TextEditingController();
  final _guardianFamilySizeController = TextEditingController();
  bool _isFatherAlive = true;
  bool _isMotherAlive = true;
  String _parentsMaritalStatus = 'stable';

  // Programs data
  List<Map<String, dynamic>> _programs = [];
  String? _selectedProgramId;
  bool _isLoadingPrograms = false;

  // المرفقات (Documents)
  final Map<String, Uint8List> _documentFiles = {};
  final Map<String, String> _documentFileNames = {};

  // Application Status
  String _applicationStatus = 'under_review';
  String? _rejectionReason;

  // Services
  final StudentRegistrationService _studentService =
      StudentRegistrationService();

  // قيم الحالة الاجتماعية
  final List<String> _maritalStatusOptions = [
    'single',
    'married',
    'divorced',
    'widowed'
  ];

  // قيم حالة الوالدين
  final List<String> _parentsMaritalStatusOptions = ['stable', 'separated'];

  // Academic Year Options
  final List<String> _academicYears = [
    'first_year',
    'second_year',
    'third_year',
    'fourth_year',
    'fifth_year',
    'sixth_year',
  ];

  @override
  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _loadExistingData();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillFromUserProfile();
    });

    _loadPrograms();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshProgramNamesForCurrentLocale();
  }

  void _refreshProgramNamesForCurrentLocale() {
    if (_programs.isNotEmpty && _selectedProgramId != null) {
      setState(() {
        final selectedProgram = _programs.firstWhere(
          (program) => program['id']?.toString() == _selectedProgramId,
          orElse: () => {},
        );
        if (selectedProgram.isNotEmpty) {
          _programController.text =
              StudentRegistrationService.getLocalizedProgramName(
                  selectedProgram, context.locale.languageCode);
        }
      });
    }
  }

  void _loadExistingData() {
    final data = widget.existingData!;

    print('=== Loading Existing Data Debug ===');
    print('Data: $data');

    // Normalize status
    String rawStatus = data['status']?.toString() ?? 'under_review';
    String normalizedStatus = rawStatus.toLowerCase();

    switch (normalizedStatus) {
      case 'under_review':
      case 'قيد المراجعة':
        _applicationStatus = 'under_review';
        break;
      case 'accepted':
      case 'مقبول':
        _applicationStatus = 'accepted';
        break;
      case 'rejected':
      case 'مرفوض':
        _applicationStatus = 'rejected';
        break;
      case 'completed':
      case 'مكتمل':
        _applicationStatus = 'completed';
        break;
      default:
        _applicationStatus = 'under_review';
    }

    _rejectionReason = data['rejection_reason']?.toString();
    if (_rejectionReason != null && _rejectionReason!.isEmpty) {
      _rejectionReason = null;
    }

    // Load personal data
    final personal = data['personal'] as Map<String, dynamic>? ?? {};
    _fullNameController.text = personal['full_name'] ?? data['full_name'] ?? '';
    _civilIdController.text = personal['civil_id'] ?? '';
    _phoneController.text = personal['phone'] ?? data['phone'] ?? '';
    _addressController.text = personal['address'] ?? '';
    _emailController.text = personal['email'] ?? data['email'] ?? '';
    _selectedMaritalStatus = personal['marital_status'] ?? 'single';

    // Parse date of birth
    final dobString = personal['date_of_birth'] ?? data['date_of_birth'];
    if (dobString != null) {
      _selectedDateOfBirth = DateTime.tryParse(dobString.toString());
    }

    // Load academic data
    final academic = data['academic'] as Map<String, dynamic>? ?? {};
    _institutionController.text =
        academic['institution'] ?? data['university'] ?? '';
    _studentIdController.text =
        academic['student_id'] ?? data['student_id'] ?? '';
    _collegeController.text = academic['college'] ?? data['college'] ?? '';
    _majorController.text = academic['major'] ?? data['major'] ?? '';
    _programController.text = academic['program'] ?? '';
    _gpaController.text = (academic['gpa'] ?? data['gpa'] ?? '').toString();
    _selectedAcademicYear = _convertAcademicYearToString(
        academic['academic_year'] ?? data['academic_year'] ?? 1);
    _selectedProgramId = data['program_id']?.toString();

    // Load guardian data
    final guardian = data['guardian'] as Map<String, dynamic>? ?? {};
    _guardianNameController.text = guardian['name'] ?? '';
    _guardianJobController.text = guardian['job'] ?? '';
    _guardianIncomeController.text =
        (guardian['monthly_income'] ?? '').toString();
    _guardianFamilySizeController.text =
        (guardian['family_size'] ?? '').toString();
    _isFatherAlive =
        guardian['is_father_alive'] == true || guardian['is_father_alive'] == 1;
    _isMotherAlive =
        guardian['is_mother_alive'] == true || guardian['is_mother_alive'] == 1;
    _parentsMaritalStatus = guardian['parents_marital_status'] ?? 'stable';
  }

  void _prefillFromUserProfile() {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final profile = auth.userProfile;
      if (profile == null) return;

      final extractedName = profile['name'] ?? profile['user']?['name'] ?? '';
      final extractedEmail =
          profile['email'] ?? profile['user']?['email'] ?? '';
      final extractedPhone =
          profile['phone'] ?? profile['user']?['phone'] ?? '';

      setState(() {
        if (extractedName is String &&
            extractedName.isNotEmpty &&
            _fullNameController.text.isEmpty) {
          _fullNameController.text = extractedName;
        }
        if (extractedEmail is String &&
            extractedEmail.isNotEmpty &&
            _emailController.text.isEmpty) {
          _emailController.text = extractedEmail;
        }
        if (extractedPhone is String &&
            extractedPhone.isNotEmpty &&
            _phoneController.text.isEmpty) {
          _phoneController.text = extractedPhone;
        }
      });
    } catch (e) {
      debugPrint('Prefill error: $e');
    }
  }

  String _convertAcademicYearToString(dynamic year) {
    final yearNum = year is int ? year : int.tryParse(year.toString()) ?? 1;
    switch (yearNum) {
      case 1:
        return 'first_year';
      case 2:
        return 'second_year';
      case 3:
        return 'third_year';
      case 4:
        return 'fourth_year';
      case 5:
        return 'fifth_year';
      case 6:
        return 'sixth_year';
      default:
        return 'first_year';
    }
  }

  int _convertAcademicYearToNumber(String? academicYear) {
    switch (academicYear) {
      case 'first_year':
        return 1;
      case 'second_year':
        return 2;
      case 'third_year':
        return 3;
      case 'fourth_year':
        return 4;
      case 'fifth_year':
        return 5;
      case 'sixth_year':
        return 6;
      default:
        return 1;
    }
  }

  String _getTranslatedValue(String value) {
    // Handle marital status
    if (['single', 'married', 'divorced', 'widowed'].contains(value)) {
      return value.tr();
    }

    // Handle parents marital status
    if (['stable', 'separated'].contains(value)) {
      return value.tr();
    }

    // Handle academic year values
    if (_academicYears.contains(value)) {
      return value.tr();
    }

    return value;
  }

  bool get _isReadOnly {
    if (widget.existingData == null) {
      return false;
    }

    String normalizedStatus = _applicationStatus.toLowerCase();

    return widget.isReadOnly ||
        normalizedStatus == 'under_review' ||
        normalizedStatus == 'accepted' ||
        normalizedStatus == 'completed';
  }

  bool get _isRejected {
    String normalizedStatus = _applicationStatus.toLowerCase();
    return normalizedStatus == 'rejected';
  }

  String _getStatusText(String status) {
    String normalizedStatus = status.toLowerCase();

    switch (normalizedStatus) {
      case 'under_review':
        return 'application_under_review'.tr();
      case 'accepted':
        return 'application_approved'.tr();
      case 'rejected':
        return 'application_rejected'.tr();
      case 'completed':
        return 'application_completed'.tr();
      default:
        return 'application_under_review'.tr();
    }
  }

  Color _getStatusColor(String status) {
    String normalizedStatus = status.toLowerCase();

    switch (normalizedStatus) {
      case 'under_review':
        return AppColors.warning;
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'completed':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  IconData _getStatusIcon(String status) {
    String normalizedStatus = status.toLowerCase();

    switch (normalizedStatus) {
      case 'under_review':
        return Icons.hourglass_empty;
      case 'accepted':
        return CupertinoIcons.checkmark_circle_fill;
      case 'rejected':
        return CupertinoIcons.xmark_circle_fill;
      case 'completed':
        return Icons.verified;
      default:
        return Icons.hourglass_empty;
    }
  }

  String _getStatusDescription(String status) {
    String normalizedStatus = status.toLowerCase();

    switch (normalizedStatus) {
      case 'under_review':
        return 'application_under_review_description'.tr();
      case 'accepted':
        return 'application_approved_description'.tr();
      case 'rejected':
        return 'application_rejected_description'.tr();
      case 'completed':
        return 'application_completed_description'.tr();
      default:
        return 'application_under_review_description'.tr();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _civilIdController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _institutionController.dispose();
    _studentIdController.dispose();
    _collegeController.dispose();
    _majorController.dispose();
    _programController.dispose();
    _gpaController.dispose();
    _guardianNameController.dispose();
    _guardianJobController.dispose();
    _guardianIncomeController.dispose();
    _guardianFamilySizeController.dispose();
    super.dispose();
  }

  Future<void> _loadPrograms() async {
    setState(() {
      _isLoadingPrograms = true;
    });

    try {
      final programs = await _studentService.getSupportPrograms();

      final validPrograms = programs.where((program) {
        final hasId = program['id'] != null;
        final hasName = program['name'] != null;
        return hasId && hasName;
      }).map((program) {
        return {
          'id': program['id'],
          'name': program['name'],
          'title_ar': program['title_ar'],
          'title_en': program['title_en'],
          'description': program['description'] ?? '',
        };
      }).toList();

      setState(() {
        _programs = validPrograms;
        _isLoadingPrograms = false;
      });

      if (validPrograms.isNotEmpty && _selectedProgramId == null) {
        setState(() {
          _selectedProgramId = validPrograms.first['id']?.toString();
          _programController.text =
              StudentRegistrationService.getLocalizedProgramName(
                  validPrograms.first, context.locale.languageCode);
        });
      }
    } catch (error) {
      print('Error loading programs: $error');
      setState(() {
        _isLoadingPrograms = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_loading_programs_message'.tr()),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'retry_button'.tr(),
              textColor: Colors.white,
              onPressed: _loadPrograms,
            ),
          ),
        );
      }
    }
  }

  Future<void> _selectDateOfBirth() async {
    if (_isReadOnly) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: context.locale,
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _pickDocument(String documentType) async {
    if (_isReadOnly) return;
    _pickImageForDocument(documentType);
  }

  Future<void> _pickImageForDocument(String documentType) async {
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('select_file'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(CupertinoIcons.camera, color: AppColors.primary),
                title: Text('camera'.tr()),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    setState(() {
                      _documentFiles[documentType] = bytes;
                      _documentFileNames[documentType] = image.name;
                    });
                  }
                },
              ),
              ListTile(
                leading:
                    const Icon(CupertinoIcons.photo, color: AppColors.primary),
                title: Text('gallery'.tr()),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    setState(() {
                      _documentFiles[documentType] = bytes;
                      _documentFileNames[documentType] = image.name;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static const _requiredDocuments = [
    DocumentType.applicationLetter,
    DocumentType.idCard,
    DocumentType.enrollmentLetter,
    DocumentType.tuitionLetter,
    DocumentType.incomeProof,
    DocumentType.bankStatements,
    DocumentType.debtProof,
    DocumentType.supportingDocuments,
    DocumentType.housingLetter,
  ];

  /// Validates one wizard step. Returns the error to show, or null if valid.
  String? _validateStep(int i) {
    if (_isReadOnly) return null;
    final formOk = _stepKeys[i].currentState?.validate() ?? true;
    if (!formOk) return 'please_fill_required_fields'.tr();
    switch (i) {
      case 0:
        if (_selectedDateOfBirth == null) {
          return 'please_select_date_of_birth'.tr();
        }
      case 1:
        if (_selectedProgramId == null || _selectedProgramId!.isEmpty) {
          return 'please_choose_program'.tr();
        }
        if (_selectedAcademicYear == null || _selectedAcademicYear!.isEmpty) {
          return 'please_select_academic_year'.tr();
        }
      case 3:
        if (_requiredDocuments.any((d) => !_documentFiles.containsKey(d))) {
          return 'please_upload_all_documents'.tr();
        }
    }
    return null;
  }

  void _showError(String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ));
  }

  void _goToStep(int i) {
    if (i < 0 || i >= _stepCount) return;
    FocusScope.of(context).unfocus();
    setState(() => _step = i);
    _pageController.animateToPage(
      i,
      duration: AppMotion.standard,
      curve: AppMotion.curve,
    );
  }

  void _onContinue() {
    final error = _validateStep(_step);
    if (error != null) {
      _showError(error);
      return;
    }
    if (_step == _stepCount - 1) {
      _submitRegistration();
    } else {
      HapticFeedback.selectionClick();
      _goToStep(_step + 1);
    }
  }

  void _submitRegistration() async {
    // Re-validate every step; jump to the first one that fails.
    for (var i = 0; i < _stepCount; i++) {
      final error = _validateStep(i);
      if (error != null) {
        _goToStep(i);
        _showError(error);
        return;
      }
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(
                'submitting_application'.tr(),
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'please_wait'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await _studentService.submitStudentRegistration(
        programId: int.parse(_selectedProgramId!),
        // البيانات الشخصية
        fullName: _fullNameController.text.trim(),
        civilId: _civilIdController.text.trim(),
        dateOfBirth: _selectedDateOfBirth!,
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        maritalStatus: _selectedMaritalStatus,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        // البيانات الأكاديمية
        institution: _institutionController.text.trim(),
        studentId: _studentIdController.text.trim(),
        college: _collegeController.text.trim().isEmpty
            ? null
            : _collegeController.text.trim(),
        major: _majorController.text.trim().isEmpty
            ? null
            : _majorController.text.trim(),
        program: _programController.text.trim().isEmpty
            ? null
            : _programController.text.trim(),
        academicYear: _selectedAcademicYear != null
            ? _convertAcademicYearToNumber(_selectedAcademicYear)
            : null,
        gpa: double.tryParse(_gpaController.text),
        // بيانات ولي الأمر
        guardianName: _guardianNameController.text.trim(),
        guardianJob: _guardianJobController.text.trim(),
        guardianMonthlyIncome:
            double.tryParse(_guardianIncomeController.text) ?? 0,
        guardianFamilySize:
            int.tryParse(_guardianFamilySizeController.text) ?? 1,
        isFatherAlive: _isFatherAlive,
        isMotherAlive: _isMotherAlive,
        parentsMaritalStatus: _parentsMaritalStatus,
        // المرفقات
        documentFiles: _documentFiles.isNotEmpty ? _documentFiles : null,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success dialog
      _showSuccessDialog();
    } catch (error) {
      // Close loading dialog
      Navigator.of(context).pop();

      if (mounted) {
        print('Registration error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${'registration_failed'.tr()}: ${error.toString()}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.surface,
              ),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'registration_successful_message'.tr(),
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'registration_sent_successfully'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    navigator.pushNamedAndRemoveUntil(
                      AppConstants.homeRoute,
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'ok_button'.tr(),
                    style: AppTextStyles.buttonMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshApplicationStatus() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text('updating_request_status'.tr()),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      final currentRegistration =
          await _studentService.getCurrentUserRegistration();

      if (currentRegistration != null) {
        setState(() {
          _applicationStatus = currentRegistration['status'] ?? 'under_review';
          _rejectionReason = currentRegistration['rejection_reason'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${'application_status_updated_to'.tr()}: ${_getStatusText(_applicationStatus)}',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      print('Error refreshing application status: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'error_updating_application_status'.tr()}: $error'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static const _stepTitles = [
    'personal_information',
    'academic_information',
    'guardian_information',
    'documents',
  ];

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return PopScope(
      // Back steps through the wizard before leaving the screen.
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goToStep(_step - 1);
      },
      child: Scaffold(
        backgroundColor: p.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTopBar(p),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  // Navigation is through Continue/Back so each step is
                  // validated before the next one opens.
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (var i = 0; i < _stepCount; i++) _buildStepPage(p, i),
                  ],
                ),
              ),
              _buildBottomBar(p),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppPalette p) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpace.xs, AppSpace.xxs, AppSpace.xs, AppSpace.xs),
      child: Column(
        children: [
          Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
                onPressed: () => Navigator.of(context).maybePop(),
                child: Icon(
                  _step == 0 ? AppIcons.chevronBack : CupertinoIcons.xmark,
                  color: p.tint,
                  size: _step == 0 ? 24 : 20,
                ),
              ),
              Expanded(
                child: Text(
                  'step_of'.tr(args: ['${_step + 1}', '$_stepCount']),
                  textAlign: TextAlign.center,
                  style: AppType.footnote.copyWith(color: p.secondaryLabel),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
                onPressed: _showFundInfoDialog,
                child: Icon(CupertinoIcons.question_circle,
                    color: p.tint, size: 24),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
            child: Row(
              children: [
                for (var i = 0; i < _stepCount; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // Completed steps can be revisited; later ones are
                      // reached by validating forward.
                      onTap: i < _step ? () => _goToStep(i) : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: AnimatedContainer(
                          duration: AppMotion.standard,
                          curve: AppMotion.curve,
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= _step ? p.tint : p.fill,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPage(AppPalette p, int i) {
    final content = switch (i) {
      0 => _buildPersonalInformationSection(),
      1 => _buildAcademicInformationSection(),
      2 => _buildGuardianInformationSection(),
      _ => _buildDocumentsSection(),
    };
    return _KeepAlive(
      child: Form(
        key: _stepKeys[i],
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(
              AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _stepTitles[i].tr(),
                style: AppType.title1.copyWith(color: p.label),
              ),
              const SizedBox(height: AppSpace.xxs),
              Text(
                'fill_form_to_register'.tr(),
                style: AppType.subheadline.copyWith(color: p.secondaryLabel),
              ),
              const SizedBox(height: AppSpace.lg),
              if (i == 0 && widget.existingData != null) ...[
                _buildStatusIndicator(),
                const SizedBox(height: AppSpace.lg),
              ],
              content,
              if (i == _stepCount - 1) ...[
                const SizedBox(height: AppSpace.lg),
                _buildPrivacyNote(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(AppPalette p) {
    final last = _step == _stepCount - 1;
    final label = !last
        ? 'continue'.tr()
        : _isReadOnly
            ? 'cannot_edit'.tr()
            : _isRejected
                ? 'resubmit_application'.tr()
                : 'register'.tr();
    final bottom = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.background,
        border: Border(top: BorderSide(color: p.separator, width: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm,
            AppSpace.screen, AppSpace.sm + bottom),
        child: Row(
          children: [
            if (_step > 0) ...[
              SizedBox(
                width: 100,
                child: OutlinedButton(
                  onPressed: () => _goToStep(_step - 1),
                  child: Text('back'.tr()),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
            ],
            Expanded(
              child: FilledButton(
                onPressed: last && _isReadOnly ? null : _onContinue,
                child: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFundInfoDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildFundInfoSheet(ctx),
    );
  }

  Widget _buildFundInfoSheet(BuildContext ctx) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFundInfoSheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'fund_info.dialog_title'.tr(),
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(CupertinoIcons.xmark),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFundInfoSection1(),
                  const SizedBox(height: 24),
                  _buildFundInfoSection2(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundInfoSheetHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.textTertiary.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildFundInfoSection1() {
    const generalConditions = [
      'تُمنح المساعدة المالية مرة واحدة فقط خلال مسيرة الطالب/ـة الجامعية.',
      'تقديم الطلب لا يعني القبول تلقائيًا، إذ يخضع لدراسة دقيقة للتحقق من استيفاء شروط الاستحقاق.',
      'صرف المساعدة مشروط بتوفر الموارد المالية لدى الصندوق.',
      'تغطي المساعدة فصلاً دراسياً واحداً فقط.',
    ];
    const excludedCases = [
      'طلبة السنة التأسيسية.',
      'طلبة برامج التأهيل التربوي.',
      'طلبة المعاهد المهنية.',
      'الطلبة الدارسون على حسابهم الخاص في السنوات الدراسية الأولى.',
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'fund_info.section1_title'.tr(),
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
            ),
            child: Text(
              'ملاحظة هامة: يرجى الاطلاع على الضوابط التالية قبل تقديم طلب المساعدة المالية من صندوق رعاية الطالب الجامعي:',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _buildNumberedSubtitle('أولًا: الشروط العامة للمساعدة'),
          const SizedBox(height: 8),
          ...generalConditions.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      '${e.key + 1}. ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          _buildNumberedSubtitle('ثانياً: الحالات غير المشمولة بالدعم'),
          const SizedBox(height: 8),
          Text(
            'لا تُمنح المساعدة المالية في الحالات التالية:',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 6),
          ...excludedCases.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      '${e.key + 1}. ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildNumberedSubtitle(String text) {
    return Text(
      text,
      style: AppTextStyles.titleSmall.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      textDirection: TextDirection.rtl,
    );
  }

  Widget _buildFundInfoSection2() {
    const reasons = [
      'عدم استيفاء مقدم الطلب لشروط الاستحقاق المنصوص عليها في لائحة الصندوق.',
      'ثبوت تقديم بيانات أو مستندات غير صحيحة أو ناقصة.',
      'سبق استفادة مقدم الطلب من دعم مالي من الصندوق، حيث تُمنح المساعدة مرة واحدة فقط وفقاً للائحة المعتمدة.',
      'انتماء مقدم الطلب إلى فئات تعليمية غير مشمولة بالدعم، وتشمل على سبيل الحصر: طلبة السنة التأسيسية، برامج التأهيل التربوي، المعاهد المهنية، طلبة السنوات الدراسية الأولى على الحساب الخاص.',
      'تقديم الطلب بعد انتهاء فترة التقديم الرسمية المحددة من قبل الصندوق.',
      'تجاوز الحد المسموح به لعدد الفصول الدراسية أو العمر الأكاديمي المقرر وفق لائحة الصندوق.',
      'عدم توافر المخصصات المالية اللازمة لدى الصندوق وقت دراسة الطلب.',
      'ثبوت تمتع أسرة مقدم الطلب بدخل أو مصادر مالية كافية، وذلك بناءً على نتائج البحث والتقييم الاجتماعي المعتمد.',
      'حصول مقدم الطلب على دعم مالي من جهة أخرى يغطي كلياً أو جزئياً تكاليف الدراسة.',
      'إخفاق مقدم الطلب في استكمال المستندات المطلوبة أو عدم التجاوب مع لجنة التقييم خلال المدة المحددة.',
      'عدم انطباق النطاق الجغرافي المعتمد للصندوق، وذلك لعدم انتماء مقدم الطلب لولاية الرستاق.',
      'كون مقدم الطلب موظفاً أو متقاضياً دخلاً ثابتاً لا يندرج ضمن الفئات المستحقة للدعم وفقاً للائحة الصندوق.',
    ];
    const generalRuling =
        'يحتفظ صندوق رعاية الطالب الجامعي بحقه في رفض أي طلب دعم لا تتوافر فيه الشروط والضوابط المعتمدة، '
        'كما يحتفظ بحقه في طلب أي مستندات إضافية أو إعادة دراسة الطلب متى ما اقتضت المصلحة ذلك، دون أدنى التزام قانوني.';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel_rounded, color: AppColors.secondary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'fund_info.section2_title'.tr(),
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'استناداً إلى أحكام لائحة صندوق رعاية الطالب الجامعي، ووفقاً للضوابط والمعايير المعتمدة، يُرفض طلب الدعم المالي في حال توافر أي من الأسباب الآتية:',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 16),
          ...reasons.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${e.key + 1}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.value,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textTertiary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Text(
                  'حكم عام: ',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    generalRuling,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(_applicationStatus).withValues(alpha: 0.3),
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
                  color: _getStatusColor(_applicationStatus),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(_applicationStatus),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'application_status'.tr(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _getStatusText(_applicationStatus),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: _getStatusColor(_applicationStatus),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isReadOnly) ...[
            const SizedBox(height: 12),
            Text(
              _getStatusDescription(_applicationStatus),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _refreshApplicationStatus,
                icon: const Icon(CupertinoIcons.refresh, size: 16),
                label: Text('refresh'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                ),
              ),
            ),
          ],
          if (_isRejected && _rejectionReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'rejection_reason'.tr(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _rejectionReason!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
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

  // 1. قسم البيانات الشخصية
  Widget _buildPersonalInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // الاسم الكامل
              _buildTextField(
                controller: _fullNameController,
                label: 'full_name'.tr(),
                hint: 'please_enter_full_name'.tr(),
                icon: CupertinoIcons.person_fill,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'please_enter_full_name'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // الرقم المدني
              _buildTextField(
                controller: _civilIdController,
                label: 'civil_id'.tr(),
                hint: 'please_enter_civil_id'.tr(),
                icon: Icons.badge,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'please_enter_civil_id'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // تاريخ الميلاد
              _buildDatePickerField(
                label: 'date_of_birth'.tr(),
                value: _selectedDateOfBirth,
                onTap: _selectDateOfBirth,
              ),
              const SizedBox(height: 16),

              // رقم الهاتف (غير قابل للتعديل - يؤخذ من بيانات الحساب)
              _buildTextField(
                controller: _phoneController,
                label: 'phone_number'.tr(),
                hint: 'please_enter_phone'.tr(),
                icon: CupertinoIcons.phone_fill,
                keyboardType: TextInputType.phone,
                alwaysReadOnly: true,
              ),
              const SizedBox(height: 16),

              // العنوان
              _buildTextField(
                controller: _addressController,
                label: 'address'.tr(),
                hint: 'please_enter_address'.tr(),
                icon: Icons.location_on,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'please_enter_address'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // الحالة الاجتماعية
              _buildDropdownField(
                label: 'marital_status'.tr(),
                value: _selectedMaritalStatus,
                items: _maritalStatusOptions,
                onChanged: (value) {
                  setState(() {
                    _selectedMaritalStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // البريد الإلكتروني (اختياري)
              _buildTextField(
                controller: _emailController,
                label: 'email'.tr(),
                hint: 'please_enter_email'.tr(),
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'please_enter_valid_email'.tr();
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. قسم البيانات الأكاديمية
  Widget _buildAcademicInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // المؤسسة التعليمية
              _buildTextField(
                controller: _institutionController,
                label: 'institution'.tr(),
                hint: 'please_enter_institution'.tr(),
                icon: Icons.account_balance,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'please_enter_institution'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // الرقم الجامعي
              _buildTextField(
                controller: _studentIdController,
                label: 'student_id'.tr(),
                hint: 'please_enter_student_id'.tr(),
                icon: Icons.numbers,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'please_enter_student_id'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // الكلية
              _buildTextField(
                controller: _collegeController,
                label: 'college'.tr(),
                hint: 'please_enter_college'.tr(),
                icon: Icons.business,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'please_enter_college_validation'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // التخصص
              _buildTextField(
                controller: _majorController,
                label: 'major'.tr(),
                hint: 'please_enter_major'.tr(),
                icon: Icons.book,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'please_enter_major_validation'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // البرنامج
              _buildProgramDropdown(),
              const SizedBox(height: 16),

              // السنة الدراسية
              _buildDropdownField(
                label: 'academic_year'.tr(),
                value: _selectedAcademicYear,
                items: _academicYears,
                onChanged: (value) {
                  setState(() {
                    _selectedAcademicYear = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // المعدل
              _buildTextField(
                controller: _gpaController,
                label: 'gpa'.tr(),
                hint: '0.0 - 4.0',
                icon: Icons.grade,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'please_enter_gpa_validation'.tr();
                  }
                  final gpa = double.tryParse(value);
                  if (gpa == null || gpa < 0 || gpa > 4) {
                    return 'please_enter_valid_gpa'.tr();
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3. قسم بيانات ولي الأمر
  Widget _buildGuardianInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // اسم ولي الأمر
              _buildTextField(
                controller: _guardianNameController,
                label: 'guardian_name'.tr(),
                hint: 'please_enter_guardian_name'.tr(),
                icon: CupertinoIcons.person_fill,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'please_enter_guardian_name'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // الوظيفة
              _buildTextField(
                controller: _guardianJobController,
                label: 'guardian_job'.tr(),
                hint: 'please_enter_guardian_job'.tr(),
                icon: Icons.work,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'please_enter_guardian_job'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // الدخل الشهري
              _buildTextField(
                controller: _guardianIncomeController,
                label: 'monthly_income'.tr(),
                hint: '0',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'required_field'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // عدد أفراد الأسرة
              _buildTextField(
                controller: _guardianFamilySizeController,
                label: 'family_size'.tr(),
                hint: '1-20',
                icon: Icons.people,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'required_field'.tr();
                  }
                  final size = int.tryParse(value);
                  if (size == null || size < 1 || size > 20) {
                    return 'invalid_family_size'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // هل الأب على قيد الحياة
              _buildSwitchTile(
                title: 'is_father_alive'.tr(),
                value: _isFatherAlive,
                onChanged: (value) {
                  setState(() {
                    _isFatherAlive = value;
                  });
                },
              ),
              const SizedBox(height: 8),

              // هل الأم على قيد الحياة
              _buildSwitchTile(
                title: 'is_mother_alive'.tr(),
                value: _isMotherAlive,
                onChanged: (value) {
                  setState(() {
                    _isMotherAlive = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // حالة الوالدين الاجتماعية
              _buildDropdownField(
                label: 'parents_marital_status'.tr(),
                value: _parentsMaritalStatus,
                items: _parentsMaritalStatusOptions,
                onChanged: (value) {
                  setState(() {
                    _parentsMaritalStatus = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4. قسم المرفقات
  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: AppColors.error,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'documents_optional_note'.tr(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDocumentUploadTile(
                type: DocumentType.applicationLetter,
                title: 'application_letter'.tr(),
                subtitle:
                    DocumentType.getDescription(DocumentType.applicationLetter),
              ),
              _buildDocumentUploadTile(
                type: DocumentType.idCard,
                title: 'id_card_doc'.tr(),
                subtitle: DocumentType.getDescription(DocumentType.idCard),
              ),
              _buildDocumentUploadTile(
                type: DocumentType.enrollmentLetter,
                title: 'enrollment_letter'.tr(),
                subtitle:
                    DocumentType.getDescription(DocumentType.enrollmentLetter),
              ),
              _buildDocumentUploadTile(
                type: DocumentType.tuitionLetter,
                title: 'tuition_letter'.tr(),
                subtitle:
                    DocumentType.getDescription(DocumentType.tuitionLetter),
              ),
              _buildDocumentUploadTile(
                type: DocumentType.incomeProof,
                title: 'income_proof'.tr(),
                subtitle: DocumentType.getDescription(DocumentType.incomeProof),
              ),
              _buildDocumentUploadTile(
                type: DocumentType.bankStatements,
                title: 'bank_statements'.tr(),
                subtitle:
                    DocumentType.getDescription(DocumentType.bankStatements),
              ),
              _buildDocumentUploadTile(
                type: DocumentType.debtProof,
                title: 'debt_proof'.tr(),
                subtitle: DocumentType.getDescription(DocumentType.debtProof),
              ),
              _buildDocumentUploadTile(
                type: DocumentType.supportingDocuments,
                title: 'supporting_documents'.tr(),
                subtitle: DocumentType.getDescription(
                    DocumentType.supportingDocuments),
              ),
              _buildDocumentUploadTile(
                type: DocumentType.housingLetter,
                title: 'housing_letter'.tr(),
                subtitle:
                    DocumentType.getDescription(DocumentType.housingLetter),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentUploadTile({
    required String type,
    required String title,
    required String subtitle,
  }) {
    final bool hasFile = _documentFiles.containsKey(type);
    final String? fileName = _documentFileNames[type];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: _isReadOnly
            ? null
            : () {
                if (hasFile) {
                  setState(() {
                    _documentFiles.remove(type);
                    _documentFileNames.remove(type);
                  });
                } else {
                  _pickDocument(type);
                }
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasFile
                ? AppColors.success.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasFile
                  ? AppColors.success.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasFile
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasFile
                      ? CupertinoIcons.checkmark_circle_fill
                      : Icons.upload_file,
                  color: hasFile ? AppColors.success : AppColors.info,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasFile && fileName != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          fileName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!_isReadOnly)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasFile
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasFile ? CupertinoIcons.xmark : CupertinoIcons.add,
                    color: hasFile ? AppColors.error : AppColors.primary,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.security,
              color: AppColors.success,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'privacy_notice'.tr(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool alwaysReadOnly = false,
  }) {
    final isFieldReadOnly = _isReadOnly || alwaysReadOnly;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      validator: isFieldReadOnly ? null : validator,
      enabled: !isFieldReadOnly,
      readOnly: isFieldReadOnly,
      style: AppTextStyles.bodyLarge.copyWith(
        color:
            isFieldReadOnly ? AppColors.textSecondary : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: isFieldReadOnly ? null : hint,
        prefixIcon: Icon(
          icon,
          color: isFieldReadOnly ? AppColors.textSecondary : AppColors.primary,
          size: 20,
        ),
        filled: true,
        fillColor:
            isFieldReadOnly ? AppColors.surfaceVariant : AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textTertiary.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textTertiary.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        suffixIcon: isFieldReadOnly
            ? const Icon(
                CupertinoIcons.lock,
                color: AppColors.textSecondary,
                size: 18,
              )
            : null,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    if (_isReadOnly) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textTertiary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value != null ? _getTranslatedValue(value) : '',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.lock,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            _getTranslatedValue(item),
            style: AppTextStyles.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textTertiary.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textTertiary.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      style: AppTextStyles.bodyLarge,
      icon: const Icon(
        CupertinoIcons.chevron_down,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final String displayText = value != null
        ? DateFormat('yyyy-MM-dd').format(value)
        : 'please_select_date_of_birth'.tr();

    return InkWell(
      onTap: _isReadOnly ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: _isReadOnly ? AppColors.surfaceVariant : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textTertiary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.calendar,
              color: _isReadOnly ? AppColors.textSecondary : AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayText,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: value != null
                          ? (_isReadOnly
                              ? AppColors.textSecondary
                              : AppColors.textPrimary)
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (_isReadOnly)
              const Icon(
                CupertinoIcons.lock,
                color: AppColors.textSecondary,
                size: 18,
              )
            else
              const Icon(
                Icons.arrow_drop_down,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isReadOnly ? AppColors.surfaceVariant : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textTertiary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: _isReadOnly
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: _isReadOnly ? null : onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildProgramDropdown() {
    if (_isLoadingPrograms) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textTertiary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'loading_programs'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_programs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(CupertinoIcons.exclamationmark_circle,
                    color: AppColors.error, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'no_programs_available_message'.tr(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loadPrograms,
                icon: const Icon(CupertinoIcons.refresh, size: 16),
                label: Text('reload_programs'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_isReadOnly) {
      final selectedProgram = _programs.firstWhere(
        (p) => p['id']?.toString() == _selectedProgramId,
        orElse: () => {},
      );
      final programName = selectedProgram.isNotEmpty
          ? StudentRegistrationService.getLocalizedProgramName(
              selectedProgram, context.locale.languageCode)
          : '';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textTertiary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.school, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'program'.tr(),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    programName,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.lock,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedProgramId,
      isExpanded: true,
      items: _programs.map((program) {
        return DropdownMenuItem<String>(
          value: program['id']?.toString(),
          child: Text(
            StudentRegistrationService.getLocalizedProgramName(
                program, context.locale.languageCode),
            style: AppTextStyles.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedProgramId = value;
          if (value != null) {
            final selectedProgram = _programs.firstWhere(
              (p) => p['id']?.toString() == value,
              orElse: () => {},
            );
            _programController.text =
                StudentRegistrationService.getLocalizedProgramName(
                    selectedProgram, context.locale.languageCode);
          }
        });
      },
      decoration: InputDecoration(
        labelText: 'program'.tr(),
        prefixIcon:
            const Icon(Icons.school, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textTertiary.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textTertiary.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      style: AppTextStyles.bodyLarge,
      icon: const Icon(CupertinoIcons.chevron_down, color: AppColors.primary),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'please_choose_program_validation'.tr();
        }
        return null;
      },
    );
  }
}

/// Keeps a wizard step mounted while off-screen so its fields keep their
/// state and can be validated on submit.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
