// import 'package:coms_india/core/utils/constants.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:intl/intl.dart' show DateFormat;
// import 'package:provider/provider.dart';
// import '../controllers/employee_provider.dart';
// import '../models/site_model.dart';
// import '../../../core/di/service_locator.dart';
// import '../../../core/services/api_service.dart';

// class DepartmentData {
//   final int id;
//   final String name;
//   final List<DesignationData> designations;

//   DepartmentData({
//     required this.id,
//     required this.name,
//     required this.designations,
//   });

//   factory DepartmentData.fromJson(Map<String, dynamic> json) {
//     return DepartmentData(
//       id: json['id'],
//       name: json['department_name'],
//       designations: (json['designations'] as List)
//           .map((e) => DesignationData.fromJson(e))
//           .toList(),
//     );
//   }
// }

// class DesignationData {
//   final int id;
//   final String name;
//   final int hierarchyLevel;
//   final int departmentId;

//   DesignationData({
//     required this.id,
//     required this.name,
//     required this.hierarchyLevel,
//     required this.departmentId,
//   });

//   factory DesignationData.fromJson(Map<String, dynamic> json) {
//     return DesignationData(
//       id: json['id'],
//       name: json['designation_name'],
//       hierarchyLevel: json['hierarchy_level'],
//       departmentId: json['department_id'],
//     );
//   }
// }

// class SiteData {
//   final int id;
//   final String name;

//   SiteData({required this.id, required this.name});

//   factory SiteData.fromJson(Map<String, dynamic> json) {
//     return SiteData(
//       id: json['id'],
//       name: json['site_name'],
//     );
//   }

//   // Convert from SiteModel
//   factory SiteData.fromSiteModel(SiteModel site) {
//     return SiteData(
//       id: site.id,
//       name: site.siteName,
//     );
//   }
// }

// class LocationData {
//   final int id;
//   final String name;

//   LocationData({required this.id, required this.name});

//   factory LocationData.fromJson(Map<String, dynamic> json) {
//     return LocationData(
//       id: json['id'],
//       name: json['location_name'],
//     );
//   }
// }

// class EmploymentDetailsSection extends StatefulWidget {
//   const EmploymentDetailsSection({super.key});

//   @override
//   State<EmploymentDetailsSection> createState() =>
//       _EmploymentDetailsSectionState();
// }

// class _EmploymentDetailsSectionState extends State<EmploymentDetailsSection> {
//   final _formKey = GlobalKey<FormState>();
//   final _punchingCodeController = TextEditingController();
//   final ApiService _apiService = getIt<ApiService>();

//   // API Data
//   List<DepartmentData> _departments = [];
//   List<SiteData> _sites = [];
//   List<LocationData> _locations = [];

//   // Selected values
//   DepartmentData? _selectedDepartment;
//   DesignationData? _selectedDesignation;
//   SiteData? _selectedSite;
//   LocationData? _selectedLocation;
//   String? _selectedModeOfJoining;

//   // Available designations for selected department
//   List<DesignationData> _availableDesignations = [];

//   // Loading states
//   bool _isLoadingDepartments = true;
//   bool _isLoadingSites = true;
//   bool _isLoadingLocations = true;

//   final List<String> _modeOfJoiningOptions = const [
//     'direct',
//     'reference',
//     'campus',
//     'online',
//     'interview'
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _loadApiData();
//     _punchingCodeController.text = "1234"; // Sample data
//   }

//   Future<void> _loadApiData() async {
//     try {
//       // Load all API data in parallel
//       await Future.wait([
//         _loadDepartments(),
//         _loadSites(),
//         _loadLocations(),
//       ]);

//       // Pre-select first options for testing
//       if (_departments.isNotEmpty) {
//         _selectedDepartment = _departments.first;
//         _availableDesignations = _selectedDepartment!.designations;
//         if (_availableDesignations.isNotEmpty) {
//           _selectedDesignation = _availableDesignations.first;
//         }
//       }

//       if (_sites.isNotEmpty) {
//         _selectedSite = _sites.first;
//       }

//       if (_locations.isNotEmpty) {
//         _selectedLocation = _locations.first;
//       }

//       _selectedModeOfJoining = 'interview';

//       print('🚀 DEBUG: API data loaded successfully');
//       print('🚀 DEBUG: Departments: ${_departments.length}');
//       print('🚀 DEBUG: Sites: ${_sites.length}');
//       print('🚀 DEBUG: Locations: ${_locations.length}');

//       if (mounted) setState(() {});
//     } catch (e) {
//       print('❌ DEBUG: Error loading API data: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error loading data: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _loadDepartments() async {
//     try {
//       setState(() => _isLoadingDepartments = true);
//       final response = await _apiService.getDepartments();

//       if (response.data['status'] == true) {
//         final List<dynamic> departmentsJson = response.data['data'];
//         _departments = departmentsJson
//             .map((json) => DepartmentData.fromJson(json))
//             .toList();
//       }
//     } catch (e) {
//       print('❌ Error loading departments: $e');
//     } finally {
//       setState(() => _isLoadingDepartments = false);
//     }
//   }

//   Future<void> _loadSites() async {
//     try {
//       setState(() => _isLoadingSites = true);
//       final response = await _apiService.getSites();

//       if (response.statusCode == 200 && response.data != null) {
//         final siteListResponse = SiteListResponse.fromJson(response.data);

//         if (siteListResponse.status) {
//           _sites = siteListResponse.data
//               .map((site) => SiteData.fromSiteModel(site))
//               .toList();
//           print('✅ Sites loaded successfully: ${_sites.length} sites');
//         } else {
//           print('❌ Failed to load sites: ${siteListResponse.message}');
//         }
//       } else {
//         print('❌ Failed to load sites. Status: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('❌ Error loading sites: $e');
//     } finally {
//       setState(() => _isLoadingSites = false);
//     }
//   }

//   Future<void> _loadLocations() async {
//     try {
//       setState(() => _isLoadingLocations = true);
//       final response = await _apiService.getLocations();

//       if (response.data['status'] == true) {
//         final List<dynamic> locationsJson = response.data['data'];
//         _locations =
//             locationsJson.map((json) => LocationData.fromJson(json)).toList();
//       }
//     } catch (e) {
//       print('❌ Error loading locations: $e');
//     } finally {
//       setState(() => _isLoadingLocations = false);
//     }
//   }

//   Future<void> _submitEmploymentDetails() async {
//     print('🐛 DEBUG: ===== EMPLOYMENT DETAILS FORM SUBMISSION =====');
//     print('🐛 DEBUG: Department ID: ${_selectedDepartment?.id}');
//     print('🐛 DEBUG: Designation ID: ${_selectedDesignation?.id}');
//     print('🐛 DEBUG: Site ID: ${_selectedSite?.id}');
//     print('🐛 DEBUG: Location ID: ${_selectedLocation?.id}');
//     print('🐛 DEBUG: Mode of Joining: $_selectedModeOfJoining');
//     print('🐛 DEBUG: Punching Code: ${_punchingCodeController.text}');

//     if (_formKey.currentState!.validate()) {
//       try {
//         // Validate required fields
//         if (_selectedDepartment == null) {
//           throw Exception('Please select a department');
//         }
//         if (_selectedDesignation == null) {
//           throw Exception('Please select a designation');
//         }
//         if (_selectedSite == null) {
//           throw Exception('Please select a site');
//         }
//         if (_selectedLocation == null) {
//           throw Exception('Please select a location');
//         }
//         if (_selectedModeOfJoining == null) {
//           throw Exception('Please select a mode of joining');
//         }

//         final provider = context.read<EmployeeProvider>();
//         final employmentData = {
//           'department_id': _selectedDepartment!.id.toString(),
//           'designation_id': _selectedDesignation!.id.toString(),
//           'site_id': _selectedSite!.id.toString(),
//           'location': _selectedLocation!.id.toString(),
//           'joining_mode': _selectedModeOfJoining!,
//           'punching_code': _punchingCodeController.text,
//         };

//         provider.updateFormData('employment_details', employmentData);
//         print('🐛 DEBUG: Updated provider with employment details');
//         print(
//             '🐛 DEBUG: Current completion: ${provider.getCompletionPercentage().toStringAsFixed(1)}%');
//         print('🐛 DEBUG: ========================================');

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text(
//                   'Employment details saved! Continue to previous employment.'),
//               backgroundColor: Colors.green,
//             ),
//           );
//           context.goNamed('previous_employment');
//         }
//       } catch (e) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Error: ${e.toString()}'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     }
//   }

//   void _onDepartmentChanged(DepartmentData? department) {
//     setState(() {
//       _selectedDepartment = department;
//       _selectedDesignation = null;
//       _availableDesignations = department?.designations ?? [];
//     });
//   }

//   @override
//   void dispose() {
//     _punchingCodeController.dispose();
//     super.dispose();
//   }

//   Widget _buildLabel(String text, {bool isRequired = false}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             text,
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey.shade700,
//             ),
//           ),
//           if (isRequired)
//             const Text(
//               ' *',
//               style: TextStyle(
//                 color: Colors.red,
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   InputDecoration _modernInputDecoration({
//     required String hintText,
//     Widget? suffixIcon,
//   }) {
//     return InputDecoration(
//       hintText: hintText,
//       hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
//       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: BorderSide(color: Colors.grey.shade300),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide: BorderSide(color: Colors.grey.shade300),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(8),
//         borderSide:
//             BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
//       ),
//       filled: true,
//       fillColor: Colors.white,
//       suffixIcon: suffixIcon,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     const double verticalGap = 20.0;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(
//             Icons.arrow_back,
//             color: Colors.white,
//           ),
//           onPressed: () {
//             // Check if there's something to pop, otherwise go to addEmployee
//             if (context.canPop()) {
//               context.pop(); // Go back to previous screen (basic_info)
//             } else {
//               context.goNamed('addEmployee'); // Fallback to basic info
//             }
//           },
//         ),
//         title: const Text(
//           'Employment Details',
//           style: TextStyle(
//               color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: const Color(AppColors.primary),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Material(
//           color: Colors.grey[50],
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(20.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Loading indicator
//                   if (_isLoadingDepartments ||
//                       _isLoadingSites ||
//                       _isLoadingLocations)
//                     const LinearProgressIndicator(),

//                   const SizedBox(height: 20),

//                   // Department Dropdown
//                   _buildDropdownField<DepartmentData>(
//                     label: 'Department',
//                     isRequired: true,
//                     value: _selectedDepartment,
//                     items: _departments,
//                     itemBuilder: (dept) => dept.name,
//                     onChanged: _onDepartmentChanged,
//                     placeholder: 'Select Department',
//                     isLoading: _isLoadingDepartments,
//                   ),
//                   const SizedBox(height: verticalGap),

//                   // Designation Dropdown
//                   _buildDropdownField<DesignationData>(
//                     label: 'Designation',
//                     isRequired: true,
//                     value: _selectedDesignation,
//                     items: _availableDesignations,
//                     itemBuilder: (designation) => designation.name,
//                     onChanged: (value) =>
//                         setState(() => _selectedDesignation = value),
//                     placeholder: 'Select Designation',
//                     isLoading: false,
//                   ),
//                   const SizedBox(height: verticalGap),

//                   // Site Dropdown
//                   _buildDropdownField<SiteData>(
//                     label: 'Site Name',
//                     isRequired: true,
//                     value: _selectedSite,
//                     items: _sites,
//                     itemBuilder: (site) => site.name,
//                     onChanged: (value) => setState(() => _selectedSite = value),
//                     placeholder: 'Select Site',
//                     isLoading: _isLoadingSites,
//                   ),
//                   const SizedBox(height: verticalGap),

//                   // Location Dropdown
//                   _buildDropdownField<LocationData>(
//                     label: 'Location',
//                     isRequired: true,
//                     value: _selectedLocation,
//                     items: _locations,
//                     itemBuilder: (location) => location.name,
//                     onChanged: (value) =>
//                         setState(() => _selectedLocation = value),
//                     placeholder: 'Select Location',
//                     isLoading: _isLoadingLocations,
//                   ),
//                   const SizedBox(height: verticalGap),

//                   // Mode of Joining Dropdown
//                   _buildDropdownField<String>(
//                     label: 'Mode of Joining',
//                     isRequired: true,
//                     value: _selectedModeOfJoining,
//                     items: _modeOfJoiningOptions,
//                     itemBuilder: (mode) => mode.toUpperCase(),
//                     onChanged: (value) =>
//                         setState(() => _selectedModeOfJoining = value),
//                     placeholder: 'Select Mode',
//                     isLoading: false,
//                   ),
//                   const SizedBox(height: verticalGap),

//                   // Punching Code Field
//                   // _buildTextField(
//                   //   controller: _punchingCodeController,
//                   //   label: 'Punching Code',
//                   //   placeholder: 'Enter Punching Code',
//                   //   isRequired: true,
//                   // ),
//                   const SizedBox(height: 40),

//                   // Submit Button
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(AppColors.primary),
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 24,
//                             vertical: 12,
//                           ),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                         onPressed: _submitEmploymentDetails,
//                         child: const Text(
//                           'Continue to Previous Employment',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDropdownField<T>({
//     required String label,
//     bool isRequired = false,
//     required T? value,
//     required List<T> items,
//     required String Function(T) itemBuilder,
//     required void Function(T?) onChanged,
//     required String placeholder,
//     required bool isLoading,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildLabel(label, isRequired: isRequired),
//         DropdownButtonFormField<T>(
//           value: value,
//           decoration: _modernInputDecoration(hintText: placeholder),
//           isExpanded: true,
//           items: isLoading
//               ? []
//               : items.map<DropdownMenuItem<T>>((T item) {
//                   return DropdownMenuItem<T>(
//                     value: item,
//                     child: Text(
//                       itemBuilder(item),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   );
//                 }).toList(),
//           onChanged: isLoading ? null : onChanged,
//           validator: isRequired
//               ? (value) {
//                   if (value == null) {
//                     return '$label is required';
//                   }
//                   return null;
//                 }
//               : null,
//           hint: isLoading
//               ? const Row(
//                   children: [
//                     SizedBox(
//                       width: 16,
//                       height: 16,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     ),
//                     SizedBox(width: 8),
//                     Text('Loading...'),
//                   ],
//                 )
//               : Text(placeholder),
//         ),
//       ],
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required String placeholder,
//     bool isRequired = false,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildLabel(label, isRequired: isRequired),
//         TextFormField(
//           controller: controller,
//           decoration: _modernInputDecoration(hintText: placeholder),
//           validator: isRequired
//               ? (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return '$label is required';
//                   }
//                   return null;
//                 }
//               : null,
//         ),
//       ],
//     );
//   }
// }
