import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:cross_file/cross_file.dart';
import 'package:choice_lux_cars/shared/screens/pdf_viewer_screen.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

class PdfViewerService {
  /// Open PDF with platform-specific handling
  static Future<void> openPdf({
    required BuildContext context,
    required String pdfUrl,
    required String title,
    String? documentType,
    Map<String, dynamic>? documentData,
  }) async {
    try {
      Log.d('Opening PDF: $title on platform: ${kIsWeb ? 'web' : 'mobile'}');
      
      if (kIsWeb) {
        // Web: Open in new browser tab
        await openPdfWeb(pdfUrl, title);
      } else {
        // Mobile: Use in-app viewer
        await _openPdfMobile(context, pdfUrl, title, documentType, documentData);
      }
    } catch (e) {
      Log.e('Failed to open PDF: $e');
      throw Exception('Failed to open PDF: $e');
    }
  }

  /// Open PDF in in-app viewer (Mobile only)
  static Future<void> openPdfInApp({
    required BuildContext context,
    required String pdfUrl,
    required String title,
    String? documentType,
    Map<String, dynamic>? documentData,
  }) async {
    try {
      Log.d('Opening PDF in app: $title');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            pdfUrl: pdfUrl,
            title: title,
            documentType: documentType,
            documentData: documentData,
          ),
        ),
      );
    } catch (e) {
      Log.e('Failed to open PDF in app: $e');
      throw Exception('Failed to open PDF: $e');
    }
  }

  /// Open PDF on web (new browser tab)
  static Future<void> openPdfWeb(String pdfUrl, String title) async {
    try {
      Log.d('Opening PDF in web browser: $title');
      final uri = Uri.parse(pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not open PDF URL in browser');
      }
    } catch (e) {
      Log.e('Failed to open PDF in web browser: $e');
      throw Exception('Failed to open PDF in browser: $e');
    }
  }

  /// Open PDF on mobile (in-app viewer)
  static Future<void> _openPdfMobile(
    BuildContext context,
    String pdfUrl,
    String title,
    String? documentType,
    Map<String, dynamic>? documentData,
  ) async {
    try {
      Log.d('Opening PDF in mobile app: $title');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            pdfUrl: pdfUrl,
            title: title,
            documentType: documentType,
            documentData: documentData,
          ),
        ),
      );
    } catch (e) {
      Log.e('Failed to open PDF in mobile app: $e');
      throw Exception('Failed to open PDF in mobile app: $e');
    }
  }

  /// Open PDF in external browser (fallback)
  static Future<void> openPdfExternal(String pdfUrl) async {
    try {
      final uri = Uri.parse(pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } else {
        throw Exception('Could not open PDF URL');
      }
    } catch (e) {
      throw Exception('Failed to open PDF: $e');
    }
  }

  /// Download PDF to device storage
  static Future<String> downloadPdf({
    required String pdfUrl,
    required String fileName,
  }) async {
    try {
      // Download PDF from URL
      final response = await http.get(Uri.parse(pdfUrl));
      
      if (response.statusCode == 200) {
        // Get downloads directory
        final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        
        // Write PDF bytes to file
        await file.writeAsBytes(response.bodyBytes);
        
        return file.path;
      } else {
        throw Exception('Failed to download PDF: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to download PDF: $e');
    }
  }

  /// Share PDF via system share sheet with file attachment
  static Future<void> sharePdf({
    required String pdfUrl,
    required String title,
    String? subject,
    String? text,
  }) async {
    try {
      // Download PDF to temporary storage first
      final fileName = '${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = await downloadPdf(pdfUrl: pdfUrl, fileName: fileName);
      
      // Share the actual PDF file
      final shareText = text ?? 'Please find the attached document: $title';
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject ?? title,
        text: shareText,
      );
    } catch (e) {
      throw Exception('Failed to share PDF: $e');
    }
  }

  /// Share PDF via email with file attachment
  static Future<void> sharePdfViaEmail({
    required String pdfUrl,
    required String title,
    required String subject,
    required String body,
    String? recipientEmail,
  }) async {
    try {
      // Download PDF to temporary storage first
      final fileName = '${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = await downloadPdf(pdfUrl: pdfUrl, fileName: fileName);
      
      // Share the actual PDF file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject,
        text: body,
      );
    } catch (e) {
      throw Exception('Failed to share PDF via email: $e');
    }
  }

  /// Copy PDF URL to clipboard
  static Future<void> copyPdfUrlToClipboard(String pdfUrl) async {
    try {
      await Clipboard.setData(ClipboardData(text: pdfUrl));
    } catch (e) {
      throw Exception('Failed to copy URL to clipboard: $e');
    }
  }

  /// Share PDF via WhatsApp with file attachment
  static Future<void> sharePdfViaWhatsApp({
    required String pdfUrl,
    required String message,
    String? phoneNumber,
  }) async {
    try {
      // Download PDF to temporary storage first
      final fileName = 'document_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = await downloadPdf(pdfUrl: pdfUrl, fileName: fileName);
      
      // Share the actual PDF file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: message,
      );
    } catch (e) {
      throw Exception('Failed to share PDF via WhatsApp: $e');
    }
  }

  /// Show share options dialog
  static Future<void> showShareOptions({
    required BuildContext context,
    required String pdfUrl,
    required String title,
    String? subject,
    String? body,
    String? recipientEmail,
    String? phoneNumber,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Share $title',
          style: const TextStyle(
            color: Color(0xFFE5E5E5),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy, color: Color(0xFFD4AF37)),
              title: const Text(
                'Copy Link',
                style: TextStyle(color: Color(0xFFE5E5E5)),
              ),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await copyPdfUrlToClipboard(pdfUrl);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copied to clipboard'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to copy link: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Color(0xFFD4AF37)),
              title: const Text(
                'Share via Email',
                style: TextStyle(color: Color(0xFFE5E5E5)),
              ),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await sharePdfViaEmail(
                    pdfUrl: pdfUrl,
                    title: title,
                    subject: subject ?? title,
                    body: body ?? 'Please find the attached document: $title',
                    recipientEmail: recipientEmail,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to open email: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Color(0xFFD4AF37)),
              title: const Text(
                'Share via System',
                style: TextStyle(color: Color(0xFFE5E5E5)),
              ),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await sharePdf(
                    pdfUrl: pdfUrl,
                    title: title,
                    subject: subject,
                    text: body,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to share: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            if (phoneNumber != null)
              ListTile(
                leading: const Icon(Icons.chat, color: Color(0xFFD4AF37)),
                title: const Text(
                  'Share via WhatsApp',
                  style: TextStyle(color: Color(0xFFE5E5E5)),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await sharePdfViaWhatsApp(
                      pdfUrl: pdfUrl,
                      message: body ?? 'Please find the attached document: $title',
                      phoneNumber: phoneNumber,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to share via WhatsApp: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFB0B0B0)),
            ),
          ),
        ],
      ),
    );
  }
}
