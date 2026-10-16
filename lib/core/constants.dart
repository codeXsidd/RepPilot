import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String generateId() => _uuid.v4();

const double kgToLbFactor = 2.20462;

double kgToLb(double kg) => kg * kgToLbFactor;
double lbToKg(double lb) => lb / kgToLbFactor;

double displayWeight(double kg, String unit) => unit == 'lb' ? kgToLb(kg) : kg;

double storageWeight(double value, String unit) =>
    unit == 'lb' ? lbToKg(value) : value;

String formatDateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime parseDateOnly(String s) => DateTime.parse(s);

DateTime stripTime(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
