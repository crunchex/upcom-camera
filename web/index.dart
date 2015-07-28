import 'dart:html';
import 'camera.dart';

void main() {
  ScriptElement jsmpgJs = new ScriptElement()
    ..type = 'text/javascript'
    ..src = 'tabs/upcom-camera/jsmpg.js';
  document.body.children.add(jsmpgJs);

  jsmpgJs.onLoad.first.then((_) {
    new UpDroidCamera(jsmpgJs);
  });
}