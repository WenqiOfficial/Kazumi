import 'package:logger/logger.dart';
import 'package:bangumi/utils/logger.dart';
import 'package:bangumi/utils/constans.dart';
import 'package:dio/dio.dart';
import 'package:bangumi/request/api.dart';
import 'package:bangumi/request/request.dart';
import 'package:bangumi/modules/bangumi/bangumi_item.dart';

class BangumiHTTP {
  // why the api havn't been replaced by getCalendarBySearch?
  // Beacause getCalendarBySearch is not stable, it will miss some bangumi items.
  static Future getCalendar() async {
    List<List<BangumiItem>> bangumiCalendar = [];
    try {
      var res = await Request().get(Api.bangumiCalendar,
          options: Options(headers: bangumiHTTPHeader));
      final jsonData = res.data;
      bangumiLogger()
          .log(Level.info, 'The length of clendar is ${jsonData.length}');
      for (dynamic jsonDayList in jsonData) {
        List<BangumiItem> bangumiList = [];
        final jsonList = jsonDayList['items'];
        for (dynamic jsonItem in jsonList) {
          try {
            BangumiItem bangumiItem = BangumiItem.fromJson(jsonItem);
            if (bangumiItem.nameCn != '') {
              bangumiList.add(bangumiItem);
            }
          } catch (_) {}
        }
        bangumiCalendar.add(bangumiList);
      }
    } catch (e) {
      bangumiLogger()
          .log(Level.error, 'Resolve calendar failed ${e.toString()}');
    }
    return bangumiCalendar;
  }

  // Get clander by search API, we need a list of strings (the start of the season and the end of the season) eg: ["2024-07-01", "2024-10-01"]
  // because the air date is the launch date of the anime, it is usually a few days before the start of the season
  // So we usually use the start of the season month -1 and the end of the season month -1
  static Future getCalendarBySearch(List<String> dateRange) async {
    List<BangumiItem> bangumiList = [];
    List<List<BangumiItem>> bangumiCalendar = [];
    var params = <String, dynamic>{
      "keyword": "",
      "filter": {
        "type": [2],
        "tag": ["日本"],
        "air_date": [">=${dateRange[0]}", "<${dateRange[1]}"],
        "rank": [">0", "<=99999"],
        "nsfw": true
      }
    };
    try {
      final res = await Request().post(Api.bangumiRankSearch,
          data: params,
          options: Options(
              headers: bangumiHTTPHeader, contentType: 'application/json'));
      final jsonData = res.data;
      final jsonList = jsonData['data'];
      for (dynamic jsonItem in jsonList) {
        if (jsonItem is Map<String, dynamic>) {
          bangumiList.add(BangumiItem.fromJson(jsonItem));
        }
      }
    } catch (e) {
      bangumiLogger()
          .log(Level.error, 'Resolve bangumi list failed ${e.toString()}');
    }
    try {
      for (int weekday = 1; weekday <= 7; weekday++) {
        List<BangumiItem> bangumiDayList = [];
        for (BangumiItem bangumiItem in bangumiList) {
          if (bangumiItem.airWeekday == weekday) {
            bangumiDayList.add(bangumiItem);
          }
        }
        bangumiCalendar.add(bangumiDayList);
      }
    } catch (e) {
      bangumiLogger().log(
          Level.error, 'Fetch bangumi item to calendar failed ${e.toString()}');
    }
    return bangumiCalendar;
  }

  static Future getBangumiList({int rank = 2, String tag = ''}) async {
    List<BangumiItem> bangumiList = [];
    late Map<String, dynamic> params;
    if (tag == '') {
      params = <String, dynamic>{
        'keyword': '',
        'sort': 'rank',
        "filter": {
          "type": [2],
          "tag": ["日本"],
          "rank": [">$rank", "<=1050"],
          "nsfw": false
        },
      };
    } else {
      params = <String, dynamic>{
        'keyword': '',
        'sort': 'rank',
        "filter": {
          "type": [2],
          "tag": [tag],
          "rank": [">${rank * 2}", "<=99999"],
          "nsfw": false
        },
      };
    }
    try {
      final res = await Request().post(Api.bangumiRankSearch,
          data: params,
          options: Options(
              headers: bangumiHTTPHeader, contentType: 'application/json'));
      final jsonData = res.data;
      final jsonList = jsonData['data'];
      for (dynamic jsonItem in jsonList) {
        if (jsonItem is Map<String, dynamic>) {
          bangumiList.add(BangumiItem.fromJson(jsonItem));
        }
      }
    } catch (e) {
      bangumiLogger()
          .log(Level.error, 'Resolve bangumi list failed ${e.toString()}');
    }
    return bangumiList;
  }

  static Future bangumiSearch(String keyword) async {
    List<BangumiItem> bangumiList = [];

    var params = <String, dynamic>{
      'keyword': keyword,
      'sort': 'rank',
      "filter": {
        "type": [2],
        "tag": [],
        "rank": [">0", "<=99999"],
        "nsfw": false
      },
    };

    try {
      final res = await Request().post(Api.bangumiRankSearch,
          data: params,
          options: Options(
              headers: bangumiHTTPHeader, contentType: 'application/json'));
      final jsonData = res.data;
      final jsonList = jsonData['data'];
      for (dynamic jsonItem in jsonList) {
        if (jsonItem is Map<String, dynamic>) {
          try {
            BangumiItem bangumiItem = BangumiItem.fromJson(jsonItem);
            if (bangumiItem.nameCn != '') {
              bangumiList.add(bangumiItem);
            }
          } catch (e) {
            bangumiLogger().log(
                Level.error, 'Resolve search results failed ${e.toString()}');
          }
        }
      }
    } catch (e) {
      bangumiLogger().log(Level.error, 'Unknown search problem ${e.toString()}');
    }
    return bangumiList;
  }

  static getBangumiSummaryByID(int id) async {
    try {
      final res = await Request().get(Api.bangumiInfoByID + id.toString(),
          options: Options(headers: bangumiHTTPHeader));
      return res.data['summary'];
    } catch (e) {
      bangumiLogger()
          .log(Level.error, 'Resolve bangumi summary failed ${e.toString()}');
      return '';
    }
  }
}
