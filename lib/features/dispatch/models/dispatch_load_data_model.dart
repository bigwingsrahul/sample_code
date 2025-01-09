// To parse this JSON data, do
//
//     final dispatchLoadDataModel = dispatchLoadDataModelFromJson(jsonString);

import 'dart:convert';

DispatchLoadDataModel dispatchLoadDataModelFromJson(String str) => DispatchLoadDataModel.fromJson(json.decode(str));

String dispatchLoadDataModelToJson(DispatchLoadDataModel data) => json.encode(data.toJson());

class DispatchLoadDataModel {
  bool status;
  List<DispatchLoadData> data;

  DispatchLoadDataModel({
    required this.status,
    required this.data,
  });

  factory DispatchLoadDataModel.fromJson(Map<String, dynamic> json) => DispatchLoadDataModel(
    status: json["status"],
    data: List<DispatchLoadData>.from(json["data"].map((x) => DispatchLoadData.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class DispatchLoadData {
  int id;
  int adminId;
  String loadId;
  dynamic invoiceNo;
  String workOrder;
  String customerType;
  Dispatcher dispatcher;
  int billTo;
  String loadType;
  String status;
  int? temperature;
  String temperatureUnit;
  int rateReceived;
  bool isReassigned;
  dynamic isAccepted;
  dynamic declineReason;
  dynamic cancelReason;
  dynamic redeliveryType;
  bool? redeliverAccepted;
  String? bolDocument;
  CustomerInfo? shipper;
  CustomerInfo? broker;
  CustomerInfo? carrier;
  List<Stop> stops;
  LoadMiles? loadMiles;
  AssignedJobs assignedJobs;
  DateTime? startTripTime;
  String origin;
  String destination;
  Stop? newStop;

  DispatchLoadData({
    required this.id,
    required this.adminId,
    required this.loadId,
    required this.invoiceNo,
    required this.workOrder,
    required this.customerType,
    required this.dispatcher,
    required this.billTo,
    required this.loadType,
    required this.status,
    required this.temperature,
    required this.temperatureUnit,
    required this.rateReceived,
    required this.isReassigned,
    required this.isAccepted,
    required this.declineReason,
    required this.cancelReason,
    required this.redeliveryType,
    required this.redeliverAccepted,
    required this.bolDocument,
    required this.shipper,
    required this.broker,
    required this.carrier,
    required this.stops,
    required this.loadMiles,
    required this.assignedJobs,
    required this.startTripTime,
    required this.origin,
    required this.destination,
    this.newStop,
  });

  factory DispatchLoadData.fromJson(Map<String, dynamic> json) => DispatchLoadData(
    id: json["id"],
    adminId: json["adminId"],
    loadId: json["loadId"],
    invoiceNo: json["invoiceNo"],
    workOrder: json["workOrder"],
    customerType: json["customerType"],
    dispatcher: Dispatcher.fromJson(json["dispatcher"]),
    billTo: json["billTo"],
    loadType: json["loadType"],
    status: json["status"],
    temperature: json["temperature"],
    temperatureUnit: json["temperatureUnit"],
    rateReceived: json["rateReceived"],
    isReassigned: json["isReassigned"],
    isAccepted: json["isAccepted"],
    declineReason: json["declineReason"],
    cancelReason: json["cancelReason"],
    redeliveryType: json["redeliveryType"],
    redeliverAccepted: json["redeliverAccepted"],
    bolDocument: json["bolDocument"],
    shipper: json["shipper"] == null ? null : CustomerInfo.fromJson(json["shipper"]),
    broker: json["broker"] == null ? null : CustomerInfo.fromJson(json["broker"]),
    carrier: json["carrier"] == null ? null : CustomerInfo.fromJson(json["carrier"]),
    stops: List<Stop>.from(json["stops"].map((x) => Stop.fromJson(x))),
    loadMiles: json["loadMiles"] == null ? null : LoadMiles.fromJson(json["loadMiles"]),
    assignedJobs: AssignedJobs.fromJson(json["assignedJobs"]),
    startTripTime: json["startTripTime"] == null ? null : DateTime.parse(json["startTripTime"]),
    origin: json["origin"],
    destination: json["destination"],
    newStop: json["newStop"] == null ? null : Stop.fromJson(json["newStop"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "adminId": adminId,
    "loadId": loadId,
    "invoiceNo": invoiceNo,
    "workOrder": workOrder,
    "customerType": customerType,
    "dispatcher": dispatcher.toJson(),
    "billTo": billTo,
    "loadType": loadType,
    "status": status,
    "temperature": temperature,
    "temperatureUnit": temperatureUnit,
    "rateReceived": rateReceived,
    "isReassigned": isReassigned,
    "isAccepted": isAccepted,
    "declineReason": declineReason,
    "cancelReason": cancelReason,
    "redeliveryType": redeliveryType,
    "redeliverAccepted": redeliverAccepted,
    "bolDocument": bolDocument,
    "shipper": shipper?.toJson(),
    "broker": broker?.toJson(),
    "carrier": carrier,
    "stops": List<dynamic>.from(stops.map((x) => x.toJson())),
    "loadMiles": loadMiles?.toJson(),
    "assignedJobs": assignedJobs.toJson(),
    "startTripTime": startTripTime?.toIso8601String(),
    "origin": origin,
    "destination": destination,
    "newStop": newStop?.toJson(),
  };
}

class AssignedJobs {
  int id;
  int adminId;
  int loadId;
  String driverType;
  List<int> driverIds;
  int truckId;
  int trailerId;
  String startLocation;
  Coordinates startCoordinates;
  String endLocation;
  Coordinates endCoordinates;
  DateTime startTime;
  DateTime endTime;
  int trailerTypeId;
  List<dynamic> reassignedDriverIds;
  dynamic reassignedTruckId;
  dynamic reassignedTrailerId;
  String reassignedLocation;
  dynamic reassignedCoordinates;
  dynamic reason;
  Dispatcher addedBy;
  dynamic modifiedBy;
  dynamic deletedBy;
  bool isDeleted;
  DateTime createdAt;
  DateTime updatedAt;
  List<Driver> drivers;
  Trucks trucks;
  Trailers trailers;

  AssignedJobs({
    required this.id,
    required this.adminId,
    required this.loadId,
    required this.driverType,
    required this.driverIds,
    required this.truckId,
    required this.trailerId,
    required this.startLocation,
    required this.startCoordinates,
    required this.endLocation,
    required this.endCoordinates,
    required this.startTime,
    required this.endTime,
    required this.trailerTypeId,
    required this.reassignedDriverIds,
    required this.reassignedTruckId,
    required this.reassignedTrailerId,
    required this.reassignedLocation,
    required this.reassignedCoordinates,
    required this.reason,
    required this.addedBy,
    required this.modifiedBy,
    required this.deletedBy,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    required this.drivers,
    required this.trucks,
    required this.trailers,
  });

  factory AssignedJobs.fromJson(Map<String, dynamic> json) => AssignedJobs(
    id: json["id"],
    adminId: json["adminId"],
    loadId: json["loadId"],
    driverType: json["driverType"],
    driverIds: List<int>.from(json["driverIds"].map((x) => x)),
    truckId: json["truckId"],
    trailerId: json["trailerId"],
    startLocation: json["startLocation"],
    startCoordinates: Coordinates.fromJson(json["startCoordinates"]),
    endLocation: json["endLocation"],
    endCoordinates: Coordinates.fromJson(json["endCoordinates"]),
    startTime: DateTime.parse(json["startTime"]),
    endTime: DateTime.parse(json["endTime"]),
    trailerTypeId: json["trailerTypeId"],
    reassignedDriverIds: List<dynamic>.from(json["reassignedDriverIds"].map((x) => x)),
    reassignedTruckId: json["reassignedTruckId"],
    reassignedTrailerId: json["reassignedTrailerId"],
    reassignedLocation: json["reassignedLocation"],
    reassignedCoordinates: json["reassignedCoordinates"],
    reason: json["reason"],
    addedBy: Dispatcher.fromJson(json["addedBy"]),
    modifiedBy: json["modifiedBy"],
    deletedBy: json["deletedBy"],
    isDeleted: json["isDeleted"],
    createdAt: DateTime.parse(json["createdAt"]),
    updatedAt: DateTime.parse(json["updatedAt"]),
    drivers: List<Driver>.from(json["drivers"].map((x) => Driver.fromJson(x))),
    trucks: Trucks.fromJson(json["trucks"]),
    trailers: Trailers.fromJson(json["trailers"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "adminId": adminId,
    "loadId": loadId,
    "driverType": driverType,
    "driverIds": List<dynamic>.from(driverIds.map((x) => x)),
    "truckId": truckId,
    "trailerId": trailerId,
    "startLocation": startLocation,
    "startCoordinates": startCoordinates.toJson(),
    "endLocation": endLocation,
    "endCoordinates": endCoordinates.toJson(),
    "startTime": startTime.toIso8601String(),
    "endTime": endTime.toIso8601String(),
    "trailerTypeId": trailerTypeId,
    "reassignedDriverIds": List<dynamic>.from(reassignedDriverIds.map((x) => x)),
    "reassignedTruckId": reassignedTruckId,
    "reassignedTrailerId": reassignedTrailerId,
    "reassignedLocation": reassignedLocation,
    "reassignedCoordinates": reassignedCoordinates,
    "reason": reason,
    "addedBy": addedBy.toJson(),
    "modifiedBy": modifiedBy,
    "deletedBy": deletedBy,
    "isDeleted": isDeleted,
    "createdAt": createdAt.toIso8601String(),
    "updatedAt": updatedAt.toIso8601String(),
    "drivers": List<dynamic>.from(drivers.map((x) => x.toJson())),
    "trucks": trucks.toJson(),
    "trailers": trailers.toJson(),
  };
}

class Driver {
  int id;
  String username;
  AssignJobDriver assignJobDriver;

  Driver({
    required this.id,
    required this.username,
    required this.assignJobDriver,
  });

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
    id: json["id"],
    username: json["username"],
    assignJobDriver: AssignJobDriver.fromJson(json["assign_job_driver"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "username": username,
    "assign_job_driver": assignJobDriver.toJson(),
  };
}

class AssignJobDriver {
  int assignJobId;
  int driverId;
  DateTime createdAt;
  DateTime updatedAt;

  AssignJobDriver({
    required this.assignJobId,
    required this.driverId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssignJobDriver.fromJson(Map<String, dynamic> json) => AssignJobDriver(
    assignJobId: json["assignJobId"],
    driverId: json["driverId"],
    createdAt: DateTime.parse(json["createdAt"]),
    updatedAt: DateTime.parse(json["updatedAt"]),
  );

  Map<String, dynamic> toJson() => {
    "assignJobId": assignJobId,
    "driverId": driverId,
    "createdAt": createdAt.toIso8601String(),
    "updatedAt": updatedAt.toIso8601String(),
  };
}

class Dispatcher {
  int id;
  String role;

  Dispatcher({
    required this.id,
    required this.role,
  });

  factory Dispatcher.fromJson(Map<String, dynamic> json) => Dispatcher(
    id: json["id"],
    role: json["role"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "role": role,
  };
}

class LoadMiles {
  int id;
  int adminId;
  int loadId;
  Miles proMiles;
  Miles driverMiles;
  dynamic reassignedHereMiles;
  dynamic reassignedDriverMiles;
  String hours;

  LoadMiles({
    required this.id,
    required this.adminId,
    required this.loadId,
    required this.proMiles,
    required this.driverMiles,
    required this.reassignedHereMiles,
    required this.reassignedDriverMiles,
    required this.hours,
  });

  factory LoadMiles.fromJson(Map<String, dynamic> json) => LoadMiles(
    id: json["id"],
    adminId: json["adminId"],
    loadId: json["loadId"],
    proMiles: Miles.fromJson(json["proMiles"]),
    driverMiles: Miles.fromJson(json["driverMiles"]),
    reassignedHereMiles: json["reassignedHereMiles"],
    reassignedDriverMiles: json["reassignedDriverMiles"],
    hours: json["hours"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "adminId": adminId,
    "loadId": loadId,
    "proMiles": proMiles.toJson(),
    "driverMiles": driverMiles.toJson(),
    "reassignedHereMiles": reassignedHereMiles,
    "reassignedDriverMiles": reassignedDriverMiles,
    "hours": hours,
  };
}

class Miles {
  double loadedMiles;
  double emptyMiles;

  Miles({
    required this.loadedMiles,
    required this.emptyMiles,
  });

  factory Miles.fromJson(Map<String, dynamic> json) => Miles(
    loadedMiles: json["loadedMiles"]?.toDouble(),
    emptyMiles: json["emptyMiles"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "loadedMiles": loadedMiles,
    "emptyMiles": emptyMiles,
  };
}

class CustomerInfo {
  String name;
  String email;

  CustomerInfo({
    required this.name,
    required this.email,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) => CustomerInfo(
    name: json["name"],
    email: json["email"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "email": email,
  };
}

class Stop {
  int id;
  int adminId;
  int loadId;
  String stopType;
  int? shipperId;
  int? consigneeId;
  String commodity;
  String? truckLoadType;
  List<Quantity> quantity;
  String location;
  String? bolDoc;
  Coordinates coordinates;
  String poNumber;
  int? weight;
  int? value;
  bool isHazardousSize;
  String shippingNotes;
  String deliveryNotes;
  String scheduleType;
  String date;
  String appointmentTime;
  String? appointmentTime2;
  String stopDateTime;
  dynamic stopDateTime2;
  bool isAccepted;
  bool isCompleted;
  String miles;
  List<StopStatus> stopStatus;
  Properties? shippers;
  Properties? consignees;
  String latestStatus;

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
    required this.bolDoc,
    required this.coordinates,
    required this.poNumber,
    required this.weight,
    required this.value,
    required this.isHazardousSize,
    required this.shippingNotes,
    required this.deliveryNotes,
    required this.scheduleType,
    required this.date,
    required this.appointmentTime,
    required this.appointmentTime2,
    required this.stopDateTime,
    required this.stopDateTime2,
    required this.isAccepted,
    required this.isCompleted,
    required this.miles,
    required this.stopStatus,
    required this.shippers,
    required this.consignees,
    required this.latestStatus,
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
    quantity: json["quantity"] == null ? [] : List<Quantity>.from(json["quantity"].map((x) => Quantity.fromJson(x))),
    location: json["location"],
    bolDoc: json["bolDoc"],
    coordinates: Coordinates.fromJson(json["coordinates"]),
    poNumber: json["poNumber"],
    weight: json["weight"],
    value: json["value"],
    isHazardousSize: json["isHazardousSize"],
    shippingNotes: json["shippingNotes"] ?? "-",
    deliveryNotes: json["deliveryNotes"] ?? "-",
    scheduleType: json["scheduleType"],
    date: json["date"],
    appointmentTime: json["appointmentTime"],
    appointmentTime2: json["appointmentTime2"],
    stopDateTime: json["stopDateTime"],
    stopDateTime2: json["stopDateTime2"],
    isAccepted: json["isAccepted"],
    isCompleted: json["isCompleted"],
    miles: json["miles"].toString(),
    stopStatus: json["stop_status"] == null ? [] : List<StopStatus>.from(json["stop_status"].map((x) => StopStatus.fromJson(x))),
    shippers: json["shippers"] == null ? null : Properties.fromJson(json["shippers"]),
    consignees: json["consignees"] == null ? null : Properties.fromJson(json["consignees"]),
    latestStatus: json["latestStatus"].toString(),
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
    "quantity": List<dynamic>.from(quantity.map((x) => x.toJson())),
    "location": location,
    "bolDoc": bolDoc,
    "coordinates": coordinates.toJson(),
    "poNumber": poNumber,
    "weight": weight,
    "value": value,
    "isHazardousSize": isHazardousSize,
    "shippingNotes": shippingNotes,
    "deliveryNotes": deliveryNotes,
    "scheduleType": scheduleType,
    "date": date,
    "appointmentTime": appointmentTime,
    "appointmentTime2": appointmentTime2,
    "stopDateTime": stopDateTime,
    "stopDateTime2": stopDateTime2,
    "isAccepted": isAccepted,
    "isCompleted": isCompleted,
    "miles": miles.toString(),
    "stop_status": List<dynamic>.from(stopStatus.map((x) => x.toJson())),
    "shippers": shippers?.toJson(),
    "consignees": consignees?.toJson(),
    "latestStatus": latestStatus,
  };
}

class StopStatus {
  DateTime createdAt;
  String status;
  String detail;

  StopStatus({
    required this.createdAt,
    required this.status,
    required this.detail,
  });

  factory StopStatus.fromJson(Map<String, dynamic> json) => StopStatus(
    createdAt: DateTime.parse(json["createdAt"]),
    status: json["status"],
    detail: json["detail"],
  );

  Map<String, dynamic> toJson() => {
    "createdAt": createdAt.toIso8601String(),
    "status": status,
    "detail": detail,
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

class Trailers {
  String trailerNumber;

  Trailers({
    required this.trailerNumber,
  });

  factory Trailers.fromJson(Map<String, dynamic> json) => Trailers(
    trailerNumber: json["trailerNumber"],
  );

  Map<String, dynamic> toJson() => {
    "trailerNumber": trailerNumber,
  };
}

class Trucks {
  String truckNumber;

  Trucks({
    required this.truckNumber,
  });

  factory Trucks.fromJson(Map<String, dynamic> json) => Trucks(
    truckNumber: json["truckNumber"],
  );

  Map<String, dynamic> toJson() => {
    "truckNumber": truckNumber,
  };
}

class Quantity {
  String type;
  String value;

  Quantity({
    required this.type,
    required this.value,
  });

  factory Quantity.fromJson(Map<String, dynamic> json) => Quantity(
    type: json["type"],
    value: json["value"],
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "value": value,
  };
}