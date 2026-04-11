import 'package:flutter/material.dart';

/// Centralized dialog system for NutriLens.
/// All dialogs follow the same design language.
///
/// Usage:
///   AppDialogs.warning(context, title: '...', message: '...', confirmLabel: 'Delete')
///   AppDialogs.success(context, title: '...', message: '...')
///   AppDialogs.confirm(context, title: '...', message: '...')
///   AppDialogs.error(context, title: '...', message: '...')
///   AppDialogs.news(context, title: '...', message: '...', imageUrl: '...')
class AppDialogs {
  static const _primary = Color(0xFFEC6F2D);
  static const _primaryFixed = Color(0xFFFFDBCC);
  static const _primaryDark = Color(0xFFA23F00);
  static const _tertiaryFixed = Color(0xFFB8F5CF);
  static const _tertiary = Color(0xFF006D3A);
  static const _errorFixed = Color(0xFFFFDAD6);
  static const _error = Color(0xFFBA1A1A);
  static const _textDark = Color(0xFF1A1A1A);
  static const _textMuted = Color(0xFF3D3D3D);
  static const _border = Color(0xFFDDDDDD);

  // ── Warning ────────────────────────────────────────────────────────────────
  /// Destructive action (delete, reset, remove). Returns true if confirmed.
  static Future<bool> warning(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
  }) async {
    return await _show(
          context,
          _AppDialogData(
            iconData: Icons.warning_amber_rounded,
            iconColor: _primaryDark,
            iconBg: _primaryFixed,
            title: title,
            message: message,
            confirmLabel: confirmLabel,
            confirmColor: _primary,
            cancelLabel: cancelLabel,
          ),
        ) ??
        false;
  }

  // ── Success ────────────────────────────────────────────────────────────────
  /// Positive feedback. Single action button.
  static Future<void> success(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'Continue',
  }) async {
    await _show(
      context,
      _AppDialogData(
        iconData: Icons.check_circle_rounded,
        iconColor: _tertiary,
        iconBg: _tertiaryFixed,
        title: title,
        message: message,
        confirmLabel: actionLabel,
        confirmColor: _primary,
        singleAction: true,
      ),
    );
  }

  // ── Confirm (Yes / No) ─────────────────────────────────────────────────────
  /// Neutral confirmation. Returns true if confirmed.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Yes',
    String cancelLabel = 'No',
  }) async {
    return await _show(
          context,
          _AppDialogData(
            iconData: Icons.help_outline_rounded,
            iconColor: _primary,
            iconBg: _primaryFixed,
            title: title,
            message: message,
            confirmLabel: confirmLabel,
            confirmColor: _primary,
            cancelLabel: cancelLabel,
          ),
        ) ??
        false;
  }

  // ── Error ──────────────────────────────────────────────────────────────────
  /// Error or failure state. Single action button.
  static Future<void> error(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'Try Again',
  }) async {
    await _show(
      context,
      _AppDialogData(
        iconData: Icons.error_rounded,
        iconColor: _error,
        iconBg: _errorFixed,
        title: title,
        message: message,
        confirmLabel: actionLabel,
        confirmColor: _error,
        singleAction: true,
      ),
    );
  }

  // ── News / Info ────────────────────────────────────────────────────────────
  /// Informational with optional image header.
  static Future<void> news(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'Learn More',
    String? imageUrl,
    VoidCallback? onAction,
  }) async {
    await showDialog(
      context: context,
      builder: (_) => _NewsDialog(
        title: title,
        message: message,
        actionLabel: actionLabel,
        imageUrl: imageUrl,
        onAction: onAction,
      ),
    );
  }

  // ── Internal builder ───────────────────────────────────────────────────────
  static Future<bool?> _show(BuildContext context, _AppDialogData data) {
    return showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + Title
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: data.iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(data.iconData, color: data.iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(data.title,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _textDark)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Message
              Text(data.message,
                  style: const TextStyle(
                      fontSize: 14, color: _textMuted, height: 1.5)),
              const SizedBox(height: 20),
              // Buttons
              if (data.singleAction)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: data.confirmColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(data.confirmLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: _border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(data.cancelLabel ?? 'Cancel',
                            style: const TextStyle(
                                color: _textMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: data.confirmColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(data.confirmLabel,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Internal data model ────────────────────────────────────────────────────────

class _AppDialogData {
  final IconData iconData;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final String? cancelLabel;
  final bool singleAction;

  const _AppDialogData({
    required this.iconData,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    this.cancelLabel,
    this.singleAction = false,
  });
}

// ── News Dialog ────────────────────────────────────────────────────────────────

class _NewsDialog extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final String? imageUrl;
  final VoidCallback? onAction;

  const _NewsDialog({
    required this.title,
    required this.message,
    required this.actionLabel,
    this.imageUrl,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            Stack(
              children: [
                SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: Image.network(imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFFFDBCC))),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.white.withOpacity(0.6)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline_rounded,
                        color: Color(0xFFEC6F2D), size: 16),
                    SizedBox(width: 6),
                    Text('UPDATE',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFEC6F2D),
                            letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A))),
                const SizedBox(height: 6),
                Text(message,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF3D3D3D), height: 1.5)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onAction?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFDBCC),
                      foregroundColor: const Color(0xFFA23F00),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(actionLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
