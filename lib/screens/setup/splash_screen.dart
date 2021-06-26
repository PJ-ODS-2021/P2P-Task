import 'package:flutter/material.dart';
import 'package:p2p_task/widgets/fade_route_builder.dart';

class SplashScreen<T> extends StatefulWidget {
  final Future<T> future;
  final Widget Function(T) onLoaded;
  final String caption;
  final Duration minDuration;

  SplashScreen(
    this.future,
    this.onLoaded,
    this.caption, {
    Duration? minDuration,
  }) : minDuration = minDuration ?? Duration(milliseconds: 300);

  @override
  State<SplashScreen<T>> createState() => _SplashScreenState<T>();
}

class _SplashScreenState<T> extends State<SplashScreen<T>> {
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.minDuration, () {
      widget.future.then(
        (value) => Navigator.of(context).pushReplacement(FadeRoute(
          (_) => widget.onLoaded(value),
        )),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'P2P Task App',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: height * 0.5,
          ),
          Text(
            widget.caption,
            style: TextStyle(color: Colors.white),
          ),
          Divider(
            height: 16,
            color: Colors.transparent,
          ),
          CircularProgressIndicator.adaptive(
            backgroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
