import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pick_my_snacks/src/data/model/kot_add_person.dart';
import 'package:pick_my_snacks/src/data/model/kot_delete_person.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_add_person_repository.dart';
import 'package:pick_my_snacks/src/domain/repository/kot_delete_person_repository.dart';
import 'package:pick_my_snacks/src/domain/usecase/add_kot_person_usecase.dart';
import 'package:pick_my_snacks/src/domain/usecase/delete_kot_person_usecase.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/cart_controller.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(CartController());
  });

  tearDown(Get.reset);

  test('builds add-person fields from the selected table and staff', () {
    const request = KotAddPersonRequest(
      tableId: 4,
      staffId: 3,
      paymentMode: 'cash',
    );

    expect(request.toFormFields(), {
      'staff_id': 3,
      'payment_mode': 'cash',
      'table_id': 4,
    });
    expect(request.productIds, [1]);
  });

  test('extracts a person ID from a nested API order response', () {
    final response = KotAddPersonResponse.fromJson({
      'status': true,
      'message': 'Person created',
      'data': {
        'person': {'person_id': 'P1-260918-1'},
      },
    });

    expect(response.status, isTrue);
    expect(response.personId, 'P1-260918-1');
  });

  test('creates a local person only after the API returns its ID', () async {
    final repository = _FakeKotAddPersonRepository();
    final deleteRepository = _FakeKotDeletePersonRepository();
    final controller = HomeController(
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      AddKotPersonUseCase(repository),
      DeleteKotPersonUseCase(deleteRepository),
    );
    await controller.showKotPersons(4);

    final personNumber = await controller.addKotPerson(
      staffName: 'Arun',
      staffId: 3,
    );

    expect(personNumber, 1);
    expect(repository.requests.single.tableId, 4);
    expect(repository.requests.single.staffId, 3);
    expect(repository.requests.single.paymentMode, 'cash');
    expect(controller.kotPersonBills[4]!.single.personId, 'P1-260918-1');

    final deleted = await controller.deleteKotPerson(1);
    expect(deleted, isTrue);
    expect(deleteRepository.requests, [(4, 'P1-260918-1')]);
    expect(controller.kotPersonBills[4], isNull);
  });
}

class _FakeKotDeletePersonRepository implements KotDeletePersonRepository {
  final requests = <(int, String)>[];

  @override
  Future<KotDeletePersonResponse> deletePerson(
    int tableId,
    String personId,
  ) async {
    requests.add((tableId, personId));
    return const KotDeletePersonResponse(
      status: true,
      message: 'Person deleted',
    );
  }
}

class _FakeKotAddPersonRepository implements KotAddPersonRepository {
  final requests = <KotAddPersonRequest>[];

  @override
  Future<KotAddPersonResponse> addPerson(KotAddPersonRequest request) async {
    requests.add(request);
    return const KotAddPersonResponse(
      status: true,
      message: 'Person created',
      personId: 'P1-260918-1',
    );
  }
}
