// To parse this JSON data, do
//
//     final reDeliverNotificationData = reDeliverNotificationDataFromJson(jsonString);

import 'dart:convert';

ReDeliverNotificationData reDeliverNotificationDataFromJson(String str) => ReDeliverNotificationData.fromJson(json.decode(str));

String reDeliverNotificationDataToJson(ReDeliverNotificationData data) => json.encode(data.toJson());

class ReDeliverNotificationData {
  Stop stop;
  String type;

  ReDeliverNotificationData({
    required this.stop,
    required this.type,
  });

  factory ReDeliverNotificationData.fromJson(Map<String, dynamic> json) => ReDeliverNotificationData(
    stop: Stop.fromJson(jsonDecode(json["stop"])),
    type: json["type"],
  );

  Map<String, dynamic> toJson() => {
    "stop": stop.toJson(),
    "type": type,
  };
}

class Stop {
  int id;
  int adminId;
  int loadId;
  String stopType;
  dynamic shipperId;
  int consigneeId;
  String commodity;
  dynamic truckLoadType;
  List<dynamic> quantity;
  String location;
  Coordinates coordinates;
  String poNumber;
  dynamic weight;
  dynamic value;
  bool isHazardousSize;
  dynamic shippingNotes;
  String scheduleType;
  DateTime date;
  String appointmentTime;
  dynamic appointmentTime2;
  DateTime stopDateTime;
  dynamic stopDateTime2;
  bool isAccepted;
  double miles;
  bool isCompleted;
  AddedBy addedBy;
  dynamic deletedBy;
  bool isDeleted;
  DateTime updatedAt;
  DateTime createdAt;
  dynamic modifiedBy;

  Stop({
    required this.id,
    required this.adminId,
    required this.loadId,
    required this.stopType,
    required this.shipperId,
    required this.consigneeId,
    required this.commodity,
    required this.truckLoadType,
    required this.quantity,
    required this.location,
    required this.coordinates,
    required this.poNumber,
    required this.weight,
    required this.value,
    required this.isHazardousSize,
    required this.shippingNotes,
    required this.scheduleType,
    required this.date,
    required this.appointmentTime,
    required this.appointmentTime2,
    required this.stopDateTime,
    required this.stopDateTime2,
    required this.isAccepted,
    required this.miles,
    required this.isCompleted,
    required this.addedBy,
    required this.deletedBy,
    required this.isDeleted,
    required this.updatedAt,
    required this.createdAt,
    required this.modifiedBy,
  });

  factory Stop.fromJson(Map<String, dynamic> json) => Stop(
    id: json["id"],
    adminId: json["adminId"],
    loadId: json["loadId"],
    stopType: json["stopType"],
    shipperId: json["shipperId"],
    consigneeId: json["consigneeId"],
    commodity: json["commodity"],
    truckLoadType: json["truckLoadType"],
    quantity: json["quantity"] ?? [],
    location: json["location"],
    coordinates: Coordinates.fromJson(json["coordinates"]),
    poNumber: json["poNumber"],
    weight: json["weight"],
    value: json["value"],
    isHazardousSize: json["isHazardousSize"],
    shippingNotes: json["shippingNotes"],
    scheduleType: json["scheduleType"],
    date: DateTime.parse(json["date"]),
    appointmentTime: json["appointmentTime"],
    appointmentTime2: json["appointmentTime2"],
    stopDateTime: DateTime.parse(json["stopDateTime"]),
    stopDateTime2: json["stopDateTime2"],
    isAccepted: json["isAccepted"],
    miles: json["miles"]?.toDouble(),
    isCompleted: json["isCompleted"],
    addedBy: AddedBy.fromJson(json["addedBy"]),
    deletedBy: json["deletedBy"],
    isDeleted: json["isDeleted"],
    updatedAt: DateTime.parse(json["updatedAt"]),
    createdAt: DateTime.parse(json["createdAt"]),
    modifiedBy: json["modifiedBy"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "adminId": adminId,
    "loadId": loadId,
    "stopType": stopType,
    "shipperId": shipperId,
    "consigneeId": consigneeId,
    "commodity": commodity,
    "truckLoadType": truckLoadType,
    "quantity": quantity,
    "location": location,
    "coordinates": coordinates.toJson(),
    "poNumber": poNumber,
    "weight": weight,
    "value": value,
    "isHazardousSize": isHazardousSize,
    "shippingNotes": shippingNotes,
    "scheduleType": scheduleType,
    "date": date.toIso8601String(),
    "appointmentTime": appointmentTime,
    "appointmentTime2": appointmentTime2,
    "stopDateTime": stopDateTime.toIso8601String(),
    "stopDateTime2": stopDateTime2,
    "isAccepted": isAccepted,
    "miles": miles,
    "isCompleted": isCompleted,
    "addedBy": addedBy.toJson(),
    "deletedBy": deletedBy,
    "isDeleted": isDeleted,
    "updatedAt": updatedAt.toIso8601String(),
    "createdAt": createdAt.toIso8601String(),
    "modifiedBy": modifiedBy,
  };
}

class AddedBy {
  int id;
  String role;

  AddedBy({
    required this.id,
    required this.role,
  });

  factory AddedBy.fromJson(Map<String, dynamic> json) => AddedBy(
    id: json["id"],
    role: json["role"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "role": role,
  };
}

class Coordinates {
  Crs crs;
  String type;
  List<double> coordinates;

  Coordinates({
    required this.crs,
    required this.type,
    required this.coordinates,
  });

  factory Coordinates.fromJson(Map<String, dynamic> json) => Coordinates(
    crs: Crs.fromJson(json["crs"]),
    type: json["type"],
    coordinates: List<double>.from(json["coordinates"].map((x) => x?.toDouble())),
  );

  Map<String, dynamic> toJson() => {
    "crs": crs.toJson(),
    "type": type,
    "coordinates": List<dynamic>.from(coordinates.map((x) => x)),
  };
}

class Crs {
  String type;
  Properties properties;

  Crs({
    required this.type,
    required this.properties,
  });

  factory Crs.fromJson(Map<String, dynamic> json) => Crs(
    type: json["type"],
    properties: Properties.fromJson(json["properties"]),
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "properties": properties.toJson(),
  };
}

class Properties {
  String name;

  Properties({
    required this.name,
  });

  factory Properties.fromJson(Map<String, dynamic> json) => Properties(
    name: json["name"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
  };
}
