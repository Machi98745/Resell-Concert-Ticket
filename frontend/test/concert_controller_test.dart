import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/controller/concert_controller.dart';

class FakeHttpClient extends http.BaseClient {
  FakeHttpClient(this.handler);

  final Future<http.Response> Function(http.Request request) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request as http.Request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
    );
  }
}

void main() {
  group('ConcertController', () {
    test('getConcerts returns a list and sends search/category filters', () async {
      late http.Request capturedRequest;
      final client = FakeHttpClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode([
            {'id': 1, 'name': 'Taylor Swift'},
          ]),
          200,
        );
      });

      final result = await ConcertController(client: client).getConcerts(
        search: '  Taylor ',
        category: ' K-Pop ',
      );

      expect(result, hasLength(1));
      expect(result.first['name'], 'Taylor Swift');
      expect(capturedRequest.url.queryParameters, {
        'search': 'Taylor',
        'category': 'K-Pop',
      });
    });

    test('getConcerts supports a data wrapper', () async {
      final client = FakeHttpClient((_) async {
        return http.Response(
          jsonEncode({
            'data': [
              {'id': 2, 'name': 'BTS'},
            ],
          }),
          200,
        );
      });

      final result = await ConcertController(client: client).getConcerts();

      expect(result, hasLength(1));
      expect(result.first['id'], 2);
    });

    test('getConcertById returns concert details', () async {
      late http.Request capturedRequest;
      final client = FakeHttpClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({'id': 7, 'name': 'BLACKPINK'}),
          200,
        );
      });

      final result = await ConcertController(client: client).getConcertById(7);

      expect(result['id'], 7);
      expect(capturedRequest.url.path, endsWith('/api/concerts/7'));
    });

    test('getConcertById throws when the concert is missing', () async {
      final client = FakeHttpClient((_) async {
        return http.Response(jsonEncode({'message': 'Not found'}), 404);
      });

      expect(
        () => ConcertController(client: client).getConcertById(999),
        throwsA(isA<Exception>()),
      );
    });
  });
}
