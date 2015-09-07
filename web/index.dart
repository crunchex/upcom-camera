import 'dart:html';
import 'package:quiver/async.dart';
import 'camera.dart';

void main() {
//  ScriptElement jsmpgJs = new ScriptElement()
//    ..type = 'text/javascript'
//    ..src = 'tabs/upcom-camera/jsmpg.js';
//  document.body.children.add(jsmpgJs);

  ScriptElement eventEmitter2 = new ScriptElement()
    ..type = 'text/javascript'
    ..src = 'tabs/upcom-camera/eventemitter2.min.js';
  document.body.children.add(eventEmitter2);

  ScriptElement mjpegCanvas = new ScriptElement()
    ..type = 'text/javascript'
    ..src = 'tabs/upcom-camera/mjpegcanvas.min.js';
  document.body.children.add(mjpegCanvas);

  FutureGroup futureGroup = new FutureGroup();
  futureGroup.add(eventEmitter2.onLoad.first);
  futureGroup.add(mjpegCanvas.onLoad.first);

  futureGroup.future.then((_) {
    new UpDroidCamera([eventEmitter2, mjpegCanvas]);
  });
}