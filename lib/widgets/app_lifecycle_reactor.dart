import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:p2p_task/utils/log_mixin.dart';

typedef VoidCallback = void Function();

class AppLifecycleReactor extends StatefulWidget with LogMixin {
  final Widget child;
  final VoidCallback? onResume;
  final VoidCallback? onInactive;
  final VoidCallback? onPaused;
  final VoidCallback? onDetached;

  AppLifecycleReactor({
    Key? key,
    required Widget child,
    this.onResume,
    this.onInactive,
    this.onPaused,
    this.onDetached,
  })  : child = child,
        assert(onResume != null ||
            onInactive != null ||
            onPaused != null ||
            onDetached != null),
        super(key: key);

  @override
  State<AppLifecycleReactor> createState() => _AppLifecycleReactorState();
}

class _AppLifecycleReactorState extends State<AppLifecycleReactor>
    with WidgetsBindingObserver, LogMixin {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        l.info('App resumed.');
        if (widget.onResume != null) widget.onResume!();
        break;
      case AppLifecycleState.inactive:
        l.info('App inactive.');
        if (widget.onInactive != null) widget.onInactive!();
        break;
      case AppLifecycleState.paused:
        l.info('App paused.');
        if (widget.onPaused != null) widget.onPaused!();
        break;
      case AppLifecycleState.detached:
        l.info('App detached.');
        if (widget.onDetached != null) widget.onDetached!();
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }
}
