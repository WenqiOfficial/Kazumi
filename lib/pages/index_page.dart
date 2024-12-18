import 'package:bangumi/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:bangumi/pages/menu/menu.dart';
import 'package:bangumi/pages/menu/side_menu.dart';


class IndexPage extends StatefulWidget {
  //const IndexPage({super.key});
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> with  WidgetsBindingObserver {

  @override
  Widget build(BuildContext context) {
    return (!Utils.isCompact()) ? const SideMenu() : const BottomMenu();
  }
}
