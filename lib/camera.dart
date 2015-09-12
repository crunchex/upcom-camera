library cmdr_camera;

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:isolate';

import 'package:upcom-api/tab_backend.dart';
import 'package:upcom-api/debug.dart';
import 'package:upcom-api/ros.dart';

part 'src/camera_server.dart';

class CmdrCamera extends Tab {
  static final List<String> names = ['upcom-camera', 'UpDroid Camera', 'Camera'];

  StreamSubscription _currentDeviceSub;
  int _currentDeviceId;

  CmdrCamera(SendPort sp, args) :
  super(CmdrCamera.names, sp, args) {

  }

  void registerMailbox() {
    mailbox.registerMessageHandler('SIGNAL_READY', _signalReady);

    _getDeviceIds().forEach((int key) {
      mailbox.registerEndPointHandler('/$refName/$id/input/$key', _handleInputStream);
    });
  }

  void _signalReady(UpDroidMessage) {
    ProcessResult result = Process.runSync('bash', ['-c', 'ffmpeg --help']);
    if (result.exitCode == 127) {
      mailbox.send(new Msg('NO_FFMPEG', ''));
      return;
    }

    mailbox.send(new Msg('CAMERA_READY', JSON.encode(_getDeviceIds())));
  }

  void _handleInputStream(String endpoint, String s) {
    _currentDeviceId = int.parse(endpoint.split('/').last);
    if (CameraServer.servers[_currentDeviceId] == null) {
      CameraServer.servers[_currentDeviceId] = new CameraServer(_currentDeviceId);
    }
    // request.uri is updroidcamera/id/input
    if (_currentDeviceSub != null) {
      CameraServer.servers[_currentDeviceId].unsubscribeToString(_currentDeviceSub);
    }
    mailbox.send(new Msg(endpoint, JSON.encode(CameraServer.streamHeader)));
    _currentDeviceSub = CameraServer.servers[_currentDeviceId].subscribeToStream().listen((data) {
      mailbox.send(new Msg(endpoint, JSON.encode(data)));
    });
  }

  void _startUsbCam() {
    String sourceCommand = '/opt/ros/indigo/setup.bash';
    String runCommand = sourceCommand + ' && roslaunch ';
    Process.start('bash', ['-c', '. $runCommand'], runInShell: true);
  }

  void _startMjpegServer() {

  }

  List<int> _getDeviceIds() {
    ProcessResult result = Process.runSync('bash', ['-c', 'find /dev -name "video*"']);
    List<String> rawDevices = result.stdout.split(new RegExp('/dev/video|\n'));
    rawDevices.removeWhere((String s) => s == '');

    List<int> deviceIds = [];
    rawDevices.forEach((String id) => deviceIds.add(int.parse(id)));
    return deviceIds;
  }

  void cleanup() {
    if (_currentDeviceSub != null) {
      CameraServer.servers[_currentDeviceId].unsubscribeToString(_currentDeviceSub);
    }

    CameraServer.servers[_currentDeviceId].cleanup().then((bool serverClean) {
      if (serverClean) CameraServer.servers.remove(_currentDeviceId);
    });
  }
}