// To parse this JSON data, do
//
//     final rejectionRequestModel = rejectionRequestModelFromJson(jsonString);

import 'dart:convert';

import 'package:image_picker/image_picker.dart';

RejectionRequestModel rejectionRequestModelFromJson(String str) => RejectionRequestModel.fromJson(json.decode(str));

String rejectionRequestModelToJson(RejectionRequestModel data) => json.encode(data.toJson());

class RejectionRequestModel {
  String product;
  String rejectionType;
 String quantity;
  List<String> productDocuments;
  String bolDocument;
  String reason;
  String additionalNotes;

  RejectionRequestModel({
    required this.product,
    required this.rejectionType,
    required this.quantity,
    required this.productDocuments,
    required this.bolDocument,
    required this.reason,
    required this.additionalNotes,
  });

  factory RejectionRequestModel.fromJson(Map<String, dynamic> json) => RejectionRequestModel(
    product: json["product"],
    rejectionType: json["rejectionType"],
    quantity: json["quantity"],
    productDocuments: List<String>.from(json["productDocuments"].map((x) => x)),
    bolDocument: json["bolDocument"],
    reason: json["reason"],
    additionalNotes: json["additionalNotes"],
  );

  Map<String, dynamic> toJson() => {
    "product": product,
    "rejectionType": rejectionType,
    "quantity": quantity,
    "productDocuments": List<dynamic>.from(productDocuments.map((x) => x)),
    "bolDocument": bolDocument,
    "reason": reason,
    "additionalNotes": additionalNotes,
  };
}
