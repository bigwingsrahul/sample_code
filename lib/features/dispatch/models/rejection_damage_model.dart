import 'package:flutter/cupertino.dart';

class RejectionDamageModel {
  final TextEditingController controller;
  final String type;

  RejectionDamageModel(this.controller, this.type);

  Map<String, dynamic> toJson() => {
    "type": type,
    "value": int.tryParse(controller.text) ?? 0,
  };
}