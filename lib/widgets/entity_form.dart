import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_dialogs.dart';

enum FieldKind { text, dropdown, chips, date, toggle, header }

class ChipOption {
  final int id;
  final String label;

  const ChipOption(this.id, this.label);
}

class FieldSpec {
  FieldSpec._({
    required this.kind,
    required this.label,
    this.controller,
    this.validator,
    this.listValidator,
    this.keyboardType,
    this.maxLines = 1,
    this.onTextChanged,
    this.dropdownValue,
    this.dropdownItems = const [],
    this.onDropdown,
    this.dropdownValidator,
    this.chipValue = const [],
    this.chipOptions = const [],
    this.onChips,
    this.dateValue,
    this.onDate,
    this.toggleValue = false,
    this.onToggle,
  });

  factory FieldSpec.text({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return FieldSpec._(
      kind: FieldKind.text,
      label: label,
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onTextChanged: onChanged,
    );
  }

  factory FieldSpec.dropdown({
    required String label,
    required int? value,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
    String? Function(int?)? validator,
  }) {
    return FieldSpec._(
      kind: FieldKind.dropdown,
      label: label,
      dropdownValue: value,
      dropdownItems: items,
      onDropdown: onChanged,
      dropdownValidator: validator,
    );
  }

  factory FieldSpec.chips({
    required String label,
    required List<int> value,
    required List<ChipOption> options,
    required ValueChanged<List<int>> onChanged,
    String? Function(List<int>?)? validator,
  }) {
    return FieldSpec._(
      kind: FieldKind.chips,
      label: label,
      chipValue: value,
      chipOptions: options,
      onChips: onChanged,
      listValidator: validator,
    );
  }

  factory FieldSpec.date({
    required String label,
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
  }) {
    return FieldSpec._(
      kind: FieldKind.date,
      label: label,
      dateValue: value,
      onDate: onChanged,
    );
  }

  factory FieldSpec.toggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return FieldSpec._(
      kind: FieldKind.toggle,
      label: label,
      toggleValue: value,
      onToggle: onChanged,
    );
  }

  factory FieldSpec.header(String label) {
    return FieldSpec._(kind: FieldKind.header, label: label);
  }

  final FieldKind kind;
  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? Function(List<int>?)? listValidator;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onTextChanged;
  final int? dropdownValue;
  final List<DropdownMenuItem<int>> dropdownItems;
  final ValueChanged<int?>? onDropdown;
  final String? Function(int?)? dropdownValidator;
  final List<int> chipValue;
  final List<ChipOption> chipOptions;
  final ValueChanged<List<int>>? onChips;
  final DateTime? dateValue;
  final ValueChanged<DateTime>? onDate;
  final bool toggleValue;
  final ValueChanged<bool>? onToggle;

  Widget build(BuildContext context) {
    switch (kind) {
      case FieldKind.header:
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        );
      case FieldKind.text:
        return TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onTextChanged,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        );
      case FieldKind.dropdown:
        final value = dropdownItems.any((item) => item.value == dropdownValue) ? dropdownValue : null;
        return DropdownButtonFormField<int>(
          value: value,
          items: dropdownItems,
          onChanged: onDropdown,
          validator: dropdownValidator,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        );
      case FieldKind.chips:
        return FormField<List<int>>(
          key: ValueKey('$label-${chipOptions.map((option) => option.id).join(',')}'),
          initialValue: chipValue,
          validator: listValidator,
          builder: (field) {
            return InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                errorText: field.errorText,
              ),
              child: chipOptions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Нет доступных значений'),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in chipOptions)
                          FilterChip(
                            label: Text(option.label),
                            selected: field.value!.contains(option.id),
                            onSelected: (_) {
                              final next = [...field.value!];
                              next.contains(option.id) ? next.remove(option.id) : next.add(option.id);
                              field.didChange(next);
                              onChips?.call(next);
                            },
                          ),
                      ],
                    ),
            );
          },
        );
      case FieldKind.date:
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          subtitle: Text(formatDate(dateValue ?? DateTime.now())),
          trailing: const Icon(Icons.calendar_today_outlined),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: dateValue ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) onDate?.call(picked);
          },
        );
      case FieldKind.toggle:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          value: toggleValue,
          onChanged: onToggle,
        );
    }
  }
}

class EntityFormScaffold extends StatelessWidget {
  final String title;
  final String fallbackPath;
  final GlobalKey<FormState> formKey;
  final bool isDirty;
  final bool saving;
  final VoidCallback onSave;
  final List<FieldSpec> fields;
  final List<Widget> extra;

  const EntityFormScaffold({
    super.key,
    required this.title,
    required this.fallbackPath,
    required this.formKey,
    required this.isDirty,
    required this.onSave,
    required this.fields,
    this.saving = false,
    this.extra = const [],
  });

  Future<void> _leave(BuildContext context) async {
    if (isDirty) {
      final discard = await confirmDiscard(context);
      if (!discard) return;
    }
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(fallbackPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await confirmDiscard(context);
        if (discard && context.mounted) context.pop();
      },
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              IconButton(onPressed: () => _leave(context), icon: const Icon(Icons.arrow_back)),
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final field in fields) ...[
                  field.build(context),
                  const SizedBox(height: 16),
                ],
                ...extra,
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: saving ? null : onSave,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(saving ? 'Сохранение…' : 'Сохранить'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
