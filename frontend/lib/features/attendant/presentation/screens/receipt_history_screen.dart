import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paynotify/core/services/transaction_service.dart';

class ReceiptHistoryScreen extends StatefulWidget {
  final String attendantName;
  final String selectedPump;

  const ReceiptHistoryScreen({
    super.key,
    required this.attendantName,
    required this.selectedPump,
  });

  @override
  State<ReceiptHistoryScreen> createState() => _ReceiptHistoryScreenState();
}

class _ReceiptHistoryScreenState extends State<ReceiptHistoryScreen> {
  List<Map<String, dynamic>> _allTransactions = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  String _searchQuery = '';
  String _selectedFilter = 'All';
  DateTime? _selectedDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  // Helper method to safely convert amount to double
  double _parseAmount(dynamic amount) {
    if (amount is String) {
      return double.parse(amount);
    } else if (amount is num) {
      return amount.toDouble();
    }
    return 0.0;
  }

  // Helper method to format amount for display
  String _formatAmount(dynamic amount) {
    final doubleValue = _parseAmount(amount);
    return NumberFormat('#,##0.00').format(doubleValue);
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactions = await TransactionService.getTransactions();
      
      // Convert backend data to the format expected by the UI
      final List<Map<String, dynamic>> formattedTransactions = transactions.map((tx) {
        return {
          'id': tx['transaction_id'] ?? tx['id'].toString(),
          'date': DateTime.parse(tx['created_at']),
          'amount': _parseAmount(tx['amount']),
          'type': _getPaymentTypeDisplay(tx['payment_type']),
          'payment_type': tx['payment_type'],
          'customer': tx['customer_name'] ?? 'Walk-in Customer',
          'phone': tx['phone_number'] ?? 'N/A',
          'status': tx['status'],
          'pump': tx['pump_number'] ?? 'Pump ${tx['pump_id']}',
          'notes': tx['notes'],
          'transaction_id': tx['transaction_id'],
        };
      }).toList();
      
      // Filter by current pump
      final filteredByPump = formattedTransactions.where((tx) {
        return tx['pump'] == widget.selectedPump;
      }).toList();
      
      setState(() {
        _allTransactions = filteredByPump;
        _isLoading = false;
      });
      
      debugPrint('✅ Loaded ${_allTransactions.length} transactions from backend');
    } catch (e) {
      debugPrint('❌ Error loading transactions: $e');
      setState(() {
        _errorMessage = 'Failed to load transactions: $e';
        _isLoading = false;
      });
    }
  }

  String _getPaymentTypeDisplay(String paymentType) {
    switch (paymentType) {
      case 'cash': return 'Cash';
      case 'card': return 'Card';
      case 'mpesa': return 'M-Pesa';
      default: return paymentType;
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    return _allTransactions.where((tx) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesId = tx['id'].toLowerCase().contains(query);
        final matchesCustomer = tx['customer'].toLowerCase().contains(query);
        final matchesPhone = tx['phone'].toLowerCase().contains(query);
        final matchesAmount = tx['amount'].toString().contains(query);
        
        if (!(matchesId || matchesCustomer || matchesPhone || matchesAmount)) {
          return false;
        }
      }
      
      // Status filter
      if (_selectedFilter != 'All' && tx['status'] != _selectedFilter.toLowerCase()) {
        return false;
      }
      
      // Date filter
      if (_selectedDate != null) {
        final txDate = DateTime(tx['date'].year, tx['date'].month, tx['date'].day);
        final filterDate = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
        if (txDate != filterDate) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  double get _totalAmount {
    return _filteredTransactions.fold(0.0, (sum, tx) => sum + (tx['amount'] as num).toDouble());
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Filter Transactions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  // Status filter
                  const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'Completed', 'Pending'].map((status) {
                      return ChoiceChip(
                        label: Text(status),
                        selected: _selectedFilter == status,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = status;
                          });
                          Navigator.pop(context);
                          this.setState(() {}); // Refresh main screen
                        },
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Date filter
                  const Text('Date', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _selectedDate = date;
                              });
                              Navigator.pop(context);
                              this.setState(() {}); // Refresh main screen
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _selectedDate == null
                                ? 'Select Date'
                                : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                          ),
                        ),
                      ),
                      if (_selectedDate != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedDate = null;
                            });
                            Navigator.pop(context);
                            this.setState(() {});
                          },
                          icon: const Icon(Icons.clear),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Clear all button
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedFilter = 'All';
                        _selectedDate = null;
                      });
                      Navigator.pop(context);
                      this.setState(() {});
                    },
                    child: const Text('Clear All Filters'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _exportTransactions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('PDF Format'),
              subtitle: const Text('Export as PDF document'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF export coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Excel Format'),
              subtitle: const Text('Export as Excel spreadsheet'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Excel export coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('Share'),
              subtitle: const Text('Share via email or messaging'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon!')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;
    final totalAmount = _totalAmount;

    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction History - ${widget.selectedPump}'),
        backgroundColor: const Color(0xFF0B3D2E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportTransactions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTransactions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by ID, customer, phone...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    
                    // Summary card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        color: const Color(0xFF0B3D2E).withAlpha(26),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Showing',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${filtered.length} transactions',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Total Amount',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'KES ${_formatAmount(totalAmount)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0B3D2E),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Transactions list
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No transactions found',
                                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchQuery.isNotEmpty || _selectedFilter != 'All' || _selectedDate != null
                                        ? 'Try clearing your filters'
                                        : 'Record a sale to see transactions here',
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadTransactions,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final tx = filtered[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      onTap: () {
                                        _showTransactionDetails(tx);
                                      },
                                      leading: CircleAvatar(
                                        backgroundColor: tx['status'] == 'completed'
                                            ? Colors.green.withAlpha(26)
                                            : Colors.orange.withAlpha(26),
                                        child: Icon(
                                          tx['type'] == 'M-Pesa'
                                              ? Icons.phone_android
                                              : tx['type'] == 'Cash'
                                                  ? Icons.money
                                                  : Icons.credit_card,
                                          color: tx['status'] == 'completed'
                                              ? Colors.green
                                              : Colors.orange,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        'KES ${_formatAmount(tx['amount'])}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${tx['customer']} • ${tx['type']}'),
                                          Text(
                                            DateFormat('dd MMM yyyy • hh:mm a').format(tx['date']),
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: tx['status'] == 'completed'
                                              ? Colors.green.withAlpha(26)
                                              : Colors.orange.withAlpha(26),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          tx['status'].toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: tx['status'] == 'completed'
                                                ? Colors.green
                                                : Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.receipt,
                    color: const Color(0xFF0B3D2E),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Transaction Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              
              _detailRow('Transaction ID', transaction['transaction_id'] ?? transaction['id']),
              _detailRow('Date & Time', DateFormat('dd MMM yyyy • hh:mm a').format(transaction['date'])),
              _detailRow('Amount', 'KES ${_formatAmount(transaction['amount'])}'),
              _detailRow('Payment Type', transaction['type']),
              _detailRow('Customer', transaction['customer']),
              _detailRow('Phone', transaction['phone']),
              _detailRow('Pump', transaction['pump']),
              _detailRow('Status', transaction['status'].toUpperCase(),
                  statusColor: transaction['status'] == 'completed'
                      ? Colors.green
                      : Colors.orange),
              
              if (transaction['notes'] != null && transaction['notes'].isNotEmpty)
                _detailRow('Note', transaction['notes']),
              
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Print feature coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Print'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B3D2E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}