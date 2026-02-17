import 'package:objectbox/objectbox.dart';

@Entity()
class EntityTodo {
  @Id()
  int id;
  String title;
  bool done;

  EntityTodo({this.id = 0, required this.title, this.done = false});
}
