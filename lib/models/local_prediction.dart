import 'dart:collection';

import 'package:google_maps_webservice/places.dart';

class LocalPrediction {
  LocalPrediction({
    this.placeId,
    this.formattedAddress,
    this.lat,
    this.lng,
  });

  String? placeId;
  String? formattedAddress;
  List<MatchedSubstring>? matchedSubstrings;
  double? lat;
  double? lng;
  LocalMap? localMap;

  LocalPrediction.fromMap(dynamic map, String matchingStr) {
    placeId = map['place_id'];
    lat = map['lat'];
    lng = map['lng'];
    formattedAddress = map['formatted_address'];
    matchedSubstrings = [
      MatchedSubstring(length: matchingStr.length, offset: 0)
    ];
    localMap = LocalMap.fromMap(map);
  }
  toMap() {
    Map<String, dynamic> map = HashMap();
    map["place_id"] = placeId;
    map["lat"] = lat;
    map["lat"] = lat;
    map["formatted_address"] = formattedAddress;
    map["local_map"] = localMap?.toMap();
    return map;
  }
}

class LocalMap {
  LocalMap({
    this.placeId,
    this.lat,
    this.lng,
    this.region,
    this.address,
  });

  String? placeId;
  String? region;
  double? lat;
  double? lng;
  String? address;

  LocalMap.fromMap(dynamic map) {
    placeId = map['place_id'];
    lat = map['lat'];
    lng = map['lng'];
    address = map['address'];
  }
  toMap() {
    Map<String, dynamic> map = HashMap();
    map["place_id"] = placeId;
    map["lat"] = lat;
    map["lat"] = lat;
    map["address"] = address;
    return map;
  }
}
