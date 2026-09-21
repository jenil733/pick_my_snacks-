import 'package:pick_my_snacks/src/data/model/kot_delete_person.dart';

abstract interface class KotDeletePersonRepository {
  Future<KotDeletePersonResponse> deletePerson(int tableId, String personId);
}
