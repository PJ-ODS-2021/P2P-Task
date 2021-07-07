import 'package:flutter/cupertino.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/peer_service.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class PullToSyncWidget extends StatelessWidget {
  PullToSyncWidget({required this.child});

  /// The used package _pull\_to\_refresh_ requires the use of ListView as a
  /// child according to the package documentation.
  ///
  /// See [Usage](https://pub.dev/packages/pull_to_refresh#usage) section of
  /// the _pull\_to\_refresh_ package.
  final ListView child;
  final RefreshController _refreshController = RefreshController();

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      enablePullDown: true,
      controller: _refreshController,
      onRefresh: () => _handleRefresh(context),
      header: MaterialClassicHeader(),
      child: child,
    );
  }

  void _handleRefresh(BuildContext context) async {
    final peerService =
        Provider.of<ChangeCallbackNotifier<PeerService>>(context, listen: false)
            .callbackProvider;

    await peerService.syncWithAllKnownPeers();
    _refreshController.refreshCompleted();
  }
}
