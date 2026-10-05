import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/constants/merchant_assets.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';

class _OnboardingPage {
  const _OnboardingPage({
    required this.asset,
    required this.title,
    required this.body,
  });

  final String asset;
  final String title;
  final String body;
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  var _index = 0;
  var _completing = false;

  static final _pages = [
    _OnboardingPage(
      asset: MerchantAssets.onboardingReceive,
      title: AppStrings.onboardingPage1Title,
      body: AppStrings.onboardingPage1Body,
    ),
    _OnboardingPage(
      asset: MerchantAssets.onboardingPrepare,
      title: AppStrings.onboardingPage2Title,
      body: AppStrings.onboardingPage2Body,
    ),
    _OnboardingPage(
      asset: MerchantAssets.onboardingBusiness,
      title: AppStrings.onboardingPage3Title,
      body: AppStrings.onboardingPage3Body,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (_completing) return;
    final session = ref.read(sessionControllerProvider);
    if (session.busy || session.onboardingSeen) return;
    setState(() => _completing = true);
    await ref.read(sessionControllerProvider.notifier).completeOnboarding();
    if (!mounted) return;
    final after = ref.read(sessionControllerProvider);
    if (!after.onboardingSeen) {
      setState(() => _completing = false);
    }
  }

  void _next() {
    if (_index >= _pages.length - 1) {
      _complete();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final last = _index == _pages.length - 1;
    final busy = session.busy || _completing;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      key: const Key('merchant-onboarding'),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      AppStrings.appName,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    key: const Key('merchant-onboarding-skip'),
                    onPressed: busy ? null : _complete,
                    child: Text(AppStrings.onboardingSkip),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                key: const Key('merchant-onboarding-pager'),
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Semantics(
                    label: '${AppStrings.onboardingPageSemantics} ${index + 1}',
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          key: Key('merchant-onboarding-scroll-$index'),
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  height: (constraints.maxHeight * 0.52).clamp(
                                    200.0,
                                    420.0,
                                  ),
                                  child: Image.asset(
                                    page.asset,
                                    key: Key('merchant-onboarding-art-$index'),
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.medium,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  page.title,
                                  key: Key('merchant-onboarding-title-$index'),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: AppColors.onSurface,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  page.body,
                                  key: Key('merchant-onboarding-body-$index'),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                8,
                24,
                bottomInset > 0 ? 12 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    label: AppStrings.onboardingPageSemantics,
                    child: Row(
                      key: const Key('merchant-onboarding-dots'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final active = i == _index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: active ? 22 : 8,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : AppColors.outlineVariant,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),
                  MerchantPrimaryButton(
                    key: const Key('merchant-onboarding-primary'),
                    label: last
                        ? AppStrings.onboardingStart
                        : AppStrings.onboardingNext,
                    loading: busy && last,
                    onPressed: busy
                        ? null
                        : () {
                            if (last) {
                              _complete();
                            } else {
                              _next();
                            }
                          },
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const Key('merchant-onboarding-existing'),
                    onPressed: busy ? null : _complete,
                    child: Text(AppStrings.onboardingHaveAccount),
                  ),
                  if (session.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      session.errorMessage!,
                      key: const Key('merchant-onboarding-error'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
