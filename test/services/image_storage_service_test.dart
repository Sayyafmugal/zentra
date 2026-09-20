import 'package:flutter_test/flutter_test.dart';
import 'package:zentra_0/services/image_storage_service.dart';

void main() {
  group('ImageStorageService.validateImageUrl', () {
    final service = UnconfiguredImageStorageService();

    test('accepts a well-formed https URL', () {
      expect(
        service.validateImageUrl('https://example.com/photo.jpg'),
        'https://example.com/photo.jpg',
      );
    });

    test('accepts a well-formed http URL', () {
      expect(service.validateImageUrl('http://example.com/photo.jpg'), isNotNull);
    });

    test('trims surrounding whitespace', () {
      expect(
        service.validateImageUrl('  https://example.com/photo.jpg  '),
        'https://example.com/photo.jpg',
      );
    });

    test('rejects an empty string', () {
      expect(service.validateImageUrl(''), isNull);
      expect(service.validateImageUrl('   '), isNull);
    });

    test('rejects a non-http(s) scheme', () {
      expect(service.validateImageUrl('ftp://example.com/photo.jpg'), isNull);
      expect(service.validateImageUrl('javascript:alert(1)'), isNull);
    });

    test('rejects a relative path with no scheme', () {
      expect(service.validateImageUrl('assets/images/shoe.jpg'), isNull);
    });
  });

  group('UnconfiguredImageStorageService', () {
    final service = UnconfiguredImageStorageService();

    test('uploadImage throws UnimplementedError rather than pretending to succeed', () {
      expect(
        () => service.uploadImage(bytes: const [1, 2, 3], fileName: 'a.jpg'),
        throwsUnimplementedError,
      );
    });

    test('deleteImage is a safe no-op', () async {
      await expectLater(service.deleteImage('https://example.com/a.jpg'), completes);
    });
  });
}
