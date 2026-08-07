import 'package:flutter_test/flutter_test.dart';
import 'package:pick_my_snacks/src/data/model/get_hold.dart';

void main() {
  test('parses held-order summaries with numeric values', () {
    final response = GetHoldOrdersResponse.fromJson({
      'status': true,
      'message': 'Held bills fetched',
      'data': [
        {
          'id': 12,
          'order_id': 'ORD0012',
          'date_time': '2026-07-27 15:30:00',
          'items_count': 4,
          'subtotal': '1195.00',
          'gst': '59.75',
          'discount': 0,
          'charge': 0,
          'total': '1254.75',
          'payment_mode': 'cash',
          'staff_id': '1',
          'status': 'hold',
        },
      ],
    });

    expect(response.status, isTrue);
    expect(response.data, hasLength(1));
    expect(response.data!.single.orderId, 'ORD0012');
    expect(response.data!.single.itemsCount, 4);
    expect(response.data!.single.gst, 59.75);
    expect(response.data!.single.total, 1254.75);
  });

  test('parses held bills returned inside a nested data object', () {
    final response = GetHoldOrdersResponse.fromJson({
      'status': true,
      'data': {
        'held_bills': [
          {
            'id': 82,
            'order_id': '82',
            'items_count': 1,
            'total': '15.00',
            'status': 'hold',
          },
        ],
      },
    });

    expect(response.data, hasLength(1));
    expect(response.data!.single.id, 82);
    expect(response.data!.single.total, 15);
  });
}
