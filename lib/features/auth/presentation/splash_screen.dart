import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/constants/merchant_assets.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/auth/presentation/splash_backdrop.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  var _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _started) return;
      _started = true;
      _bootstrap();
    });
  }

  /// Keep [SessionPhase.boot] (and this route) until brand hold + restore.
  /// Restore must not run in parallel with the hold — that left boot early and
  /// redirected away before the splash could paint meaningfully.
  Future<void> _bootstrap() async {
    final min = ref.read(splashMinDurationProvider);
    if (min > Duration.zero) {
      await Future<void>.delayed(min);
    }
    if (!mounted) return;
    await ref.read(sessionControllerProvider.notifier).restore();
  }

  @override
  Widget build(BuildContext context) {
    final animate = ref.watch(splashAnimateProvider);
    final size = MediaQuery.sizeOf(context);
    final logoWidth = (size.width * 0.62).clamp(180.0, 280.0);

    return Scaffold(
      key: const Key('merchant-splash'),
      backgroundColor: AppColors.primary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(
            painter: MerchantSplashBackdropPainter(),
            child: SizedBox.expand(),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: logoWidth,
                    child: AspectRatio(
                      aspectRatio: 1774 / 887,
                      child: Image.asset(
                        MerchantAssets.logo,
                        key: const Key('merchant-splash-logo'),
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    AppStrings.splashTagline,
                    key: const Key('merchant-splash-tagline'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                if (animate)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 36),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        key: Key('merchant-splash-loader'),
                        strokeWidth: 2.4,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 64),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    return Scaffold(
      key: const Key('merchant-language'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                AppStrings.languageBilingualTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('merchant-language-fr'),
                onPressed: session.busy
                    ? null
                    : () => ref
                          .read(sessionControllerProvider.notifier)
                          .setLocale('fr'),
                child: session.busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppStrings.languageOptionFrench),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                key: const Key('merchant-language-ar'),
                onPressed: session.busy
                    ? null
                    : () => ref
                          .read(sessionControllerProvider.notifier)
                          .setLocale('ar'),
                child: Text(AppStrings.languageOptionArabic),
              ),
              if (session.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  session.errorMessage!,
                  key: const Key('merchant-language-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class RestoreScreen extends ConsumerWidget {
  const RestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final retryable = session.phase == SessionPhase.restoreRetryable;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                retryable ? AppStrings.restoreOffline : AppStrings.restoreTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                session.errorMessage ??
                    (retryable
                        ? AppStrings.restoreOffline
                        : AppStrings.restoreLoading),
              ),
              const Spacer(),
              if (retryable)
                FilledButton(
                  onPressed: () => ref
                      .read(sessionControllerProvider.notifier)
                      .retryRestore(),
                  child: Text(AppStrings.restoreRetry),
                ),
              TextButton(
                onPressed: () => ref
                    .read(sessionControllerProvider.notifier)
                    .invalidateLocalSession(),
                child: Text(AppStrings.restoreOtherAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
