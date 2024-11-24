import 'package:bangumi/pages/webdav_editor/webdav_editor_page.dart';
import 'package:bangumi/pages/webdav_editor/webdav_setting.dart';
import 'package:flutter_modular/flutter_modular.dart';

class WebDavModule extends Module {
  @override
  void binds(i) {}

  @override
  void routes(r) {
    r.child("/", child: (_) => const WebDavSettingsPage());
    r.child("/editor",
        child: (_) => const WebDavEditorPage(),);
  }
}
