import 'package:get/get.dart' hide Condition;
import 'package:intl/intl.dart';
import '../../../../model/entity_bill.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_object_box.dart';

class ControllerHomeDashboard extends GetxController {
  late final Box<EntityBill> _boxBill;

  // ── Today stats ──
  final RxDouble todaySales = 0.0.obs;
  final RxInt todayOrders = 0.obs;
  final RxDouble averageBill = 0.0.obs;

  // ── Line chart: daily sales for last 7 days ──
  // Index 0 = 6 days ago, index 6 = today
  final RxList<double> weeklySales = List.filled(7, 0.0).obs;
  final RxList<String> weekLabels = <String>[].obs;

  // ── Pie chart: payment mode breakdown ──
  // { 'CASH': 45.0, 'CARD': 30.0, 'UPI': 25.0 }
  final RxMap<String, double> paymentBreakdown = <String, double>{}.obs;

  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxBill = ob.box<EntityBill>();
    loadData();
  }

  void loadData() {
    isLoading.value = true;

    final fmt = DateFormat('d/MM/yyyy');
    final labelFmt = DateFormat('EEE'); // Mon, Tue …

    final now = DateTime.now();

    // ── Weekly data (last 7 days) ──
    final labels = <String>[];
    final sales = List.filled(7, 0.0);

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dateStr = fmt.format(day);
      labels.add(labelFmt.format(day));

      final query = _boxBill
          .query(EntityBill_.billDate.equals(dateStr))
          .build();
      final bills = query.find();
      query.close();

      double dayTotal = 0;
      for (final b in bills) {
        dayTotal += (b.grandTotal ?? 0);
      }
      sales[6 - i] = dayTotal;
    }

    weekLabels.value = labels;
    weeklySales.value = sales;

    // ── Today stats ──
    final todayStr = fmt.format(now);
    final todayQuery = _boxBill
        .query(EntityBill_.billDate.equals(todayStr))
        .build();
    final todayBills = todayQuery.find();
    todayQuery.close();

    double tSales = 0;
    final modeMap = <String, double>{};
    for (final b in todayBills) {
      tSales += (b.grandTotal ?? 0);
      final mode = (b.paymentMode ?? 'CASH').toUpperCase();
      modeMap[mode] = (modeMap[mode] ?? 0) + (b.grandTotal ?? 0);
    }

    todaySales.value = tSales;
    todayOrders.value = todayBills.length;
    averageBill.value = todayBills.isNotEmpty ? tSales / todayBills.length : 0;
    paymentBreakdown.value = modeMap;

    isLoading.value = false;
  }
}
