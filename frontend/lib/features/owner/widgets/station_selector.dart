// lib/features/owner/widgets/station_selector.dart
import 'package:flutter/material.dart';
import '../domain/models/station_model.dart';

class StationSelector extends StatelessWidget {
  final List<Station> stations;
  final int? selectedStationId;
  final ValueChanged<int?> onStationSelected;
  final String hintText;

  const StationSelector({
    super.key,
    required this.stations,
    this.selectedStationId,
    required this.onStationSelected,
    this.hintText = 'Select Station',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: selectedStationId,
          hint: Text(hintText),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          elevation: 16,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          onChanged: onStationSelected,
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('All Stations'),
            ),
            ...stations.map((station) {
              return DropdownMenuItem<int?>(
                value: station.id,
                child: Row(
                  children: [
                    Icon(
                      Icons.business,
                      size: 16,
                      color: station.isActive ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station.stationName,
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            station.stationCode,
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    if (!station.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'INACTIVE',
                          style: TextStyle(fontSize: 8, color: Colors.red),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}