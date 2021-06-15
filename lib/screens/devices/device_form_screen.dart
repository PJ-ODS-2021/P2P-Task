import 'package:flutter/material.dart';
import 'package:p2p_task/models/peer_info.dart';
import 'package:p2p_task/services/change_callback_notifier.dart';
import 'package:p2p_task/services/peer_info_service.dart';
import 'package:provider/provider.dart';

class DeviceFormScreen extends StatefulWidget {
  @override
  _DeviceFormScreenState createState() => _DeviceFormScreenState();
}

class _DeviceFormScreenState extends State<DeviceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: '');
  final _ipController = TextEditingController(text: '');
  final _portController = TextEditingController(text: '');
  final _nameFocusNode = FocusNode();
  final _ipFocusNode = FocusNode();
  final _portFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Device'),
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
                  focusNode: _nameFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Name',
                    filled: true,
                    fillColor: Colors.purple[50],
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.length < 1)
                      return 'Give the device a name.';
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
                  focusNode: _ipFocusNode,
                  decoration: InputDecoration(
                    hintText: 'IP Address',
                    filled: true,
                    fillColor: Colors.purple[50],
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  controller: _ipController,
                  validator: (value) {
                    if (value == null || value.length < 1)
                      return 'The IP address is missing.';
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
                    if (value == null || value.length < 1)
                      return 'The port is missing.';
                    int port = int.parse(value);
                    if (port < 49152 || port > 65535)
                      return 'The port must be in the range 49152 to 65535';
                    return null;
                  },
                  onFieldSubmitted: (value) {
                    if (value.isNotEmpty && _formKey.currentState!.validate()) {
                      _onSubmit();
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
                        child: Text(
                          "Submit",
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          _formKey.currentState?.save();
                          if (_formKey.currentState!.validate()) {
                            _onSubmit();
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: MaterialButton(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        color: Theme.of(context).accentColor,
                        child: Text(
                          "Reset",
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          _formKey.currentState?.reset();
                        },
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

  void _onSubmit() {
    Provider.of<ChangeCallbackNotifier<PeerInfoService>>(context, listen: false)
        .callbackProvider
        .addPeerLocation(PeerInfo()..name = _nameController.text,
            PeerLocation('ws://${_ipController.text}:${_portController.text}'));
    Navigator.of(context).pop();
  }
}
