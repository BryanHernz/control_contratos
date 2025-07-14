// ignore_for_file: depend_on_referenced_packages

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Color primario = Colors.blueGrey[700]!;
Color secundario = const Color.fromRGBO(43, 43, 43, 1);

String formatTimestamp(Timestamp timestamp) {
  var format = DateFormat.MMMd('es');
  var date =
      DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);
  return format.format(date);
}

String formatTimestamp2(Timestamp timestamp) {
  var format = DateFormat.yMMMMEEEEd('es');
  var date =
      DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);
  return format.format(date);
}

String formatTimestamp3(Timestamp timestamp) {
  var format = DateFormat.Hm('es');
  var date =
      DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);
  return format.format(date);
}

NumberFormat numfor = NumberFormat.simpleCurrency(
  decimalDigits: 0,
);
