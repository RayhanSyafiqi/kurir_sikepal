class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'http://202.10.44.54';

  // ===== AUTH =====
  static const String login = '/api/mobile/auth/login';
  static const String me = '/api/mobile/auth/me';

  // ===== RESOURCES =====
  static const String stores = '/api/mobile/stores';
  static const String orders = '/api/mobile/orders';
  static const String retur = '/api/mobile/retur';
  static const String routes = '/api/mobile/routes';
  static const String products = '/api/mobile/products';
  static const String bulkPayment = '/api/mobile/orders/bulk-payment';
  static const String extraOrders = '/api/mobile/extra-orders';

  static String storeDetail(String id) => '$stores/$id';
  static String orderDetail(String id) => '$orders/$id';
  static String routeDetail(String id) => '$routes/$id';
  static String orderDelivery(String id) => '$orders/$id/delivery';
  static String orderPayment(String id) => '$orders/$id/payment';
  static String extraOrderDetail(String id) => '$extraOrders/$id';
  static String extraOrderPayment(String id) => '$extraOrders/$id/payment';
  static String extraOrderDelivery(String id) => '$extraOrders/$id/delivery';
}
