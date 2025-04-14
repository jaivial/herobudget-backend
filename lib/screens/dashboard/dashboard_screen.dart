import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../onboarding/onboarding_screen.dart';
import 'dart:convert';
import 'dart:ui';

class DashboardScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userInfo;

  const DashboardScreen({
    super.key,
    required this.userId,
    required this.userInfo,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _latestUserInfo = {};
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Start with the passed userInfo
    _latestUserInfo = widget.userInfo;
    // Then fetch the latest from the server
    _fetchLatestUserInfo();
  }

  Future<void> _fetchLatestUserInfo() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      // First try with the userId passed to the widget
      if (widget.userId == null || widget.userId.isEmpty) {
        print("Attempting to fetch user info with ID: null");

        // If userId is not provided, try to get it from localStorage
        print(
          "User ID is empty or 'null', attempting to retrieve from localStorage",
        );
        final userId = await DashboardService.getCurrentUserId();

        if (userId == null || userId.isEmpty) {
          throw Exception('No valid user ID found');
        }

        print("Retrieved user ID from localStorage: $userId");
        try {
          final latestInfo = await DashboardService.fetchUserInfo(userId);

          if (mounted) {
            setState(() {
              _latestUserInfo = latestInfo;
              _isLoading = false;
            });
          }
        } catch (e) {
          // Check if this is a user not found error
          if (e.toString().contains('404') ||
              e.toString().contains('User not found') ||
              e.toString().contains('Failed to fetch user information')) {
            print(
              "User not found (404) - clearing data and returning to onboarding",
            );
            await _handleUserNotFound();
            return;
          } else {
            // Rethrow other errors to be caught in the outer catch block
            rethrow;
          }
        }
      } else {
        print("Using provided user ID: ${widget.userId}");
        try {
          final latestInfo = await DashboardService.fetchUserInfo(
            widget.userId,
          );

          if (mounted) {
            setState(() {
              _latestUserInfo = latestInfo;
              _isLoading = false;
            });
          }
        } catch (e) {
          // Check if this is a user not found error
          if (e.toString().contains('404') ||
              e.toString().contains('User not found') ||
              e.toString().contains('Failed to fetch user information')) {
            print(
              "User not found (404) - clearing data and returning to onboarding",
            );
            await _handleUserNotFound();
            return;
          } else {
            // Rethrow other errors to be caught in the outer catch block
            rethrow;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to fetch the latest user information';
          _isLoading = false;
        });
      }
      print('Error fetching user info: $e');
    }
  }

  // Helper method to handle user not found errors
  Future<void> _handleUserNotFound() async {
    try {
      // Clear user data from localStorage
      await AuthService.signOut(context);

      // Navigate to onboarding screen
      if (mounted && context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error during handling user not found: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLatestUserInfo,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.signOut(context);

              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnboardingScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _fetchLatestUserInfo,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _buildProfileImage(_latestUserInfo)),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Welcome, ${_latestUserInfo['name'] ?? 'User'}!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildInfoCard(context),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileImage(Map<String, dynamic> userInfo) {
    // Use the new display_image field if available
    if (userInfo['display_image'] != null && userInfo['display_image'] != '') {
      // Check if this is a Google user by checking google_id
      if (userInfo['google_id'] != null && userInfo['google_id'] != '') {
        // Google user: display_image is a URL
        print('Using Google profile picture URL');
        return CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(userInfo['display_image']),
        );
      } else {
        // Regular user: display_image is a base64 string
        print('Using profile image blob (base64)');
        try {
          return CircleAvatar(
            radius: 50,
            backgroundImage: MemoryImage(
              base64Decode(userInfo['display_image']),
            ),
          );
        } catch (e) {
          print('Error decoding profile image blob: $e');
        }
      }
    }

    // Fallback to default avatar with initials
    return CircleAvatar(
      radius: 50,
      backgroundColor: Color(0xFFE1BEE7), // Light purple
      child: Text(
        _getInitials(userInfo['name'] ?? ''),
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.length == 1 && nameParts[0].isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }

    return '?';
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              'User ID',
              _latestUserInfo['id']?.toString() ?? 'N/A',
            ),
            _buildInfoRow('Email', _latestUserInfo['email'] ?? 'N/A'),
            _buildInfoRow('Full Name', _latestUserInfo['name'] ?? 'N/A'),
            _buildInfoRow('Given Name', _latestUserInfo['given_name'] ?? 'N/A'),
            _buildInfoRow(
              'Family Name',
              _latestUserInfo['family_name'] ?? 'N/A',
            ),
            _buildInfoRow('Locale', _latestUserInfo['locale'] ?? 'N/A'),
            _buildInfoRow(
              'Email Verified',
              (_latestUserInfo['verified_email'] ?? false) ? 'Yes' : 'No',
            ),
            _buildInfoRow(
              'Created At',
              _latestUserInfo['created_at']?.toString().split('.')[0] ?? 'N/A',
            ),
            _buildInfoRow(
              'Last Updated',
              _latestUserInfo['updated_at']?.toString().split('.')[0] ?? 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF9C27B0),
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
