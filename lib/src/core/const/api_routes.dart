class ApiRoutes {
  ApiRoutes._();

  static const baseUrl = 'http://64.227.170.206/iyangarbakery.com/public/api/';

  static const products = 'get_product';
  static const lowStockProducts = 'lowStockProducts';
  static const outOfStockProducts = 'outOfStockProducts';
  static const notificationCount = 'notificationCount';
  static const fcmToken = 'fcm_token';
  static const login = 'login_staff';
  static const staff = 'get_staff';
  static const tables = 'get_kot_tables';
  static const save = 'save_order';
  static const hold = 'hold_save_order';
  static const getHold = 'get_hold_bills';
  static const tableStatus = 'kot_table_status';
  static const kot = 'kot_hold_save_order';
  static const remove = 'kot_hold_remove_product';
  static const rquantity = 'kot_hold_remove_quantity';
  static const takeAwayHold = 'take_away_hold';
  static const takeAwaySaveOrder = 'take_away_save_order';
  static const takeAwayProcessing = 'take_away_processing';
  static String takeAwayProcessingView(int holdOrderId) =>
      'take_away_processing_view/$holdOrderId';
  static const takeAwayCompleted = 'take_away_completed';
  static String takeAwayCompletedView(int orderId) =>
      'take_away_completed_view/$orderId';
  static String kotSave(int tableId) => 'kot_save_order/$tableId';
  static String processingOrder(int tableId) => 'get_processing_order/$tableId';
  static String resumeHoldBill(int orderId) => 'resume_hold_bill/$orderId';
  static String deleteHoldBill(int orderId) => 'delete_hold_bill/$orderId';

  static const apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: 'dvvervdgdgdfgmtbjL7554434pvxmjts6MFL3F9FIuAPjmFI0g=',
  );
}
