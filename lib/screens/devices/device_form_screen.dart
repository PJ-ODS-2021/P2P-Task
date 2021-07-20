import 'package:flutter/material.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/viewmodels/device_list_viewmodel.dart';
import 'package:provider/provider.dart';

class DeviceFormScreen extends StatefulWidget {
  final PeerInfo? _template;

  DeviceFormScreen({PeerInfo? template}) : _template = template;

  @override
  _DeviceFormScreenState createState() =>
      _DeviceFormScreenState(template: _template);
}

class _DeviceFormScreenState extends State<DeviceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: '');
  final _idController = TextEditingController(text: '');
  final _ipController = TextEditingController(text: '');
  final _publicKeyController = TextEditingController(text: '');
  final _portController = TextEditingController(text: '');
  final _nameFocusNode = FocusNode();
  final _idFocusNode = FocusNode();
  final _ipFocusNode = FocusNode();
  final _publicKeyFocusNode = FocusNode();
  final _portFocusNode = FocusNode();
  final _isPeerInfoTemplate;

  _DeviceFormScreenState({PeerInfo? template})
      : _isPeerInfoTemplate = template != null {
    if (template != null) {
      _nameController.text = template.name;
      _idController.text = template.id ?? '';
      _publicKeyController.text = template.publicKeyPem;
      _ipFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isPeerInfoTemplate ? 'Add Device Location' : 'Add Device'),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(15.0),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  autofocus: true,
                  readOnly: _isPeerInfoTemplate,
                  focusNode: _nameFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Name',
                    filled: true,
                    fillColor: Colors.purple[50],
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Give the device a name.';
                    }

                    return null;
                  },
                  onFieldSubmitted: (value) {
                    if (value.isNotEmpty) _ipFocusNode.requestFocus();
                    _nameFocusNode.requestFocus();
                  },
                ),
                SizedBox(
                  height: 15,
                ),
                TextFormField(
                  autofocus: true,
                  readOnly: _isPeerInfoTemplate,
                  focusNode: _idFocusNode,
                  decoration: InputDecoration(
                    hintText: 'ID',
                    filled: true,
                    fillColor: Colors.purple[50],
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  controller: _idController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Give the device an id.';
                    }

                    return null;
                  },
                  onFieldSubmitted: (value) {
                    _idFocusNode.requestFocus();
                  },
                ),
                SizedBox(
                  height: 15,
                ),
                TextFormField(
                  readOnly: _isPeerInfoTemplate,
                  focusNode: _publicKeyFocusNode,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Public Key',
                    filled: true,
                    fillColor: Colors.purple[50],
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  controller: _publicKeyController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'The publicKey address is missing.';
                    }

                    return null;
                  },
                  onFieldSubmitted: (value) {
                    _publicKeyFocusNode.requestFocus();
                  },
                ),
                SizedBox(
                  height: 15,
                ),
                TextFormField(
                  focusNode: _ipFocusNode,
                  decoration: InputDecoration(
                    hintText: 'IP Address',
                    filled: true,
                    fillColor: Colors.purple[50],
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  controller: _ipController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'The IP address is missing.';
                    }
                    if (value.contains(' ')) {
                      return 'The IP may not contain spaces';
                    }

                    return null;
                  },
                  onFieldSubmitted: (value) {
                    if (value.isNotEmpty) _portFocusNode.requestFocus();
                    _ipFocusNode.requestFocus();
                  },
                ),
                SizedBox(
                  height: 15,
                ),
                TextFormField(
                  focusNode: _portFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Port',
                    filled: true,
                    fillColor: Colors.purple[50],
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  controller: _portController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'The port is missing.';
                    }
                    var port = int.parse(value);
                    if (port < 49152 || port > 65535) {
                      return 'The port must be in the range 49152 to 65535';
                    }

                    return null;
                  },
                  onFieldSubmitted: (value) {
                    if (value.isNotEmpty && _formKey.currentState!.validate()) {
                      _handleSubmit();
                    }
                    _portFocusNode.requestFocus();
                  },
                ),
                SizedBox(height: 15),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: MaterialButton(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        color: Theme.of(context).accentColor,
                        onPressed: () {
                          _formKey.currentState?.save();
                          if (_formKey.currentState!.validate()) {
                            _handleSubmit();
                          }
                        },
                        child: Text(
                          'Submit',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: MaterialButton(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        color: Theme.of(context).accentColor,
                        onPressed: () {
                          _formKey.currentState?.reset();
                        },
                        child: Text(
                          'Reset',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() async {
    var location =
        PeerLocation('ws://${_ipController.text}:${_portController.text}');

    final peerInfo = PeerInfo(
      name: _nameController.text,
      status: Status.created,
      publicKeyPem: _publicKeyController.text,
      id: _idController.text,
      locations: [location],
    );

    var viewModel = Provider.of<DeviceListViewModel>(context, listen: false);
    await viewModel.addNewPeer(peerInfo);

    Navigator.of(context).pop();
  }
}
