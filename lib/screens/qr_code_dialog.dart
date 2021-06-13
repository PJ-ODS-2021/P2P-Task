import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/network_info_service.dart';
import 'package:p2p_task/services/peer_service.dart';
import 'package:p2p_task/utils/log_mixin.dart';
import 'package:provider/provider.dart';
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
    final peerService =
        Provider.of<ChangeCallbackNotifier<PeerService>>(context)
            .callbackProvider;

    // size calculation is very hacky:
    final windowSize = MediaQuery.of(context).size;
    final smallestSide = (windowSize.width < windowSize.height
            ? windowSize.width
            : (windowSize.height - 60)) -
        175;

    return SimpleDialog(
      title: Text('Scan QR Code'),
      children: [
        FutureBuilder<List<dynamic>>(
          future: Future.wait(
              [identityService.name, identityService.ip, identityService.port]),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Column(
                children: [Text('Error'), Text(snapshot.error.toString())],
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting ||
                !snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final storedDeviceName = snapshot.data![0] as String;
            final storedIp = snapshot.data![1] as String?;
            final storedPort = snapshot.data![2] as int;

            final ips = networkInfoService.ips;
            final selectedIp = _selectIp(ips, storedIp);
            if (selectedIp != storedIp && selectedIp != null)
              identityService.setIp(selectedIp);

            return Column(children: [
              if (!peerService.isServerRunning)
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: const [
                      WidgetSpan(child: Icon(Icons.warning_outlined)),
                      TextSpan(
                          text: ' The server is not running',
                          style: TextStyle(fontSize: 20.0)),
                    ],
                  ),
                ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('IP: '),
                DropdownButton<String>(
                    value: selectedIp,
                    items: ips
                        .map((e) =>
                            DropdownMenuItem<String>(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null && value != selectedIp)
                        identityService.setIp(value);
                    }),
                Padding(padding: EdgeInsets.symmetric(horizontal: 10.0)),
                Text('Port: $storedPort'),
              ]),
              if (selectedIp != null)
                Center(
                  child: SizedBox(
                    width: smallestSide,
                    height: smallestSide,
                    child: QrImage(
                        data: _makeQrContent(
                            storedDeviceName, selectedIp, storedPort),
                        version: QrVersions.auto),
                  ),
                )
            ]);
          },
        ),
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text('Close')),
      ],
    );
  }

  String? _selectIp(UnmodifiableListView<String> ips, String? storedIp) {
    if (ips.contains(storedIp)) return storedIp;
    return ips.isNotEmpty ? ips.first : null;
  }

  String _makeQrContent(String deviceName, String ip, int port) =>
      '$deviceName,$ip,$port';
}
