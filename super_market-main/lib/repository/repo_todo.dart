import 'package:objectbox/objectbox.dart';
import '../model/entity_todo.dart';

class RepoTodo {
  final Box<EntityTodo> box;

  RepoTodo(this.box);

  List<EntityTodo> all() => box.getAll();

  int upsert(EntityTodo todo) => box.put(todo);

  bool remove(int id) => box.remove(id);
}
