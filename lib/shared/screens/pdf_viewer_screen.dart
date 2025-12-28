import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/shared/widgets/luxury_app_bar.dart';
import 'package:choice_lux_cars/shared/widgets/system_safe_scaffold.dart';
import 'package:choice_lux_cars/shared/utils/background_pattern_utils.dart';
import 'package:choice_lux_cars/shared/services/pdf_viewer_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final String? documentType;
  final Map<String, dynamic>? documentData;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
    this.documentType,
    this.documentData,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? localPath;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    
    // Check if running on web
    if (kIsWeb) {
      Log.d('PDF viewer opened on web - redirecting to external browser');
      _redirectToWebBrowser();
    } else {
      _downloadAndCachePdf();
    }
  }

  Future<void> _redirectToWebBrowser() async {
    try {
      await PdfViewerService.openPdfWeb(widget.pdfUrl, widget.title);
      // Close this screen since we're opening in external browser
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      Log.e('Failed to redirect to web browser: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to open PDF in browser: $e';
      });
    }
  }

  Future<void> _downloadAndCachePdf() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      // Download PDF from URL
      final response = await http.get(Uri.parse(widget.pdfUrl));
      
      if (response.statusCode == 200) {
        // Get temporary directory
        final tempDir = await getTemporaryDirectory();
        final fileName = '${widget.documentType ?? 'document'}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${tempDir.path}/$fileName');
        
        // Write PDF bytes to file
        await file.writeAsBytes(response.bodyBytes);
        
        setState(() {
          localPath = file.path;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to download PDF: HTTP ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SystemSafeScaffold(
      backgroundColor: Colors.transparent,
      appBar: LuxuryAppBar(
        title: widget.title,
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
        actions: [
          if (!_isLoading && !_hasError && localPath != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadPdf,
              tooltip: 'Download PDF',
            ),
          if (!_isLoading && !_hasError && localPath != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _showShareOptions,
              tooltip: 'Share PDF',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: ChoiceLuxTheme.backgroundGradient,
            ),
          ),
          // Background pattern
          CustomPaint(
            painter: BackgroundPatterns.dashboard,
            size: Size.infinite,
          ),
          // Main content
          SafeArea(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (localPath == null) {
      return _buildErrorState(message: 'PDF file not found');
    }

    return _buildPdfViewer();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ChoiceLuxTheme.richGold),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading PDF...',
            style: TextStyle(
              color: ChoiceLuxTheme.platinumSilver,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState({String? message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: ChoiceLuxTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load PDF',
              style: TextStyle(
                color: ChoiceLuxTheme.softWhite,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? _errorMessage ?? 'Unknown error occurred',
              style: TextStyle(
                color: ChoiceLuxTheme.platinumSilver,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _downloadAndCachePdf,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChoiceLuxTheme.richGold,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    return Column(
      children: [
        // PDF Info Bar
        if (_isReady && _totalPages > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: ChoiceLuxTheme.charcoalGray.withOpacity(0.8),
              border: Border(
                bottom: BorderSide(
                  color: ChoiceLuxTheme.richGold.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  color: ChoiceLuxTheme.richGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Page $_currentPage of $_totalPages',
                  style: TextStyle(
                    color: ChoiceLuxTheme.platinumSilver,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_totalPages > 1)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 0 ? _previousPage : null,
                        color: ChoiceLuxTheme.richGold,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _currentPage < _totalPages - 1 ? _nextPage : null,
                        color: ChoiceLuxTheme.richGold,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        // PDF Viewer
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: PDFView(
                filePath: localPath!,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: false,
                pageFling: true,
                pageSnap: true,
                onRender: (pages) {
                  setState(() {
                    _totalPages = pages ?? 0;
                    _isReady = true;
                  });
                },
                onViewCreated: (PDFViewController controller) {
                  // Store controller for navigation
                },
                onPageChanged: (page, total) {
                  setState(() {
                    _currentPage = page ?? 0;
                    _totalPages = total ?? 0;
                  });
                },
                onError: (error) {
                  setState(() {
                    _hasError = true;
                    _errorMessage = error.toString();
                  });
                },
                onPageError: (page, error) {
                  setState(() {
                    _hasError = true;
                    _errorMessage = 'Error loading page $page: $error';
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  Future<void> _downloadPdf() async {
    try {
      final fileName = '${widget.documentType ?? 'document'}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = await PdfViewerService.downloadPdf(
        pdfUrl: widget.pdfUrl,
        fileName: fileName,
      );
      
      // Get file size for better user feedback
      final file = File(filePath);
      final fileSize = await file.length();
      final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      
      // Show enhanced success message with share option
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PDF downloaded successfully!'),
              Text('File: ${fileName}'),
              Text('Size: ${fileSizeMB} MB'),
              Text('Location: Downloads folder'),
            ],
          ),
          backgroundColor: ChoiceLuxTheme.successColor,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Share Now',
            textColor: Colors.white,
            onPressed: () => _showShareOptions(),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: ChoiceLuxTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _showShareOptions() async {
    final subject = _getEmailSubject();
    final body = _getEmailBody();
    
    await PdfViewerService.showShareOptions(
      context: context,
      pdfUrl: widget.pdfUrl,
      title: widget.title,
      subject: subject,
      body: body,
      recipientEmail: _getRecipientEmail(),
      phoneNumber: _getPhoneNumber(),
    );
  }

  String _getEmailSubject() {
    switch (widget.documentType) {
      case 'quote':
        return 'Quote #${widget.documentData?['id'] ?? 'N/A'} - ${widget.documentData?['title'] ?? 'Untitled Quote'}';
      case 'voucher':
        return 'Voucher #${widget.documentData?['id'] ?? 'N/A'} - ${widget.documentData?['title'] ?? 'Untitled Voucher'}';
      case 'invoice':
        return 'Invoice #${widget.documentData?['id'] ?? 'N/A'} - ${widget.documentData?['title'] ?? 'Untitled Invoice'}';
      default:
        return widget.title;
    }
  }

  String _getEmailBody() {
    final documentType = widget.documentType ?? 'document';
    final documentId = widget.documentData?['id'] ?? 'N/A';
    final documentTitle = widget.documentData?['title'] ?? 'Untitled Document';
    
    return '''
Hello,

Please find the $documentType attached: $documentTitle

Document Details:
- $documentType ID: $documentId
- Date: ${DateTime.now().toString().split(' ')[0]}
- Company: Choice Lux Cars

You can view the $documentType here: ${widget.pdfUrl}

Best regards,
Choice Lux Cars Team
''';
  }

  String? _getRecipientEmail() {
    return widget.documentData?['recipientEmail'] as String?;
  }

  String? _getPhoneNumber() {
    return widget.documentData?['phoneNumber'] as String?;
  }
}
