import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/controller/payment_controller.dart';
import 'package:frontend/controller/resell_controller.dart';
import 'package:frontend/views/cart_service.dart';
import 'package:frontend/views/favorite_service.dart';

void main() {
  setUp(() {
    CartService.items.clear();
    CartService.history.clear();
    CartService.resaleListings.clear();
    FavoriteService.favorites.clear();
  });

  group('ResellController.validateResellInput', () {
    test('accepts a valid ticket and price', () {
      expect(
        ResellController.validateResellInput(
          ticketId: 12,
          priceText: '1500',
          originalPrice: 1000,
        ),
        isNull,
      );
    });

    test('rejects a missing or invalid ticket id', () {
      for (final ticketId in <int?>[null, 0, -1]) {
        expect(
          ResellController.validateResellInput(
            ticketId: ticketId,
            priceText: '1500',
          ),
          'Please select a concert ticket to list for resale',
        );
      }
    });

    test('rejects invalid, zero, and negative prices', () {
      for (final price in ['abc', '0', '-1']) {
        expect(
          ResellController.validateResellInput(ticketId: 12, priceText: price),
          price == 'abc'
              ? 'Please enter a valid selling price'
              : 'The selling price must be greater than 0 THB',
        );
      }
    });

    test('rejects prices above the global maximum', () {
      expect(
        ResellController.validateResellInput(
          ticketId: 12,
          priceText: '1000000.01',
        ),
        'The selling price is too high',
      );
    });

    test('rejects markup above five times the original price', () {
      expect(
        ResellController.validateResellInput(
          ticketId: 12,
          priceText: '5001',
          originalPrice: 1000,
        ),
        'The selling price exceeds the maximum allowed markup',
      );
    });

    test('accepts the exact five-times markup boundary', () {
      expect(
        ResellController.validateResellInput(
          ticketId: 12,
          priceText: '5000',
          originalPrice: 1000,
        ),
        isNull,
      );
    });
  });

  group('PaymentController.validateCheckoutInput', () {
    String? validate({
      int? listingId = 10,
      String paymentMethod = 'Bank Transfer',
      String deliveryMethod = 'Parcel Shipping',
      String shippingInfo = '12 Main Street',
    }) =>
        PaymentController.validateCheckoutInput(
          listingId: listingId,
          paymentMethod: paymentMethod,
          deliveryMethod: deliveryMethod,
          shippingInfo: shippingInfo,
        );

    test('accepts complete checkout details', () {
      expect(validate(), isNull);
    });

    test('requires a valid listing id', () {
      expect(validate(listingId: null), 'Unable to find the requested ticket listing');
      expect(validate(listingId: 0), 'Unable to find the requested ticket listing');
    });

    test('requires a payment method', () {
      expect(validate(paymentMethod: '  '), 'Please select a payment method');
    });

    test('rejects unsupported delivery methods', () {
      expect(validate(deliveryMethod: 'Teleportation'), 'Invalid ticket pickup method');
    });

    test('asks for delivery address when parcel shipping info is blank', () {
      expect(
        validate(shippingInfo: '  '),
        'Please enter the shipping address for ticket delivery',
      );
    });

    test('asks for pickup details for meetup or digital transfer', () {
      for (final method in ['meetup', 'Digital Transfer']) {
        expect(
          validate(deliveryMethod: method, shippingInfo: ''),
          'Please specify the location/time or email for ticket pickup',
        );
      }
    });
  });

  group('PaymentController payment expiry helpers', () {
    test('returns zero for missing and invalid expiry values', () {
      expect(PaymentController.getRemainingSeconds(null), 0);
      expect(PaymentController.getRemainingSeconds('not a date'), 0);
      expect(PaymentController.isPaymentExpired(null), isTrue);
    });

    test('clamps expired timestamps to zero', () {
      final expired = DateTime.now().subtract(const Duration(minutes: 1));
      expect(PaymentController.getRemainingSeconds(expired.toIso8601String()), 0);
      expect(PaymentController.isPaymentExpired(expired.toIso8601String()), isTrue);
    });

    test('reports a future payment as not expired', () {
      final future = DateTime.now().add(const Duration(minutes: 5));
      expect(PaymentController.getRemainingSeconds(future.toIso8601String()), greaterThan(0));
      expect(PaymentController.isPaymentExpired(future.toIso8601String()), isFalse);
    });
  });

  group('CartService ticket and cart behavior', () {
    test('detects sold tickets and prevents adding them to cart', () {
      final ticket = {'ticketId': 1, 'status': ' Sold '};
      expect(CartService.isTicketSold(ticket), isTrue);
      expect(CartService.canBuy(ticket), isFalse);
      expect(CartService.addToCart(ticket), isFalse);
      expect(CartService.items, isEmpty);
    });

    test('adds available tickets only once and totals prices', () {
      final first = {'ticketId': 1, 'price': '1200'};
      expect(CartService.addToCart(first), isTrue);
      expect(CartService.addToCart({'id': 1, 'price': '1200'}), isFalse);
      expect(CartService.addToCart({'id': 2, 'price': 800}), isTrue);
      expect(CartService.totalPrice, 2000);
    });

    test('ignores invalid remove indexes', () {
      CartService.addToCart({'id': 1, 'price': 10});
      CartService.removeFromCart(-1);
      CartService.removeFromCart(1);
      expect(CartService.items, hasLength(1));
      CartService.removeFromCart(0);
      expect(CartService.items, isEmpty);
    });

    test('classifies sold out, available, and empty concerts', () {
      expect(CartService.getConcertStatus({'tickets': []}), 'No Tickets');
      expect(CartService.getConcertStatus({'tickets': [{'status': 'available'}]}), 'Available');
      expect(CartService.getConcertStatus({'tickets': [{'isSold': true}]}), 'Sold Out');
    });

    test('creates an unpaid order, copies items, and clears the cart', () {
      final ticket = {'id': 2, 'price': '250'};
      CartService.addToCart(ticket);

      final order = CartService.createOrder();

      expect(order, isNotNull);
      expect(order!['status'], 'To Pay');
      expect(order['paymentStatus'], 'Unpaid');
      expect(order['totalPrice'], 250);
      expect(order['paymentDeadline'], isA<DateTime>());
      expect(CartService.items, isEmpty);
      expect(CartService.history, contains(order));
      expect(order['items'], isNot(same(CartService.items)));
    });

    test('does not create an order from an empty list', () {
      expect(CartService.createOrderFromItems([]), isNull);
    });

    test('expires unpaid orders after their payment deadline', () {
      final order = <String, dynamic>{
        'status': 'To Pay',
        'paymentDeadline': DateTime.now().subtract(const Duration(seconds: 1)),
      };
      CartService.history.add(order);

      CartService.refreshExpiredOrders();

      expect(order['status'], 'Cancelled');
      expect(order['paymentStatus'], 'Expired');
      expect(CartService.hasActiveUnpaidOrder(), isFalse);
    });

    test('advances order through payment, shipping, and receipt', () {
      final listing = <String, dynamic>{
        'listingId': 'LIST_1',
        'status': 'Available',
      };
      CartService.resaleListings.add(listing);
      final order = <String, dynamic>{
        'status': 'To Pay',
        'paymentDeadline': DateTime.now().add(const Duration(minutes: 5)),
        'items': [{'listingId': 'LIST_1'}],
        'timeline': <Map<String, dynamic>>[],
      };

      expect(CartService.payOrder(order), isTrue);
      expect(order['status'], 'To Ship');
      expect(listing['status'], 'Sold');
      expect(CartService.shipOrder(order), isTrue);
      expect(order['status'], 'To Receive');
      expect(order['trackingNumber'], startsWith('TP'));
      expect(listing['status'], 'Shipped');
      expect(CartService.confirmReceived(order), isTrue);
      expect(order['status'], 'Completed');
      expect(listing['status'], 'Completed');
    });

    test('cannot pay an expired order', () {
      final order = <String, dynamic>{
        'status': 'To Pay',
        'paymentDeadline': DateTime.now().subtract(const Duration(seconds: 1)),
      };
      CartService.history.add(order);

      expect(CartService.payOrder(order), isFalse);
      expect(order['status'], 'Cancelled');
    });
  });

  group('FavoriteService', () {
    final concert = {'name': 'Test Concert'};

    test('toggles a concert into and out of favorites', () {
      expect(FavoriteService.isFavorite(concert), isFalse);
      FavoriteService.toggleFavorite(concert);
      expect(FavoriteService.isFavorite(concert), isTrue);
      FavoriteService.toggleFavorite(concert);
      expect(FavoriteService.isFavorite(concert), isFalse);
    });

    test('removes a favorited concert', () {
      FavoriteService.toggleFavorite(concert);
      FavoriteService.removeFavorite(concert);
      expect(FavoriteService.favorites, isEmpty);
    });
  });
}
