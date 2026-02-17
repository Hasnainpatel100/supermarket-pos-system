/*
username: owner, afroz, store, cash, inventory, accountant, audit
password: 12345


dart run build_runner build --delete-conflicting-outputs

final query = _boxUser
  .query(EntityUser_.username.equals(email) & EntityUser_.password.equals(password))
  .build();
final user = query.findFirst();
if (user == null) { /*invalid credential*/ }
**/