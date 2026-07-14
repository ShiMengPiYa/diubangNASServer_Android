import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:diubang_nasserver/features/api/handlers/preview_handler.dart';
import 'package:diubang_nasserver/features/webdav/resolvers/dav_resource_resolver.dart';
import 'package:diubang_nasserver/features/webdav/resources/dav_resource.dart';
import 'package:diubang_nasserver/features/webdav/utils/content_type_resolver.dart';
import 'package:shelf/shelf.dart';

void main() {
  group('PreviewHandler', () {
    test(
      'returns progressive metadata for videos with poster and auth headers',
      () async {
        final resolver = _FakeDavResourceResolver({
          '/fs/movies/demo.mp4': DavResource.fsFile(
            davPath: '/fs/movies/demo.mp4',
            name: 'demo.mp4',
            size: 123456,
            contentType: 'video/mp4',
            lastModified: DateTime.utc(2026, 4, 8, 12),
          ),
        });
        final handler = PreviewHandler(
          resourceResolver: resolver,
          contentTypeResolver: ContentTypeResolver(),
        ).handler;

        final response = await handler(
          Request(
            'GET',
            Uri.parse(
              'http://10.0.0.8:9090/api/v1/preview/meta?path=%2Ffs%2Fmovies%2Fdemo.mp4',
            ),
            headers: const {'Authorization': 'Basic abc123'},
          ),
        );

        expect(response.statusCode, 200);
        final json =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(json['kind'], 'video');
        expect(json['strategy'], 'progressive');
        expect(json['url'], 'http://10.0.0.8:9090/dav/fs/movies/demo.mp4');
        expect(json['headers'], const {'Authorization': 'Basic abc123'});
        expect(json['contentType'], 'video/mp4');
        expect(json['size'], 123456);
        expect(
          json['thumbnailUrl'],
          'http://10.0.0.8:9090/api/v1/thumbnail?path=%2Ffs%2Fmovies%2Fdemo.mp4&type=grid',
        );
        expect(
          json['posterUrl'],
          'http://10.0.0.8:9090/api/v1/thumbnail?path=%2Ffs%2Fmovies%2Fdemo.mp4&type=preview',
        );
        expect(json['expiresAt'], isNull);
      },
    );

    test('returns unsupported payload for unsupported file types', () async {
      final resolver = _FakeDavResourceResolver({
        '/fs/docs/readme.txt': DavResource.fsFile(
          davPath: '/fs/docs/readme.txt',
          name: 'readme.txt',
          size: 32,
          contentType: 'text/plain',
          lastModified: DateTime.utc(2026, 4, 8, 12),
        ),
      });
      final handler = PreviewHandler(
        resourceResolver: resolver,
        contentTypeResolver: ContentTypeResolver(),
      ).handler;

      final response = await handler(
        Request(
          'GET',
          Uri.parse(
            'http://10.0.0.8:9090/api/v1/preview/meta?path=%2Ffs%2Fdocs%2Freadme.txt',
          ),
        ),
      );

      expect(response.statusCode, 200);
      final json =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(json['kind'], isNull);
      expect(json['strategy'], 'unsupported');
      expect(json['url'], isNull);
      expect(json['headers'], isNull);
      expect(json['thumbnailUrl'], isNull);
      expect(json['posterUrl'], isNull);
    });
  });
}

class _FakeDavResourceResolver implements DavResourceResolver {
  _FakeDavResourceResolver(this._resources);

  final Map<String, DavResource> _resources;

  @override
  Future<List<DavResource>> listChildren(String davPath) async => const [];

  @override
  Future<DavResource?> resolve(String davPath) async => _resources[davPath];
}
