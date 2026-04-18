enum PaymentMode {
  cash,
  cheque,
  bankTransfer,
  upi;

  String get label => switch (this) {
    PaymentMode.cash => 'Cash',
    PaymentMode.cheque => 'Cheque',
    PaymentMode.bankTransfer => 'Bank Transfer',
    PaymentMode.upi => 'UPI',
  };

  int get iconCodePoint => switch (this) {
    PaymentMode.cash => 0xe0ca,   // Icons.payments_rounded
    PaymentMode.cheque => 0xe1bb, // Icons.description_rounded
    PaymentMode.bankTransfer => 0xe530, // Icons.account_balance_rounded
    PaymentMode.upi => 0xf04b0,  // Icons.phone_android_rounded fallback
  };
}
