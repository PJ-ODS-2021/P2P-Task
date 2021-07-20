import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:p2p_task/widgets/list_section.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutListSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListSection(
      title: 'About',
      children: [
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            return Column(
              children: [
                ListTile(
                  tileColor: Colors.white,
                  leading: Icon(Icons.report_gmailerrorred_rounded),
                  title: Text('App Name'),
                  subtitle: Text(
                    snapshot.hasData ? snapshot.data!.appName : '',
                  ),
                ),
                Divider(
                  height: 1.0,
                ),
                ListTile(
                  tileColor: Colors.white,
                  leading: Icon(Icons.architecture_rounded),
                  title: Text('App Version'),
                  subtitle: Text(
                    snapshot.hasData ? snapshot.data!.version : '',
                  ),
                ),
              ],
            );
          },
        ),
        ListTile(
          tileColor: Colors.white,
          leading: Icon(Icons.help_outline_rounded),
          title: Text('Licenses'),
          subtitle: FutureBuilder(
            future: LicenseRegistry.licenses.length,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Text('');

              return Text(snapshot.data.toString());
            },
          ),
          onTap: () => showLicensePage(context: context),
        ),
      ],
    );
  }
}
