import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final profileBoxProvider = Provider<Box<dynamic>>(
    (ref) => throw UnimplementedError('profileBox non inizializzato'));
final historyBoxProvider = Provider<Box<dynamic>>(
    (ref) => throw UnimplementedError('historyBox non inizializzato'));
