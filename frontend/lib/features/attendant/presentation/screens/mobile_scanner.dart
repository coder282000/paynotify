import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class QrPayScreen extends StatefulWidget {
  final String attendantName;
  final String selectedPump;

  const QrPayScreen({
    super.key,
    required this.attendantName,
    required this.selectedPump,
  });

  @override
  State<QrPayScreen> createState() => _QrPayScreenState();
}

class _QrPayScreenState extends State<QrPayScreen> with WidgetsBindingObserver {
  int _selectedMode = 0; // 0 = Scan, 1 = Generate
  bool _isFlashOn = false;
  String? _scannedData;
  bool _isProcessing = false;
  MobileScannerController? _scannerController;

  // For generating QR
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _generatedQrData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCameraPermission();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController?.dispose();
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scannerController?.start();
    }
    if (state == AppLifecycleState.paused) {
      _scannerController?.stop();
    }
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isDenied) {
      await Permission.camera.request();
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    
    final barcode = capture.barcodes.first;
    if (barcode.rawValue == null) return;
    
    setState(() {
      _isProcessing = true;
      _scannedData = barcode.rawValue;
      _scannerController?.stop();
    });
    
    _processScannedData(barcode.rawValue!);
  }

  void _processScannedData(String data) {
    if (!mounted) return;
    
    try {
      // Expected format: PAY|AMOUNT|PHONE|REF
      final parts = data.split('|');
      if (parts.length >= 3 && parts[0] == 'PAY') {
        final amount = double.tryParse(parts[1]) ?? 0;
        final phone = parts[2];
        final reference = parts.length > 3 ? parts[3] : 'QR${DateTime.now().millisecondsSinceEpoch}';
        
        if (!mounted) return;
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Payment Request'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Amount', 'KES ${amount.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _buildDetailRow('Phone', phone),
                const SizedBox(height: 8),
                _buildDetailRow('Reference', reference),
                const SizedBox(height: 16),
                const Text(
                  'Process this payment?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  if (mounted) _resetScanner();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  if (mounted) _processPayment(amount, phone, reference);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B3D2E),
                ),
                child: const Text('Process Payment'),
              ),
            ],
          ),
        );
      } else {
        if (mounted) _showErrorDialog('Invalid QR Code', 'This QR code is not a valid payment request.');
      }
    } catch (e) {
      if (mounted) _showErrorDialog('Error', 'Could not process QR code: $e');
    }
  }

  void _processPayment(double amount, String phone, String reference) {
    if (!mounted) return;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      Navigator.pop(context); // Remove loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Payment of KES ${amount.toStringAsFixed(0)} processed successfully!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      
      _resetScanner();
    });
  }

  void _resetScanner() {
    setState(() {
      _scannedData = null;
      _isProcessing = false;
    });
    _scannerController?.start();
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) _resetScanner();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _generateQRCode() {
    if (_amountController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter amount and phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = _amountController.text;
    final phone = _phoneController.text;
    final reference = 'QR${DateTime.now().millisecondsSinceEpoch}';
    
    // Format: PAY|AMOUNT|PHONE|REF
    final qrData = 'PAY|$amount|$phone|$reference';
    
    setState(() {
      _generatedQrData = qrData;
    });
  }

  void _toggleFlash() {
    _scannerController?.toggleTorch();
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  void _switchCamera() {
    _scannerController?.switchCamera();
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Pay'),
        backgroundColor: const Color(0xFF0B3D2E),
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() {
                      _selectedMode = 0;
                      _resetScanner();
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedMode == 0
                                ? const Color(0xFF0B3D2E)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Scan QR',
                          style: TextStyle(
                            color: Color(0xFF0B3D2E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedMode = 1);
                      _scannerController?.stop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedMode == 1
                                ? const Color(0xFF0B3D2E)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Generate QR',
                          style: TextStyle(
                            color: Color(0xFF0B3D2E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _selectedMode == 0 ? _buildScanMode() : _buildGenerateMode(),
    );
  }

  Widget _buildScanMode() {
    return Stack(
      children: [
        // QR Scanner using mobile_scanner
        MobileScanner(
          controller: _scannerController,
          onDetect: _onDetect,
        ),
        
        // Scanner overlay - Fixed: Removed QrScannerOverlayShape and used Container with decoration
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF0B3D2E),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(50),
        ),
        
        // Scanner controls
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(77),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: const Color(0xFF0B3D2E),
                  ),
                  onPressed: _toggleFlash,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey[300],
                ),
                IconButton(
                  icon: const Icon(Icons.cameraswitch, color: Color(0xFF0B3D2E)),
                  onPressed: _switchCamera,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey[300],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF0B3D2E)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),

        // Scanned data display
        if (_scannedData != null)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(77),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'QR Code scanned! Processing...',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGenerateMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generate Payment QR',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a QR code for customers to scan and pay',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // Amount field
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount (KES)',
              prefixIcon: const Icon(Icons.attach_money),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF0B3D2E), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Phone field
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Customer Phone',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF0B3D2E), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Generate button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _generateQRCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B3D2E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Generate QR Code',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Generated QR Code - Fixed deprecated foregroundColor
          if (_generatedQrData != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(51),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Scan this QR code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: QrImageView(
                      data: _generatedQrData!,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        color: Color(0xFF0B3D2E),
                        eyeShape: QrEyeShape.square,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        color: Color(0xFF0B3D2E),
                        dataModuleShape: QrDataModuleShape.square,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Amount: KES ${_amountController.text}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Phone: ${_phoneController.text}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Share feature coming soon!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _generatedQrData = null;
                            _amountController.clear();
                            _phoneController.clear();
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('New'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B3D2E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}