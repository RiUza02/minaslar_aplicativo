import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Servicos {
  // ===========================================================================
  // SERVIÇO DE WHATSAPP
  // ===========================================================================
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

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint("Não foi possível abrir o WhatsApp.");
      }
    } catch (e) {
      debugPrint("Erro no WhatsApp: $e");
    }
  }

  // ===========================================================================
  // SERVIÇO DE LIGAÇÃO
  // ===========================================================================
  static Future<void> fazerLigacao(String telefone) async {
    String numeroLimpo = telefone.replaceAll(RegExp(r'[^\d]'), '');

    if (numeroLimpo.isEmpty) return;

    final Uri url = Uri.parse("tel:$numeroLimpo");

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        debugPrint("Não foi possível realizar a ligação.");
      }
    } catch (e) {
      debugPrint("Erro ao ligar: $e");
    }
  }

  // ===========================================================================
  // SERVIÇO DE GOOGLE MAPS [NOVO]
  // ===========================================================================
  static Future<void> abrirGoogleMaps(String endereco) async {
    if (endereco.trim().isEmpty) return;

    // Codifica o endereço para ser válido na URL (espaços viram %20, etc)
    final query = Uri.encodeComponent(endereco);
    final Uri url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$query",
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint("Não foi possível abrir o mapa.");
      }
    } catch (e) {
      debugPrint("Erro ao abrir mapa: $e");
    }
  }
}
