enum StockTxnType {
  sell, // Stock sold via POS
  add, // Stock added via new batch (hasExpiry=true)
  adjust, // Stock directly adjusted (hasExpiry=false)
  deduct, // Stock deducted via FIFO (hasExpiry=true, decrement)
  purchaseIn, //Stock received via Purchase Order
  returnStock, // Stock returned via bill cancellation/edit
}