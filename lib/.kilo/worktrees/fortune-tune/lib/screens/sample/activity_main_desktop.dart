import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_market/widget/my_card.dart';

import 'controller_sample.dart';

class ActivitySampleDesktop extends StatelessWidget {
  final ControllerSample controller;

  const ActivitySampleDesktop({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('home_title'.tr),
        actions: [
          IconButton(
            tooltip: 'toggle_theme'.tr,
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              // controller.serviceTheme.toggle();
            },
          ),
          PopupMenuButton<Locale>(
            tooltip: 'change_language'.tr,
            onSelected: (local) {
              controller.serviceLocale.update(local);
            },
            itemBuilder: (_) => const [
              PopupMenuItem<Locale>(
                value: Locale('en', 'US'),
                child: Text('English'),
              ),
              PopupMenuItem<Locale>(
                value: Locale('hi', 'IN'),
                child: Text('हिंदी'),
              ),
              PopupMenuItem<Locale>(
                value: Locale('mr', 'IN'),
                child: Text('मराठी'),
              ),
              PopupMenuItem<Locale>(
                value: Locale('ur', 'PK'),
                // or Locale('ur', 'IN') if you added ur_IN
                child: Text('اردو'),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.indigo,
        child: Row(
          children: [
            MyCard(
              // ← no Obx, no Rx, still updates instantly
              child: Text(
                'Generic LCD',
                style: TextStyle(
                  //   fontSize: 26,
                  fontFamily: 'RobotoMono',
                  //   color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            MyCard(
              // ← no Obx, no Rx, still updates instantly
              child: Text(
                'Generic LCD',
                style: TextStyle(
                  fontSize: 26,
                  fontFamily: 'RobotoMono',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
