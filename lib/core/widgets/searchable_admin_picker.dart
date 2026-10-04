import 'package:flutter/material.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';

typedef AdminOptionLabel<T> = String Function(T option);
typedef AdminOptionSearchText<T> = String Function(T option);

/// Searchable single-select bottom sheet used for Wilaya / Commune.
Future<T?> showSearchableAdminPicker<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required AdminOptionLabel<T> labelOf,
  AdminOptionSearchText<T>? searchTextOf,
  T? selected,
  bool enabled = true,
}) {
  if (!enabled) return Future<T?>.value(null);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return _SearchableAdminPickerSheet<T>(
        title: title,
        options: options,
        labelOf: labelOf,
        searchTextOf: searchTextOf ?? labelOf,
        selected: selected,
      );
    },
  );
}

class _SearchableAdminPickerSheet<T> extends StatefulWidget {
  const _SearchableAdminPickerSheet({
    required this.title,
    required this.options,
    required this.labelOf,
    required this.searchTextOf,
    this.selected,
  });

  final String title;
  final List<T> options;
  final AdminOptionLabel<T> labelOf;
  final AdminOptionSearchText<T> searchTextOf;
  final T? selected;

  @override
  State<_SearchableAdminPickerSheet<T>> createState() =>
      _SearchableAdminPickerSheetState<T>();
}

class _SearchableAdminPickerSheetState<T>
    extends State<_SearchableAdminPickerSheet<T>> {
  late final TextEditingController _query;
  late List<T> _filtered;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController();
    _filtered = List<T>.from(widget.options);
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _onQuery(String raw) {
    final needle = raw.trim().toLowerCase();
    setState(() {
      if (needle.isEmpty) {
        _filtered = List<T>.from(widget.options);
        return;
      }
      _filtered = widget.options
          .where(
            (option) =>
                widget.searchTextOf(option).toLowerCase().contains(needle),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.75;
    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _query,
              onChanged: _onQuery,
              autofocus: true,
              decoration: InputDecoration(
                hintText: AppStrings.adminLocationSearchHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      AppStrings.adminLocationEmpty,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final option = _filtered[index];
                      final selected =
                          widget.selected != null &&
                          identical(widget.selected, option);
                      return ListTile(
                        title: Text(widget.labelOf(option)),
                        selected: selected,
                        trailing: selected
                            ? const Icon(Icons.check, color: AppColors.primary)
                            : null,
                        onTap: () => Navigator.of(context).pop(option),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Tappable field showing current Wilaya/Commune selection.
class AdminLocationSelectField extends StatelessWidget {
  const AdminLocationSelectField({
    super.key,
    required this.label,
    required this.valueText,
    required this.enabled,
    required this.onTap,
    this.requiredMark = true,
    this.hint,
  });

  final String label;
  final String? valueText;
  final bool enabled;
  final VoidCallback? onTap;
  final bool requiredMark;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = (valueText == null || valueText!.trim().isEmpty)
        ? (hint ?? AppStrings.adminLocationChoose)
        : valueText!;
    final isPlaceholder = valueText == null || valueText!.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (requiredMark)
              Text(
                ' *',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Material(
          color: enabled ? AppColors.surface : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      display,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isPlaceholder || !enabled
                            ? AppColors.onSurfaceVariant
                            : AppColors.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.expand_more,
                    color: enabled
                        ? AppColors.onSurfaceVariant
                        : AppColors.outlineVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
