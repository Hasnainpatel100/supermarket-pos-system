import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_market/service/service_currency.dart';
import 'controller_home_pos.dart';

class PaymentDetails {
  final String paymentMode;
  final double amountReceived;
  final double changeReturned;
  final String utrNumber;
  final double splitCash;
  final double splitOnline;
  final double dueAmount;

  PaymentDetails({
    required this.paymentMode,
    this.amountReceived = 0.0,
    this.changeReturned = 0.0,
    this.utrNumber = '',
    this.splitCash = 0.0,
    this.splitOnline = 0.0,
    this.dueAmount = 0.0,
  });
}

class SplitEntryController {
  final RxString mode = 'CASH'.obs;
  final TextEditingController amountController = TextEditingController();
  final TextEditingController utrController = TextEditingController();
  
  void dispose() {
    amountController.dispose();
    utrController.dispose();
  }
}

class ControllerPaymentOptions extends GetxController {
  final double grandTotal;
  final ServiceCurrency serviceCurrency = Get.find();

  final rxSelectedMode = "CASH".obs; // CASH, UPI, NETBANKING, SPLIT

  // Generic mode fields (CASH, UPI, NETBANKING)
  final amountController = TextEditingController();
  final rxAmountReceived = 0.0.obs;
  final rxChangeReturned = 0.0.obs;
  final rxDueAmount = 0.0.obs;
  final utrController = TextEditingController();

  // Split mode fields
  final rxSplitEntries = <SplitEntryController>[].obs;
  final rxSplitTotal = 0.0.obs;

  ControllerPaymentOptions({required this.grandTotal});

  @override
  void onInit() {
    super.onInit();
    // Default amount received to the grand total
    amountController.text = grandTotal.toStringAsFixed(2);
    rxAmountReceived.value = grandTotal;
    calculateAmounts();

    // Default split logic
    final c1 = SplitEntryController();
    c1.mode.value = 'CASH';
    c1.amountController.text = (grandTotal / 2).toStringAsFixed(2);
    
    final c2 = SplitEntryController();
    c2.mode.value = 'UPI';
    c2.amountController.text = (grandTotal / 2).toStringAsFixed(2);
    
    rxSplitEntries.addAll([c1, c2]);
    
    c1.amountController.addListener(calculateSplitTotal);
    c2.amountController.addListener(calculateSplitTotal);
    calculateSplitTotal();
  }

  void setPaymentMode(String mode) {
    rxSelectedMode.value = mode;
  }

  void onAmountChanged(String val) {
    rxAmountReceived.value = double.tryParse(val) ?? 0.0;
    calculateAmounts();
  }

  void calculateAmounts() {
    double received = rxAmountReceived.value;
    if (received >= grandTotal) {
      rxChangeReturned.value = received - grandTotal;
      rxDueAmount.value = 0.0;
    } else {
      rxChangeReturned.value = 0.0;
      rxDueAmount.value = grandTotal - received;
    }
  }

  void addSplitEntry() {
    final c = SplitEntryController();
    c.amountController.addListener(calculateSplitTotal);
    rxSplitEntries.add(c);
  }

  void removeSplitEntry(int index) {
    final c = rxSplitEntries[index];
    c.amountController.removeListener(calculateSplitTotal);
    c.dispose();
    rxSplitEntries.removeAt(index);
    calculateSplitTotal();
  }

  void calculateSplitTotal() {
    double total = 0;
    for (var e in rxSplitEntries) {
      total += double.tryParse(e.amountController.text) ?? 0.0;
    }
    rxSplitTotal.value = total;
  }

  bool validateAndConfirm() {
    final mode = rxSelectedMode.value;
    double due = 0.0;
    double received = 0.0;
    double change = 0.0;
    double splitC = 0.0;
    double splitO = 0.0;

    if (mode == "CASH" || mode == "UPI" || mode == "NETBANKING") {
      received = rxAmountReceived.value;
      if (received < grandTotal) {
        due = grandTotal - received;
      } else {
        change = received - grandTotal;
      }
      
      if ((mode == "UPI" || mode == "NETBANKING") && utrController.text.trim().isEmpty) {
        Get.snackbar(
          "Error",
          "Please enter UTR/Reference Number",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } else if (mode == "SPLIT") {
      final totalPaid = rxSplitTotal.value;
      if (totalPaid > grandTotal + 0.01) {
        Get.snackbar("Error", "Split total cannot exceed Grand Total",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        return false;
      }
      received = totalPaid;
      if (totalPaid < grandTotal - 0.01) {
        due = grandTotal - totalPaid;
      }

      for (var e in rxSplitEntries) {
        if ((e.mode.value == 'UPI' || e.mode.value == 'NETBANKING') && e.utrController.text.trim().isEmpty) {
          Get.snackbar(
            "Error",
            "Please enter UTR/Reference Number for online split portion",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return false;
        }
      }
    }

    if (due > 0.01) {
      try {
        final posController = Get.find<ControllerHomePos>();
        if (posController.rxSelectedCustomer.value == null) {
          Get.snackbar(
            "Customer Required",
            "Please map a customer details for the pending due amount (₹${due.toStringAsFixed(2)}).",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade800,
            colorText: Colors.white,
          );
          return false;
        }
      } catch (e) {
        return false;
      }
    }

    if (mode == "SPLIT") {
      for (var e in rxSplitEntries) {
        final amt = double.tryParse(e.amountController.text) ?? 0.0;
        if (e.mode.value == 'CASH') {
          splitC += amt;
        } else {
          splitO += amt;
        }
      }
    }

    final details = PaymentDetails(
      paymentMode: mode,
      amountReceived: mode == "SPLIT" ? 0.0 : received,
      dueAmount: due,
      changeReturned: change,
      utrNumber: utrController.text.trim(),
      splitCash: splitC,
      splitOnline: splitO,
    );

    Get.back(result: details);
    return true;
  }

  @override
  void onClose() {
    amountController.dispose();
    utrController.dispose();
    for (var e in rxSplitEntries) {
      e.dispose();
    }
    super.onClose();
  }
}
