import 'dart:ui';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

enum AppDialogType {
  primary,
  destructive,
  warning,
  info,
  success,
}

/// A comprehensive suite of modern, attractive dialogs for the entire application.
class AppDialogs {
  AppDialogs._();

  /// Generic general dialog with smooth zoom-fade transition and backdrop blur.
  static Future<T?> showCustomDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'AppDialog',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, anim1, anim2) => child,
      transitionBuilder: (context, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4 * anim1.value, sigmaY: 4 * anim1.value),
          child: FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Attractive Exit App Confirmation Dialog
  static Future<bool> showExitAppDialog(BuildContext context) async {
    final result = await showCustomDialog<bool>(
      context: context,
      child: Center(
        child: _DialogContainer(
          icon: Icons.power_settings_new_rounded,
          iconColor: const Color(0xFFFF9318),
          iconBgColor: const Color(0xFFFFF2E2),
          title: context.tr('exitAppTitle'),
          message: context.tr('exitAppMessage'),
          confirmText: context.tr('exitAppConfirm'),
          confirmColor: const Color(0xFFFF9318),
          cancelText: context.tr('exitAppCancel'),
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        ),
      ),
    );
    return result ?? false;
  }

  /// Attractive Delete Project Dialog
  static Future<bool> showDeleteProjectDialog(
    BuildContext context, {
    required String title,
  }) async {
    final result = await showCustomDialog<bool>(
      context: context,
      child: Center(
        child: _DialogContainer(
          icon: Icons.delete_outline_rounded,
          iconColor: const Color(0xFFE53935),
          iconBgColor: const Color(0xFFFFEBEE),
          title: context.tr('deleteProjectTitle'),
          message: context.tr('deleteProjectMessage'),
          highlightChip: title,
          confirmText: context.tr('deleteProjectConfirm'),
          confirmColor: const Color(0xFFE53935),
          cancelText: context.tr('keepProject'),
          isDestructive: true,
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        ),
      ),
    );
    return result ?? false;
  }

  /// Attractive Rename Project Dialog
  static Future<String?> showRenameProjectDialog(
    BuildContext context, {
    required String initialTitle,
  }) async {
    final controller = TextEditingController(text: initialTitle);
    return showCustomDialog<String>(
      context: context,
      child: _InputDialogContainer(
        icon: Icons.edit_note_rounded,
        iconColor: const Color(0xFFFF9318),
        iconBgColor: const Color(0xFFFFF2E2),
        title: context.tr('renameProjectTitle'),
        hintText: context.tr('enterProjectTitle'),
        initialText: initialTitle,
        confirmText: context.tr('saveTitle'),
        cancelText: context.tr('cancel'),
        controller: controller,
        onConfirm: (text) => Navigator.of(context).pop(text),
        onCancel: () => Navigator.of(context).pop(null),
      ),
    );
  }

  /// Attractive Delete Frame Dialog
  static Future<bool> showDeleteFrameDialog(
    BuildContext context, {
    required int frameIndex,
  }) async {
    final result = await showCustomDialog<bool>(
      context: context,
      child: Center(
        child: _DialogContainer(
          icon: Icons.delete_sweep_rounded,
          iconColor: const Color(0xFFE53935),
          iconBgColor: const Color(0xFFFFEBEE),
          title: context.tr('deleteFrameTitle', {'num': '${frameIndex + 1}'}),
          message: context.tr('deleteFrameMessage'),
          confirmText: context.tr('deleteFrameConfirm'),
          confirmColor: const Color(0xFFE53935),
          cancelText: context.tr('keepFrame'),
          isDestructive: true,
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        ),
      ),
    );
    return result ?? false;
  }

  /// Attractive Clear Canvas Confirmation Dialog
  static Future<bool> showClearCanvasDialog(BuildContext context) async {
    final result = await showCustomDialog<bool>(
      context: context,
      child: Center(
        child: _DialogContainer(
          icon: Icons.cleaning_services_rounded,
          iconColor: const Color(0xFFFF9318),
          iconBgColor: const Color(0xFFFFF2E2),
          title: context.tr('clearCanvasTitle'),
          message: context.tr('clearCanvasMessage'),
          confirmText: context.tr('clearCanvasConfirm'),
          confirmColor: const Color(0xFFFF9318),
          cancelText: context.tr('cancel'),
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        ),
      ),
    );
    return result ?? false;
  }

  /// Attractive Delete Audio Clip Dialog
  static Future<bool> showDeleteAudioClipDialog(
    BuildContext context, {
    required String clipTitle,
    required int trackIndex,
  }) async {
    final result = await showCustomDialog<bool>(
      context: context,
      child: Center(
        child: _DialogContainer(
          icon: Icons.music_off_rounded,
          iconColor: const Color(0xFFE53935),
          iconBgColor: const Color(0xFFFFEBEE),
          title: context.tr('deleteAudioClipTitle'),
          message: context.tr('deleteAudioClipMessage', {'num': '${trackIndex + 1}'}),
          highlightChip: clipTitle,
          confirmText: context.tr('deleteAudioConfirm'),
          confirmColor: const Color(0xFFE53935),
          cancelText: context.tr('keepAudio'),
          isDestructive: true,
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        ),
      ),
    );
    return result ?? false;
  }

  /// Attractive Cancel Export Dialog
  static Future<bool> showCancelExportDialog(BuildContext context) async {
    final result = await showCustomDialog<bool>(
      context: context,
      child: Center(
        child: _DialogContainer(
          icon: Icons.stop_circle_outlined,
          iconColor: const Color(0xFFFF9318),
          iconBgColor: const Color(0xFFFFF2E2),
          title: context.tr('cancelExportTitle'),
          message: context.tr('cancelExportMessage'),
          confirmText: context.tr('stopExportConfirm'),
          confirmColor: const Color(0xFFE53935),
          cancelText: context.tr('continueExport'),
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        ),
      ),
    );
    return result ?? false;
  }

  /// Attractive Notice / Error Dialog
  static Future<void> showNoticeDialog(
    BuildContext context, {
    required String title,
    required String message,
    bool isError = false,
    String? dismissText,
  }) {
    return showCustomDialog<void>(
      context: context,
      child: Center(
        child: _NoticeDialogContainer(
          title: title,
          message: message,
          isError: isError,
          dismissText: dismissText,
          onDismiss: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  /// Attractive Loading / Progress Dialog
  static void showProgressDialog(BuildContext context, {required String message}) {
    showCustomDialog<void>(
      context: context,
      barrierDismissible: false,
      child: Center(
        child: PopScope(
          canPop: false,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9318)),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E1E24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Attractive Text Sticker Input / Edit Dialog
  static Future<String?> showTextStickerDialog(
    BuildContext context, {
    String initialText = '',
    String? title,
    String? hintText,
    String? confirmText,
    String? cancelText,
  }) {
    final controller = TextEditingController(text: initialText);
    return showCustomDialog<String>(
      context: context,
      child: _InputDialogContainer(
        icon: Icons.text_fields_rounded,
        iconColor: const Color(0xFFFF9318),
        iconBgColor: const Color(0xFFFFF2E2),
        title: title ?? context.tr('addTextSticker'),
        hintText: hintText ?? context.tr('typeStickerText'),
        initialText: initialText,
        confirmText: confirmText ??
            (initialText.isEmpty ? context.tr('addToCanvas') : context.tr('saveText')),
        cancelText: cancelText ?? context.tr('cancel'),
        controller: controller,
        onConfirm: (text) => Navigator.of(context).pop(text),
        onCancel: () => Navigator.of(context).pop(null),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Standard Confirmation Dialog Card Widget
// ---------------------------------------------------------------------------
class _DialogContainer extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String message;
  final String? highlightChip;
  final String confirmText;
  final Color confirmColor;
  final String cancelText;
  final bool isDestructive;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _DialogContainer({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.message,
    this.highlightChip,
    required this.confirmText,
    required this.confirmColor,
    required this.cancelText,
    this.isDestructive = false,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.86,
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Glow Icon Badge
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 30),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1E24),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            // Optional Highlight Chip (e.g. Project Name / Clip Title)
            if (highlightChip != null && highlightChip!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: Text(
                  highlightChip!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2D35),
                  ),
                ),
              ),
            ],

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.black.withValues(alpha: 0.65),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF4F5F8),
                        foregroundColor: const Color(0xFF4A4B57),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          cancelText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Confirm Action Button
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: confirmColor.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input Dialog Card Widget (Rename, Text Stickers, etc.)
// ---------------------------------------------------------------------------
class _InputDialogContainer extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String hintText;
  final String initialText;
  final String confirmText;
  final String cancelText;
  final TextEditingController controller;
  final ValueChanged<String> onConfirm;
  final VoidCallback onCancel;

  const _InputDialogContainer({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.hintText,
    required this.initialText,
    required this.confirmText,
    this.cancelText = 'Cancel',
    required this.controller,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_InputDialogContainer> createState() => _InputDialogContainerState();
}

class _InputDialogContainerState extends State<_InputDialogContainer> {
  late bool _hasText;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) {
      setState(() {
        _hasText = has;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.86,
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Glow Icon Badge
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: widget.iconBgColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.iconColor.withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(widget.icon, color: widget.iconColor, size: 28),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E1E24),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input Field
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                    ),
                    child: TextField(
                      controller: widget.controller,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E1E24),
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withValues(alpha: 0.35),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: InputBorder.none,
                        suffixIcon: widget.controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.cancel_rounded, size: 18, color: Colors.black26),
                                onPressed: () => widget.controller.clear(),
                              )
                            : null,
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          widget.onConfirm(val.trim());
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: TextButton(
                            onPressed: widget.onCancel,
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFF4F5F8),
                              foregroundColor: const Color(0xFF4A4B57),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.cancelText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _hasText
                                ? () => widget.onConfirm(widget.controller.text.trim())
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9318),
                              disabledBackgroundColor: const Color(0xFFFF9318).withValues(alpha: 0.4),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.confirmText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notice / Error Dialog Container
// ---------------------------------------------------------------------------
class _NoticeDialogContainer extends StatelessWidget {
  final String title;
  final String message;
  final bool isError;
  final String? dismissText;
  final VoidCallback onDismiss;

  const _NoticeDialogContainer({
    required this.title,
    required this.message,
    required this.isError,
    this.dismissText,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFE53935) : const Color(0xFFFF9318);
    final bgColor = isError ? const Color(0xFFFFEBEE) : const Color(0xFFFFF2E2);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.86,
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
                  color: color,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1E24),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.black.withValues(alpha: 0.65),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  dismissText ?? context.tr('okGotIt'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
