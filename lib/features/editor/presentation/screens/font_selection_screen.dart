import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/runtime_font_service.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/font_presets.dart';
import '../controllers/editor_controller.dart';
import '../widgets/sticker_widgets/text_sticker_widget.dart';

enum FontViewMode { grid, list }

class FontSelectionScreen extends StatefulWidget {
  final ActiveTextSticker sticker;
  final EditorController controller;

  const FontSelectionScreen({
    super.key,
    required this.sticker,
    required this.controller,
  });

  static Future<void> open(
    BuildContext context, {
    required ActiveTextSticker sticker,
    required EditorController controller,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FontSelectionScreen(
          sticker: sticker,
          controller: controller,
        ),
      ),
    );
  }

  @override
  State<FontSelectionScreen> createState() => _FontSelectionScreenState();
}

class _FontSelectionScreenState extends State<FontSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _previewTextController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  FontViewMode _viewMode = FontViewMode.grid;
  double _previewFontSize = 24.0;
  bool _isDownloadingAll = false;
  bool _isEditingPreview = false;
  bool _isCompactPreview = false;

  final List<String> _categories = const [
    'All',
    'Script & Cursive',
    'Handwritten & Casual',
    'Bold & Display',
    'Serif & Elegant',
    'Clean & Sans',
    'Retro & Cyber',
    'Downloaded',
  ];

  @override
  void initState() {
    super.initState();
    _previewTextController.text = widget.sticker.text.trim().isNotEmpty
        ? widget.sticker.text.trim()
        : 'Creative Typography';

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _previewTextController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<FontPreset> _getFilteredPresets() {
    final fontService = RuntimeFontService.instance;
    return fontPresets.where((preset) {
      // 1. Category filter
      if (_selectedCategory == 'Downloaded') {
        final status = fontService.getFontStatus(preset.name);
        if (status != FontDownloadStatus.downloaded) return false;
      } else if (_selectedCategory != 'All' && preset.category != _selectedCategory) {
        return false;
      }

      // 2. Search query filter
      if (_searchQuery.isNotEmpty) {
        final matchesName = preset.name.toLowerCase().contains(_searchQuery);
        final matchesFamily = (preset.fontFamily ?? '').toLowerCase().contains(_searchQuery);
        final matchesCategory = preset.category.toLowerCase().contains(_searchQuery);
        final matchesStyle = preset.styleTag.toLowerCase().contains(_searchQuery);
        return matchesName || matchesFamily || matchesCategory || matchesStyle;
      }

      return true;
    }).toList();
  }


  void _onSelectFont(FontPreset preset) async {
    final fontService = RuntimeFontService.instance;
    final status = fontService.getFontStatus(preset.name);

    if (status == FontDownloadStatus.downloaded) {
      // Font is already downloaded: select & apply to sticker immediately!
      setState(() {
        widget.sticker.fontFamily = preset.name;
      });
      widget.controller.updateSnapshot();
      return;
    }

    if (status == FontDownloadStatus.downloading) {
      Fluttertoast.showToast(
        msg: 'Downloading "${preset.name}"...',
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    // Font is not downloaded: User cannot select it yet, tap initiates download
    final hasNet = await fontService.checkInternet();
    if (!hasNet) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'No internet connection. Please check your network to download fonts.',
          toastLength: Toast.LENGTH_LONG,
        );
      }
      return;
    }

    Fluttertoast.showToast(
      msg: 'Downloading "${preset.name}"...',
      toastLength: Toast.LENGTH_SHORT,
    );

    final result = await fontService.downloadFontDetailed(preset.name);

    if (result.success && mounted) {
      // Only now that the font is downloaded, apply and select it
      setState(() {
        widget.sticker.fontFamily = preset.name;
      });
      widget.controller.updateSnapshot();
      Fluttertoast.showToast(
        msg: 'Downloaded & applied "${preset.name}"',
        toastLength: Toast.LENGTH_SHORT,
      );
    } else if (!result.success && mounted) {
      Fluttertoast.showToast(
        msg: result.message.isNotEmpty
            ? result.message
            : 'Could not download "${preset.name}".',
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  void _onDownloadAll() async {
    if (_isDownloadingAll) return;

    final hasNet = await RuntimeFontService.instance.checkInternet();
    if (!hasNet) {
      Fluttertoast.showToast(
        msg: 'No internet connection. Please check your network to download fonts.',
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    setState(() {
      _isDownloadingAll = true;
    });

    Fluttertoast.showToast(
      msg: 'Downloading remaining fonts in background...',
      toastLength: Toast.LENGTH_SHORT,
    );

    await RuntimeFontService.instance.downloadAllFonts();

    if (mounted) {
      setState(() {
        _isDownloadingAll = false;
      });
      final loaded = RuntimeFontService.instance.loadedFontsCount;
      final total = fontPresets.length;
      if (loaded == total) {
        Fluttertoast.showToast(
          msg: 'All fonts are downloaded and ready!',
          toastLength: Toast.LENGTH_SHORT,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Fonts downloaded successfully.',
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = ColorConstants.primary;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : ColorConstants.darkText;
    final subTextColor = isDark ? const Color(0xFF94A3B8) : ColorConstants.mediumText;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: RuntimeFontService.instance,
      builder: (context, child) {
        final filteredPresets = _getFilteredPresets();
        final currentPreset = getFontPresetByName(widget.sticker.fontFamily);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: _buildAppBar(
            context: context,
            isDark: isDark,
            primaryColor: primaryColor,
            textColor: textColor,
            subTextColor: subTextColor,
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. PINNED LIVE PREVIEW BANNER (Never scrolls away!)
                _buildLivePreviewBanner(
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  currentPreset: currentPreset,
                ),

                // 2. PINNED SEARCH & CATEGORY FILTER BAR
                _buildSearchAndFilterSection(
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),

                // 3. SCROLLABLE FONTS SHOWCASE (Grid or List scrolls underneath preview)
                Expanded(
                  child: filteredPresets.isEmpty
                      ? _buildEmptyState(
                          isDark: isDark,
                          primaryColor: primaryColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                        )
                      : _viewMode == FontViewMode.grid
                          ? GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.15,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: filteredPresets.length,
                              itemBuilder: (context, index) {
                                final preset = filteredPresets[index];
                                final status = RuntimeFontService.instance.getFontStatus(preset.name);
                                final isSelected = widget.sticker.fontFamily == preset.name &&
                                    status == FontDownloadStatus.downloaded;
                                return _buildFontGridCard(
                                  preset: preset,
                                  isSelected: isSelected,
                                  isDark: isDark,
                                  surfaceColor: surfaceColor,
                                  borderColor: borderColor,
                                  primaryColor: primaryColor,
                                  textColor: textColor,
                                  subTextColor: subTextColor,
                                );
                              },
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: filteredPresets.length,
                              itemBuilder: (context, index) {
                                final preset = filteredPresets[index];
                                final status = RuntimeFontService.instance.getFontStatus(preset.name);
                                final isSelected = widget.sticker.fontFamily == preset.name &&
                                    status == FontDownloadStatus.downloaded;
                                return _buildFontListRow(
                                  preset: preset,
                                  isSelected: isSelected,
                                  isDark: isDark,
                                  surfaceColor: surfaceColor,
                                  borderColor: borderColor,
                                  primaryColor: primaryColor,
                                  textColor: textColor,
                                  subTextColor: subTextColor,
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar({
    required BuildContext context,
    required bool isDark,
    required Color primaryColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    final loadedCount = RuntimeFontService.instance.loadedFontsCount;
    final totalCount = fontPresets.length;
    final allDownloaded = loadedCount >= totalCount;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      leading: const AppBackButton(),
      centerTitle: false,
      title: Text(
        'Typography & Fonts',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        // Download All Button (Only visible if not all fonts are downloaded)
        if (!allDownloaded)
          IconButton(
            tooltip: 'Download All Fonts',
            icon: _isDownloadingAll
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  )
                : Icon(
                    Icons.cloud_download_outlined,
                    color: primaryColor,
                    size: 22,
                  ),
            onPressed: _isDownloadingAll ? null : _onDownloadAll,
          ),

        // Apply / Done Action
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 4),
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Done',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLivePreviewBanner({
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color primaryColor,
    required Color textColor,
    required Color subTextColor,
    required FontPreset currentPreset,
  }) {
    final previewText = _previewTextController.text.isNotEmpty
        ? _previewTextController.text
        : widget.sticker.text.isNotEmpty
            ? widget.sticker.text
            : 'Type to test...';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: _isCompactPreview ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Live Preview Badge + Font Name + Minimize/Expand + Size Stepper
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 12, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'PREVIEW',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 9.5,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        currentPreset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '• ${currentPreset.styleTag}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Font Size Stepper
              if (!_isCompactPreview) ...[
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                        onTap: () {
                          if (_previewFontSize > 14) {
                            setState(() => _previewFontSize -= 3);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          child: Icon(Icons.remove, size: 14, color: subTextColor),
                        ),
                      ),
                      Text(
                        '${_previewFontSize.toInt()}',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      InkWell(
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                        onTap: () {
                          if (_previewFontSize < 44) {
                            setState(() => _previewFontSize += 3);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          child: Icon(Icons.add, size: 14, color: subTextColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
              ],

              // Compact / Full toggle button
              InkWell(
                onTap: () {
                  setState(() {
                    _isCompactPreview = !_isCompactPreview;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(
                    _isCompactPreview
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    size: 20,
                    color: subTextColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Live Text Display Box
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: _isCompactPreview ? 6 : 10,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: _isEditingPreview && !_isCompactPreview
                ? TextField(
                    controller: _previewTextController,
                    autofocus: true,
                    style: currentPreset.getTextStyle(
                      color: widget.sticker.color,
                      fontSize: _previewFontSize,
                      forceBold: widget.sticker.isBold,
                      forceItalic: widget.sticker.isItalic,
                      forceUnderline: widget.sticker.isUnderline,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (val) {
                      setState(() {
                        _isEditingPreview = false;
                        if (val.trim().isNotEmpty) {
                          widget.sticker.text = val.trim();
                          widget.controller.updateSnapshot();
                        }
                      });
                    },
                  )
                : GestureDetector(
                    onTap: () {
                      if (!_isCompactPreview) {
                        setState(() {
                          _isEditingPreview = true;
                        });
                      }
                    },
                    child: Center(
                      child: Text(
                        previewText,
                        textAlign: TextAlign.center,
                        maxLines: _isCompactPreview ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: currentPreset.getTextStyle(
                          color: widget.sticker.color,
                          fontSize: _isCompactPreview ? 18 : _previewFontSize,
                          forceBold: widget.sticker.isBold,
                          forceItalic: widget.sticker.isItalic,
                          forceUnderline: widget.sticker.isUnderline,
                        ),
                      ),
                    ),
                  ),
          ),

          // Bottom Quick Controls (Only in expanded mode)
          if (!_isCompactPreview) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                // Style modifiers (Bold, Italic, Underline)
                _buildStyleToggle(
                  icon: Icons.format_bold_rounded,
                  isActive: widget.sticker.isBold,
                  isDark: isDark,
                  primaryColor: primaryColor,
                  onTap: () {
                    setState(() {
                      widget.sticker.isBold = !widget.sticker.isBold;
                    });
                    widget.controller.updateSnapshot();
                  },
                ),
                const SizedBox(width: 6),
                _buildStyleToggle(
                  icon: Icons.format_italic_rounded,
                  isActive: widget.sticker.isItalic,
                  isDark: isDark,
                  primaryColor: primaryColor,
                  onTap: () {
                    setState(() {
                      widget.sticker.isItalic = !widget.sticker.isItalic;
                    });
                    widget.controller.updateSnapshot();
                  },
                ),
                const SizedBox(width: 6),
                _buildStyleToggle(
                  icon: Icons.format_underlined_rounded,
                  isActive: widget.sticker.isUnderline,
                  isDark: isDark,
                  primaryColor: primaryColor,
                  onTap: () {
                    setState(() {
                      widget.sticker.isUnderline = !widget.sticker.isUnderline;
                    });
                    widget.controller.updateSnapshot();
                  },
                ),

                const Spacer(),

                // Sample text preset buttons
                _buildSampleTextChip(
                  label: 'Sample',
                  isDark: isDark,
                  onTap: () {
                    setState(() {
                      _previewTextController.text = 'The quick brown fox';
                    });
                  },
                ),
                const SizedBox(width: 6),
                _buildSampleTextChip(
                  label: 'Numbers',
                  isDark: isDark,
                  onTap: () {
                    setState(() {
                      _previewTextController.text = '0123456789 #@!';
                    });
                  },
                ),
                const SizedBox(width: 6),
                _buildSampleTextChip(
                  label: 'Sticker Text',
                  isDark: isDark,
                  onTap: () {
                    setState(() {
                      _previewTextController.text = widget.sticker.text;
                    });
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStyleToggle({
    required IconData icon,
    required bool isActive,
    required bool isDark,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isActive
              ? primaryColor.withOpacity(0.15)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? primaryColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 15,
          color: isActive ? primaryColor : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildSampleTextChip({
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF475569),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterSection({
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color primaryColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search & View Mode row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              // Search Input
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: TextStyle(color: textColor, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Search fonts & styles...',
                      hintStyle: TextStyle(color: subTextColor, fontSize: 12.5),
                      prefixIcon: Icon(Icons.search_rounded, color: subTextColor, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, color: subTextColor, size: 16),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Grid / List Toggle
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.grid_view_rounded,
                        size: 18,
                        color: _viewMode == FontViewMode.grid ? primaryColor : subTextColor,
                      ),
                      onPressed: () {
                        setState(() => _viewMode = FontViewMode.grid);
                      },
                    ),
                    Container(width: 1, height: 20, color: borderColor),
                    IconButton(
                      icon: Icon(
                        Icons.view_agenda_rounded,
                        size: 18,
                        color: _viewMode == FontViewMode.list ? primaryColor : subTextColor,
                      ),
                      onPressed: () {
                        setState(() => _viewMode = FontViewMode.list);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Horizontal Category Tabs
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;

              return InkWell(
                onTap: () {
                  setState(() => _selectedCategory = category);
                },
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? primaryColor : borderColor,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : ColorConstants.darkText),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildFontGridCard({
    required FontPreset preset,
    required bool isSelected,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color primaryColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    final status = RuntimeFontService.instance.getFontStatus(preset.name);
    final sample = _previewTextController.text.isNotEmpty
        ? _previewTextController.text
        : widget.sticker.text.isNotEmpty
            ? widget.sticker.text
            : 'Aa Bb Gg 123';

    return InkWell(
      onTap: () => _onSelectFont(preset),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? primaryColor.withOpacity(0.12) : const Color(0xFFFFF7ED))
              : surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : borderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Font Name & Status Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    preset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? primaryColor : textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _buildStatusIcon(status, isSelected, primaryColor, isDark),
              ],
            ),

            const SizedBox(height: 2),

            // Style Tag
            Text(
              preset.styleTag,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: subTextColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),

            const Spacer(),

            // Typography Specimen Sample (shows the user's text in this font)
            Center(
              child: Text(
                sample,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: preset.getTextStyle(
                  color: isSelected ? primaryColor : textColor,
                  fontSize: 20,
                  forceBold: widget.sticker.isBold,
                  forceItalic: widget.sticker.isItalic,
                ),
              ),
            ),

            const Spacer(),

            // Category Mini Chip
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  preset.category.split('&').first.trim(),
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontListRow({
    required FontPreset preset,
    required bool isSelected,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color primaryColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    final status = RuntimeFontService.instance.getFontStatus(preset.name);
    final sample = _previewTextController.text.isNotEmpty
        ? _previewTextController.text
        : widget.sticker.text.isNotEmpty
            ? widget.sticker.text
            : 'The quick brown fox';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _onSelectFont(preset),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? primaryColor.withOpacity(0.12) : const Color(0xFFFFF7ED))
                : surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? primaryColor : borderColor,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Selection or Download state icon
              _buildStatusIcon(status, isSelected, primaryColor, isDark),

              const SizedBox(width: 14),

              // Font info & typography preview
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            preset.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected ? primaryColor : textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              preset.styleTag,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sample,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: preset.getTextStyle(
                        color: isSelected ? primaryColor : textColor,
                        fontSize: 18,
                        forceBold: widget.sticker.isBold,
                        forceItalic: widget.sticker.isItalic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Category tag
              Text(
                preset.category.split('&').first.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(
    FontDownloadStatus status,
    bool isSelected,
    Color primaryColor,
    bool isDark,
  ) {
    if (isSelected && status == FontDownloadStatus.downloaded) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.check_rounded, size: 15, color: Colors.white),
      );
    }

    switch (status) {
      case FontDownloadStatus.downloading:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        );
      case FontDownloadStatus.notDownloaded:
      case FontDownloadStatus.failed:
        return Icon(
          Icons.download_rounded,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          size: 20,
        );
      case FontDownloadStatus.downloaded:
        return const SizedBox(width: 20, height: 20);
    }
  }

  Widget _buildEmptyState({
    required bool isDark,
    required Color primaryColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.font_download_off_rounded,
              size: 54,
              color: subTextColor.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No fonts found',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try searching with a different name or category',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subTextColor,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedCategory = 'All';
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
