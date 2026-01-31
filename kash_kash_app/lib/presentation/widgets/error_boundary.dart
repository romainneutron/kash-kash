import 'package:flutter/material.dart';

import 'error_view.dart';

/// A widget that catches errors in its child widget tree and displays an error view.
///
/// This is useful for catching provider exceptions or other runtime errors
/// that would otherwise cause a red screen of death.
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRetry;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.onRetry,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    // Reset error when widget is rebuilt
    _error = null;
  }

  void _handleRetry() {
    setState(() {
      _error = null;
    });
    widget.onRetry?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorView(
        message: 'Something went wrong. Please try again.',
        onRetry: _handleRetry,
      );
    }

    return _ErrorBoundaryInherited(
      onError: (error) {
        if (mounted) {
          setState(() {
            _error = error;
          });
        }
      },
      child: widget.child,
    );
  }
}

/// Inherited widget to propagate error handling down the tree.
class _ErrorBoundaryInherited extends InheritedWidget {
  final void Function(Object error) onError;

  const _ErrorBoundaryInherited({
    required this.onError,
    required super.child,
  });

  static _ErrorBoundaryInherited? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ErrorBoundaryInherited>();
  }

  @override
  bool updateShouldNotify(_ErrorBoundaryInherited oldWidget) => false;
}

/// Extension to report errors to the nearest ErrorBoundary.
extension ErrorBoundaryContext on BuildContext {
  /// Report an error to the nearest ErrorBoundary.
  void reportError(Object error) {
    _ErrorBoundaryInherited.of(this)?.onError(error);
  }
}
