import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NoticeBoardScreen extends StatefulWidget {
  final String attendantName;
  final String selectedPump;

  const NoticeBoardScreen({
    super.key,
    required this.attendantName,
    required this.selectedPump,
  });

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  // Mock announcements - In real app, these would come from backend
  final List<Announcement> _announcements = [
    Announcement(
      id: '1',
      title: '⚠️ Fuel Price Change',
      message: 'Effective immediately: Super Petrol - KES 195.50/L, Diesel - KES 180.20/L',
      type: AnnouncementType.price,
      priority: Priority.high,
      postedBy: 'Management',
      postedAt: DateTime.now().subtract(const Duration(hours: 2)),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      readBy: [],
    ),
    Announcement(
      id: '2',
      title: '🛢️ Low Fuel Stock Alert',
      message: 'Diesel stock running low at Pump 2 & 4. New delivery expected at 3 PM.',
      type: AnnouncementType.stock,
      priority: Priority.urgent,
      postedBy: 'Operations',
      postedAt: DateTime.now().subtract(const Duration(hours: 5)),
      expiresAt: DateTime.now().add(const Duration(hours: 10)),
      readBy: [],
    ),
    Announcement(
      id: '3',
      title: '📅 Shift Schedule Update',
      message: 'Saturday shifts: Morning (6AM-2PM) - John, Mary; Afternoon (2PM-10PM) - Peter, Grace',
      type: AnnouncementType.shift,
      priority: Priority.medium,
      postedBy: 'HR',
      postedAt: DateTime.now().subtract(const Duration(days: 1)),
      expiresAt: DateTime.now().add(const Duration(days: 6)),
      readBy: [],
    ),
    Announcement(
      id: '4',
      title: '🎉 Employee of the Month',
      message: 'Congratulations to Peter for outstanding customer service! 🌟',
      type: AnnouncementType.general,
      priority: Priority.low,
      postedBy: 'Management',
      postedAt: DateTime.now().subtract(const Duration(days: 2)),
      expiresAt: DateTime.now().add(const Duration(days: 28)),
      readBy: [],
    ),
    Announcement(
      id: '5',
      title: '🔧 Maintenance Notice',
      message: 'Pump 3 will be under maintenance tomorrow (9AM - 11AM). Please direct customers to Pumps 1 & 2.',
      type: AnnouncementType.maintenance,
      priority: Priority.high,
      postedBy: 'Maintenance',
      postedAt: DateTime.now().subtract(const Duration(hours: 12)),
      expiresAt: DateTime.now().add(const Duration(days: 2)),
      readBy: [],
    ),
    Announcement(
      id: '6',
      title: '⚠️ Emergency - Fuel Shortage',
      message: 'Due to supply chain issues, limit diesel sales to KES 5,000 per customer until further notice.',
      type: AnnouncementType.emergency,
      priority: Priority.urgent,
      postedBy: 'Management',
      postedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      expiresAt: DateTime.now().add(const Duration(hours: 48)),
      readBy: [],
    ),
  ];

  List<Announcement> _filteredAnnouncements = [];
  String _selectedFilter = 'All';
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _filteredAnnouncements = _announcements;
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _filterAnnouncements();
    });
  }

  void _toggleUnreadOnly() {
    setState(() {
      _showUnreadOnly = !_showUnreadOnly;
      _filterAnnouncements();
    });
  }

  void _filterAnnouncements() {
    var filtered = List<Announcement>.from(_announcements);
    
    // Apply type filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((a) {
        switch (_selectedFilter) {
          case 'Urgent':
            return a.priority == Priority.urgent || a.priority == Priority.high;
          case 'Price':
            return a.type == AnnouncementType.price;
          case 'Shift':
            return a.type == AnnouncementType.shift;
          case 'Stock':
            return a.type == AnnouncementType.stock;
          case 'Emergency':
            return a.type == AnnouncementType.emergency;
          default:
            return true;
        }
      }).toList();
    }
    
    // Apply unread filter
    if (_showUnreadOnly) {
      filtered = filtered.where((a) => !a.readBy.contains(widget.attendantName)).toList();
    }
    
    // Sort by priority and date
    filtered.sort((a, b) {
      // Urgent first
      if (a.priority == Priority.urgent && b.priority != Priority.urgent) return -1;
      if (b.priority == Priority.urgent && a.priority != Priority.urgent) return 1;
      
      // Then high priority
      if (a.priority == Priority.high && b.priority != Priority.high) return -1;
      if (b.priority == Priority.high && a.priority != Priority.high) return 1;
      
      // Then by date (newest first)
      return b.postedAt.compareTo(a.postedAt);
    });
    
    _filteredAnnouncements = filtered;
  }

  void _markAsRead(Announcement announcement) {
    if (!announcement.readBy.contains(widget.attendantName)) {
      setState(() {
        announcement.readBy.add(widget.attendantName);
      });
    }
  }

  void _showAnnouncementDetails(Announcement announcement) {
    _markAsRead(announcement);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with priority color
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getPriorityColor(announcement.priority).withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getTypeIcon(announcement.type),
                      color: _getPriorityColor(announcement.priority),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            announcement.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getPriorityText(announcement.priority),
                            style: TextStyle(
                              color: _getPriorityColor(announcement.priority),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Message
              Text(
                announcement.message,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              
              const SizedBox(height: 20),
              
              // Metadata
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.person, 'Posted by', announcement.postedBy),
                    _buildInfoRow(Icons.access_time, 'Posted', _formatTime(announcement.postedAt)),
                    _buildInfoRow(Icons.update, 'Expires', _formatTime(announcement.expiresAt)),
                    _buildInfoRow(Icons.visibility, 'Views', '${announcement.readBy.length} attendants'),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Acknowledged: ${announcement.title}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Acknowledge'),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return DateFormat('dd MMM yyyy').format(time);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.urgent:
        return Colors.red;
      case Priority.high:
        return Colors.orange;
      case Priority.medium:
        return Colors.blue;
      case Priority.low:
        return Colors.green;
    }
  }

  String _getPriorityText(Priority priority) {
    switch (priority) {
      case Priority.urgent:
        return 'URGENT';
      case Priority.high:
        return 'HIGH PRIORITY';
      case Priority.medium:
        return 'MEDIUM PRIORITY';
      case Priority.low:
        return 'LOW PRIORITY';
    }
  }

  IconData _getTypeIcon(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.price:
        return Icons.trending_up;
      case AnnouncementType.shift:
        return Icons.schedule;
      case AnnouncementType.stock:
        return Icons.inventory;
      case AnnouncementType.maintenance:
        return Icons.build;
      case AnnouncementType.emergency:
        return Icons.warning;
      case AnnouncementType.general:
        return Icons.info;
    }
  }

  Color _getTypeColor(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.price:
        return Colors.purple;
      case AnnouncementType.shift:
        return Colors.blue;
      case AnnouncementType.stock:
        return Colors.orange;
      case AnnouncementType.maintenance:
        return Colors.brown;
      case AnnouncementType.emergency:
        return Colors.red;
      case AnnouncementType.general:
        return Colors.teal;
    }
  }

  int _getUnreadCount() {
    return _announcements.where((a) => !a.readBy.contains(widget.attendantName)).length;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _getUnreadCount();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notice Board'),
        backgroundColor: const Color(0xFF0B3D2E),
        foregroundColor: Colors.white,
        actions: [
          // Unread filter toggle
          if (unreadCount > 0)
            Stack(
              children: [
                IconButton(
                  icon: Icon(
                    _showUnreadOnly ? Icons.mark_chat_read : Icons.mark_chat_unread,
                    color: _showUnreadOnly ? Colors.amber : Colors.white,
                  ),
                  onPressed: _toggleUnreadOnly,
                  tooltip: _showUnreadOnly ? 'Show all' : 'Show unread only',
                ),
                if (!_showUnreadOnly && unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', Icons.all_inbox),
                  const SizedBox(width: 8),
                  _buildFilterChip('Urgent', Icons.priority_high, color: Colors.red),
                  const SizedBox(width: 8),
                  _buildFilterChip('Price', Icons.trending_up, color: Colors.purple),
                  const SizedBox(width: 8),
                  _buildFilterChip('Shift', Icons.schedule, color: Colors.blue),
                  const SizedBox(width: 8),
                  _buildFilterChip('Stock', Icons.inventory, color: Colors.orange),
                  const SizedBox(width: 8),
                  _buildFilterChip('Emergency', Icons.warning, color: Colors.red),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _filteredAnnouncements.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No announcements',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _showUnreadOnly
                        ? 'You\'ve read all announcements'
                        : 'Check back later for updates',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredAnnouncements.length,
              itemBuilder: (context, index) {
                final announcement = _filteredAnnouncements[index];
                final isUnread = !announcement.readBy.contains(widget.attendantName);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isUnread
                        ? BorderSide(color: _getPriorityColor(announcement.priority), width: 2)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    onTap: () => _showAnnouncementDetails(announcement),
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _getTypeColor(announcement.type).withAlpha(26),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getTypeIcon(announcement.type),
                        color: _getTypeColor(announcement.type),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            announcement.title,
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (announcement.priority == Priority.urgent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'URGENT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          announcement.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(announcement.postedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              announcement.postedBy,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: isUnread
                        ? Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getPriorityColor(announcement.priority),
                              shape: BoxShape.circle,
                            ),
                          )
                        : Icon(
                            Icons.check_circle,
                            color: Colors.green[300],
                            size: 16,
                          ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, {Color color = Colors.grey}) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : color),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) => _applyFilter(label),
      backgroundColor: Colors.grey[200],
      selectedColor: color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

// Models
enum Priority { urgent, high, medium, low }
enum AnnouncementType { price, shift, stock, maintenance, emergency, general }

class Announcement {
  final String id;
  final String title;
  final String message;
  final AnnouncementType type;
  final Priority priority;
  final String postedBy;
  final DateTime postedAt;
  final DateTime expiresAt;
  final List<String> readBy;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.postedBy,
    required this.postedAt,
    required this.expiresAt,
    required this.readBy,
  });
}