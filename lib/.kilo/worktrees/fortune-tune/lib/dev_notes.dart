/*
username: owner, afroz, store, cash, inventory, accountant, audit
password: 12345


flutter pub run build_runner build
dart run build_runner build --delete-conflicting-outputs

final query = _boxUser
  .query(EntityUser_.username.equals(email) & EntityUser_.password.equals(password))
  .build();
final user = query.findFirst();
if (user == null) { /*invalid credential*/ }












#inventory:
#add item: [milk]
item -> master product item
1. when stock arrives [select item: milk] impact on 2 tables:
add new: batch [name, expiry date, qty]
add new: stock_tnx [100 qty], type: IN => show stock_tnx in expiry screen if expired
2. item.id==null ? insert: update => stock_summary.qty + 100 [only one paramater i.e. qty]
_____
#pos:
add new: stock_tnx [-5 qty], type: OUT => show stock_tnx in expiry screen if expired
update: stock_summary.qty-5
update: batch.qty - 5 [logic #BATCH_LOGIC]

#BATCH_LOGIC
Decide which physical stock goes out (FIFO):
Suppose:
• Batch A → qty 1 [today]
• Batch B → qty 99 [2 days later]
To sell 2:
• Take 1 from Batch A
• Take 1 from Batch B
Update batches:
Batch A quantity → 0
Batch B quantity → 98
_____
#expiry:
cron job, daily run at once ->
WHERE expiryDate <= now + 30 days
ockTransaction - type = OUT - quantity = -X - referenceType = expired
_____
# Stock Adjustment:
add new: stock_tnx [-5 qty], type: ADJUST
update: stock_summary.qty-5
_____
# stock count: auditor cross check system count and physical item count
add new: StockCount:  systemQty - physicalQty = 0 => correct
add new if sysCount != phycialCount: stock_tnx [-5 qty], type: COUNT
update: stock_summary.qty-5

StockTransaction - type = COUNT - quantity = -20 - referenceType = audit
**/