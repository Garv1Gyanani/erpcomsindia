import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coms_india/features/auth/controllers/auth_controller.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/di/service_locator.dart';
import '../../../core/services/storage_service.dart'; // Import the storage service

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? profileImageUrl;
  List<String> empSites = [];
  bool isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() {
      isLoadingProfile = true;
    });

    try {
      // Get the storage service from the service locator
      final StorageService _storageService = getIt<StorageService>();

      // Get the auth data from storage
      final authData = await _storageService.getAllAuthData();
      final String? token = authData['token']?.trim();

      if (token == null || token.isEmpty) {
        // Handle the case where the token is not found in storage
        print('Token not found in storage');
        // Optionally, navigate to the login page or show an error message
        return; // Exit the function if there's no token
      }

      final response = await http.get(
        Uri.parse('https://erp.comsindia.in/api/profile'), // API endpoint
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('this is pic $data');
        if (data['status'] == true) {
          // Construct the full image URL
          final String? empImgPath = data['empImg']; // Get relative path
          String? fullImageUrl;

          if (empImgPath != null && empImgPath.isNotEmpty) {
            fullImageUrl =
                'https://erp.comsindia.in/$empImgPath'; // Combine base URL
          } else {
            fullImageUrl = null; // Or a default image URL
          }

          setState(() {
            profileImageUrl = fullImageUrl;
            empSites = data['empSite'] != null
                ? List<String>.from(data['empSite'])
                : [];
          });
        }
      } else {
        // Handle API error
        print('API Error: ${response.statusCode} - ${response.body}');
        // Show an error message to the user or log the error.
      }
    } catch (e) {
      print('Error fetching profile data: $e');
      // Handle network errors or other exceptions.  Display an error message.
    } finally {
      setState(() {
        isLoadingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthController _authController = getIt<AuthController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.goNamed('home');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          final user = _authController.currentUser.value;

          // If user data is not available, show placeholder
          if (user == null) {
            return const Column(
              children: [
                SizedBox(height: 20),
                Center(
                  child: CircularProgressIndicator(color: Colors.red),
                ),
                SizedBox(height: 20),
                Text('Loading profile data...'),
              ],
            );
          }

          // Get the first letter of the user's name for the avatar fallback
          final avatarText =
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'S';
          //removed baseUrl from here
          //final baseUrl = 'https://erp.comsindia.in/storage/';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: ClipOval(
                    child: isLoadingProfile
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : profileImageUrl != null && profileImageUrl!.isNotEmpty
                            ? Image.network(
                                profileImageUrl!, // Use the full URL here
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  print(
                                      "Error loading image: $error"); // Print to console for debugging
                                  return _buildAvatarFallback(avatarText);
                                },
                              )
                            : _buildAvatarFallback(avatarText),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user.email,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Profile information
              _buildProfileInfoItem('Name', user.name),
              _buildProfileInfoItem('Email', user.email),
              _buildProfileInfoItem('Role',
                  user.roles.isNotEmpty ? user.roles.first.name : 'N/A'),
              _buildProfileInfoItem('Phone', user.phone),

              // Display assigned sites if available
              if (empSites.isNotEmpty)
                _buildProfileInfoItem('Sites', empSites.join(', ')),

              _buildProfileInfoItem(
                  'Joined Date', _formatDate(user.createdAt ?? '')),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildAvatarFallback(String avatarText) {
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          avatarText,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 40,
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildProfileInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
