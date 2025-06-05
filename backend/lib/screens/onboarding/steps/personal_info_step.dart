import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/extensions.dart';

class PersonalInfoStep extends StatelessWidget {
  final TextEditingController givenNameController;
  final TextEditingController familyNameController;
  final FocusNode firstNameFocusNode;
  final FocusNode lastNameFocusNode;

  const PersonalInfoStep({
    super.key,
    required this.givenNameController,
    required this.familyNameController,
    required this.firstNameFocusNode,
    required this.lastNameFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First name field
          TextFormField(
            controller: givenNameController,
            focusNode: firstNameFocusNode,
            autofocus: true,
            decoration: InputDecoration(
              labelText: context.tr.translate('first_name'),
              prefixIcon: const Icon(Icons.person_outline),
              hintText: context.tr.translate('enter_first_name'),
            ),
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) {
              lastNameFocusNode.requestFocus();
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.tr.translate('please_enter_first_name');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Last name field
          TextFormField(
            controller: familyNameController,
            focusNode: lastNameFocusNode,
            decoration: InputDecoration(
              labelText: context.tr.translate('last_name'),
              prefixIcon: const Icon(Icons.person_outline),
              hintText: context.tr.translate('enter_last_name'),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.tr.translate('please_enter_last_name');
              }
              return null;
            },
          ),

          // Information box at the bottom
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.privacy_tip_outlined,
                        color: AppTheme.secondaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.tr.translate('privacy_information'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr.translate('privacy_info_text'),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
