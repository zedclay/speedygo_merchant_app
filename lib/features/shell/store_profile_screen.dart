import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_ui.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/store/application/store_controllers.dart';
import 'package:speedygo_merchant_app/features/store/presentation/merchant_branch_cover_thumb.dart';

/// Profil tab landing — aligned with `store_profile_french`.
class StoreProfileScreen extends ConsumerWidget {
  const StoreProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    final merchantName = membership?.merchantName ?? '';
    final branchName = branch?.name ?? merchantName;
    final roleLabel = _roleLabel(membership?.role ?? '');
    final unread = ref.watch(notificationsUnreadCountProvider).value ?? 0;
    final verified =
        membership?.merchantStatus.toUpperCase() == 'ACTIVE' &&
        membership?.approved == true;
    final displayName = merchantName.isNotEmpty ? merchantName : branchName;

    return Scaffold(
      key: const Key('store-profile-screen'),
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHeader(
              displayName: displayName,
              subtitle: branchName != displayName ? branchName : null,
              verified: verified,
              operationalStatus: branch?.operationalStatus ?? '',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                MerchantCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      MerchantNavRow(
                        key: const Key('store-profile-general'),
                        icon: Icons.storefront_outlined,
                        title: AppStrings.storeProfileGeneral,
                        subtitle: AppStrings.storeProfileGeneralSub,
                        onTap: () => context.push(AppRoutes.storeGeneral),
                      ),
                      const Divider(height: 1),
                      MerchantNavRow(
                        key: const Key('store-profile-category'),
                        icon: Icons.category_outlined,
                        title: AppStrings.storeProfileCategory,
                        subtitle:
                            ref
                                .watch(branchClassificationProvider)
                                .value
                                ?.name ??
                            branch?.classification?.name ??
                            AppStrings.storeProfileCategorySub,
                        onTap: () => context.push(AppRoutes.storeCategory),
                      ),
                      const Divider(height: 1),
                      MerchantNavRow(
                        icon: Icons.image_outlined,
                        title: AppStrings.storeProfileMedia,
                        subtitle: AppStrings.storeProfileMediaSub,
                        onTap: () => context.push(AppRoutes.storeCover),
                      ),
                      const Divider(height: 1),
                      MerchantNavRow(
                        icon: Icons.location_on_outlined,
                        title: AppStrings.storeProfileAddress,
                        subtitle: AppStrings.storeProfileAddressSub,
                        onTap: () => context.push(AppRoutes.storeAddress),
                      ),
                      const Divider(height: 1),
                      MerchantNavRow(
                        key: const Key('store-profile-availability'),
                        icon: Icons.toggle_on_outlined,
                        title: AppStrings.storeProfileAvailability,
                        subtitle: AppStrings.storeProfileAvailabilitySub,
                        onTap: () => context.push(AppRoutes.storeAvailability),
                      ),
                      const Divider(height: 1),
                      MerchantNavRow(
                        key: const Key('store-profile-hours'),
                        icon: Icons.schedule,
                        title: AppStrings.storeProfileHours,
                        subtitle: AppStrings.storeProfileHoursSub,
                        onTap: () => context.push(AppRoutes.openingHours),
                      ),
                      const Divider(height: 1),
                      MerchantNavRow(
                        icon: Icons.timer_outlined,
                        title: AppStrings.storeProfilePrep,
                        subtitle: AppStrings.storeProfilePrepUnavailable,
                        enabled: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                MerchantCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      MerchantNavRow(
                        key: const Key('store-profile-notifications'),
                        icon: Icons.notifications_outlined,
                        title: AppStrings.storeProfileNotifications,
                        subtitle: AppStrings.storeProfileNotificationsSub,
                        trailing: unread > 0
                            ? StatusBadge(
                                label: '$unread',
                                tone: StatusTone.error,
                              )
                            : null,
                        onTap: () => context.push(AppRoutes.notifications),
                      ),
                      const Divider(height: 1),
                      MerchantNavRow(
                        key: const Key('store-profile-notification-settings'),
                        icon: Icons.tune_outlined,
                        title: AppStrings.notifSettingsTitle,
                        subtitle: AppStrings.notifSettingsForeground,
                        onTap: () =>
                            context.push(AppRoutes.notificationSettings),
                      ),
                      const Divider(height: 1),
                      MerchantNavRow(
                        key: const Key('store-profile-settings'),
                        icon: Icons.settings_outlined,
                        title: AppStrings.storeProfileSettings,
                        subtitle: AppStrings.storeProfileSettingsSub,
                        onTap: () => context.push(AppRoutes.settings),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                MerchantCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.surfaceContainer,
                        child: Text(
                          _initials(displayName),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              roleLabel.toUpperCase(),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    letterSpacing: 0.6,
                                  ),
                            ),
                            Text(
                              displayName,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.storeProfilePreviewUnavailable,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final s = parts[0];
    return s.substring(0, s.length >= 2 ? 2 : 1).toUpperCase();
  }
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

String _roleLabel(String role) {
  switch (role.toUpperCase()) {
    case 'OWNER':
      return AppStrings.profileRoleOwner;
    case 'MANAGER':
      return AppStrings.profileRoleManager;
    case 'STAFF':
      return AppStrings.profileRoleStaff;
    default:
      return role;
  }
}

String _operationalLabel(String status) {
  switch (status.toUpperCase()) {
    case 'ACTIVE':
      return AppStrings.operationalActive;
    case 'INACTIVE':
      return AppStrings.operationalInactive;
    case 'SUSPENDED':
      return AppStrings.operationalSuspended;
    default:
      return status;
  }
}

const _heroHeight = 192.0;

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.subtitle,
    required this.verified,
    required this.operationalStatus,
  });

  final String displayName;
  final String? subtitle;
  final bool verified;
  final String operationalStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final stacked = MediaQuery.textScalerOf(context).scale(1) >= 1.25;
    final chip = operationalStatus.isEmpty
        ? null
        : _OperationalChip(status: operationalStatus);
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: displayName,
            children: [
              if (verified)
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.check_circle,
                      key: Key('store-profile-verified'),
                      color: Color(0xFF1D4ED8),
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        if (stacked && chip != null) ...[const SizedBox(height: 8), chip],
      ],
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        MerchantBranchCoverThumb(
          key: const Key('store-profile-hero'),
          width: double.infinity,
          height: _heroHeight + top,
          borderRadius: 0,
          framed: false,
          placeholder: const SizedBox.shrink(),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: _heroHeight + top,
          child: IgnorePointer(
            child: DecoratedBox(
              key: const Key('store-profile-hero-scrim'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, top + _heroHeight - 48, 16, 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      offset: Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MerchantBranchLogoThumb(
                      key: Key('store-profile-logo'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: identity),
                    if (!stacked && chip != null) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, right: 16),
                        child: chip,
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                top: -20,
                right: -8,
                child: Material(
                  color: AppColors.surfaceContainerLowest,
                  shape: const CircleBorder(),
                  elevation: 3,
                  shadowColor: Colors.black.withValues(alpha: 0.2),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      key: const Key('store-profile-gear'),
                      padding: EdgeInsets.zero,
                      tooltip: AppStrings.profileSettingsTitle,
                      onPressed: () => context.push(AppRoutes.settings),
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OperationalChip extends StatelessWidget {
  const _OperationalChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final active = status.toUpperCase() == 'ACTIVE';
    final fg = active ? const Color(0xFF065F46) : AppColors.warning;
    final accent = active ? const Color(0xFF10B981) : AppColors.warning;
    return Container(
      key: const Key('store-profile-status'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFECFDF5) : AppColors.warningWash,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _operationalLabel(status),
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
