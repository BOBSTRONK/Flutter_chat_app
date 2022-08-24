import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/user_service_contract.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

class UserService implements IUserService {
  final Connection _connection;
  final RethinkDb r;

  UserService(this.r, this._connection);

  @override
  Future<User> connect(User user) async {
    var data = user.toJson();
    //if id is not present , rethink will automatically creates a id
    //if a id is there then rethink we use that id as an existing user
    //then will update that user instead of create a new user
    data['id'] = user.getId();

    final result = await r.table('users').insert(data, {
      'conflict': 'update',
      //whenever the user is created,db will return the changes and then from that change
      //i will create a new user object to return and that new user object will have the id of the created user
      'return_changes': true,
    }).run(_connection);

    return User.fromJson(result['changes'].first['new_val']);
    //each change returned by would have like an old value and a new value as json object
    //fetch the new value json object and create a user from that.
  }

  @override
  Future<void> disconnect(User user) async {
    await r.table('users').update({
      'id': user.getId(),
      'active': false,
      'last_seen': DateTime.now(),
    }).run(_connection);
    _connection.close();
  }

  @override
  Future<List<User>> online() async {
    //cursor is stream of data
    Cursor users = await r.table('users').filter({'active': true}).run(
        _connection); //query to take all the record in users table quale nell campo active è vero
    //fetch all the user from the cursor
    final userList = await users.toList();
    //each item in the list to a user model and return a new created list of users.
    return userList.map((item) => User.fromJson(item)).toList();
  }
}
