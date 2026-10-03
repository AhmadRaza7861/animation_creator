import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../common_widgets/show_toast.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppLanguage> get _filteredLanguages {
    if (_searchQuery.trim().isEmpty) {
      return AppLanguage.supportedLanguages;
    }
    final q = _searchQuery.toLowerCase().trim();
    return AppLanguage.supportedLanguages.where((lang) {
      return lang.name.toLowerCase().contains(q) ||
          lang.nativeName.toLowerCase().contains(q) ||
          lang.code.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final filtered = _filteredLanguages;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: const AppBackButton(),
        title: Text(
          context.tr('selectLanguage'),
          style: const TextStyle(
            color: ColorConstants.darkText,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Box
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: context.tr('searchLanguages'),
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.grey,
                    size: 22,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Language List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final lang = filtered[index];
                final isSelected = currentLocale.languageCode.toLowerCase() == lang.code.toLowerCase();

                return GestureDetector(
                  onTap: () async {
                    await ref.read(localeProvider.notifier).setLanguageCode(lang.code);
                    if (context.mounted) {
                      showToast(
                        message: context.tr('languageChanged', {'lang': lang.nativeName}),
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? ColorConstants.primary : const Color(0xFFE2E8F0),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? ColorConstants.primary.withOpacity(0.08)
                              : Colors.black.withOpacity(0.02),
                          blurRadius: isSelected ? 8 : 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        // Flag Badge
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? ColorConstants.primary.withOpacity(0.1)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              lang.flagEmoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Language Names
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.nativeName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? ColorConstants.primary
                                      : ColorConstants.darkText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lang.name,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Selection Indicator
                        if (isSelected)
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: ColorConstants.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          )
                        else
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300, width: 1.5),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
