import '../models/user.dart';

/**contract represents like an interface or an abstraction
so our code will always depends on abstraction so it will be easy to switch all parts **/

abstract class IUserService {
  //accept a user object comming in for the first time without
  //an id, and once a user is connected and id will return
  //so the user object will be returned with the created id
  Future<User> connect(User user);

  Future<List<User>> online();

  Future<void> disconnect(User user);
}
