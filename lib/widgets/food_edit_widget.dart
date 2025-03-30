import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/log_item.dart';
import '../services/logs_notifier.dart';
import '../services/firestore_logs_service.dart';

class FoodEditWidget extends ConsumerStatefulWidget {
  final LogItem logItem;

  const FoodEditWidget({
    Key? key,
    required this.logItem,
  }) : super(key: key);

  @override
  _FoodEditWidgetState createState() => _FoodEditWidgetState();
}

class _FoodEditWidgetState extends ConsumerState<FoodEditWidget> {
  late TextEditingController _nameController;
  late TextEditingController _caloriesController;
  late TextEditingController _weightController;
  late List<TextEditingController> _macroControllers;
  int _originalWeight = 100;
  bool _isAdjusting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.logItem.name);
    _caloriesController = TextEditingController(text: widget.logItem.calories.toInt().toString());

    // Initialize weight controller
    _originalWeight = widget.logItem.weight ?? 100;
    _weightController = TextEditingController(
        text: (min(widget.logItem.weight ?? _originalWeight, 500)).toString()
    );

    // Initialize macro controllers
    _macroControllers = widget.logItem.macros?.map((macro) =>
        TextEditingController(text: macro.value.toInt().toString())
    ).toList() ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _weightController.dispose();
    for (var controller in _macroControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5DC), // Keeping the beige background
      appBar: AppBar(
        title: Text(
          'Food Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFFF5F5DC), // Keeping the beige background
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),

            // Name Input
            _buildTextField(
              controller: _nameController,
              label: 'Food Name',
              icon: Icons.restaurant,
            ),

            const SizedBox(height: 16),

            // Weight Input with slider
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.scale, color: Colors.black54),
                          SizedBox(width: 12),
                          Text(
                            'Weight',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_weightController.text}g',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '0g',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Theme.of(context).primaryColor,
                            inactiveTrackColor: Theme.of(context).primaryColor.withOpacity(0.2),
                            thumbColor: Theme.of(context).primaryColor,
                            trackHeight: 4.0,
                          ),
                          child: Slider(
                            min: 0,
                            max: 500.0,
                            value: double.tryParse(_weightController.text)?.toDouble() ?? _originalWeight.toDouble(),
                            onChanged: (value) {
                              _isAdjusting = true;
                              setState(() {
                                _weightController.text = value.toStringAsFixed(1);
                                _updateMacrosBasedOnWeight();
                              });
                              _isAdjusting = false;
                            },
                          ),
                        ),
                      ),
                      Text(
                        '500g',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Calories Input
            _buildTextField(
              controller: _caloriesController,
              label: 'Calories',
              icon: Icons.local_fire_department,
              iconColor: Colors.orange,
              suffix: 'kcal',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),

            const SizedBox(height: 24),

            // Macros Title
            if (widget.logItem.macros != null && widget.logItem.macros!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                child: Text(
                  'Macronutrients',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Macros Inputs
            if (widget.logItem.macros != null)
              ...widget.logItem.macros!.asMap().entries.map((entry) {
                final index = entry.key;
                final macro = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildTextField(
                    controller: _macroControllers[index],
                    label: _getMacroLabel(macro.icon),
                    icon: _getMacroIcon(macro.icon),
                    iconColor: Color(0xFF8B4513),
                    suffix: 'g',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                );
              }).toList(),

            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _saveLogItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Save Changes',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    Color iconColor = Colors.black54,
    String? suffix,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade700),
          prefixIcon: Icon(icon, color: iconColor),
          suffixText: suffix,
          suffixStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _updateMacrosBasedOnWeight() {
    double currentWeight = double.tryParse(_weightController.text) ?? _originalWeight.toDouble();
    double scaleFactor = currentWeight / _originalWeight;

    // Update calories
    double newCalories = (widget.logItem.calories * scaleFactor);
    _caloriesController.text = newCalories.toInt().toString();

    // Update macros
    for (int i = 0; i < _macroControllers.length; i++) {
      double originalMacroValue = widget.logItem.macros![i].value;
      double newMacroValue = (originalMacroValue * scaleFactor);
      _macroControllers[i].text = newMacroValue.toInt().toString();
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Item?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this food item?', style: GoogleFonts.poppins()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteLogItem();
            },
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _saveLogItem() {
    // Create an updated LogItem
    final updatedLogItem = LogItem(
      name: _nameController.text,
      calories: double.parse(_caloriesController.text),
      timestamp: widget.logItem.timestamp,
      type: widget.logItem.type,
      macros: widget.logItem.macros?.asMap().entries.map((entry) {
        final index = entry.key;
        final macro = entry.value;
        return MacroDetail(
          icon: macro.icon,
          value: double.parse(_macroControllers[index].text),
        );
      }).toList(),
      weight: double.tryParse(_weightController.text)?.round(),
    );

    if (updatedLogItem != widget.logItem) {
      ref.read(firebaseLogsServiceProvider).updateLogItem(widget.logItem);
      ref.read(logsProvider.notifier).state = [
        ...ref.read(logsProvider.notifier).state.where((log) => log != widget.logItem),
        updatedLogItem
      ];
    }

    Navigator.of(context).pop();
  }

  void _deleteLogItem() {
    // Remove the log item from Firebase and local state
    ref.read(firebaseLogsServiceProvider).deleteLogItem(widget.logItem);
    ref.read(logsProvider.notifier).state =
        ref.read(logsProvider.notifier).state.where((log) => log != widget.logItem).toList();

    // Close the screen
    Navigator.of(context).pop();
  }

  String _getMacroLabel(String icon) {
    switch (icon) {
      case '🍗':
        return 'Protein';
      case '🍞':
        return 'Carbohydrates';
      case '🧀':
        return 'Fat';
      default:
        return 'Macro';
    }
  }

  IconData _getMacroIcon(String icon) {
    switch (icon) {
      case '🍗':
        return Icons.egg;
      case '🍞':
        return Icons.grain;
      case '🧀':
        return Icons.opacity;
      default:
        return Icons.food_bank;
    }
  }
}