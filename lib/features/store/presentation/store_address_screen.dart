import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/core/widgets/searchable_admin_picker.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/geo_models.dart';
import 'package:speedygo_merchant_app/features/access/data/map_config.dart';
import 'package:speedygo_merchant_app/features/access/presentation/location_picker_screen.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';

class StoreAddressScreen extends ConsumerStatefulWidget {
  const StoreAddressScreen({super.key});

  @override
  ConsumerState<StoreAddressScreen> createState() => _StoreAddressScreenState();
}

class _StoreAddressScreenState extends ConsumerState<StoreAddressScreen> {
  late final TextEditingController _address;
  late final TextEditingController _phone;
  double? _lat;
  double? _lng;
  var _locationConfirmed = false;
  var _saving = false;
  String? _error;

  List<AlgeriaWilaya> _wilayas = const [];
  List<AlgeriaCommune> _communes = const [];
  AlgeriaWilaya? _selectedWilaya;
  AlgeriaCommune? _selectedCommune;
  var _wilayasLoading = false;
  var _communesLoading = false;
  String? _wilayasError;
  String? _communesError;
  int _communesRequestId = 0;

  @override
  void initState() {
    super.initState();
    final branch = ref.read(accessControllerProvider).selectedBranch;
    _address = TextEditingController(text: branch?.addressText ?? '');
    _phone = TextEditingController(text: branch?.phone ?? '');
    final lat = branch?.latitude;
    final lng = branch?.longitude;
    if (lat != null &&
        lng != null &&
        lat.isFinite &&
        lng.isFinite &&
        !(lat == 0 && lng == 0)) {
      _lat = lat;
      _lng = lng;
      _locationConfirmed = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapAdminLocation(branch?.wilayaCode, branch?.communeId);
    });
  }

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _canManage {
    final role = ref.read(accessControllerProvider).membership?.role ?? '';
    final upper = role.toUpperCase();
    return upper == 'OWNER' || upper == 'MANAGER';
  }

  Future<void> _bootstrapAdminLocation(
    String? wilayaCode,
    int? communeId,
  ) async {
    await _loadWilayas();
    if (!mounted) return;
    if (wilayaCode == null || wilayaCode.isEmpty) return;
    AlgeriaWilaya? match;
    for (final w in _wilayas) {
      if (w.code == wilayaCode) {
        match = w;
        break;
      }
    }
    if (match == null) return;
    setState(() => _selectedWilaya = match);
    await _loadCommunes(wilayaCode);
    if (!mounted || communeId == null) return;
    AlgeriaCommune? commune;
    for (final c in _communes) {
      if (c.id == communeId) {
        commune = c;
        break;
      }
    }
    if (commune != null) {
      setState(() => _selectedCommune = commune);
    }
  }

  Future<void> _loadWilayas() async {
    setState(() {
      _wilayasLoading = true;
      _wilayasError = null;
    });
    try {
      final list = await ref.read(merchantApiProvider).listWilayas();
      if (!mounted) return;
      setState(() {
        _wilayas = list;
        _wilayasLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _wilayasLoading = false;
        _wilayasError = AppStrings.adminLocationLoadError;
      });
    }
  }

  Future<void> _loadCommunes(String wilayaCode) async {
    final requestId = ++_communesRequestId;
    setState(() {
      _communesLoading = true;
      _communesError = null;
      _communes = const [];
    });
    try {
      final list = await ref
          .read(merchantApiProvider)
          .listCommunes(wilayaCode: wilayaCode);
      if (!mounted || requestId != _communesRequestId) return;
      setState(() {
        _communes = list;
        _communesLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _communesRequestId) return;
      setState(() {
        _communesLoading = false;
        _communesError = AppStrings.adminLocationLoadError;
      });
    }
  }

  Future<void> _pickWilaya() async {
    if (!_canManage || _saving || _wilayasLoading) return;
    if (_wilayas.isEmpty) {
      await _loadWilayas();
      if (!mounted || _wilayas.isEmpty) return;
    }
    final picked = await showSearchableAdminPicker<AlgeriaWilaya>(
      context: context,
      title: AppStrings.storeAddressWilaya,
      options: _wilayas,
      labelOf: (w) => w.displayLabel,
      searchTextOf: (w) => '${w.code} ${w.nameFr} ${w.nameAr}',
      selected: _selectedWilaya,
    );
    if (!mounted || picked == null) return;
    final wilayaChanged = _selectedWilaya?.code != picked.code;
    setState(() {
      _selectedWilaya = picked;
      if (wilayaChanged) {
        _selectedCommune = null;
        _communes = const [];
      }
      _error = null;
    });
    if (wilayaChanged) {
      await _loadCommunes(picked.code);
    }
  }

  Future<void> _pickCommune() async {
    if (!_canManage || _saving) return;
    final wilaya = _selectedWilaya;
    if (wilaya == null) {
      setState(() => _error = AppStrings.adminLocationWilayaRequired);
      return;
    }
    if (_communesLoading) return;
    if (_communes.isEmpty) {
      await _loadCommunes(wilaya.code);
      if (!mounted || _communes.isEmpty) return;
    }
    final picked = await showSearchableAdminPicker<AlgeriaCommune>(
      context: context,
      title: AppStrings.storeAddressCommune,
      options: _communes,
      labelOf: (c) => c.displayLabel,
      searchTextOf: (c) => '${c.nameFr} ${c.nameAr} ${c.aliasesFr.join(' ')}',
      selected: _selectedCommune,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedCommune = picked;
      _error = null;
    });
  }

  Future<void> _openMap() async {
    final result = await Navigator.of(context).push<LocationPickResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLatitude: _locationConfirmed ? _lat : null,
          initialLongitude: _locationConfirmed ? _lng : null,
          addressHint: _address.text.trim().isEmpty
              ? null
              : _address.text.trim(),
          branchLabel: ref.read(accessControllerProvider).selectedBranch?.name,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _lat = result.latitude;
      _lng = result.longitude;
      _locationConfirmed = true;
      _error = null;
    });
  }

  @visibleForTesting
  void debugSetMapConfirmation({
    required bool confirmed,
    double? latitude,
    double? longitude,
  }) {
    setState(() {
      _locationConfirmed = confirmed;
      if (latitude != null) _lat = latitude;
      if (longitude != null) _lng = longitude;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (!_canManage || _saving) return;
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    if (membership == null || branch == null) return;
    final address = _address.text.trim();
    final phone = _phone.text.trim();
    final wilaya = _selectedWilaya;
    final commune = _selectedCommune;
    if (address.isEmpty ||
        phone.isEmpty ||
        !_locationConfirmed ||
        _lat == null ||
        _lng == null) {
      setState(() => _error = AppStrings.storeAddressSaveError);
      return;
    }
    // Pair only when one is chosen: legacy branches without a pair may still
    // update phone/address; omitted fields keep server values.
    if ((wilaya == null) != (commune == null)) {
      setState(() => _error = AppStrings.adminLocationPairRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ref
          .read(merchantApiProvider)
          .updateBranch(
            merchantId: membership.merchantId,
            branchId: branch.id,
            phone: phone,
            addressText: address,
            latitude: _lat,
            longitude: _lng,
            wilayaCode: wilaya?.code,
            communeId: commune?.id,
          );
      await ref.read(accessControllerProvider.notifier).selectBranch(updated);
      if (!mounted) return;
      // Pop before refresh so the editor dismisses even if refresh remounts shell.
      context.pop(true);
      try {
        await ref.read(accessControllerProvider.notifier).refreshInPlace();
      } catch (_) {}
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = AppStrings.storeAddressSaveError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = _canManage;
    final theme = Theme.of(context);
    final communeEnabled =
        canManage && !_saving && _selectedWilaya != null && !_communesLoading;
    return MerchantScaffold(
      title: AppStrings.storeAddressTitle,
      titleStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
      bodyPadding: EdgeInsets.zero,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: const Key('store-address-screen'),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            AppStrings.storeAddressBanner,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _AddressSection(
                    title: AppStrings.storeAddressCoordsSection,
                    icon: Icons.call_outlined,
                    children: [
                      TextField(
                        key: const Key('store-address-phone'),
                        controller: _phone,
                        enabled: canManage && !_saving,
                        keyboardType: TextInputType.phone,
                        decoration: _outlinedDecoration(
                          AppStrings.storeAddressPhone,
                        ),
                      ),
                      const MerchantContractGapRow(
                        label: AppStrings.storeAddressPublicContact,
                      ),
                      Text(
                        AppStrings.storeAddressPhoneHint,
                        key: const Key('store-address-phone-hint'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _AddressSection(
                    title: AppStrings.storeAddressSection,
                    icon: Icons.location_on_outlined,
                    children: [
                      if (_wilayasError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _wilayasError!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _wilayasLoading
                                    ? null
                                    : _loadWilayas,
                                child: const Text(
                                  AppStrings.adminLocationRetry,
                                ),
                              ),
                            ],
                          ),
                        ),
                      _OutlinedSelect(
                        key: const Key('store-address-wilaya'),
                        label: AppStrings.storeAddressWilaya,
                        valueText: _selectedWilaya?.displayLabel,
                        enabled: canManage && !_saving && !_wilayasLoading,
                        onTap: _pickWilaya,
                        hint: _wilayasLoading
                            ? AppStrings.loading
                            : AppStrings.adminLocationChoose,
                      ),
                      if (_communesError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _communesError!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    _selectedWilaya == null || _communesLoading
                                    ? null
                                    : () =>
                                          _loadCommunes(_selectedWilaya!.code),
                                child: const Text(
                                  AppStrings.adminLocationRetry,
                                ),
                              ),
                            ],
                          ),
                        ),
                      _OutlinedSelect(
                        key: const Key('store-address-commune'),
                        label: AppStrings.storeAddressCommune,
                        valueText: _selectedCommune?.displayLabel,
                        enabled: communeEnabled,
                        onTap: _pickCommune,
                        hint: _selectedWilaya == null
                            ? AppStrings.adminLocationWilayaRequired
                            : (_communesLoading
                                  ? AppStrings.loading
                                  : AppStrings.adminLocationChoose),
                      ),
                      TextField(
                        key: const Key('store-address-text'),
                        controller: _address,
                        enabled: canManage && !_saving,
                        minLines: 3,
                        maxLines: 4,
                        decoration: _outlinedDecoration(
                          AppStrings.storeAddressDetailed,
                        ),
                      ),
                      const MerchantContractGapRow(
                        label: AppStrings.storeAddressPickupHints,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _AddressSection(
                    children: [
                      SizedBox(
                        height: 160,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              _locationConfirmed && _lat != null && _lng != null
                              ? AbsorbPointer(
                                  child: FlutterMap(
                                    key: ValueKey(
                                      'store-address-map-${_lat!.toStringAsFixed(5)}-${_lng!.toStringAsFixed(5)}',
                                    ),
                                    options: MapOptions(
                                      initialCenter: LatLng(_lat!, _lng!),
                                      initialZoom: 15,
                                      interactionOptions:
                                          const InteractionOptions(
                                            flags: InteractiveFlag.none,
                                          ),
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            MerchantMapConfig.tileUrlTemplate,
                                        userAgentPackageName: MerchantMapConfig
                                            .userAgentPackageName,
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: LatLng(_lat!, _lng!),
                                            width: 40,
                                            height: 40,
                                            child: const Icon(
                                              Icons.location_on,
                                              color: AppColors.primary,
                                              size: 36,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              : ColoredBox(
                                  color: AppColors.surfaceContainerHigh,
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        AppStrings.regLocationRequired,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: AppColors.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      if (_locationConfirmed)
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: AppColors.tertiaryContainer,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                AppStrings.storeAddressLocationSummary,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      OutlinedButton.icon(
                        key: const Key('store-address-open-map'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onPressed: canManage && !_saving ? _openMap : null,
                        icon: const Icon(Icons.map_outlined, size: 20),
                        label: const Text(AppStrings.storeAddressConfirmMap),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      key: const Key('store-address-error'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (canManage)
            MerchantStickyBar(
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  key: const Key('store-address-save'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: !_saving ? _save : null,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          AppStrings.storeAddressSave,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

InputDecoration _outlinedDecoration(String label, {Widget? suffixIcon}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurfaceVariant,
    ),
    floatingLabelStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurfaceVariant,
    ),
    filled: false,
    contentPadding: const EdgeInsets.all(16),
    suffixIcon: suffixIcon,
    border: border(AppColors.outline),
    enabledBorder: border(AppColors.outline),
    disabledBorder: border(AppColors.outlineVariant),
    focusedBorder: border(AppColors.primary, 2),
  );
}

class _AddressSection extends StatelessWidget {
  const _AddressSection({this.title, this.icon, required this.children});

  final String? title;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Icon(icon, color: AppColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Outlined select matching the reference form fields; opens a picker.
class _OutlinedSelect extends StatelessWidget {
  const _OutlinedSelect({
    super.key,
    required this.label,
    required this.valueText,
    required this.enabled,
    required this.onTap,
    this.hint,
  });

  final String label;
  final String? valueText;
  final bool enabled;
  final VoidCallback? onTap;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final placeholder = valueText == null || valueText!.trim().isEmpty;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        isEmpty: false,
        decoration: _outlinedDecoration(
          label,
          suffixIcon: Icon(
            Icons.expand_more,
            color: enabled ? AppColors.outline : AppColors.outlineVariant,
          ),
        ).copyWith(enabled: enabled),
        child: Text(
          placeholder ? (hint ?? AppStrings.adminLocationChoose) : valueText!,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: placeholder || !enabled
                ? AppColors.onSurfaceVariant
                : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}
