class removequantity {
  bool? status;
  String? message;
  Data? data;

  removequantity({this.status, this.message, this.data});

  removequantity.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
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
        json['product'] != null ? Product.fromJson(json['product']) : null;
    order = json['order'] != null ? Order.fromJson(json['order']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (product != null) {
      data['product'] = product!.toJson();
    }
    if (order != null) {
      data['order'] = order!.toJson();
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['detail_id'] = detailId;
    data['product_id'] = productId;
    data['product_name'] = productName;
    data['previous_quantity'] = previousQuantity;
    data['removed_quantity'] = removedQuantity;
    data['remaining_quantity'] = remainingQuantity;
    data['remaining_unit_value'] = remainingUnitValue;
    data['row_total'] = rowTotal;
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
        products!.add(Products.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['order_id'] = orderId;
    data['table_id'] = tableId;
    data['branch_id'] = branchId;
    data['staff_id'] = staffId;
    data['subtotal'] = subtotal;
    data['gst'] = gst;
    data['discount'] = discount;
    data['charge'] = charge;
    data['total'] = total;
    data['status'] = status;
    if (products != null) {
      data['products'] = products!.map((v) => v.toJson()).toList();
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['order_id'] = orderId;
    data['product_id'] = productId;
    data['product_name'] = productName;
    data['product_code'] = productCode;
    data['variant_code'] = variantCode;
    data['mrp'] = mrp;
    data['price'] = price;
    data['quantity'] = quantity;
    data['unit_value'] = unitValue;
    data['unit'] = unit;
    data['tax'] = tax;
    data['row_total'] = rowTotal;
    data['is_kot'] = isKot;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
