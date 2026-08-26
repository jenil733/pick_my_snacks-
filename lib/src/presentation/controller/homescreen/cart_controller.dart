import 'package:get/get.dart';
import 'package:pick_my_snacks/src/presentation/controller/homescreen/home_controller.dart';

class CartController extends GetxController {
  HomeController get _homeController => Get.find<HomeController>();

  final RxList<CartItem> cart = <CartItem>[].obs;
  final RxString paymentMethod = 'cash'.obs;
  final List<String> paymentMethods = ['cash', 'card', 'upi'];
  final RxString discountType = 'none'.obs;
  final Rx<double> discountValue = 0.0.obs;
  final RxString discountOffer = ''.obs;
  final RxString discountReason = ''.obs;
  final Rx<double> chargeAmount = 0.0.obs;
  final RxString chargeReason = ''.obs;
  final RxBool isSyncingTotals = false.obs;
  final Rxn<double> backendSubtotal = Rxn<double>();
  final Rxn<double> backendGst = Rxn<double>();
  final Rxn<double> backendTotal = Rxn<double>();

  double get cartSubtotal => cart.fold(0.0, (sum, item) => sum + (item.quantity * item.product.price));
  double get cartTotalQuantity => cart.fold(0.0, (sum, item) => sum + item.quantity);

  void addProduct(Product product, {int quantity = 1}) {
    _homeController.addProduct(product);
  }

  void removeProduct(CartItem item) {
    _homeController.remove(item);
  }

  void incrementQuantity(CartItem item) {
    _homeController.increment(item);
  }

  void decrementQuantity(CartItem item) {
    _homeController.decrement(item);
  }

  void clearCart() {
    _homeController.clearCart();
  }
}
