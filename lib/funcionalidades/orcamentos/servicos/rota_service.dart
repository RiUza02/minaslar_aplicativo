import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class PontoParada {
  final String nome;
  final double lat;
  final double lng;
  PontoParada({required this.nome, required this.lat, required this.lng});
}

class RotaService {
  /// Executa todo o processo de otimização de rota e abre o mapa[cite: 11]
  static Future<void> otimizarRotaDoDia(
    List<Map<String, dynamic>> orcamentos,
  ) async {
    if (orcamentos.isEmpty) {
      throw Exception("Não há orçamentos para traçar rota.");
    }

    // 1. Pega a localização atual (lança erro se o GPS estiver desativado ou sem permissão)[cite: 11]
    Position pontoPartida = await _obterLocalizacaoAtual();

    // 2. Geocodificação em paralelo[cite: 11]
    final List<Future<PontoParada?>> geocodingFutures = orcamentos.map((
      item,
    ) async {
      String enderecoCompleto =
          "${item['rua']}, ${item['numero']} - ${item['bairro']}, ${item['cidade']}";
      try {
        List<Location> locs = await locationFromAddress(enderecoCompleto);
        if (locs.isNotEmpty) {
          return PontoParada(
            nome: item['nome_cliente'] ?? 'Cliente',
            lat: locs.first.latitude,
            lng: locs.first.longitude,
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            "Erro de geocodificação para o endereço: $enderecoCompleto. Erro: $e",
          );
        }
      }
      return null;
    }).toList();

    final List<PontoParada?> resultados = await Future.wait(geocodingFutures);
    final List<PontoParada> paradas = resultados
        .whereType<PontoParada>()
        .toList();

    if (paradas.isEmpty) {
      throw Exception("Nenhum endereço válido encontrado para a rota.");
    }

    // 3. Algoritmo do Caixeiro Viajante[cite: 11]
    List<PontoParada> rotaOrdenada = _ordenarPorProximidade(
      pontoPartida,
      paradas,
    );

    // 4. Lança o mapa[cite: 11]
    await _abrirGoogleMaps(pontoPartida, rotaOrdenada);
  }

  static List<PontoParada> _ordenarPorProximidade(
    Position origem,
    List<PontoParada> listaDesordenada,
  ) {
    List<PontoParada> rotaFinal = [];
    List<PontoParada> pendentes = List.from(listaDesordenada);

    double latAtual = origem.latitude;
    double lngAtual = origem.longitude;

    while (pendentes.isNotEmpty) {
      PontoParada? maisProximo;
      double menorDistancia = double.infinity;

      for (var ponto in pendentes) {
        double distancia = Geolocator.distanceBetween(
          latAtual,
          lngAtual,
          ponto.lat,
          ponto.lng,
        );
        if (distancia < menorDistancia) {
          menorDistancia = distancia;
          maisProximo = ponto;
        }
      }

      if (maisProximo != null) {
        rotaFinal.add(maisProximo);
        pendentes.remove(maisProximo);
        latAtual = maisProximo.lat;
        lngAtual = maisProximo.lng;
      }
    }
    return rotaFinal;
  }

  static Future<void> _abrirGoogleMaps(
    Position origem,
    List<PontoParada> rota,
  ) async {
    String strOrigem = "${origem.latitude},${origem.longitude}";
    PontoParada destinoFinal = rota.last;
    String strDestino = "${destinoFinal.lat},${destinoFinal.lng}";

    String strWaypoints = "";
    if (rota.length > 1) {
      strWaypoints =
          "&waypoints=${rota.sublist(0, rota.length - 1).map((p) => "${p.lat},${p.lng}").join("|")}";
    }

    final Uri url = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&origin=$strOrigem&destination=$strDestino$strWaypoints&travelmode=driving",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Não foi possível abrir o Google Maps.');
    }
  }

  static Future<Position> _obterLocalizacaoAtual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('O serviço de GPS está desativado no seu aparelho.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permissão de localização negada pelo usuário.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'A permissão de localização foi negada permanentemente nas configurações do aparelho.',
      );
    }

    return await Geolocator.getCurrentPosition();
  }
}
