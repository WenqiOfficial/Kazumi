import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:video_player/video_player.dart';
import 'package:bangumi/modules/danmaku/danmaku_module.dart';
import 'package:mobx/mobx.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:bangumi/request/damaku.dart';
import 'package:bangumi/pages/video/video_controller.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hive/hive.dart';
import 'package:bangumi/utils/storage.dart';
import 'package:logger/logger.dart';
import 'package:bangumi/utils/logger.dart';
import 'package:bangumi/utils/utils.dart';

part 'player_controller.g.dart';

class PlayerController = _PlayerController with _$PlayerController;

abstract class _PlayerController with Store {
  @observable
  bool loading = true;

  String videoUrl = '';
  // dandanPlay弹幕ID
  int bangumiID = 0;
  late VideoPlayerController mediaPlayer;
  late DanmakuController danmakuController;
  final VideoPageController videoPageController =
      Modular.get<VideoPageController>();

  @observable
  Map<int, List<Danmaku>> danDanmakus = {};

  @observable
  bool playing = false;
  @observable
  bool isBuffering = true;
  @observable
  bool completed = false;
  @observable
  Duration currentPosition = Duration.zero;
  @observable
  Duration buffer = Duration.zero;
  @observable
  Duration duration = Duration.zero;

  // 弹幕开关
  @observable
  bool danmakuOn = false;

  // 视频音量/亮度
  @observable
  double volume = 0;
  @observable
  double brightness = 0;

  // 播放器倍速
  @observable
  double playerSpeed = 1.0;

  Box setting = GStorage.setting;
  late bool hAenable;

  Future init({int offset = 0}) async {
    playing = false;
    loading = true;
    isBuffering = true;
    currentPosition = Duration.zero;
    buffer = Duration.zero;
    duration = Duration.zero;
    completed = false;
    try {
      mediaPlayer.dispose();
    } catch (_) {}
    bangumiLogger().log(Level.info, 'VideoItem开始初始化');
    int episodeFromTitle = 0;
    try {
      episodeFromTitle = Utils.extractEpisodeNumber(videoPageController.roadList[videoPageController.currentRoad].identifier[videoPageController.currentEspisode - 1]);
    } catch (e) {
      bangumiLogger().log(Level.error, '从标题解析集数错误 ${e.toString()}');
    }
    if (episodeFromTitle == 0) {
      episodeFromTitle = videoPageController.currentEspisode;
    }
    getDanDanmaku(
        videoPageController.title, episodeFromTitle);
    mediaPlayer = await createVideoController();
    bool aotoPlay = setting.get(SettingBoxKey.autoPlay, defaultValue: true);
    playerSpeed = setting.get(SettingBoxKey.defaultPlaySpeed, defaultValue: 1.0);
    if (offset != 0) {
      await mediaPlayer.seekTo(Duration(seconds: offset));
    }
    if (aotoPlay) {
      await mediaPlayer.play();
    }
    setPlaybackSpeed(playerSpeed);
    bangumiLogger().log(Level.info, 'VideoURL初始化完成');
    // 加载弹幕
    loading = false;
  }

  Future<VideoPlayerController> createVideoController() async {
    String userAgent = '';
    if (videoPageController.currentPlugin.userAgent == '') {
      userAgent = Utils.getRandomUA();
    } else {
      userAgent = videoPageController.currentPlugin.userAgent;
    }
    bangumiLogger().log(Level.info, 'media_kit UA: $userAgent');
    String referer = videoPageController.currentPlugin.referer;
    bangumiLogger().log(Level.info, 'media_kit Referer: $referer');
    var httpHeaders = {
      'user-agent': userAgent,
      if (referer.isNotEmpty) 'referer': referer,
    };
    mediaPlayer = VideoPlayerController.networkUrl(Uri.parse(videoUrl),
        httpHeaders: httpHeaders);
    mediaPlayer.addListener(() {
      if (mediaPlayer.value.hasError && !mediaPlayer.value.isCompleted) {
        SmartDialog.showToast('播放器内部错误 ${mediaPlayer.value.errorDescription}');
        bangumiLogger().log(Level.error, 'Player inent error. ${mediaPlayer.value.errorDescription} $videoUrl');
      }
    });
    await mediaPlayer.initialize();
    bangumiLogger().log(Level.info, 'videoController 配置成功 $videoUrl');
    return mediaPlayer;
  }

  Future setPlaybackSpeed(double playerSpeed) async {
    this.playerSpeed = playerSpeed;
    try {
      mediaPlayer.setPlaybackSpeed(playerSpeed);
    } catch (e) {
      bangumiLogger().log(Level.error, '设置播放速度失败 ${e.toString()}');
    }
  }

  Future playOrPause() async {
    if (mediaPlayer.value.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future seek(Duration duration) async {
    danmakuController.clear();
    await mediaPlayer.seekTo(duration);
  }

  Future pause() async {
    danmakuController.pause();
    await mediaPlayer.pause();
    playing = false;
  }

  Future play() async {
    danmakuController.resume();
    await mediaPlayer.play();
    playing = true;
  }

  Future getDanDanmaku(String title, int episode) async {
    bangumiLogger().log(Level.info, '尝试获取弹幕 $title');
    try {
      danDanmakus.clear();
      bangumiID = await DanmakuRequest.getBangumiID(title);
      var res = await DanmakuRequest.getDanDanmaku(bangumiID, episode);
      addDanmakus(res);
    } catch (e) {
      bangumiLogger().log(Level.warning, '获取弹幕错误 ${e.toString()}');
    }
  }

  Future getDanDanmakuByEpisodeID(int episodeID) async {
    bangumiLogger().log(Level.info, '尝试获取弹幕 $episodeID');
    try {
      danDanmakus.clear();
      var res = await DanmakuRequest.getDanDanmakuByEpisodeID(episodeID);
      addDanmakus(res);
    } catch (e) {
      bangumiLogger().log(Level.warning, '获取弹幕错误 ${e.toString()}');
    }
  }

  void addDanmakus(List<Danmaku> danmakus) {
    for (var element in danmakus) {
      var danmakuList =
          danDanmakus[element.time.toInt()] ?? List.empty(growable: true);
      danmakuList.add(element);
      danDanmakus[element.time.toInt()] = danmakuList;
    }
  }
}
