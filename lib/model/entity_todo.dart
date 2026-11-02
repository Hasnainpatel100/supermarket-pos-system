import 'package:objectbox/objectbox.dart';
import 'package:objectid/objectid.dart';

@Entity()
class EntityTodo {
  @Id()
  int id = 0;
  String title;
  bool done;


  @Unique()
  String objectId = ObjectId().hexString;  //mongo id

  EntityTodo({this.id = 0, required this.title, this.done = false});
}
