import 'package:pick_my_snacks/src/data/model/kot_get_persons.dart';

abstract interface class KotGetPersonsRepository {
  Future<KotGetPersonsResponse> getPersons(int tableId);
}
