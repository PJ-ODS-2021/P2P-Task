import 'package:flutter/material.dart';
import 'package:p2p_task/services/identity_service.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final identityService =
        Provider.of<IdentityService>(context, listen: false);
    final size = MediaQuery.of(context).size;
    final smallestSide =
        (size.width < size.height ? size.width : size.height) - 175;

    return SimpleDialog(
      title: Text('Scan QR Code'),
      children: [
        FutureBuilder<List<dynamic>>(
          future: Future.wait([
            identityService.name,
            identityService.ip,
            identityService.port,
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  Text('Error'),
                  Text(snapshot.error.toString()),
                ],
              );
            }
            final content =
                snapshot.data!.reduce((value, element) => '$value,$element');

            return Center(
              child: SizedBox(
                width: smallestSide,
                height: smallestSide,
                child: QrImage(
                  data: content,
                  version: QrVersions.auto,
                ),
              ),
            );
          },
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }
}
