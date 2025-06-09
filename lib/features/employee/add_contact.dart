import 'package:coms_india/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ContactFormScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Contact Details',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        backgroundColor: Colors.red,
        elevation: 1.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row 1
            Column(
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabeledTextField(
                  context: context,
                  label: 'Mobile Number',
                  hintText: 'Phone Number',
                  isRequired: true,
                ),
                SizedBox(height: 12),
                _buildLabeledTextField(
                  context: context,
                  label: 'Email',
                  hintText: 'Email Address',
                  isRequired: true,
                ),
                SizedBox(height: 12),
                _buildLabeledTextField(
                  context: context,
                  label: 'Emergency Contact',
                  hintText: 'Emergency Contact',
                  isRequired: true,
                ),
              ],
            ),
            SizedBox(height: 16),

            // Row 2
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildAddressSection(
                    context: context,
                    title: 'Present Address',
                    isRequired: true,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildAddressSection(
                    context: context,
                    title: 'Permanent Address',
                    isRequired: true,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Relationship
            _buildLabeledTextField(
              context: context,
              label: 'Relationship with Emergency Contact',
              hintText: 'Relationship',
              isRequired: true,
            ),
            SizedBox(height: 10),

            // Submit Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      context.goNamed("educationDetails");
                    },
                    child: const Text(
                      'Next',
                      style: TextStyle(color: Colors.white),
                    ))
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequiredLabel(String label) {
    return RichText(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.black.withOpacity(0.85),
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledTextField({
    required BuildContext context,
    required String label,
    required String hintText,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isRequired
            ? _buildRequiredLabel(label)
            : Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Colors.black.withOpacity(0.85),
                ),
              ),
        SizedBox(height: 6),
        TextFormField(
          maxLines: maxLines,
          style: TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.0),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.0),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection({
    required BuildContext context,
    required String title,
    bool isRequired = false,
  }) {
    final addressFields = [
      'Street Address',
      'City',
      'District',
      'Post Office',
      'Thana',
      'Pincode',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isRequired
            ? _buildRequiredLabel(title)
            : Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Colors.black.withOpacity(0.85),
                ),
              ),
        SizedBox(height: 6),
        ...addressFields.map((field) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: TextFormField(
              style: TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: field,
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6.0),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6.0),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6.0),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
