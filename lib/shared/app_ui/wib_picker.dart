import 'package:flutter/material.dart';
import 'package:pramu_apps/core/time.dart';

/// Pemilih tanggal (WIB) -> instan UTC pukul 00.00 WIB. Tanggal lampau diblok.
Future<DateTime?> pickWibDate(BuildContext context, {DateTime? initial}) async {
  final now = toWib(DateTime.now());
  final today = DateTime(now.year, now.month, now.day);
  final init = initial == null ? today : _wallDate(initial);
  final d = await showDatePicker(
    context: context,
    initialDate: init.isBefore(today) ? today : init,
    firstDate: today,
    lastDate: today.add(const Duration(days: 365)),
  );
  return d == null ? null : fromWib(d.year, d.month, d.day);
}

/// Tanggal lalu jam (WIB) -> instan UTC. Default tanggal = besok.
Future<DateTime?> pickWibDateTime(BuildContext context) async {
  final now = toWib(DateTime.now());
  final today = DateTime(now.year, now.month, now.day);
  final d = await showDatePicker(
    context: context,
    initialDate: today.add(const Duration(days: 1)),
    firstDate: today,
    lastDate: today.add(const Duration(days: 180)),
  );
  if (d == null || !context.mounted) return null;
  final t = await showTimePicker(
    context: context,
    initialTime: const TimeOfDay(hour: 10, minute: 0),
  );
  return t == null ? null : fromWib(d.year, d.month, d.day, t.hour, t.minute);
}

DateTime _wallDate(DateTime utc) {
  final w = toWib(utc);
  return DateTime(w.year, w.month, w.day);
}
