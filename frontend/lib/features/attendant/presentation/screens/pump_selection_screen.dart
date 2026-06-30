import 'package:flutter/material.dart';
import 'package:paynotify/core/services/pump_service.dart';
import 'attendant_dashboard.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class PumpSelectionScreen extends StatefulWidget {
  final String attendantName;

  const PumpSelectionScreen({super.key, required this.attendantName});

  @override
  State<PumpSelectionScreen> createState() => _PumpSelectionScreenState();
}

class _PumpSelectionScreenState extends State<PumpSelectionScreen> {
  List<Pump> _pumps = [];
  String? _selectedPump;
  bool _isLoading = true;
  bool _isConfirming = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPumps();
  }

  Future<void> _loadPumps() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pumpsData = await PumpService.getPumps();

      final List<Pump> loadedPumps = pumpsData
          .map((json) => Pump.fromJson(json))
          .toList();

      setState(() {
        _pumps = loadedPumps;
        _isLoading = false;
      });

      debugPrint('✅ Loaded ${_pumps.length} pumps from backend');
    } catch (e) {
      debugPrint('❌ Error loading pumps: $e');
      setState(() {
        _errorMessage = 'Failed to load pumps: $e';
        _isLoading = false;
      });
    }
  }

  void _selectPump(String pumpName) {
    setState(() {
      _selectedPump = pumpName;
    });
  }

  Future<void> _confirmSelection() async {
    if (_selectedPump == null) return;

    setState(() => _isConfirming = true);

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AttendantDashboard(
            selectedPump: _selectedPump!,
            attendantName: widget.attendantName,
          ),
        ),
      ).then((_) {
        if (mounted) {
          setState(() {
            _isConfirming = false;
          });
        }
      });
    }
  }

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Pump Selection?'),
        content: _selectedPump == null
            ? const Text(
                'You haven\'t selected a pump. Are you sure you want to go back?')
            : const Text(
                'Are you sure you want to go back? You will need to select a pump again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Go Back'),
          ),
        ],
      ),
    );

    if (shouldPop == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }

    return false;
  }

  Color _getStatusColor(PumpStatus status) {
    switch (status) {
      case PumpStatus.available:
        return Colors.green;
      case PumpStatus.occupied:
        return Colors.orange;
      case PumpStatus.maintenance:
        return Colors.red;
    }
  }

  String _getStatusText(PumpStatus status) {
    switch (status) {
      case PumpStatus.available:
        return 'AVAILABLE';
      case PumpStatus.occupied:
        return 'OCCUPIED';
      case PumpStatus.maintenance:
        return 'MAINTENANCE';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Pump'),
          backgroundColor: const Color(0xFF0B3D2E),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _onWillPop();
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPumps,
              tooltip: 'Refresh Pumps',
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B3D2E).withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF0B3D2E),
                        child: Text(
                          widget.attendantName
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${widget.attendantName}!',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0B3D2E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Choose the pump you\'re operating today',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Center(
                  child: Wrap(
                    spacing: 12,
                    children: [
                      _buildStatusIndicator(PumpStatus.available, 'Available'),
                      _buildStatusIndicator(PumpStatus.occupied, 'Occupied'),
                      _buildStatusIndicator(
                          PumpStatus.maintenance, 'Maintenance'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 48, color: Colors.red[300]),
                                  const SizedBox(height: 16),
                                  Text(_errorMessage!,
                                      textAlign: TextAlign.center),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadPumps,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : _pumps.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.local_gas_station,
                                          size: 48, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      const Text('No pumps available'),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: _loadPumps,
                                        child: const Text('Refresh'),
                                      ),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 1.2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: _pumps.length,
                                  itemBuilder: (context, index) {
                                    final pump = _pumps[index];
                                    final isSelected =
                                        _selectedPump == pump.name;
                                    final isAvailable =
                                        pump.status == PumpStatus.available;

                                    return AnimatedScale(
                                      scale: isSelected ? 1.03 : 1.0,
                                      duration:
                                          const Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                      child: PumpCard(
                                        pump: pump,
                                        isSelected: isSelected,
                                        isEnabled: isAvailable,
                                        getStatusColor: _getStatusColor,
                                        getStatusText: _getStatusText,
                                        onTap: () {
                                          if (isAvailable) {
                                            _selectPump(pump.name);
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: _isConfirming ? null : _onWillPop,
                          style: OutlinedButton.styleFrom(
                            side:
                                const BorderSide(color: Color(0xFF0B3D2E)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'BACK',
                            style: TextStyle(
                                color: Color(0xFF0B3D2E), fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed:
                              _selectedPump != null && !_isConfirming
                                  ? _confirmSelection
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B3D2E),
                            disabledBackgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isConfirming
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'START SHIFT',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(PumpStatus status, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _getStatusColor(status),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// PUMP CARD WIDGET
// ─────────────────────────────────────────────

class PumpCard extends StatelessWidget {
  final Pump pump;
  final bool isSelected;
  final bool isEnabled;
  final Color Function(PumpStatus) getStatusColor;
  final String Function(PumpStatus) getStatusText;
  final VoidCallback onTap;

  const PumpCard({
    super.key,
    required this.pump,
    required this.isSelected,
    required this.isEnabled,
    required this.getStatusColor,
    required this.getStatusText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      color: _getCardColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF0B3D2E)
              : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_gas_station,
                size: 32,
                color: _getIconColor(),
              ),
              const SizedBox(height: 4),
              Text(
                pump.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getTextColor(),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                pump.fuelType,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'KES ${pump.pricePerLiter.toStringAsFixed(2)}/L',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: getStatusColor(pump.status),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  getStatusText(pump.status),
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCardColor() {
    if (!isEnabled) return Colors.grey[200]!;
    if (isSelected) return const Color(0xFF0B3D2E).withAlpha(26);
    return Colors.white;
  }

  Color _getIconColor() {
    if (!isEnabled) return Colors.grey;
    return getStatusColor(pump.status);
  }

  Color _getTextColor() {
    if (!isEnabled) return Colors.grey;
    if (isSelected) return const Color(0xFF0B3D2E);
    return Colors.black;
  }
}

// ─────────────────────────────────────────────
// PUMP MODEL
// ─────────────────────────────────────────────

class Pump {
  final String name;
  final PumpStatus status;
  final String fuelType;
  final double pricePerLiter;

  const Pump({
    required this.name,
    required this.status,
    required this.fuelType,
    required this.pricePerLiter,
  });

  /// Maps backend camelCase response → Pump model
  /// Backend returns: pumpNumber, fuelType, status, pricePerLiter
  factory Pump.fromJson(Map<String, dynamic> json) {
    // Handle price — backend returns camelCase 'pricePerLiter'
    double price;
    final priceValue = json['pricePerLiter'] ?? json['price_per_liter'];
    if (priceValue is String) {
      price = double.tryParse(priceValue) ?? 0.0;
    } else if (priceValue is num) {
      price = priceValue.toDouble();
    } else {
      price = 0.0;
    }

    // Map backend status string → PumpStatus enum
    PumpStatus status;
    final statusValue =
        (json['status'] ?? 'inactive').toString().toLowerCase();
    switch (statusValue) {
      case 'active':
        status = PumpStatus.available;
        break;
      case 'occupied':
        status = PumpStatus.occupied;
        break;
      case 'maintenance':
      case 'inactive':
      case 'emergency':
      case 'offline':
        status = PumpStatus.maintenance;
        break;
      default:
        status = PumpStatus.maintenance;
    }

    return Pump(
      // Backend returns camelCase 'pumpNumber'
      name: json['pumpNumber'] ?? json['pump_number'] ?? 'Unknown',
      status: status,
      fuelType: json['fuelType'] ?? json['fuel_type'] ?? 'Petrol',
      pricePerLiter: price,
    );
  }
}

// ─────────────────────────────────────────────
// PUMP STATUS ENUM
// ─────────────────────────────────────────────

enum PumpStatus {
  available,
  occupied,
  maintenance;
}