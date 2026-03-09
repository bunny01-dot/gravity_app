import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

void main() async {
  final links = [
    "https://1drv.ms/u/c/dca3937b157b5f79/IQS7YIMPh76UTrUIP7EfUrNXARGQzBqrFWKSJ1P8jhxgeGM",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQStK6yAbKZyT5u8Xs0vG_R6AUczwSd8Hnhge84PPLad4yg",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQSiMFJxPz8qQZsZ4VNfhoueAdeC2yCpGldUaynOLVh0tSY",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQSFtXSFzYzpSoMMb3hxT9nfAQRmtFTYmRL-e-Zq0yfXZRU",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQTsWmoTivXDTZxNjmpS5ho3AdL5Q7XyaPHy0fqkj5YaBCA",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQSLqp1rxD21RqpbtcwwEvlfAXf7E6TSM3YI3b3NSXI9_Bg",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQQ4tjG8RJSyQIFRKItuBGaGAZwXcnJkykR4oeKChPNsNaU",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQRHDHabsQutT6KfP8cjPv1uAfyPz54s7qt-YFHFcwR2ydA",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQQF9GTGPQNXSpRIlaQn3HtzASPAZyrtH8N1e7GO2iYb7ck",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQQPxOZKlg4CTojIGQWMDQxJAZre__ErFSBy2U9umbN-TUw",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQQFDXg6iM6ISJokc4i9DqxtAVktXp89v6qBjltVZaF2rjM",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQTtA4ApXBtLSYKOyAhkJm88AVe1n881cYTFu0ei3IXb6wo",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQRsTysLjlHvS4bFGv0ozC7TAdxZYNQRB56icgHFznRe1RY",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQShlGadpQitR7efpWQt9Ny3AZvF-ujzYA9-4063Fg4sPDs",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQROMGiiQmXVSJo1Q3mYZ6JGAfLcCQj8-ruVX5NyuW8VwmI",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQR77gGsU1YYRY6XReFDNnBaAVYDQmo2oA0hKYVJc7EeE_Y",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQQlAvRauX5mTYEiWlxlhORtAb2gc4-vskOAo7q1WgpLa2Y",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQQu-t2ApVOdTLbRN0DHp1wKAZ9AsFzfIMXlszEsAT3Dsns",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQRMoQJx0L6QQqbg915ldBiFASKaGXiimC41DmQBbfoAQpQ",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQRAVCi_EwgzS4WQq4dnssGxAb0--blsN33iZKYe3rBkDDw",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQQyE1dE4cSaRZ_bYwP2H07jAVFUweWWyDariFoyDZNa7xw",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQT3-n59rFWwT4sIu8LGtMptAXKAJJdQOCgPxGcUB8P1CC0",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQTDQ8l-kqNQTr5yvr0CN1JCAbINF8Of0Hn0uSQpBYrXTfM",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQQOItzzCtXjQ4ZxdrFsdCm4AReffG74CI6R8k7mqr0ZDaA",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQQw8hgVukz2QowWy7m49Cc8AQVP4wv8NsfgbmppqjSwKes",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQT-4txloawPS73G_z_LD0QtAe6X7cS9z0BbGrxjV7BvMS8",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQTFgVga8gD5RoXWH-WQRt7TAUmd-yGBoRO3PCEjmuO1zZg",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQQWWR3vtjJ-RbSGvYbUklUtAQG11uXzIgJiTQNDcQoSVtw",
    "https://1drv.ms/u/c/dca3937b157b5f79/IQQXUGEeEzZoSpZGyjtF6in2AbwVeX10yhoit9AUJSuoEi0",
  ];

  stdout.writeln('[INFO] Probing ${links.length} links (fingerprinting)...');
  final client = http.Client();

  for (var i = 0; i < links.length; i++) {
    await probeLink(i, links[i], client);
  }
}

Future<void> probeLink(int index, String url, http.Client client) async {
  try {
    // Naive retry approach for download link
    String downloadUrl = url;
    if (!downloadUrl.contains('download=1')) {
      if (downloadUrl.contains('?')) {
        downloadUrl += '&download=1';
      } else {
        downloadUrl += '?download=1';
      }
    }

    final tempFile = File('${Directory.systemTemp.path}/probe_v2_$index.zip');
    if (await tempFile.exists()) await tempFile.delete();

    // Attempt download
    var res = await client.get(Uri.parse(downloadUrl));
    if (res.statusCode != 200) {
      // Follow redirect manually?
      // Try raw URL
      res = await client.get(Uri.parse(url));
    }

    if (res.statusCode == 200) {
      await tempFile.writeAsBytes(res.bodyBytes);

      try {
        final archive = ZipDecoder().decodeBytes(res.bodyBytes);
        // Print first 5 files
        List<String> files = [];
        for (final f in archive) {
          if (!f.name.startsWith('__') && !f.name.startsWith('.') && f.isFile) {
            files.add(f.name);
          }
        }

        String fingerPrint = files.take(5).join(', ');
        // Try to find folder name
        String? folder;
        for (final f in archive) {
          if (f.name.contains('/')) {
            folder = f.name.split('/').first;
            if (!folder.startsWith('__')) break;
          }
        }

        stdout.writeln(
          'LINK_$index: ZipSize=${res.bodyBytes.length}, Folder=${folder ?? "NONE"}, Files=[$fingerPrint] URL=$url',
        );
      } catch (e) {
        stdout.writeln(
          'LINK_$index: Not a valid zip. ContentType: ${res.headers['content-type']}',
        );
      }
    } else {
      stdout.writeln('LINK_$index: Failed ${res.statusCode}');
    }
  } catch (e) {
    stdout.writeln('LINK_$index: Error $e');
  }
}
