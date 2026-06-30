// lib/features/owner/presentation/screens/add_station_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/owner_provider.dart';
import 'package:paynotify/core/services/pump_service.dart';

// ─────────────────────────────────────────────
// PUMP ENTRY MODEL (local, for the form only)
// ─────────────────────────────────────────────
class _PumpEntry {
  final TextEditingController numberController;
  String fuelType;
  final TextEditingController priceController;
  final TextEditingController capacityController;

  _PumpEntry()
      : numberController = TextEditingController(),
        fuelType = 'petrol',
        priceController = TextEditingController(),
        capacityController = TextEditingController(text: '10000');

  void dispose() {
    numberController.dispose();
    priceController.dispose();
    capacityController.dispose();
  }

  bool get isValid =>
      numberController.text.trim().isNotEmpty &&
      priceController.text.trim().isNotEmpty &&
      (double.tryParse(priceController.text.trim()) ?? 0) > 0;
}

// ─────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────
class AddStationScreen extends StatefulWidget {
  const AddStationScreen({super.key});

  @override
  State<AddStationScreen> createState() => _AddStationScreenState();
}

class _AddStationScreenState extends State<AddStationScreen> {
  // Step tracking
  int _currentStep = 0; // 0 = station details, 1 = add pumps

  // ── Step 1 — Station form ──
  final _stationFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _locationController = TextEditingController();
  final _cityController = TextEditingController();
  final _countyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _paybillController = TextEditingController();
  final _tillController = TextEditingController();

  bool _isCreatingStation = false;
  String? _stationError;
  int? _createdStationId; // set after step 1 succeeds

  // ── Step 2 — Pump form ──
  final List<_PumpEntry> _pumps = [];
  bool _isSavingPumps = false;
  String? _pumpError;
  int _pumpsCreated = 0;

  static const List<String> _fuelTypes = [
    'petrol',
    'diesel',
    'kerosene',
    'premium',
  ];

  static const Map<String, IconData> _fuelIcons = {
    'petrol': Icons.local_gas_station,
    'diesel': Icons.local_gas_station_outlined,
    'kerosene': Icons.oil_barrel,
    'premium': Icons.star,
  };

  static const Map<String, Color> _fuelColors = {
    'petrol': Color(0xFF0B3D2E),
    'diesel': Color(0xFF2ECC71),
    'kerosene': Color(0xFFF39C12),
    'premium': Color(0xFF9B59B6),
  };

  @override
  void initState() {
    super.initState();
    _addPump(); // start with one pump row
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _countyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _paybillController.dispose();
    _tillController.dispose();
    for (final p in _pumps) {
      p.dispose();
    }
    super.dispose();
  }

  void _addPump() {
    setState(() => _pumps.add(_PumpEntry()));
  }

  void _removePump(int index) {
    if (_pumps.length == 1) return; // keep at least one
    setState(() {
      _pumps[index].dispose();
      _pumps.removeAt(index);
    });
  }

  // ─────────────────────────────────────────────
  // STEP 1 — CREATE STATION
  // ─────────────────────────────────────────────
  Future<void> _createStation() async {
    if (!_stationFormKey.currentState!.validate()) return;

    setState(() {
      _isCreatingStation = true;
      _stationError = null;
    });

    final stationData = {
      'station_name': _nameController.text.trim(),
      'station_code': _codeController.text.trim().toUpperCase(),
      'location': _locationController.text.trim(),
      if (_cityController.text.trim().isNotEmpty)
        'city': _cityController.text.trim(),
      if (_countyController.text.trim().isNotEmpty)
        'county': _countyController.text.trim(),
      if (_phoneController.text.trim().isNotEmpty)
        'phone': _phoneController.text.trim(),
      if (_emailController.text.trim().isNotEmpty)
        'email': _emailController.text.trim(),
      if (_paybillController.text.trim().isNotEmpty)
        'paybill_number': _paybillController.text.trim(),
      if (_tillController.text.trim().isNotEmpty)
        'till_number': _tillController.text.trim(),
    };

    try {
      final ownerProvider = context.read<OwnerProvider>();
      final success = await ownerProvider.createStation(stationData);

      if (!mounted) return;

      if (success) {
        // Get the newly created station ID from the provider
        final newStation = ownerProvider.stations.isNotEmpty
            ? ownerProvider.stations.first
            : null;

        setState(() {
          _isCreatingStation = false;
          _createdStationId = newStation?.id;
          _currentStep = 1; // move to pump step
        });
      } else {
        setState(() {
          _isCreatingStation = false;
          _stationError =
              ownerProvider.errorMessage ?? 'Failed to create station';
        });
      }
    } catch (e) {
      setState(() {
        _isCreatingStation = false;
        _stationError = e.toString();
      });
    }
  }

  // ─────────────────────────────────────────────
  // STEP 2 — CREATE PUMPS
  // ─────────────────────────────────────────────
  Future<void> _createPumps() async {
    // Validate all pump entries
    bool allValid = true;
    for (final pump in _pumps) {
      if (!pump.isValid) {
        allValid = false;
        break;
      }
    }

    if (!allValid) {
      setState(() {
        _pumpError =
            'Please fill in pump number and price for all pumps.';
      });
      return;
    }

    if (_createdStationId == null) {
      setState(() {
        _pumpError = 'Station ID missing. Please go back and retry.';
      });
      return;
    }

    setState(() {
      _isSavingPumps = true;
      _pumpError = null;
      _pumpsCreated = 0;
    });

    int successCount = 0;
    final List<String> errors = [];

    for (final pump in _pumps) {
      try {
        final result = await PumpService.createPump(
          pumpNumber: pump.numberController.text.trim(),
          fuelType: pump.fuelType,
          pricePerLiter:
              double.parse(pump.priceController.text.trim()),
          tankCapacity: double.tryParse(
                  pump.capacityController.text.trim()) ??
              10000,
          stationId: _createdStationId!,
        );

        if (result != null) {
          successCount++;
          setState(() => _pumpsCreated = successCount);
        } else {
          errors.add(
              '${pump.numberController.text.trim()}: failed to create');
        }
      } catch (e) {
        errors.add('${pump.numberController.text.trim()}: $e');
      }
    }

    if (!mounted) return;

    setState(() => _isSavingPumps = false);

    if (errors.isEmpty) {
      // All pumps created — done!
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Station and $successCount pump(s) created successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context, true);
    } else {
      setState(() {
        _pumpError =
            '$successCount pump(s) created. Failed:\n${errors.join('\n')}';
      });
    }
  }

  void _skipPumps() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Station created. You can add pumps later.'),
        backgroundColor: Colors.orange,
      ),
    );
    Navigator.pop(context, true);
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            _currentStep == 0 ? 'Add New Station' : 'Add Pumps'),
        backgroundColor: const Color(0xFF0B3D2E),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep == 1) {
              setState(() => _currentStep = 0);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: _currentStep == 0
                ? _buildStationForm()
                : _buildPumpForm(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STEP INDICATOR
  // ─────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          _buildStep(1, 'Station Details', _currentStep >= 0),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep >= 1
                  ? const Color(0xFF2ECC71)
                  : Colors.grey.shade300,
            ),
          ),
          _buildStep(2, 'Add Pumps', _currentStep >= 1),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String label, bool isActive) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isActive
              ? const Color(0xFF0B3D2E)
              : Colors.grey.shade300,
          child: Text(
            '$number',
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive
                ? const Color(0xFF0B3D2E)
                : Colors.grey,
            fontWeight: isActive
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // STEP 1 — STATION FORM
  // ─────────────────────────────────────────────
  Widget _buildStationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _stationFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Required'),
            const SizedBox(height: 12),

            _field(
              controller: _nameController,
              label: 'Station Name',
              icon: Icons.business,
              hint: 'e.g., Westlands Main Station',
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Station name is required';
                }
                if (v.trim().length < 3) {
                  return 'Must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            _field(
              controller: _codeController,
              label: 'Station Code',
              icon: Icons.code,
              hint: 'e.g., WST001',
              helperText: 'Uppercase letters and numbers only',
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[A-Za-z0-9]')),
                TextInputFormatter.withFunction(
                  (old, newVal) => newVal.copyWith(
                    text: newVal.text.toUpperCase(),
                  ),
                ),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Station code is required';
                }
                if (v.trim().length < 2) {
                  return 'Must be at least 2 characters';
                }
                if (!RegExp(r'^[A-Z0-9]+$').hasMatch(v.trim())) {
                  return 'Only uppercase letters and numbers allowed';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            _field(
              controller: _locationController,
              label: 'Location / Address',
              icon: Icons.location_on,
              hint: 'e.g., Westlands Shopping Centre, Nairobi',
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Location is required';
                }
                if (v.trim().length < 5) {
                  return 'Must be at least 5 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            _sectionHeader('Optional'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _field(
                    controller: _cityController,
                    label: 'City',
                    icon: Icons.location_city,
                    hint: 'e.g., Nairobi',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    controller: _countyController,
                    label: 'County',
                    icon: Icons.map,
                    hint: 'e.g., Nairobi',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _field(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              hint: '0712345678',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            _field(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email,
              hint: 'station@example.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(v.trim())) {
                    return 'Enter a valid email address';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _field(
                    controller: _paybillController,
                    label: 'Paybill Number',
                    icon: Icons.payment,
                    hint: '500123',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    controller: _tillController,
                    label: 'Till Number',
                    icon: Icons.point_of_sale,
                    hint: '123456',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            if (_stationError != null) ...[
              const SizedBox(height: 16),
              _errorBox(_stationError!),
            ],

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed:
                        _isCreatingStation ? null : _createStation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B3D2E),
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isCreatingStation
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Next: Add Pumps →'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STEP 2 — PUMP FORM
  // ─────────────────────────────────────────────
  Widget _buildPumpForm() {
    return Column(
      children: [
        // Info banner
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0B3D2E).withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: const Color(0xFF0B3D2E).withAlpha(60)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle,
                  color: Color(0xFF2ECC71), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Station created! Now add pumps for this station.',
                  style: TextStyle(
                    color: const Color(0xFF0B3D2E),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Pump list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _pumps.length,
            itemBuilder: (context, index) =>
                _buildPumpCard(index),
          ),
        ),

        // Add pump button
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          child: OutlinedButton.icon(
            onPressed: _addPump,
            icon: const Icon(Icons.add),
            label: const Text('Add Another Pump'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0B3D2E),
              side: const BorderSide(color: Color(0xFF0B3D2E)),
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ),

        if (_pumpError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _errorBox(_pumpError!),
          ),

        // Progress indicator while saving
        if (_isSavingPumps)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _pumps.isEmpty
                      ? 0
                      : _pumpsCreated / _pumps.length,
                  backgroundColor: Colors.grey.shade200,
                  color: const Color(0xFF2ECC71),
                ),
                const SizedBox(height: 4),
                Text(
                  'Creating pump $_pumpsCreated of ${_pumps.length}...',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isSavingPumps ? null : _skipPumps,
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Skip for Now'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed:
                      _isSavingPumps ? null : _createPumps,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ECC71),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSavingPumps
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Save ${_pumps.length} Pump(s)'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPumpCard(int index) {
    final pump = _pumps[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (_fuelColors[pump.fuelType] ??
                            const Color(0xFF0B3D2E))
                        .withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _fuelIcons[pump.fuelType] ??
                        Icons.local_gas_station,
                    color: _fuelColors[pump.fuelType] ??
                        const Color(0xFF0B3D2E),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Pump ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (_pumps.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red),
                    onPressed: () => _removePump(index),
                    tooltip: 'Remove pump',
                    constraints: const BoxConstraints(
                        minWidth: 36, minHeight: 36),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Pump number
            TextFormField(
              controller: pump.numberController,
              decoration: InputDecoration(
                labelText: 'Pump Number / Name',
                hintText: 'e.g., Pump ${index + 1}',
                prefixIcon:
                    const Icon(Icons.local_gas_station),
                border: const OutlineInputBorder(
                  borderRadius:
                      BorderRadius.all(Radius.circular(8)),
                ),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Fuel type selector
            const Text(
              'Fuel Type',
              style: TextStyle(
                  fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: _fuelTypes.map((type) {
                final isSelected = pump.fuelType == type;
                return ChoiceChip(
                  label: Text(
                    type[0].toUpperCase() + type.substring(1),
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => pump.fuelType = type);
                  },
                  selectedColor:
                      _fuelColors[type]?.withAlpha(51) ??
                          Colors.green.withAlpha(51),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? (_fuelColors[type] ??
                            const Color(0xFF0B3D2E))
                        : Colors.black,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  avatar: Icon(
                    _fuelIcons[type] ??
                        Icons.local_gas_station,
                    size: 14,
                    color: isSelected
                        ? (_fuelColors[type] ??
                            const Color(0xFF0B3D2E))
                        : Colors.grey,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Price and capacity row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: pump.priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                            decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Price/Liter (KES)',
                      hintText: '180.50',
                      prefixIcon:
                          const Icon(Icons.attach_money),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                            Radius.circular(8)),
                      ),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: pump.capacityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tank Capacity (L)',
                      hintText: '10000',
                      prefixIcon:
                          Icon(Icons.water_drop_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                            Radius.circular(8)),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────
  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? helperText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      validator: validator,
    );
  }

  Widget _errorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}