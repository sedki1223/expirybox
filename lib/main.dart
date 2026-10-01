import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ExpiryBoxApp());
}

class ExpiryBoxApp extends StatelessWidget {
  const ExpiryBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF5F1EA);
    const ink = Color(0xFF20201D);
    const accent = Color(0xFF476A5A);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ExpiryBox',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
        ),
        fontFamily: 'Arial',
        textTheme: const TextTheme(
          displaySmall: TextStyle(
            color: ink,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
          headlineSmall: TextStyle(
            color: ink,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
          titleLarge: TextStyle(
            color: ink,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF5F5D57),
            fontSize: 16,
            height: 1.4,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF77736A),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
      home: const ExpiryBoxHomePage(),
    );
  }
}

class ExpiryItem {
  final String id;
  final String name;
  final DateTime expiryDate;

  const ExpiryItem({
    required this.id,
    required this.name,
    required this.expiryDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'expiryDate': expiryDate.toIso8601String(),
    };
  }

  factory ExpiryItem.fromJson(Map<String, dynamic> json) {
    return ExpiryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      expiryDate: DateTime.parse(json['expiryDate'] as String),
    );
  }
}

enum ExpiryStatus {
  fresh,
  expiringSoon,
  expired,
}

class ExpiryBoxHomePage extends StatefulWidget {
  const ExpiryBoxHomePage({super.key});

  @override
  State<ExpiryBoxHomePage> createState() => _ExpiryBoxHomePageState();
}

class _ExpiryBoxHomePageState extends State<ExpiryBoxHomePage> {
  final List<ExpiryItem> _items = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final preferences = await SharedPreferences.getInstance();
    final savedItems = preferences.getStringList('expiry_items') ?? [];

    final loadedItems = <ExpiryItem>[];

    for (final item in savedItems) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        loadedItems.add(ExpiryItem.fromJson(decoded));
      } catch (_) {
        // Ignore invalid saved entries.
      }
    }

    loadedItems.sort(
      (a, b) => a.expiryDate.compareTo(b.expiryDate),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _items
        ..clear()
        ..addAll(loadedItems);
      _isLoading = false;
    });
  }

  Future<void> _saveItems() async {
    final preferences = await SharedPreferences.getInstance();

    final encodedItems = _items
        .map((item) => jsonEncode(item.toJson()))
        .toList();

    await preferences.setStringList(
      'expiry_items',
      encodedItems,
    );
  }

  Future<void> _addItem() async {
    final nameController = TextEditingController();
    DateTime? selectedDate;

    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFBF9F5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              title: const Text(
                'Add an item',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Item name',
                      hintText: 'Milk, cheese, medicine...',
                      filled: true,
                      fillColor: const Color(0xFFF1EEE8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final today = DateTime.now();

                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: today,
                        firstDate: today,
                        lastDate: DateTime(2100),
                      );

                      if (pickedDate != null) {
                        setDialogState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1EEE8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedDate == null
                                  ? 'Choose expiry date'
                                  : 'Expires ${_formatDate(selectedDate!)}',
                              style: TextStyle(
                                color: selectedDate == null
                                    ? const Color(0xFF77736A)
                                    : const Color(0xFF20201D),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF304B40),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();

                    if (name.isEmpty || selectedDate == null) {
                      return;
                    }

                    Navigator.pop(context, selectedDate);
                  },
                  child: const Text('Add item'),
                ),
              ],
            );
          },
        );
      },
    );

    final name = nameController.text.trim();
    nameController.dispose();

    if (result == null || name.isEmpty) {
      return;
    }

    final item = ExpiryItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      expiryDate: result,
    );

    setState(() {
      _items.add(item);
      _items.sort(
        (a, b) => a.expiryDate.compareTo(b.expiryDate),
      );
    });

    await _saveItems();
  }

  Future<void> _deleteItem(ExpiryItem item) async {
    setState(() {
      _items.removeWhere(
        (currentItem) => currentItem.id == item.id,
      );
    });

    await _saveItems();
  }

  ExpiryStatus _getStatus(DateTime expiryDate) {
    final today = DateTime.now();

    final todayOnly = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final expiryOnly = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );

    final daysRemaining = expiryOnly.difference(todayOnly).inDays;

    if (daysRemaining < 0) {
      return ExpiryStatus.expired;
    }

    if (daysRemaining <= 3) {
      return ExpiryStatus.expiringSoon;
    }

    return ExpiryStatus.fresh;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _statusLabel(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.fresh:
        return 'Fresh';
      case ExpiryStatus.expiringSoon:
        return 'Expiring Soon';
      case ExpiryStatus.expired:
        return 'Expired';
    }
  }

  Color _statusColor(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.fresh:
        return const Color(0xFF476A5A);
      case ExpiryStatus.expiringSoon:
        return const Color(0xFFC27A28);
      case ExpiryStatus.expired:
        return const Color(0xFFB84C43);
    }
  }

  IconData _statusIcon(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.fresh:
        return Icons.check_rounded;
      case ExpiryStatus.expiringSoon:
        return Icons.schedule_rounded;
      case ExpiryStatus.expired:
        return Icons.priority_high_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final freshCount = _items
        .where(
          (item) => _getStatus(item.expiryDate) == ExpiryStatus.fresh,
        )
        .length;

    final soonCount = _items
        .where(
          (item) =>
              _getStatus(item.expiryDate) == ExpiryStatus.expiringSoon,
        )
        .length;

    final expiredCount = _items
        .where(
          (item) => _getStatus(item.expiryDate) == ExpiryStatus.expired,
        )
        .length;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 760;

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 1100,
                      ),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          24,
                          24,
                          24,
                          110,
                        ),
                        children: [
                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 46,
                                          height: 46,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF304B40),
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          child: const Icon(
                                            Icons.inventory_2_rounded,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'ExpiryBox',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 22),
                                    const Text(
                                      'Know what expires next.',
                                      style: TextStyle(
                                        fontSize: 36,
                                        height: 1.02,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1.4,
                                        color: Color(0xFF20201D),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'A simple way to keep everyday items '
                                      'under control before they become waste.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        height: 1.45,
                                        color: Color(0xFF77736A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3ECE5),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.wifi_off_rounded,
                                      size: 15,
                                      color: Color(0xFF476A5A),
                                    ),
                                    SizedBox(width: 7),
                                    Text(
                                      'Offline',
                                      style: TextStyle(
                                        color: Color(0xFF476A5A),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Overview
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: const Color(0xFF304B40),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Your overview',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${_items.length} total',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _OverviewStat(
                                        value: freshCount.toString(),
                                        label: 'Fresh',
                                        icon: Icons.check_rounded,
                                        foreground: Colors.white,
                                        background:
                                            Colors.white.withValues(
                                          alpha: 0.10,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _OverviewStat(
                                        value: soonCount.toString(),
                                        label: 'Soon',
                                        icon: Icons.schedule_rounded,
                                        foreground: const Color(0xFFFFE2B6),
                                        background:
                                            Colors.white.withValues(
                                          alpha: 0.10,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _OverviewStat(
                                        value: expiredCount.toString(),
                                        label: 'Expired',
                                        icon: Icons.priority_high_rounded,
                                        foreground: const Color(0xFFFFC4BE),
                                        background:
                                            Colors.white.withValues(
                                          alpha: 0.10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Section header
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Your items',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              Text(
                                _items.isEmpty
                                    ? 'Nothing added'
                                    : 'Sorted by expiry',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF8A857C),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          if (_items.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 40,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: const Color(0xFFE6E0D7),
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 42,
                                    color: Color(0xFF9B958B),
                                  ),
                                  SizedBox(height: 14),
                                  Text(
                                    'Your box is empty',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Add your first item and start tracking '
                                    'its expiry date.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF8A857C),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            isWide
                                ? _WideItemLayout(
                                    items: _items,
                                    getStatus: _getStatus,
                                    statusColor: _statusColor,
                                    statusLabel: _statusLabel,
                                    statusIcon: _statusIcon,
                                    formatDate: _formatDate,
                                    onDelete: _deleteItem,
                                  )
                                : Column(
                                    children: _items.map((item) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: _ItemCard(
                                          item: item,
                                          status: _getStatus(
                                            item.expiryDate,
                                          ),
                                          statusColor: _statusColor(
                                            _getStatus(item.expiryDate),
                                          ),
                                          statusLabel: _statusLabel(
                                            _getStatus(item.expiryDate),
                                          ),
                                          statusIcon: _statusIcon(
                                            _getStatus(item.expiryDate),
                                          ),
                                          formattedDate:
                                              _formatDate(
                                            item.expiryDate,
                                          ),
                                          onDelete: () =>
                                              _deleteItem(item),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        backgroundColor: const Color(0xFF20201D),
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Item',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;

  const _OverviewStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: foreground,
            size: 20,
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              color: foreground,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.75),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ExpiryItem item;
  final ExpiryStatus status;
  final Color statusColor;
  final String statusLabel;
  final IconData statusIcon;
  final String formattedDate;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.item,
    required this.status,
    required this.statusColor,
    required this.statusLabel,
    required this.statusIcon,
    required this.formattedDate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE6E0D7),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Expires $formattedDate',
                  style: const TextStyle(
                    color: Color(0xFF8A857C),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Delete item',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFF8A857C),
            ),
          ),
        ],
      ),
    );
  }
}

class _WideItemLayout extends StatelessWidget {
  final List<ExpiryItem> items;
  final ExpiryStatus Function(DateTime) getStatus;
  final Color Function(ExpiryStatus) statusColor;
  final String Function(ExpiryStatus) statusLabel;
  final IconData Function(ExpiryStatus) statusIcon;
  final String Function(DateTime) formatDate;
  final Future<void> Function(ExpiryItem) onDelete;

  const _WideItemLayout({
    required this.items,
    required this.getStatus,
    required this.statusColor,
    required this.statusLabel,
    required this.statusIcon,
    required this.formatDate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        final status = getStatus(item.expiryDate);

        return SizedBox(
          width: 520,
          child: _ItemCard(
            item: item,
            status: status,
            statusColor: statusColor(status),
            statusLabel: statusLabel(status),
            statusIcon: statusIcon(status),
            formattedDate: formatDate(item.expiryDate),
            onDelete: () {
              onDelete(item);
            },
          ),
        );
      }).toList(),
    );
  }
}