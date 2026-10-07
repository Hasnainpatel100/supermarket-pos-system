enum PurchaseStatus {
  draft, // Created but not finalized
  ordered, // Sent to supplier
  partial, // Some items received
  received, // All items received
  cancelled, // Purchase cancelled
}

extension PurchaseStatusExtension on PurchaseStatus {
  String get label {
    switch (this) {
      case PurchaseStatus.draft:
        return 'Draft';
      case PurchaseStatus.ordered:
        return 'Ordered';
      case PurchaseStatus.partial:
        return 'Partial';
      case PurchaseStatus.received:
        return 'Received';
      case PurchaseStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Badge color for UI
  int get colorValue {
    switch (this) {
      case PurchaseStatus.draft:
        return 0xFF9E9E9E; // grey
      case PurchaseStatus.ordered:
        return 0xFF2196F3; // blue
      case PurchaseStatus.partial:
        return 0xFFFF9800; // orange
      case PurchaseStatus.received:
        return 0xFF4CAF50; // green
      case PurchaseStatus.cancelled:
        return 0xFFF44336; // red
    }
  }
}
