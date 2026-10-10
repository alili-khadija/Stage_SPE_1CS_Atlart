import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;

import '../app_session.dart';
import '../services/auth_api.dart';
import '../services/reservation_api.dart';

String formatMoney(int amount, String currency) {
  final digits = amount.toString();
  final formatted = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) formatted.write(' ');
    formatted.write(digits[i]);
  }
  return '$formatted $currency';
}

class Product {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.artisanName,
    required this.artisanLocation,
    this.backendId,
    this.currency = 'DZD',
    this.category = 'Artisanat',
    this.description = '',
    this.stock,
    this.priceNote = 'Prix fixe',
    this.allowsPickup = true,
    this.allowsDelivery = true,
    this.deliveryFee = 0,
    this.autoAccept = false,
    this.isMine = false,
    this.imageAsset,
    this.imagePath,
    this.thumbColor = const Color(0xFFA9CCEE),
  });

  final String id;
  final String? backendId;
  final String title;
  final int price;
  final String currency;
  final String category;
  final String description;
  final int? stock;
  final String priceNote;
  final String artisanName;
  final String artisanLocation;
  final bool allowsPickup;
  final bool allowsDelivery;
  final int deliveryFee;
  final bool autoAccept;
  final bool isMine;
  final String? imageAsset;
  final String? imagePath;
  final Color thumbColor;

  String get priceLabel => formatMoney(price, currency);

  static const demoTeapot = Product(
    id: 'theiere-terre-cuite',
    title: 'Théière en terre cuite',
    category: 'Poterie',
    price: 4500,
    currency: 'DZD',
    stock: 12,
    description:
        'Théière artisanale faite main, cuite au four traditionnel, motifs '
        'gravés à la main. Chaque pièce est unique dans ses finitions.',
    artisanName: 'Atelier Dorra',
    artisanLocation: 'Tlemcen, Algérie',
    deliveryFee: 600,
  );
}

enum FulfillmentMode { pickup, delivery }

enum OrderStatus { pending, accepted, completed, declined, cancelled }

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
    OrderStatus.pending => 'En attente',
    OrderStatus.accepted => 'Acceptée',
    OrderStatus.completed => 'Terminée',
    OrderStatus.declined => 'Refusée',
    OrderStatus.cancelled => 'Annulée',
  };
}

class OrderContact {
  const OrderContact({
    required this.phone,
    this.address = '',
    this.city = '',
    this.note = '',
  });

  final String phone;
  final String address;
  final String city;
  final String note;
}

class Order {
  const Order({
    required this.id,
    required this.product,
    required this.quantity,
    required this.mode,
    required this.contact,
    required this.placedAt,
    required this.status,
  });

  final String id;
  final Product product;
  final int quantity;
  final FulfillmentMode mode;
  final OrderContact contact;
  final DateTime placedAt;
  final OrderStatus status;

  int get subtotal => product.price * quantity;
  int get deliveryFee =>
      mode == FulfillmentMode.delivery ? product.deliveryFee : 0;
  int get total => subtotal + deliveryFee;

  Order copyWith({OrderStatus? status}) => Order(
    id: id,
    product: product,
    quantity: quantity,
    mode: mode,
    contact: contact,
    placedAt: placedAt,
    status: status ?? this.status,
  );
}

class OrderStore extends ChangeNotifier {
  OrderStore._();

  static final OrderStore instance = OrderStore._();

  final List<Order> _orders = [];
  int _sequence = 1041;

  List<Order> get orders => List.unmodifiable(_orders);

  Order? byId(String id) {
    for (final order in _orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  int stockLeft(Product product) {
    final stock = product.stock;
    if (stock == null) return 999;
    final ordered = _orders
        .where(
          (order) =>
              order.product.id == product.id &&
              (order.status == OrderStatus.pending ||
                  order.status == OrderStatus.accepted ||
                  order.status == OrderStatus.completed),
        )
        .fold<int>(0, (sum, order) => sum + order.quantity);
    return math.max(0, stock - ordered);
  }

  Future<Order> place({
    required Product product,
    required int quantity,
    required FulfillmentMode mode,
    required OrderContact contact,
  }) async {
    if (product.isMine) {
      throw StateError('Vous ne pouvez pas commander votre propre article.');
    }
    if (quantity < 1 || quantity > stockLeft(product)) {
      throw StateError('Le stock disponible a changé. Vérifiez la quantité.');
    }
    if (mode == FulfillmentMode.pickup && !product.allowsPickup) {
      throw StateError(
        'Le retrait atelier n’est pas disponible pour cet article.',
      );
    }
    if (mode == FulfillmentMode.delivery && !product.allowsDelivery) {
      throw StateError('La livraison n’est pas disponible pour cet article.');
    }
    if (mode == FulfillmentMode.delivery &&
        (contact.address.trim().isEmpty || contact.city.trim().isEmpty)) {
      throw StateError('Renseignez une adresse et une ville de livraison.');
    }
    if (contact.phone.trim().isEmpty) {
      throw StateError('Renseignez un numéro de téléphone.');
    }

    if (AuthApi.useBackend) {
      final token = AtlartSession.instance.token;
      final backendId = product.backendId;
      if (token == null) {
        throw StateError('Connectez-vous pour passer une commande.');
      }
      if (backendId == null || backendId.isEmpty) {
        throw StateError(
          'Cet article de démonstration n’est pas relié au catalogue backend.',
        );
      }
      final reservation = await ReservationApi.create(
        token: token,
        oeuvreId: backendId,
        quantity: quantity,
        fulfillment: mode == FulfillmentMode.pickup
            ? 'RETRAIT_ATELIER'
            : 'LIVRAISON',
        phone: contact.phone,
        address: contact.address,
        city: contact.city,
        note: contact.note,
      );
      final reservationId = '${reservation['id'] ?? ''}';
      if (reservationId.isEmpty) {
        throw const ReservationApiException(
          'Le serveur n’a pas retourné l’identifiant de la réservation.',
        );
      }
      final order = Order(
        id: reservationId,
        product: product,
        quantity: int.tryParse('${reservation['quantite']}') ?? quantity,
        mode: mode,
        contact: contact,
        placedAt: DateTime.tryParse('${reservation['date_reservation']}') ??
            DateTime.now(),
        status: OrderStatus.pending,
      );
      _orders.insert(0, order);
      notifyListeners();
      return order;
    }

    // Mode démo hors ligne : conserve une commande locale temporaire.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (quantity > stockLeft(product)) {
      throw StateError('Le stock disponible a changé. Vérifiez la quantité.');
    }

    final order = Order(
      id: 'AT-${++_sequence}',
      product: product,
      quantity: quantity,
      mode: mode,
      contact: contact,
      placedAt: DateTime.now(),
      status: product.autoAccept ? OrderStatus.accepted : OrderStatus.pending,
    );
    _orders.insert(0, order);
    notifyListeners();
    return order;
  }

  Future<void> cancel(String orderId) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 || _orders[index].status != OrderStatus.pending) return;
    if (AuthApi.useBackend) {
      final token = AtlartSession.instance.token;
      if (token == null) {
        throw StateError('Connectez-vous pour annuler cette réservation.');
      }
      await ReservationApi.updateStatus(
        token: token,
        reservationId: orderId,
        status: 'ANNULEE',
      );
    }
    _orders[index] = _orders[index].copyWith(status: OrderStatus.cancelled);
    notifyListeners();
  }

  void updateStatus(String orderId, OrderStatus status) {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0 || _orders[index].status == status) return;
    _orders[index] = _orders[index].copyWith(status: status);
    notifyListeners();
  }
}
