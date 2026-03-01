import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_market/service/service_currency.dart';

class PaymentDetails {
  final String paymentMode;
  final double amountReceived;
  final double changeReturned;
  final String utrNumber;
  final double splitCash;
  final double splitOnline;

  PaymentDetails({
    required this.paymentMode,
    this.amountReceived = 0.0,
    this.changeReturned = 0.0,
    this.utrNumber = '',
    this.splitCash = 0.0,
    this.splitOnline = 0.0,
  });
}

class ControllerPaymentOptions extends GetxController {
  final double grandTotal;
  final ServiceCurrency serviceCurrency = Get.find();

  final rxSelectedMode = "CASH".obs; // CASH, UPI, NETBANKING, SPLIT

  // Cash mode fields
  final cashAmountController = TextEditingController();
  final rxCashAmountReceived = 0.0.obs;
  final rxChangeReturned = 0.0.obs;

  // Online mode fields (UPI, Netbanking)
  final utrController = TextEditingController();

  // Split mode fields
  final splitCashController = TextEditingController();
  final splitOnlineController = TextEditingController();
  final rxSplitCash = 0.0.obs;
  final rxSplitOnline = 0.0.obs;

  ControllerPaymentOptions({required this.grandTotal});

  @override
  void onInit() {
    super.onInit();
    // Default cash amount received to the grand total
    cashAmountController.text = grandTotal.toStringAsFixed(2);
    rxCashAmountReceived.value = grandTotal;
    calculateCashReturn();

    // Default split logic
    splitCashController.text = (grandTotal / 2).toStringAsFixed(2);
    splitOnlineController.text = (grandTotal / 2).toStringAsFixed(2);
    rxSplitCash.value = grandTotal / 2;
    rxSplitOnline.value = grandTotal / 2;
  }

  void setPaymentMode(String mode) {
    rxSelectedMode.value = mode;
  }

  void onCashAmountChanged(String val) {
    rxCashAmountReceived.value = double.tryParse(val) ?? 0.0;
    calculateCashReturn();
  }

  void calculateCashReturn() {
    double returnAmount = rxCashAmountReceived.value - grandTotal;
    rxChangeReturned.value = returnAmount;
  }

  void onSplitCashChanged(String val) {
    rxSplitCash.value = double.tryParse(val) ?? 0.0;
  }

  void onSplitOnlineChanged(String val) {
    rxSplitOnline.value = double.tryParse(val) ?? 0.0;
  }

  bool validateAndConfirm() {
    final mode = rxSelectedMode.value;

    if (mode == "CASH") {
      if (rxCashAmountReceived.value < grandTotal) {
        Get.snackbar(
          "Error",
          "Amount received cannot be less than Grand Total",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } else if (mode == "UPI" || mode == "NETBANKING") {
      if (utrController.text.trim().isEmpty) {
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
      final totalPaid = rxSplitCash.value + rxSplitOnline.value;
      // Allow minor floating point difference
      if ((totalPaid - grandTotal).abs() > 0.01) {
        Get.snackbar(
          "Error",
          "Split amounts must exactly match Grand Total (${grandTotal.toStringAsFixed(2)})",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
      if (utrController.text.trim().isEmpty && rxSplitOnline.value > 0) {
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

    final details = PaymentDetails(
      paymentMode: mode,
      amountReceived: rxCashAmountReceived.value,
      changeReturned: rxChangeReturned.value < 0 ? 0 : rxChangeReturned.value,
      utrNumber: utrController.text.trim(),
      splitCash: rxSplitCash.value,
      splitOnline: rxSplitOnline.value,
    );

    Get.back(result: details);
    return true;
  }

  @override
  void onClose() {
    cashAmountController.dispose();
    utrController.dispose();
    splitCashController.dispose();
    splitOnlineController.dispose();
    super.onClose();
  }
}
