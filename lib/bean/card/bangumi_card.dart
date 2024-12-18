import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:bangumi/utils/constans.dart';
import 'package:bangumi/utils/utils.dart';
import 'package:bangumi/modules/bangumi/bangumi_item.dart';
import 'package:bangumi/bean/card/network_img_layer.dart';
import 'package:bangumi/pages/info/info_controller.dart';
import 'package:bangumi/pages/popular/popular_controller.dart';

// 视频卡片 - 垂直布局
class BangumiCardV extends StatelessWidget {
  const BangumiCardV({
    super.key,
    required this.bangumiItem,
    this.canTap = true,
    this.longPress,
    this.longPressEnd,
  });

  final BangumiItem bangumiItem;
  final bool canTap;
  final Function()? longPress;
  final Function()? longPressEnd;

  @override
  Widget build(BuildContext context) {
    String heroTag = Utils.makeHeroTag(bangumiItem.id);
    final InfoController infoController = Modular.get<InfoController>();
    final PopularController popularController =
        Modular.get<PopularController>();
    return Card(
      elevation: 0,
      clipBehavior: Clip.hardEdge,
      margin: EdgeInsets.zero,
      child: GestureDetector(
        child: InkWell(
          onTap: () {
            if (!canTap) {
              SmartDialog.showToast('编辑模式',
                  displayType: SmartToastType.onlyRefresh);
              return;
            }
            infoController.bangumiItem = bangumiItem;
            if (popularController.searchKeyword == '') {
              popularController.keyword = bangumiItem.nameCn == ''
                  ? bangumiItem.name
                  : (bangumiItem.nameCn);
            } else {
              popularController.keyword = popularController.searchKeyword;
            }
            Modular.to.pushNamed('/info/');
          },
          child: Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: StyleString.imgRadius,
                  topRight: StyleString.imgRadius,
                  bottomLeft: StyleString.imgRadius,
                  bottomRight: StyleString.imgRadius,
                ),
                child: AspectRatio(
                  aspectRatio: 0.65,
                  child: LayoutBuilder(builder: (context, boxConstraints) {
                    final double maxWidth = boxConstraints.maxWidth;
                    final double maxHeight = boxConstraints.maxHeight;
                    return Stack(
                      children: [
                        Hero(
                          tag: heroTag,
                          child: NetworkImgLayer(
                            src: bangumiItem.images['large'] ?? '',
                            width: maxWidth,
                            height: maxHeight,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              BangumiContent(bangumiItem: bangumiItem)
            ],
          ),
        ),
      ),
    );
  }
}

class BangumiContent extends StatelessWidget {
  const BangumiContent({super.key, required this.bangumiItem});
  final BangumiItem bangumiItem;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        // 多列
        padding: const EdgeInsets.fromLTRB(5, 3, 5, 0),
        // 单列
        // padding: const EdgeInsets.fromLTRB(14, 10, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(
                  bangumiItem.nameCn,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                  maxLines: Utils.isDesktop() || Utils.isTablet() ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                )),
              ],
            ),
            const SizedBox(height: 1),
          ],
        ),
      ),
    );
  }
}
