
// =============================================================================
// HELPERS GLOBALES
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digitaltv/ui/programming/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const dayLabels = {
  'mon': 'Lunes',
  'tue': 'Martes',
  'wed': 'Miércoles',
  'thu': 'Jueves',
  'fri': 'Viernes',
  'sat': 'Sábado',
  'sun': 'Domingo',
};
const dayShort = {
  'mon': 'L',
  'tue': 'M',
  'wed': 'X',
  'thu': 'J',
  'fri': 'V',
  'sat': 'S',
  'sun': 'D',
};
const orderedDays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

String fmtMinutes(int m) {
  final h = m ~/ 60;
  final min = m % 60;
  return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
}

SnackBar snack(String msg, {Color? bg}) => SnackBar(
      content:
          Text(msg, style: const TextStyle(color: CP.textHi, fontSize: 13)),
      backgroundColor: bg ?? CP.card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: CP.border)),
      margin: const EdgeInsets.all(14),
      duration: const Duration(seconds: 3),
    );

Future<String?> getCompanyId() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;
  final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
  return (doc.data() as Map<String, dynamic>?)?['companyId'] as String?;
}