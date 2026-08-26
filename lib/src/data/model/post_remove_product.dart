class PostRemoveProduct {
  bool? status;
  String? message;
  Data? data;

  PostRemoveProduct({this.status, this.message, this.data});

  PostRemoveProduct.fromJson(Map<String, dynamic> json) {
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
  RemovedProduct? removedProduct;
  int? remainingProductCount;
  Order? order;

  Data({this.removedProduct, this.remainingProductCount, this.order});

  Data.fromJson(Map<String, dynamic> json) {
    removedProduct = json['removed_product'] != null
        ? RemovedProduct.fromJson(json['removed_product'])
        : null;
    remainingProductCount = json['remaining_product_count'];
    order = json['order'] != null ? Order.fromJson(json['order']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (removedProduct != null) {
      data['removed_product'] = removedProduct!.toJson();
    }
    data['remaining_product_count'] = remainingProductCount;
    if (order != null) {
      data['order'] = order!.toJson();
    }
    return data;
  }
}

class RemovedProduct {
  int? detailId;
  int? productId;
  String? productName;
  int? quantity;
  int? rowTotal;

  RemovedProduct(
      {this.detailId,
      this.productId,
      this.productName,
      this.quantity,
      this.rowTotal});

  RemovedProduct.fromJson(Map<String, dynamic> json) {
    detailId = json['detail_id'];
    productId = json['product_id'];
    productName = json['product_name'];
    quantity = json['quantity'];
    rowTotal = json['row_total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['detail_id'] = detailId;
    data['product_id'] = productId;
    data['product_name'] = productName;
    data['quantity'] = quantity;
    data['row_total'] = rowTotal;
    return data;
  }
}

class Order {
  int? id;
  String? orderId;
  double? subtotal;
  int? gst;
  int? discount;
  int? charge;
  double? total;
  List<Products>? products;

  Order(
      {this.id,
      this.orderId,
      this.subtotal,
      this.gst,
      this.discount,
      this.charge,
      this.total,
      this.products});

  Order.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    orderId = json['order_id'];
    subtotal = json['subtotal'];
    gst = json['gst'];
    discount = json['discount'];
    charge = json['charge'];
    total = json['total'];
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
    data['subtotal'] = subtotal;
    data['gst'] = gst;
    data['discount'] = discount;
    data['charge'] = charge;
    data['total'] = total;
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
