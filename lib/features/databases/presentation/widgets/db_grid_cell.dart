import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/index.dart';
import '../../domain/database_providers.dart';

class DbGridCell extends ConsumerStatefulWidget {
  final String rowId;
  final String colId;
  final String colType;
  final dynamic value;

  const DbGridCell({
    super.key,
    required this.rowId,
    required this.colId,
    required this.colType,
    required this.value,
  });

  @override
  ConsumerState<DbGridCell> createState() => _DbGridCellState();
}

class _DbGridCellState extends ConsumerState<DbGridCell> {
  late TextEditingController _ctrl;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant DbGridCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_isEditing) {
      _ctrl.text = widget.value?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save(String newVal) {
    if (widget.value?.toString() == newVal) return;
    
    dynamic parsedVal = newVal;
    if (widget.colType == 'number') {
      parsedVal = double.tryParse(newVal);
      if (parsedVal == null && newVal.isNotEmpty) {
        // invalid number, revert or ignore
        _ctrl.text = widget.value?.toString() ?? '';
        return;
      }
    }
    
    updateDbCell(ref, widget.rowId, widget.colId, parsedVal);
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.colType) {
      case 'text':
      case 'number':
        return _buildTextField();
      case 'checkbox':
        return _buildCheckbox();
      case 'select':
      case 'date':
      default:
        // Fallback para input de texto pros demais tipos nao desenhados ainda
        return _buildTextField();
    }
  }

  Widget _buildTextField() {
    return Focus(
      onFocusChange: (focused) {
        setState(() => _isEditing = focused);
        if (!focused) {
          _save(_ctrl.text);
        }
      },
      child: TextField(
        controller: _ctrl,
        keyboardType: widget.colType == 'number' ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        style: context.bodyMd,
      ),
    );
  }

  Widget _buildCheckbox() {
    final bool isChecked = (widget.value == true || widget.value == 'true');
    return InkWell(
      onTap: () {
        updateDbCell(ref, widget.rowId, widget.colId, !isChecked);
      },
      child: Center(
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: isChecked ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: isChecked ? AppColors.primary : (context.isDark ? AppColors.borderDark : AppColors.border),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: isChecked
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
