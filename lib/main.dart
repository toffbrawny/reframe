import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'state/capsule_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CapsuleProvider(),
      child: const ReframeApp(),
    ),
  );
}