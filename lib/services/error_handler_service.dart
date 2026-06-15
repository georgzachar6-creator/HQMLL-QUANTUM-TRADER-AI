/// HQMLL Quantum Trader — ErrorHandlerService v49.0
/// Flutter-Äquivalent zu React Error Boundaries
/// Zentrales Fehler-Management: Capture, Log, Recover, Notify
/// Grigori Saks · 2025
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
// ERROR MODELS
// ══════════════════════════════════════════════════════════════

enum AppErrorType {
  network,
  data,
  auth,
  service,
  ui,
  unknown,
}

enum AppErrorSeverity { info, warning, error, critical }

class AppError {
  final String id;
  final AppErrorType type;
  final AppErrorSeverity severity;
  final String message;
  final String? details;
  final String? source;
  final DateTime timestamp;
  final Object? originalError;
  final StackTrace? stackTrace;
  bool dismissed;

  AppError({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    this.details,
    this.source,
    required this.timestamp,
    this.originalError,
    this.stackTrace,
    this.dismissed = false,
  });

  String get typeLabel => const {
    AppErrorType.network:  'NETZWERK',
    AppErrorType.data:     'DATEN',
    AppErrorType.auth:     'AUTH',
    AppErrorType.service:  'SERVICE',
    AppErrorType.ui:       'UI',
    AppErrorType.unknown:  'UNBEKANNT',
  }[type] ?? 'UNBEKANNT';

  Color get severityColor => const {
    AppErrorSeverity.info:     Color(0xFF00F0FF),
    AppErrorSeverity.warning:  Color(0xFFF7931A),
    AppErrorSeverity.error:    Color(0xFFFF4444),
    AppErrorSeverity.critical: Color(0xFFFF0055),
  }[severity] ?? const Color(0xFFFF4444);

  IconData get icon => const {
    AppErrorType.network:  Icons.wifi_off_outlined,
    AppErrorType.data:     Icons.storage_outlined,
    AppErrorType.auth:     Icons.lock_outline,
    AppErrorType.service:  Icons.settings_outlined,
    AppErrorType.ui:       Icons.broken_image_outlined,
    AppErrorType.unknown:  Icons.error_outline,
  }[type] ?? Icons.error_outline;
}

// ══════════════════════════════════════════════════════════════
// ERROR HANDLER SERVICE
// ══════════════════════════════════════════════════════════════
class ErrorHandlerService extends ChangeNotifier {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal() {
    _setupFlutterErrorHandler();
  }

  // State
  final List<AppError>         _errors        = [];
  final StreamController<AppError> _errorStream =
      StreamController<AppError>.broadcast();
  int _errorCount = 0;

  // Getters
  List<AppError> get errors     => List.unmodifiable(_errors);
  List<AppError> get activeErrors => _errors.where((e) => !e.dismissed).toList();
  Stream<AppError> get errorStream => _errorStream.stream;
  int get errorCount             => _errorCount;
  bool get hasActiveErrors       => activeErrors.isNotEmpty;
  AppError? get latestError      =>
      activeErrors.isNotEmpty ? activeErrors.first : null;

  // ── Flutter Global Error Hook ─────────────────────────────
  void _setupFlutterErrorHandler() {
    FlutterError.onError = (FlutterErrorDetails details) {
      capture(
        message: details.exceptionAsString(),
        details: details.stack?.toString(),
        type: AppErrorType.ui,
        severity: AppErrorSeverity.error,
        source: details.library ?? 'Flutter',
        originalError: details.exception,
        stackTrace: details.stack,
      );
    };

    // Capture async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      capture(
        message: error.toString(),
        details: stack.toString(),
        type: AppErrorType.unknown,
        severity: AppErrorSeverity.error,
        source: 'PlatformDispatcher',
        originalError: error,
        stackTrace: stack,
      );
      return true;
    };
  }

  // ── Capture ───────────────────────────────────────────────
  AppError capture({
    required String message,
    String? details,
    AppErrorType type = AppErrorType.unknown,
    AppErrorSeverity severity = AppErrorSeverity.error,
    String? source,
    Object? originalError,
    StackTrace? stackTrace,
  }) {
    _errorCount++;
    final err = AppError(
      id:            'ERR_${DateTime.now().millisecondsSinceEpoch}_$_errorCount',
      type:          type,
      severity:      severity,
      message:       message,
      details:       details,
      source:        source,
      timestamp:     DateTime.now(),
      originalError: originalError,
      stackTrace:    stackTrace,
    );

    _errors.insert(0, err);
    if (_errors.length > 100) _errors.removeLast();

    _errorStream.add(err);

    if (kDebugMode) {
      debugPrint('[ErrorHandler] ${err.typeLabel} [${err.severity.name}]: $message');
      if (details != null) debugPrint('  Details: $details');
    }

    notifyListeners();
    return err;
  }

  // ── Service-spezifische Capture-Helfer ────────────────────

  AppError captureNetwork(String message, {Object? err, String? source}) =>
      capture(
        message: message, type: AppErrorType.network,
        severity: AppErrorSeverity.warning, source: source ?? 'Network',
        originalError: err,
      );

  AppError captureData(String message, {Object? err, String? source}) =>
      capture(
        message: message, type: AppErrorType.data,
        severity: AppErrorSeverity.error, source: source ?? 'DataService',
        originalError: err,
      );

  AppError captureAuth(String message, {Object? err}) =>
      capture(
        message: message, type: AppErrorType.auth,
        severity: AppErrorSeverity.critical, source: 'AuthService',
        originalError: err,
      );

  AppError captureService(String message, {String? service, Object? err}) =>
      capture(
        message: message, type: AppErrorType.service,
        severity: AppErrorSeverity.warning, source: service,
        originalError: err,
      );

  // ── Recovery ──────────────────────────────────────────────
  void dismiss(String errorId) {
    final idx = _errors.indexWhere((e) => e.id == errorId);
    if (idx >= 0) {
      _errors[idx].dismissed = true;
      notifyListeners();
    }
  }

  void dismissAll() {
    for (final e in _errors) {
      e.dismissed = true;
    }
    notifyListeners();
  }

  void clearAll() {
    _errors.clear();
    notifyListeners();
  }

  /// Retry-Wrapper: Führt die Aktion aus und fängt Fehler automatisch
  Future<T?> runSafe<T>(
    Future<T> Function() action, {
    String? source,
    AppErrorType type = AppErrorType.service,
    T? fallback,
  }) async {
    try {
      return await action();
    } catch (e, stack) {
      capture(
        message: e.toString(),
        details: stack.toString(),
        type: type,
        severity: AppErrorSeverity.error,
        source: source,
        originalError: e,
        stackTrace: stack,
      );
      return fallback;
    }
  }

  @override
  void dispose() {
    _errorStream.close();
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════════════
// FLUTTER ÄQUIVALENT ZU REACT ERROR BOUNDARY
// Wrap um kritische Widgets — fängt Widget-Build-Fehler
// ══════════════════════════════════════════════════════════════
class QuantumErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stack)? fallbackBuilder;
  final String? boundaryName;

  const QuantumErrorBoundary({
    super.key,
    required this.child,
    this.fallbackBuilder,
    this.boundaryName,
  });

  @override
  State<QuantumErrorBoundary> createState() => _QuantumErrorBoundaryState();
}

class _QuantumErrorBoundaryState extends State<QuantumErrorBoundary> {
  Object? _error;
  StackTrace? _stack;

  // Stream-Subscription zum ErrorHandlerService (kein FlutterError.onError Override!)
  StreamSubscription<AppError>? _errorSub;

  @override
  void initState() {
    super.initState();
    // ── KORREKTES Flutter Error Boundary Pattern ──────────────
    // KEIN FlutterError.onError Override hier — das macht bereits
    // ErrorHandlerService._setupFlutterErrorHandler() einmalig global.
    // Stattdessen: Lausche auf den errorStream des Services.
    _errorSub = ErrorHandlerService().errorStream.listen((appErr) {
      // Nur UI-kritische Fehler anzeigen (severity >= error)
      if (appErr.severity.index >= AppErrorSeverity.error.index &&
          appErr.type == AppErrorType.ui) {
        if (mounted) {
          setState(() {
            _error = appErr.originalError ?? appErr.message;
            _stack = appErr.stackTrace;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _errorSub?.cancel();
    super.dispose();
  }

  void _reset() => setState(() { _error = null; _stack = null; });

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.fallbackBuilder != null) {
        return widget.fallbackBuilder!(_error!, _stack);
      }
      return _DefaultErrorFallback(
        error: _error!,
        stack: _stack,
        boundaryName: widget.boundaryName,
        onRetry: _reset,
      );
    }
    return widget.child;
  }
}

// ══════════════════════════════════════════════════════════════
// GLOBAL ERROR OVERLAY — zeigt aktive Fehler als Banner
// ══════════════════════════════════════════════════════════════
class GlobalErrorOverlay extends StatefulWidget {
  final Widget child;

  const GlobalErrorOverlay({super.key, required this.child});

  @override
  State<GlobalErrorOverlay> createState() => _GlobalErrorOverlayState();
}

class _GlobalErrorOverlayState extends State<GlobalErrorOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<Offset>   _slideAnim;
  AppError? _shownError;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1), end: Offset.zero)
      .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));

    // Listen to error stream
    final errSvc = ErrorHandlerService();
    errSvc.errorStream.listen((err) {
      if (err.severity.index >= AppErrorSeverity.warning.index) {
        _showBanner(err);
      }
    });
  }

  void _showBanner(AppError err) {
    if (!mounted) return;
    setState(() => _shownError = err);
    _animCtrl.forward(from: 0);

    // Auto-dismiss after 5s for warnings
    if (err.severity == AppErrorSeverity.warning) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _shownError?.id == err.id) {
          _hideBanner(err.id);
        }
      });
    }
  }

  void _hideBanner(String id) {
    if (!mounted) return;
    _animCtrl.reverse().then((_) {
      if (mounted) setState(() => _shownError = null);
    });
    ErrorHandlerService().dismiss(id);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shownErr = _shownError; // lokale nicht-nullable Kopie
    return Stack(children: [
      widget.child,
      if (shownErr != null)
        Positioned(
          top: 0, left: 0, right: 0,
          child: SlideTransition(
            position: _slideAnim,
            child: _ErrorBanner(
              error: shownErr,
              onDismiss: () => _hideBanner(shownErr.id),
            ),
          ),
        ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
// ERROR BANNER — Live-Banner im Dashboard-Stil
// ══════════════════════════════════════════════════════════════
class _ErrorBanner extends StatelessWidget {
  final AppError error;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.error, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final color = error.severityColor;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 12, spreadRadius: 1,
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Icon(error.icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(error.typeLabel,
                    style: TextStyle(
                      color: color, fontSize: 8,
                      fontWeight: FontWeight.w800, letterSpacing: 1,
                      fontFamily: 'Rajdhani',
                    )),
                ),
                const SizedBox(width: 6),
                if (error.source != null)
                  Text(error.source!,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.7),
                      fontSize: 8, fontFamily: 'Rajdhani',
                    )),
              ]),
              const SizedBox(height: 2),
              Text(error.message,
                style: const TextStyle(
                  color: Colors.white, fontSize: 11,
                  fontWeight: FontWeight.w600, fontFamily: 'Rajdhani',
                ),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
            ],
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDismiss,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              child: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.6), size: 14),
            ),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// DEFAULT ERROR FALLBACK (für QuantumErrorBoundary)
// ══════════════════════════════════════════════════════════════
class _DefaultErrorFallback extends StatelessWidget {
  final Object error;
  final StackTrace? stack;
  final String? boundaryName;
  final VoidCallback onRetry;

  const _DefaultErrorFallback({
    required this.error,
    this.stack,
    this.boundaryName,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF4444).withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF4444), size: 20),
            const SizedBox(width: 8),
            Text(
              boundaryName != null
                  ? 'FEHLER IN: ${boundaryName!.toUpperCase()}'
                  : 'KOMPONENTE NICHT VERFÜGBAR',
              style: const TextStyle(
                color: Color(0xFFFF4444), fontSize: 11,
                fontWeight: FontWeight.w800, letterSpacing: 1,
                fontFamily: 'Rajdhani',
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              error.toString(),
              style: const TextStyle(
                color: Color(0xFFAAAAAA), fontSize: 9,
                fontFamily: 'RobotoMono',
              ),
              maxLines: 3, overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Erneut versuchen',
                style: TextStyle(fontFamily: 'Rajdhani', fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4444).withValues(alpha: 0.2),
                foregroundColor: const Color(0xFFFF4444),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: Color(0xFFFF4444), width: 1),
                ),
                elevation: 0,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ROUTE ERROR PAGE — für Navigations-Fehler (Flutter-Äquivalent)
// ══════════════════════════════════════════════════════════════
class RouteErrorPage extends StatelessWidget {
  final String routeName;
  final String? errorMessage;

  const RouteErrorPage({
    super.key,
    required this.routeName,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error icon with glow
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF4444).withValues(alpha: 0.1),
                  border: Border.all(
                    color: const Color(0xFFFF4444).withValues(alpha: 0.4)),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFFFF4444).withValues(alpha: 0.2),
                    blurRadius: 20, spreadRadius: 2,
                  )],
                ),
                child: const Icon(Icons.error_outline,
                  color: Color(0xFFFF4444), size: 32),
              ),
              const SizedBox(height: 20),
              const Text('ROUTE NICHT VERFÜGBAR',
                style: TextStyle(
                  color: Color(0xFFFF4444), fontSize: 10,
                  fontWeight: FontWeight.w800, letterSpacing: 2,
                  fontFamily: 'Rajdhani',
                )),
              const SizedBox(height: 8),
              Text(
                routeName,
                style: const TextStyle(
                  color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.w800, fontFamily: 'Rajdhani',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage ?? 'Diese Seite konnte nicht geladen werden. '
                    'Bitte versuche es erneut oder kehre zur Startseite zurück.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13, fontFamily: 'Rajdhani', height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Row(children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Zurück',
                    style: TextStyle(fontFamily: 'Rajdhani', fontSize: 12,
                      fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9945FF).withValues(alpha: 0.2),
                    foregroundColor: const Color(0xFF9945FF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(
                        color: Color(0xFF9945FF), width: 1)),
                    elevation: 0,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ErrorHandlerService().clearAll();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  icon: const Icon(Icons.home_outlined, size: 16),
                  label: const Text('Startseite',
                    style: TextStyle(fontFamily: 'Rajdhani', fontSize: 12,
                      fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white.withValues(alpha: 0.6),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
