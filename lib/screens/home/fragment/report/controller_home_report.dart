import 'package:get/get.dart';
import '../../../../model/entity_bill.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_object_box.dart';

class ControllerHomeReport extends GetxController {
  late final Box<EntityBill> _boxBill;

  final RxList<EntityBill> rxListBill = <EntityBill>[].obs;

  // Stats
  final RxDouble todaySales = 0.0.obs;
  final RxInt todayOrders = 0.obs;
  final RxDouble averageBillValue = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    final ob = Get.find<ServiceObjectBox>();
    _boxBill = ob.box<EntityBill>();
    loadData();
  }

  void loadData() {
    // Determine start of today
    final now = DateTime.now();
    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    ).toUtc().millisecondsSinceEpoch;
    final endOfDay = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
      999,
    ).toUtc().millisecondsSinceEpoch;

    // Query recent bills (limit 50 for performance, or paginate later)
    final bills = _boxBill
        .query()
        .order(EntityBill_.createdAtUtcMs, flags: Order.descending)
        .build()
        .find()
        .take(100) // Show last 100 transactions
        .toList();

    rxListBill.assignAll(bills);

    // Calculate Today's Stats
    final todayBills = _boxBill
        .query(EntityBill_.createdAtUtcMs.between(startOfDay, endOfDay))
        .build()
        .find();

    double sales = 0;
    for (var bill in todayBills) {
      sales += (bill.grandTotal ?? 0);
    }

    todaySales.value = sales;
    todayOrders.value = todayBills.length;
    averageBillValue.value = todayOrders.value > 0
        ? sales / todayOrders.value
        : 0;
  }
}
