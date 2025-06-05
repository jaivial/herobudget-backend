import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/extensions.dart';

class EmailSentStep extends StatelessWidget {
  final String email;
  final VoidCallback onBack;

  const EmailSentStep({Key? key, required this.email, required this.onBack})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Email sent icon
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_read_outlined,
                color: AppTheme.getPrimaryColor(context),
                size: 60,
              ),
            ),
            const SizedBox(height: 32),

            // Email sent text
            Text(
              context.tr.translate('email_sent_title'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.getPrimaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr.translate('email_sent_description'),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.getSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr.translate('email_instructions'),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Try different email button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: onBack,
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  context.tr.translate('try_different_email'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getSecondaryColor(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
