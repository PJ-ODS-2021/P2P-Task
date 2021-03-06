import 'package:flutter/material.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/network_info_service.dart';
import 'package:p2p_task/services/peer_service.dart';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:provider/provider.dart';
import 'package:p2p_task/viewmodels/device_list_viewmodel.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeDialog extends StatelessWidget with LogMixin {
  @override
  Widget build(BuildContext context) {
    final identityService =
        Provider.of<ChangeCallbackNotifier<IdentityService>>(context)
            .callbackProvider;
    final networkInfoService =
        Provider.of<ChangeCallbackNotifier<NetworkInfoService>>(context)
            .callbackProvider;

    return SimpleDialog(
      title: Text('Scan QR Code'),
      children: [
        FutureBuilder<List>(
          future: Future.wait([
            identityService.name,
            identityService.ip,
            identityService.port,
            identityService.peerId,
            identityService.publicKeyPem,
          ]),
          builder: (context, snapshot) {
            final loadingWidget = _createLoadingWidget(snapshot);
            if (loadingWidget != null) return loadingWidget;

            final storedIp = snapshot.data![1] as String?;
            final ips = networkInfoService.ips;
            final connectionInfo = _ConnectionInfo(
              selectedIp: _selectIp(ips, storedIp),
              ips: ips,
              port: snapshot.data![2] as int,
              deviceName: snapshot.data![0] as String,
              peerID: snapshot.data![3] as String,
              publicKeyPem: snapshot.data![4] as String,
            );
            if (connectionInfo.selectedIp != null &&
                connectionInfo.selectedIp != storedIp) {
              identityService.setIp(connectionInfo.selectedIp!);
            }

            return Column(children: [
              ..._createServerNotRunningWidgets(context),
              ..._createServerConnectionInfoWidgets(
                context,
                connectionInfo,
                identityService,
              ),
              ..._createQrWidgets(
                connectionInfo,
                _calculateQrCodeSize(context),
              ),
            ]);
          },
        ),
        TextButton(
          onPressed: () {
            var viewmodel =
                Provider.of<DeviceListViewModel>(context, listen: false);
            viewmodel.loadDevices();
            Navigator.pop(context);
          },
          child: Text('Close'),
        ),
      ],
    );
  }

  /// returns a widget to be displayed if the snapshot is not ready
  Widget? _createLoadingWidget(AsyncSnapshot snapshot) {
    if (snapshot.hasError) {
      return Column(
        children: [
          Text('Error'),
          Text(
            snapshot.error.toString(),
          ),
        ],
      );
    }
    if (snapshot.connectionState == ConnectionState.waiting ||
        !snapshot.hasData) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return null;
  }

  List<Widget> _createServerNotRunningWidgets(BuildContext context) {
    final peerService =
        Provider.of<ChangeCallbackNotifier<PeerService>>(context)
            .callbackProvider;

    return [
      if (!peerService.isServerRunning)
        _buildWarningText(
          context,
          'The server is not running',
        ),
    ];
  }

  List<Widget> _createServerConnectionInfoWidgets(
    BuildContext context,
    _ConnectionInfo connectionInfo,
    IdentityService identityService,
  ) {
    return connectionInfo.ips.isEmpty
        ? [_buildWarningText(context, 'Cannot detect connection info')]
        : [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('IP: '),
              connectionInfo.ips.length > 1
                  ? DropdownButton<String>(
                      value: connectionInfo.selectedIp,
                      items: connectionInfo.ips
                          .map((e) => DropdownMenuItem<String>(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null &&
                            value != connectionInfo.selectedIp) {
                          identityService.setIp(value);
                        }
                      },
                    )
                  : Text(connectionInfo.ips.first),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
              ),
              Text('Port: ${connectionInfo.port}'),
            ]),
          ];
  }

  Widget _buildWarningText(BuildContext context, String message) {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          WidgetSpan(
            child: Icon(Icons.warning_outlined),
          ),
          TextSpan(
            text: ' $message',
            style: TextStyle(fontSize: 20.0),
          ),
        ],
      ),
    );
  }

  List<Widget> _createQrWidgets(
    _ConnectionInfo connectionInfo,
    double displaySize,
  ) {
    return [
      if (connectionInfo.selectedIp != null)
        Center(
          child: Container(
            width: displaySize,
            height: displaySize,
            constraints: BoxConstraints(
              maxWidth: 350.0,
              maxHeight: 350.0,
            ),
            child: QrImage(
              data: _makeQrContent(
                connectionInfo.deviceName,
                connectionInfo.selectedIp!,
                connectionInfo.port,
                connectionInfo.publicKeyPem,
                connectionInfo.peerID,
              ),
              version: QrVersions.auto,
            ),
          ),
        ),
    ];
  }

  String? _selectIp(List<String> ips, String? storedIp) {
    if (ips.contains(storedIp)) return storedIp;

    return ips.isNotEmpty ? ips.first : null;
  }

  // ignore: long-parameter-list
  String _makeQrContent(
    String name,
    String ip,
    int port,
    String publicKey,
    String peerID,
  ) {
    return '$peerID,$name,$ip,$port,$publicKey';
  }

  /// size calculation is very hacky
  double _calculateQrCodeSize(BuildContext context) {
    final windowSize = MediaQuery.of(context).size;

    return (windowSize.width < windowSize.height
            ? windowSize.width
            : (windowSize.height - 60)) -
        175;
  }
}

class _ConnectionInfo {
  final String? selectedIp;
  final List<String> ips;
  final int port;
  final String deviceName;
  final String peerID;
  final String publicKeyPem;

  const _ConnectionInfo({
    required this.selectedIp,
    required this.ips,
    required this.port,
    required this.deviceName,
    required this.peerID,
    required this.publicKeyPem,
  });
}
