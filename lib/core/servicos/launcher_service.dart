import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class LauncherService {
  static Future<void> abrirWhatsApp(String telefone) async {
    String numeroLimpo = telefone.replaceAll(RegExp(r'[^\d]'), '');
    if (numeroLimpo.isEmpty) return;

    if (numeroLimpo.length >= 10 && numeroLimpo.length <= 11) {
      numeroLimpo = "55$numeroLimpo";
    } else if ((numeroLimpo.length == 12 || numeroLimpo.length == 13) &&
        numeroLimpo.startsWith('0')) {
      numeroLimpo = "55${numeroLimpo.substring(1)}";
    }

    final Uri url = Uri.parse("https://wa.me/$numeroLimpo");
    await _lancarUrl(url, modoExterno: true);
  }

  static Future<void> fazerLigacao(String telefone) async {
    String numeroLimpo = telefone.replaceAll(RegExp(r'[^\d]'), '');
    if (numeroLimpo.isEmpty) return;

    final Uri url = Uri.parse("tel:$numeroLimpo");
    await _lancarUrl(url);
  }

  static Future<void> abrirGoogleMaps(String endereco) async {
    if (endereco.trim().isEmpty) return;
    final query = Uri.encodeComponent(endereco);

    final Uri url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$query",
    );
    await _lancarUrl(url, modoExterno: true);
  }

  static Future<void> _lancarUrl(Uri url, {bool modoExterno = false}) async {
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: modoExterno
              ? LaunchMode.externalApplication
              : LaunchMode.platformDefault,
        );
      } else {
        debugPrint("Não foi possível abrir a URL: $url");
      }
    } catch (e) {
      debugPrint("Erro ao abrir link: $e");
    }
  }
}
