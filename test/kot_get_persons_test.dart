import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_snacks/src/core/const/api_routes.dart';
import 'package:pick_my_snacks/src/data/model/kot_get_persons.dart';

void main() {
  test('builds the get-persons endpoint with the selected table ID', () {
    expect(ApiRoutes.kotGetPersons(1), 'kot_get_persons/1');
    expect(ApiRoutes.kotGetPersons(9), 'kot_get_persons/9');
  });

  test('parses persons returned inside the API data object', () {
    final response = KotGetPersonsResponse.fromJson({
      'status': true,
      'message': 'Persons fetched successfully',
      'data': {
        'persons': [
          {'person_id': 'P1-260918-7'},
          {'person_id': 'P1-260918-8', 'person_number': 8},
        ],
      },
    });

    expect(response.status, isTrue);
    expect(response.persons, hasLength(2));
    expect(response.persons.first.personId, 'P1-260918-7');
    expect(response.persons.first.personNumber, 7);
    expect(response.persons.last.personId, 'P1-260918-8');
    expect(response.persons.last.personNumber, 8);
  });

  test('parses persons when the API data itself is a list', () {
    final response = KotGetPersonsResponse.fromJson({
      'status': true,
      'data': [
        {'person_id': 'P1-260918-1'},
      ],
    });

    expect(response.persons.single.personId, 'P1-260918-1');
    expect(response.persons.single.personNumber, 1);
  });

  test('restores nested person products and their hold-order IDs', () {
    final response = KotGetPersonsResponse.fromJson({
      'status': true,
      'data': {
        'persons': [
          {
            'person_id': 'P1-260918-7',
            'orders': [
              {
                'id': 234,
                'products': [
                  {
                    'id': 265,
                    'product_id': 1,
                    'product_name': 'Black Forest',
                    'quantity': 1,
                    'price': 999.89,
                    'unit': 'kg',
                  },
                ],
              },
            ],
          },
        ],
      },
    });

    final person = response.persons.single;
    expect(person.holdOrderIds, contains(234));
    expect(person.products.single.holdOrderId, 234);
    expect(person.products.single.id, 265);
    expect(person.products.single.productName, 'Black Forest');
  });
}
