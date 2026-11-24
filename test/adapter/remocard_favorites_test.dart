import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/adapter/composite_adapter.dart';
import 'package:nlpa2/adapter/remote/remocard_adapter.dart';
import 'package:nlpa2/settings/app_settings.dart';

void main() {
  late CompositeAdapter composite;
  final servers = <HttpServer>[];

  setUp(() async {
    composite = CompositeAdapter();
    await composite.disconnect();
  });

  tearDown(() async {
    await composite.disconnect();
    for (final server in servers) {
      await server.close(force: true);
    }
    servers.clear();
  });

  Future<({String url, List<String> paths})> startServer(
    String slotName,
  ) async {
    final paths = <String>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    servers.add(server);
    server.listen((request) async {
      paths.add(request.uri.path);
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'slots': [
            {'name': slotName, 'eid': '89049032000000000000000000000001'},
          ],
        }),
      );
      await request.response.close();
    });
    return (
      url: 'http://${server.address.address}:${server.port}',
      paths: paths,
    );
  }

  test('loads only the server selected by its cloud action', () async {
    final first = await startServer('Favorite A');
    final second = await startServer('Favorite B');

    final changed = expectLater(composite.readerListChangedStream, emits(null));

    final readers = await composite.loadRemoteReadersFromUrl(first.url);
    await changed;

    expect(first.paths, ['/listSlots']);
    expect(second.paths, isEmpty);
    expect(readers, hasLength(1));
    expect(readers.single.id, 'remocard:${first.url}|Favorite A');
    expect(readers.single.source, isA<RemoCardAdapter>());
    expect((readers.single.source as RemoCardAdapter).baseUrl, first.url);
    expect(composite.remoteServerUrls, contains(first.url));
    expect(AppSettings().remoCardUrls, isNot(contains(first.url)));
  });

  test(
    'a disconnected session reader can be loaded again from its favorite',
    () async {
      final favorite = await startServer('Persistent Favorite');
      final firstLoad = await composite.loadRemoteReadersFromUrl(favorite.url);

      composite.removeReader(firstLoad.single.id);
      final secondLoad = await composite.loadRemoteReadersFromUrl(favorite.url);

      expect(favorite.paths, ['/listSlots', '/listSlots']);
      expect(secondLoad.single.id, firstLoad.single.id);
    },
  );
}
