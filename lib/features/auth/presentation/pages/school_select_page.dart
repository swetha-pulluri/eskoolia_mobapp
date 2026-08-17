import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../widgets/glass_panel.dart';
import '../widgets/auth_input_field.dart';
import '../widgets/atrium_button.dart';
import '../providers/auth_providers.dart';

/// School Identification Page
///
/// On web, each school has its own subdomain (e.g. vasavi.eskoolia.com,
/// created via Admin > School Tenancy > Add School), which is how the
/// browser tells the backend which school it's talking to before the login
/// form ever renders. The mobile app hits a single fixed API host instead
/// (see EnvConfig.apiBaseUrl), so it can't rely on that — this page asks the
/// user for their school's subdomain once, confirms it against the public
/// `GET /tenancy/school-info/?subdomain=` lookup, and shows that school's
/// branding before handing off to the existing login screen. The login
/// call itself is unchanged; this is purely an identification step.
class SchoolSelectPage extends ConsumerStatefulWidget {
  const SchoolSelectPage({super.key});

  @override
  ConsumerState<SchoolSelectPage> createState() => _SchoolSelectPageState();
}

class _SchoolSelectPageState extends ConsumerState<SchoolSelectPage> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _confirmedSubdomain;
  String? _errorText;
  bool _checking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Accepts either a bare subdomain ("vasavi") or a full URL/hostname
  /// ("vasavi.eskoolia.com", "https://vasavi.eskoolia.com/") and reduces it
  /// to the bare subdomain the backend's lookup expects — matching
  /// school_info_view's own bare-match-then-prefix-match behaviour.
  String _normalize(String input) {
    var value = input.trim().toLowerCase();
    value = value.replaceFirst(RegExp(r'^https?://'), '');
    value = value.split('/').first;
    if (value.contains('.')) {
      value = value.split('.').first;
    }
    return value;
  }

  Future<void> _handleCheck() async {
    if (!_formKey.currentState!.validate()) return;
    final subdomain = _normalize(_controller.text);

    setState(() {
      _checking = true;
      _errorText = null;
      _confirmedSubdomain = null;
    });

    try {
      final info = await ref.read(schoolInfoProvider(subdomain).future);
      if (!mounted) return;
      if (info == null) {
        setState(() {
          _checking = false;
          _errorText = "We couldn't find a school at that address. Check the URL and try again.";
        });
        return;
      }
      setState(() {
        _checking = false;
        _confirmedSubdomain = subdomain;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _errorText = 'Could not reach the server. Check your connection and try again.';
      });
    }
  }

  Future<void> _handleContinue() async {
    final subdomain = _confirmedSubdomain;
    if (subdomain == null) return;
    await selectSchool(ref, subdomain);
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final schoolInfoAsync = _confirmedSubdomain != null
        ? ref.watch(schoolInfoProvider(_confirmedSubdomain!))
        : null;

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: screenSize.width,
          height: screenSize.height,
          color: AppColors.surfaceBright,
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.04,
                  child: Image.network(
                    AppConstants.mandalaImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(),
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: GlassPanel(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Image.asset(
                              AppConstants.eskooliaLogo,
                              height: 56,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(Icons.school, size: 56),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "Find your school",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.atriumIndigo,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Enter your school's eSkoolia web address to continue.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            AuthInputField(
                              label: 'School URL',
                              placeholder: 'yourschool.eskoolia.com',
                              icon: Icons.apartment,
                              tone: AuthInputTone.teal,
                              controller: _controller,
                              autofocus: true,
                              keyboardType: TextInputType.url,
                              validator: (value) {
                                if (value == null || _normalize(value).isEmpty) {
                                  return 'Enter your school\'s web address';
                                }
                                return null;
                              },
                            ),
                            if (_errorText != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _errorText!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (_confirmedSubdomain != null && schoolInfoAsync != null) ...[
                              const SizedBox(height: 16),
                              _buildResolvedSchoolCard(schoolInfoAsync),
                            ],
                            const SizedBox(height: 20),
                            if (_confirmedSubdomain == null)
                              AtriumButton(
                                text: 'Continue',
                                isLoading: _checking,
                                onPressed: _handleCheck,
                              )
                            else
                              AtriumButton(
                                text: 'Continue to Login',
                                onPressed: _handleContinue,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResolvedSchoolCard(AsyncValue<dynamic> schoolInfoAsync) {
    return schoolInfoAsync.when(
      data: (info) {
        if (info == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.airaTeal.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              if (info.logoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    info.logoUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.school, size: 40, color: AppColors.airaTeal),
                  ),
                )
              else
                const Icon(Icons.school, size: 40, color: AppColors.airaTeal),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      info.name as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.atriumIndigo,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const Text(
                      'School found',
                      style: TextStyle(
                        color: AppColors.airaTeal,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: AppColors.airaTeal),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
