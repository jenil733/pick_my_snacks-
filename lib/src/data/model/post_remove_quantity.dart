class removequantity {
  bool? status;
  String? message;
  Data? data;

  removequantity({this.status, this.message, this.data});

  removequantity.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  Product? product;
  Order? order;

  Data({this.product, this.order});

  Data.fromJson(Map<String, dynamic> json) {
    product =
        json['product'] != null ? new Product.fromJson(json['product']) : null;
    order = json['order'] != null ? new Order.fromJson(json['order']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.product != null) {
      data['product'] = this.product!.toJson();
    }
    if (this.order != null) {
      data['order'] = this.order!.toJson();
    }
    return data;
  }
}

class Product {
  int? detailId;
  int? productId;
  String? productName;
  int? previousQuantity;
  int? removedQuantity;
  int? remainingQuantity;
  int? remainingUnitValue;
  int? rowTotal;

  Product(
      {this.detailId,
      this.productId,
      this.productName,
      this.previousQuantity,
      this.removedQuantity,
      this.remainingQuantity,
      this.remainingUnitValue,
      this.rowTotal});

  Product.fromJson(Map<String, dynamic> json) {
    detailId = json['detail_id'];
    productId = json['product_id'];
    productName = json['product_name'];
    previousQuantity = json['previous_quantity'];
    removedQuantity = json['removed_quantity'];
    remainingQuantity = json['remaining_quantity'];
    remainingUnitValue = json['remaining_unit_value'];
    rowTotal = json['row_total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['detail_id'] = this.detailId;
    data['product_id'] = this.productId;
    data['product_name'] = this.productName;
    data['previous_quantity'] = this.previousQuantity;
    data['removed_quantity'] = this.removedQuantity;
    data['remaining_quantity'] = this.remainingQuantity;
    data['remaining_unit_value'] = this.remainingUnitValue;
    data['row_total'] = this.rowTotal;
    return data;
  }
}

class Order {
  int? id;
  String? orderId;
  int? tableId;
  int? branchId;
  int? staffId;
  double? subtotal;
  int? gst;
  int? discount;
  int? charge;
  double? total;
  String? status;
  List<Products>? products;

  Order(
      {this.id,
      this.orderId,
      this.tableId,
      this.branchId,
      this.staffId,
      this.subtotal,
      this.gst,
      this.discount,
      this.charge,
      this.total,
      this.status,
      this.products});

  Order.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    orderId = json['order_id'];
    tableId = json['table_id'];
    branchId = json['branch_id'];
    staffId = json['staff_id'];
    subtotal = json['subtotal'];
    gst = json['gst'];
    discount = json['discount'];
    charge = json['charge'];
    total = json['total'];
    status = json['status'];
    if (json['products'] != null) {
      products = <Products>[];
      json['products'].forEach((v) {
        products!.add(new Products.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['order_id'] = this.orderId;
    data['table_id'] = this.tableId;
    data['branch_id'] = this.branchId;
    data['staff_id'] = this.staffId;
    data['subtotal'] = this.subtotal;
    data['gst'] = this.gst;
    data['discount'] = this.discount;
    data['charge'] = this.charge;
    data['total'] = this.total;
    data['status'] = this.status;
    if (this.products != null) {
      data['products'] = this.products!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Products {
  int? id;
  int? orderId;
  int? productId;
  String? productName;
  String? productCode;
  String? variantCode;
  String? mrp;
  String? price;
  String? quantity;
  String? unitValue;
  String? unit;
  String? tax;
  String? rowTotal;
  String? isKot;
  String? createdAt;
  String? updatedAt;

  Products(
      {this.id,
      this.orderId,
      this.productId,
      this.productName,
      this.productCode,
      this.variantCode,
      this.mrp,
      this.price,
      this.quantity,
      this.unitValue,
      this.unit,
      this.tax,
      this.rowTotal,
      this.isKot,
      this.createdAt,
      this.updatedAt});

  Products.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    orderId = json['order_id'];
    productId = json['product_id'];
    productName = json['product_name'];
    productCode = json['product_code'];
    variantCode = json['variant_code'];
    mrp = json['mrp'];
    price = json['price'];
    quantity = json['quantity'];
    unitValue = json['unit_value'];
    unit = json['unit'];
    tax = json['tax'];
    rowTotal = json['row_total'];
    isKot = json['is_kot'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['order_id'] = this.orderId;
    data['product_id'] = this.productId;
    data['product_name'] = this.productName;
    data['product_code'] = this.productCode;
    data['variant_code'] = this.variantCode;
    data['mrp'] = this.mrp;
    data['price'] = this.price;
    data['quantity'] = this.quantity;
    data['unit_value'] = this.unitValue;
    data['unit'] = this.unit;
    data['tax'] = this.tax;
    data['row_total'] = this.rowTotal;
    data['is_kot'] = this.isKot;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
