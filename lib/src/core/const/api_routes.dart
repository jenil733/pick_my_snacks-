class ApiRoutes {
  ApiRoutes._();

  static const baseUrl =
      'http://64.227.170.206/iyangarbakery.com/public/api/';
  static const products = 'get_product';
  static const login = 'login_staff';
  static const staff = 'get_staff';
  static const save = 'save_order';
  static const hold = 'hold_save_order';
  static const getHold = 'get_hold_bills';
  static String resumeHoldBill(int orderId) => 'resume_hold_bill/$orderId';
  static String deleteHoldBill(int orderId) => 'delete_hold_bill/$orderId';

  static const apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: 'dvvervdgdgdfgmtbjL7554434pvxmjts6MFL3F9FIuAPjmFI0g=',
  );
}
