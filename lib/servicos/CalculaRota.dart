import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class ServicoRota {
  /// Função principal: Recebe a lista de orçamentos e abre o mapa
  // Substitua o método otimizarRotaDoDia (ou o trecho equivalente) por este:
  static Future<void> otimizarRotaDoDia(
    BuildContext context,
    List<Map<String, dynamic>> orcamentos,
  ) async {
    // 1. Validação básica (Aqui pode usar context direto pois não teve await antes)
    if (orcamentos.isEmpty) {
      _aviso(context, "Não há orçamentos para traçar rota.");
      return;
    }

    _aviso(context, "Obtendo localização e calculando rota...");

    try {
      // 2. Pegar Localização Atual (Ponto de Partida)
      Position? pontoPartida = await _obterLocalizacaoAtual(context);

      // Se não conseguiu pegar a localização ou o usuário saiu da tela
      if (pontoPartida == null || !context.mounted) return;

      // 3. Converter Endereços (Texto) em Coordenadas (Lat/Lng)
      // MELHORIA DE PERFORMANCE: Executa todas as buscas de endereço em paralelo.
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
          // Ignora erros de geocodificação para não parar a rota inteira
          if (kDebugMode) {
            print(
              "Erro de geocodificação para o endereço: $enderecoCompleto. Erro: $e",
            );
          }
        }
        return null; // Retorna nulo se não encontrar ou der erro
      }).toList();

      // Aguarda todas as buscas terminarem
      final List<PontoParada?> resultados = await Future.wait(geocodingFutures);
      // Filtra apenas os que tiveram sucesso (remove nulos)
      final List<PontoParada> paradas = resultados
          .whereType<PontoParada>()
          .toList();

      // Verificação de segurança: O usuário ainda está na tela após o loop demorado?
      if (!context.mounted) return;

      if (paradas.isEmpty) {
        _aviso(context, "Nenhum endereço válido encontrado para a rota.");
        return;
      }

      // 4. Algoritmo do Caixeiro Viajante (Vizinho Mais Próximo)
      List<PontoParada> rotaOrdenada = _ordenarPorProximidade(
        pontoPartida,
        paradas,
      );

      // 5. Montar URL e Abrir Google Maps
      await _abrirGoogleMaps(pontoPartida, rotaOrdenada);
    } catch (e) {
      // Verifica se a tela ainda existe antes de mostrar o erro
      if (context.mounted) {
        _aviso(context, "Erro ao gerar rota: $e");
      }
    }
  }

  // --- ALGORITMO DE ORDENAÇÃO (Vizinho Mais Próximo) ---
  static List<PontoParada> _ordenarPorProximidade(
    Position origem,
    List<PontoParada> listaDesordenada,
  ) {
    List<PontoParada> rotaFinal = [];
    List<PontoParada> pendentes = List.from(listaDesordenada);

    // Começamos da posição atual do técnico
    double latAtual = origem.latitude;
    double lngAtual = origem.longitude;

    while (pendentes.isNotEmpty) {
      PontoParada? maisProximo;
      double menorDistancia = double.infinity;

      for (var ponto in pendentes) {
        // Calcula distância em metros entre o ponto atual e o candidato
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

        // O ponto encontrado vira a nova referência para o próximo loop
        latAtual = maisProximo.lat;
        lngAtual = maisProximo.lng;
      }
    }

    return rotaFinal;
  }

  // --- URL LAUNCHER PARA GOOGLE MAPS ---
  static Future<void> _abrirGoogleMaps(
    Position origem,
    List<PontoParada> rota,
  ) async {
    // Limite do Google Maps URL: O ideal é até 9 waypoints + origem + destino.
    // Se tiver mais que isso, o Google pode ignorar alguns ou pedir para abrir no navegador.

    // Origem: Onde o técnico está agora
    String strOrigem = "${origem.latitude},${origem.longitude}";

    // Destino: O último cliente da rota otimizada
    PontoParada destinoFinal = rota.last;
    String strDestino = "${destinoFinal.lat},${destinoFinal.lng}";

    // Waypoints: Todos os clientes intermediários (do 1º até o penúltimo)
    String strWaypoints = "";
    if (rota.length > 1) {
      strWaypoints =
          "&waypoints=${rota.sublist(0, rota.length - 1) // Pega todos menos o último
          .map((p) => "${p.lat},${p.lng}").join("|")}";
    }

    // Monta a URL Universal do Google Maps (Dir Action)
    // api=1 garante o formato novo
    final Uri url = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&origin=$strOrigem&destination=$strDestino$strWaypoints&travelmode=driving",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Não foi possível abrir o mapa.';
    }
  }

  // --- UTILITÁRIOS ---
  static Future<Position?> _obterLocalizacaoAtual(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      // Verifica se a tela ainda está ativa antes de usar o context
      if (context.mounted) {
        _aviso(context, 'O GPS está desativado.');
      }
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        // Verifica novamente após a espera do requestPermission
        if (context.mounted) {
          _aviso(context, 'Permissão de localização negada.');
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Verifica se a tela ainda está ativa
      if (context.mounted) {
        _aviso(context, 'Permissão de localização negada permanentemente.');
      }
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  static void _aviso(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// Classe simples para ajudar na organização
class PontoParada {
  final String nome;
  final double lat;
  final double lng;
  PontoParada({required this.nome, required this.lat, required this.lng});
}
