import 'package:pick_my_snacks/src/data/model/kot_add_person.dart';

abstract interface class KotAddPersonRepository {
  Future<KotAddPersonResponse> addPerson(KotAddPersonRequest request);
}
