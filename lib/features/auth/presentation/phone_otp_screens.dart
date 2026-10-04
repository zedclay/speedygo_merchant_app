import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_constants.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/core/utils/phone_input.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _cooldownTicker;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() {});
    });
    final pending = ref.read(sessionControllerProvider).pendingPhone;
    if (pending != null && pending.isNotEmpty) {
      _controller.text = PhoneInput.formatLocal(pending);
    }
    _syncCooldownTicker(ref.read(sessionControllerProvider));
  }

  @override
  void dispose() {
    _cooldownTicker?.cancel();
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _syncCooldownTicker(SessionState session) {
    if (session.otpResendSecondsRemaining > 0) {
      _cooldownTicker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final left = ref
            .read(sessionControllerProvider)
            .otpResendSecondsRemaining;
        setState(() {});
        if (left <= 0) {
          _cooldownTicker?.cancel();
          _cooldownTicker = null;
        }
      });
    } else {
      _cooldownTicker?.cancel();
      _cooldownTicker = null;
    }
  }

  Future<void> _submit() async {
    final current = ref.read(sessionControllerProvider);
    if (!current.canRequestOtp || current.busy) return;
    await ref
        .read(sessionControllerProvider.notifier)
        .requestOtp(_controller.text);
    if (!mounted) return;
    final next = ref.read(sessionControllerProvider);
    _syncCooldownTicker(next);
    if (next.pendingPhone != null && next.errorMessage == null) {
      context.go(AppRoutes.otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final valid = PhoneInput.isValid(_controller.text);
    final canSubmit = valid && !session.busy && session.canRequestOtp;
    final cooldown = session.otpResendSecondsRemaining;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final hasError = session.errorMessage != null;
    final focused = _focus.hasFocus;

    ref.listen(sessionControllerProvider, (_, next) {
      _syncCooldownTicker(next);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: session.pendingPhone != null
                          ? IconButton(
                              tooltip: AppStrings.back,
                              padding: EdgeInsets.zero,
                              onPressed: () => context.go(AppRoutes.otp),
                              icon: const Icon(Icons.arrow_back),
                            )
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        AppStrings.appName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                              height: 32 / 24,
                            ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                children: [
                  Text(
                    AppStrings.phoneTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      height: 32 / 24,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.phoneSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 16,
                      height: 24 / 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Semantics(
                    label: AppStrings.phoneTitle,
                    textField: true,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasError
                              ? AppColors.error
                              : focused
                              ? AppColors.primaryContainer
                              : AppColors.outlineVariant,
                          width: focused || hasError ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const _AlgeriaFlag(),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.phonePrefix,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  height: 24 / 16,
                                ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 1,
                            height: 28,
                            color: AppColors.outlineVariant,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              key: const Key('merchant-phone-field'),
                              controller: _controller,
                              focusNode: _focus,
                              autofocus: true,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    height: 24 / 16,
                                    letterSpacing: 0.4,
                                    color: AppColors.onSurface,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: const InputDecoration(
                                hintText: AppStrings.phoneHint,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (value) {
                                ref
                                    .read(sessionControllerProvider.notifier)
                                    .dismissError();
                                final formatted = PhoneInput.formatLocal(value);
                                if (formatted != value) {
                                  _controller.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(
                                      offset: formatted.length,
                                    ),
                                  );
                                }
                                setState(() {});
                              },
                              onSubmitted: (_) {
                                if (canSubmit) _submit();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      AppStrings.phoneSmsNote,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                        height: 16 / 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (cooldown > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      '${AppStrings.otpCooldownHint} ($cooldown s)',
                      key: const Key('merchant-phone-otp-cooldown'),
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                  if (session.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      session.errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 32),
                  IgnorePointer(
                    child: Opacity(
                      opacity: 0.2,
                      child: Container(
                        height: 1,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0x00000000),
                              AppColors.primaryContainer,
                              Color(0x00000000),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: ColoredBox(
                  color: AppColors.background.withValues(alpha: 0.8),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      bottomInset > 0 ? 8 : 16,
                    ),
                    child: Column(
                      children: [
                        MerchantPrimaryButton(
                          key: const Key('merchant-phone-continue'),
                          label: AppStrings.continueLabel,
                          icon: Icons.arrow_forward,
                          loading: session.busy,
                          onPressed: canSubmit ? _submit : null,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(AppStrings.helpUnavailable),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            textStyle: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  height: 20 / 14,
                                ),
                          ),
                          child: const Text(AppStrings.needHelp),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _controller.text.replaceAll(RegExp(r'\D'), '');
    await ref.read(sessionControllerProvider.notifier).verifyOtp(code);
  }

  Future<void> _resend() async {
    final phone = ref.read(sessionControllerProvider).pendingPhone;
    if (phone == null || phone.isEmpty) return;
    await ref.read(sessionControllerProvider.notifier).requestOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final phone = session.pendingPhone ?? '';
    final code = _controller.text.replaceAll(RegExp(r'\D'), '');
    final seconds = session.otpResendSecondsRemaining;
    final clock = '00:${seconds.toString().padLeft(2, '0')}';
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final masked = PhoneInput.maskInternational(phone);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: AppStrings.back,
                      onPressed: () => context.go(AppRoutes.phone),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: AppStrings.needHelp,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(AppStrings.helpUnavailable),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.help_outline,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                children: [
                  Text(
                    AppStrings.otpTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      height: 32 / 24,
                      letterSpacing: -0.2,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        AppStrings.otpSentTo(masked),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 16,
                          height: 24 / 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.phone),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                height: 24 / 16,
                              ),
                        ),
                        child: const Text(AppStrings.editNumber),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _OtpBoxes(
                    code: code,
                    hasError: session.errorMessage != null,
                    onTap: () => _focus.requestFocus(),
                    child: TextField(
                      key: const Key('merchant-otp-field'),
                      controller: _controller,
                      focusNode: _focus,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(
                          AppConstants.otpLength,
                        ),
                      ],
                      style: const TextStyle(
                        color: Colors.transparent,
                        fontSize: 1,
                      ),
                      cursorColor: Colors.transparent,
                      showCursor: false,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) {
                        ref
                            .read(sessionControllerProvider.notifier)
                            .dismissError();
                        setState(() {});
                      },
                      onSubmitted: (_) {
                        if (code.length == AppConstants.otpLength) {
                          _verify();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  seconds > 0
                      ? Builder(
                          builder: (context) {
                            final label = AppStrings.resendIn(clock);
                            final prefixLen = label.length - clock.length;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 18,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text.rich(
                                    TextSpan(
                                      text: label.substring(0, prefixLen),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.onSurfaceVariant,
                                            fontSize: 14,
                                            height: 20 / 14,
                                          ),
                                      children: [
                                        TextSpan(
                                          text: clock,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppColors.onSurface,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                height: 20 / 14,
                                              ),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            );
                          },
                        )
                      : Center(
                          child: TextButton(
                            onPressed: session.busy ? null : _resend,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text(AppStrings.resend),
                          ),
                        ),
                  if (session.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      session.errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                bottomInset > 0 ? 8 : 32,
              ),
              child: MerchantPrimaryButton(
                key: const Key('merchant-otp-verify'),
                label: AppStrings.verify,
                loading: session.busy,
                onPressed: code.length == AppConstants.otpLength
                    ? _verify
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({
    required this.code,
    required this.onTap,
    required this.child,
    this.hasError = false,
  });

  final String code;
  final bool hasError;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: List.generate(AppConstants.otpLength, (index) {
              final filled = index < code.length;
              final focused =
                  index == code.length ||
                  (code.length == AppConstants.otpLength &&
                      index == AppConstants.otpLength - 1);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == AppConstants.otpLength - 1 ? 0 : 12,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasError
                            ? AppColors.error
                            : focused
                            ? AppColors.primaryContainer
                            : AppColors.outlineVariant,
                        width: hasError || focused ? 2 : 1,
                      ),
                      boxShadow: focused && !hasError
                          ? const [
                              BoxShadow(
                                color: Color(0x140A4096),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      filled ? code[index] : '',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                            height: 32 / 24,
                            color: AppColors.onSurface,
                          ),
                    ),
                  ),
                ),
              );
            }),
          ),
          Positioned.fill(child: Opacity(opacity: 0.01, child: child)),
        ],
      ),
    );
  }
}

class _AlgeriaFlag extends StatelessWidget {
  const _AlgeriaFlag();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 24,
        height: 16,
        child: Row(
          children: [
            const Expanded(child: ColoredBox(color: Color(0xFF006233))),
            Expanded(
              child: ColoredBox(
                color: Colors.white,
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD21034)),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
