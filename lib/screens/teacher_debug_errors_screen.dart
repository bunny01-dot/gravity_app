import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class TeacherDebugErrorsScreen extends StatelessWidget {
  const TeacherDebugErrorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final bg = isDark ? const Color(0xFF0F172A) : theme.scaffoldBackgroundColor;
    final appBarBg = isDark
        ? const Color(0xFF1E293B)
        : theme.colorScheme.surface;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Technical Issues (Debug)"),
        backgroundColor: appBarBg,
        foregroundColor: onSurface,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('app_errors')
            .orderBy('timestamp', descending: true)
            .limit(50) // Limit to recent 50
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final errorText = snapshot.error.toString();
            if (errorText.contains('permission-denied')) {
              final email =
                  FirebaseAuth.instance.currentUser?.email ?? 'signed-out';
              return _PermissionDeniedPanel(email: email);
            }
            return Center(
              child: Text(
                'Error: $errorText',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No technical issues reported.",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _ErrorCard(docId: doc.id, data: data);
            },
          );
        },
      ),
    );
  }
}

class _PermissionDeniedPanel extends StatelessWidget {
  const _PermissionDeniedPanel({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              color: Colors.orangeAccent,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Access denied for Technical Issues.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Signed-in email: $email\nThis screen requires teacher access in Firestore rules.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'If this is the teacher account, ensure the email is allowlisted and firestore rules are deployed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.54),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _ErrorCard({required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final studentName = data['studentName'] ?? 'Unknown Student';
    final category = data['category'] ?? 'Technical Issue';
    final severity = data['severity'] ?? 'medium';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final resolved = data['resolved'] ?? false;
    final message = data['errorMessage'] ?? 'No message';

    final Color severityColor = _getSeverityColor(severity);

    return Card(
      color: isDark ? const Color(0xFF1E293B) : theme.colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: resolved
              ? Colors.green.withValues(alpha: 0.3)
              : severityColor.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: () => _showErrorDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      category.toUpperCase(),
                      style: TextStyle(
                        color: severityColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (resolved)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "RESOLVED",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (!resolved && timestamp != null)
                    Text(
                      _formatDate(timestamp),
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.3),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                studentName,
                style: TextStyle(
                  color: onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'low':
        return Colors.blueAccent;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  void _showErrorDetails(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: onSurface.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildDetailRow(
                  context,
                  "Student",
                  data['studentName'] ?? 'Unknown',
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  context,
                  "Category",
                  data['category'] ?? 'General',
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  context,
                  "Platform",
                  data['platform'] ?? 'Unknown',
                ),
                const SizedBox(height: 24),
                Text(
                  "Error Message",
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.54),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  data['errorMessage'] ?? 'No message',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Stack Trace",
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.54),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black38
                        : onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? Colors.white10
                          : onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  child: SelectableText(
                    data['stackTrace'] ?? 'No stack trace available',
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.7),
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(
                              text:
                                  "Error: ${data['errorMessage']}\n\nStack: ${data['stackTrace']}",
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Copied to clipboard"),
                            ),
                          );
                        },
                        child: const Text("Copy Details"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          SharePlus.instance.share(
                            ShareParams(
                              text:
                                  "Issue Report:\nStudent: ${data['studentName']}\nError: ${data['errorMessage']}\nStack: ${data['stackTrace']}",
                              subject: "Gravity App Issue Report",
                            ),
                          );
                        },
                        child: const Text("Share"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (data['resolved'] ?? false)
                              ? Colors.grey
                              : Colors.green,
                        ),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('app_errors')
                              .doc(docId)
                              .update({
                                'resolved': !(data['resolved'] ?? false),
                              });
                          Navigator.pop(context);
                        },
                        child: Text(
                          (data['resolved'] ?? false)
                              ? "Mark Unresolved"
                              : "Mark Resolved",
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(color: onSurface.withValues(alpha: 0.54)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
