// To parse this JSON data, do
//
//     final getGeoBoundDataModel = getGeoBoundDataModelFromJson(jsonString);

import 'dart:convert';

List<GetGeoBoundDataModel> getGeoBoundDataModelFromJson(String str) => List<GetGeoBoundDataModel>.from(json.decode(str).map((x) => GetGeoBoundDataModel.fromJson(x)));

String getGeoBoundDataModelToJson(List<GetGeoBoundDataModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetGeoBoundDataModel {
  int placeId;
  String licence;
  String osmType;
  int osmId;
  String lat;
  String lon;
  String getGeoBoundDataModelClass;
  String type;
  int placeRank;
  double importance;
  String addresstype;
  String name;
  String displayName;
  List<String> boundingbox;
  Geojson geojson;

  GetGeoBoundDataModel({
    required this.placeId,
    required this.licence,
    required this.osmType,
    required this.osmId,
    required this.lat,
    required this.lon,
    required this.getGeoBoundDataModelClass,
    required this.type,
    required this.placeRank,
    required this.importance,
    required this.addresstype,
    required this.name,
    required this.displayName,
    required this.boundingbox,
    required this.geojson,
  });

  factory GetGeoBoundDataModel.fromJson(Map<String, dynamic> json) => GetGeoBoundDataModel(
    placeId: json["place_id"],
    licence: json["licence"],
    osmType: json["osm_type"],
    osmId: json["osm_id"],
    lat: json["lat"],
    lon: json["lon"],
    getGeoBoundDataModelClass: json["class"],
    type: json["type"],
    placeRank: json["place_rank"],
    importance: json["importance"]?.toDouble(),
    addresstype: json["addresstype"],
    name: json["name"],
    displayName: json["display_name"],
    boundingbox: List<String>.from(json["boundingbox"].map((x) => x)),
    geojson: Geojson.fromJson(json["geojson"]),
  );

  Map<String, dynamic> toJson() => {
    "place_id": placeId,
    "licence": licence,
    "osm_type": osmType,
    "osm_id": osmId,
    "lat": lat,
    "lon": lon,
    "class": getGeoBoundDataModelClass,
    "type": type,
    "place_rank": placeRank,
    "importance": importance,
    "addresstype": addresstype,
    "name": name,
    "display_name": displayName,
    "boundingbox": List<dynamic>.from(boundingbox.map((x) => x)),
    "geojson": geojson.toJson(),
  };
}

class Geojson {
  String type;
  List<dynamic> coordinates;

  Geojson({
    required this.type,
    required this.coordinates,
  });

  factory Geojson.fromJson(Map<String, dynamic> json) => Geojson(
    type: json["type"],
    coordinates: List<dynamic>.from(json["coordinates"].map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "coordinates": List<dynamic>.from(coordinates.map((x) => x)),
  };
}