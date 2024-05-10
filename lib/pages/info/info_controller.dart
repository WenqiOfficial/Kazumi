import 'package:kazumi/modules/bangumi/calendar_module.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:kazumi/modules/plugins/plugins_module.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

part 'info_controller.g.dart';

class InfoController = _InfoController with _$InfoController;

abstract class _InfoController with Store {
  late BangumiItem bangumiItem;

  querySource(String keyword) async {
    final PluginsController pluginsController = Modular.get<PluginsController>();
    for (Plugin plugin in pluginsController.pluginList) {
      plugin.queryBangumi(keyword);
    }
  }
}