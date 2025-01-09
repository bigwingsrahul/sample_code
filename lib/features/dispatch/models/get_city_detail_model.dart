// To parse this JSON data, do
//
//     final getCityDetailModel = getCityDetailModelFromJson(jsonString);

import 'dart:convert';

GetCityDetailModel getCityDetailModelFromJson(String str) => GetCityDetailModel.fromJson(json.decode(str));

String getCityDetailModelToJson(GetCityDetailModel data) => json.encode(data.toJson());

class GetCityDetailModel {
  int placeId;
  String licence;
  String osmType;
  int osmId;
  double lat;
  double lon;
  String getCityDetailModelClass;
  String type;
  int placeRank;
  double importance;
  String addresstype;
  String name;
  String displayName;
  Address address;
  List<double> boundingbox;

  GetCityDetailModel({
    required this.placeId,
    required this.licence,
    required this.osmType,
    required this.osmId,
    required this.lat,
    required this.lon,
    required this.getCityDetailModelClass,
    required this.type,
    required this.placeRank,
    required this.importance,
    required this.addresstype,
    required this.name,
    required this.displayName,
    required this.address,
    required this.boundingbox,
  });

  factory GetCityDetailModel.fromJson(Map<String, dynamic> json) => GetCityDetailModel(
    placeId: json["place_id"],
    licence: json["licence"],
    osmType: json["osm_type"],
    osmId: json["osm_id"],
    lat: double.tryParse(json["lat"]) ?? 0.0,
    lon: double.tryParse(json["lon"]) ?? 0.0,
    getCityDetailModelClass: json["class"],
    type: json["type"],
    placeRank: json["place_rank"],
    importance: json["importance"]?.toDouble(),
    addresstype: json["addresstype"],
    name: json["name"],
    displayName: json["display_name"],
    address: Address.fromJson(json["address"]),
    boundingbox: List<double>.from(json["boundingbox"].map((x) => double.tryParse(x) ?? 0.0)),
  );

  Map<String, dynamic> toJson() => {
    "place_id": placeId,
    "licence": licence,
    "osm_type": osmType,
    "osm_id": osmId,
    "lat": lat,
    "lon": lon,
    "class": getCityDetailModelClass,
    "type": type,
    "place_rank": placeRank,
    "importance": importance,
    "addresstype": addresstype,
    "name": name,
    "display_name": displayName,
    "address": address.toJson(),
    "boundingbox": List<dynamic>.from(boundingbox.map((x) => x)),
  };
}

class Address {
  String? road;
  String? cityBlock;
  String? neighbourhood;
  String? city;
  String? cityDistrict;
  String? industrial;
  String? suburb;
  String? town;
  String? stateDistrict;
  String? state;
  String? iso31662Lvl4;
  String? postcode;
  String? country;
  String? countryCode;

  Address({
    required this.road,
    required this.cityBlock,
    required this.neighbourhood,
    required this.city,
    required this.cityDistrict,
    required this.industrial,
    required this.suburb,
    required this.town,
    required this.stateDistrict,
    required this.state,
    required this.iso31662Lvl4,
    required this.postcode,
    required this.country,
    required this.countryCode,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    road: json["road"],
    cityBlock: json["city_block"],
    neighbourhood: json["neighbourhood"],
    city: json["city"],
    cityDistrict: json["city_district"],
    industrial: json["industrial"],
    suburb: json["suburb"],
    town: json["town"],
    stateDistrict: json["state_district"],
    state: json["state"],
    iso31662Lvl4: json["ISO3166-2-lvl4"],
    postcode: json["postcode"],
    country: json["country"],
    countryCode: json["country_code"],
  );

  Map<String, dynamic> toJson() => {
    "road": road,
    "city_block": cityBlock,
    "neighbourhood": neighbourhood,
    "city": city,
    "city_district": cityDistrict,
    "industrial": industrial,
    "suburb": suburb,
    "town": town,
    "state_district": stateDistrict,
    "state": state,
    "ISO3166-2-lvl4": iso31662Lvl4,
    "postcode": postcode,
    "country": country,
    "country_code": countryCode,
  };
}
