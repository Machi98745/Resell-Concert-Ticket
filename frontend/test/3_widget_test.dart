import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/views/detail.dart';
import 'package:frontend/views/favorite.dart';
import 'package:frontend/views/favorite_service.dart';
import 'package:frontend/views/homepage.dart';
import 'package:frontend/views/sell_page.dart';

Finder searchField() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TextField &&
        widget.decoration?.hintText == 'Search concerts, artists...',
  );
}

void main() {
  setUp(() {
    FavoriteService.favorites.clear();
  });

  group('Person 3 - Concert, Resell & Favorite UI', () {
    testWidgets('HomePage shows concerts and filters by search', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pump();

      expect(find.text('BLACKPINK WORLD TOUR'), findsWidgets);
      expect(searchField(), findsOneWidget);

      await tester.enterText(
        searchField(),
        'concert-does-not-exist',
      );
      await tester.pump();

      expect(find.text('No upcoming concerts found.'), findsOneWidget);
    });

    testWidgets('DetailPage can add a concert to favorites', (
      WidgetTester tester,
    ) async {
      final concert = <String, dynamic>{
        'name': 'Test Concert',
        'artist': 'Test Artist',
        'date': '25 December 2026',
        'time': '19:00',
        'location': 'Bangkok',
        'category': 'Pop',
        'image': '',
        'description': 'A test concert',
        'tickets': [
          {
            'seller': 'Test Seller',
            'zone': 'VIP Zone',
            'price': 1000,
            'condition': 'Available',
            'status': 'available',
            'seats': ['A1'],
          },
        ],
      };

      await tester.pumpWidget(
        MaterialApp(home: DetailPage(concert: concert)),
      );
      await tester.pump();

      expect(find.text('Test Concert'), findsWidgets);
      expect(find.byTooltip('Add to Favorites'), findsOneWidget);

      await tester.tap(find.byTooltip('Add to Favorites'));
      await tester.pump();

      expect(FavoriteService.isFavorite(concert), isTrue);
      expect(find.text('Added to My Favorites!'), findsOneWidget);
    });

    testWidgets('SellPage validates required ticket information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SellPage()));
      await tester.pump();

      expect(find.text('Sell Your Ticket'), findsOneWidget);
      expect(find.text('Ticket Details'), findsOneWidget);
      expect(find.text('Continue to Review'), findsOneWidget);

      await tester.tap(find.text('Continue to Review'));
      await tester.pump();

      expect(find.text('Please select a concert.'), findsOneWidget);
    });

    testWidgets('FavoritePage displays saved concerts', (
      WidgetTester tester,
    ) async {
      FavoriteService.favorites.add({
        'name': 'Saved Concert',
        'artist': 'Saved Artist',
        'date': '1 January 2027',
        'image': '',
      });

      await tester.pumpWidget(const MaterialApp(home: FavoritePage()));
      await tester.pump();

      expect(find.text('My Favorites'), findsOneWidget);
      expect(find.text('Saved Concert'), findsOneWidget);
      expect(find.text('Saved Artist'), findsOneWidget);
    });
  });
}
