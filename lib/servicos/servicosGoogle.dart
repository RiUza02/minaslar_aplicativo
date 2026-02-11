import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../modelos/Usuario.dart';
import '../modelos/Cliente.dart';

class Servicos {
  // ===========================================================================
  // SERVIÇO DE WHATSAPP
  // ===========================================================================
  static Future<void> abrirWhatsApp(String telefone) async {
    String numeroLimpo = telefone.replaceAll(RegExp(r'[^\d]'), '');

    if (numeroLimpo.isEmpty) return;

    // Lógica para adicionar o código do Brasil (55) se faltar
    if (numeroLimpo.length >= 10 && numeroLimpo.length <= 11) {
      numeroLimpo = "55$numeroLimpo";
    } else if ((numeroLimpo.length == 12 || numeroLimpo.length == 13) &&
        numeroLimpo.startsWith('0')) {
      numeroLimpo = "55${numeroLimpo.substring(1)}";
    }

    // Usar a URL universal que funciona melhor em Android e iOS
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
  // SERVIÇO DE GOOGLE MAPS
  // ===========================================================================
  static Future<void> abrirGoogleMaps(String endereco) async {
    if (endereco.trim().isEmpty) return;

    final query = Uri.encodeComponent(endereco);

    // URL Universal do Google Maps (Funciona Web, Android e iOS)
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

  // ===========================================================================
  // SERVIÇO DE CACHE DE DADOS GLOBAIS
  // ===========================================================================
  static List<Cliente> clientesComOrcamentos = [];
  static List<Cliente> orcamentosComClientes = [];
  static List<Usuario> usuarios = [];
  static final ValueNotifier<bool> isDataLoaded = ValueNotifier(false);

  /// Carrega todos os dados essenciais do Supabase para um cache em memória.
  static Future<void> carregarCacheGlobal() async {
    isDataLoaded.value = false;
    try {
      // Executa as buscas em paralelo
      final responses = await Future.wait([
        Supabase.instance.client
            .from('clientes')
            .select('*, orcamentos(data_pega)'), // Index 0
        Supabase.instance.client
            .from('orcamentos')
            .select('*, clientes(*)'), // Index 1
        Supabase.instance.client.from('usuarios').select(), // Index 2
      ]);

      // Extrai os dados da resposta, tratando casos de nulo
      final clientesData = responses[0] as List? ?? [];
      final orcamentosData = responses[1] as List? ?? [];
      final usuariosData = responses[2] as List? ?? [];

      // Converte os mapas em objetos
      clientesComOrcamentos = clientesData
          .map((map) => Cliente.fromMap(map))
          .toList();

      // Para orcamentosComClientes, extraímos o cliente aninhado
      orcamentosComClientes = orcamentosData
          .where((map) => map['clientes'] != null)
          .map((map) => Cliente.fromMap(map['clientes']))
          .toList();

      usuarios = usuariosData.map((map) => Usuario.fromMap(map)).toList();

      isDataLoaded.value = true;
      debugPrint("Cache Global: Dados carregados com sucesso.");
    } catch (e) {
      isDataLoaded.value = false;
      debugPrint("Erro ao carregar dados para o cache: $e");
      rethrow;
    }
  }

  // Função útil para limpar o cache ao fazer Logout
  static void limparCache() {
    clientesComOrcamentos = [];
    orcamentosComClientes = [];
    usuarios = [];
    isDataLoaded.value = false;
  }

  // ===========================================================================
  // SERVIÇO DE VERIFICAÇÃO DE CLIENTE DUPLICADO
  // ===========================================================================
  static Future<Cliente?> verificarClienteDuplicado({
    required String nome,
    required String rua,
    required String numero,
  }) async {
    if (nome.trim().isEmpty || rua.trim().isEmpty || numero.trim().isEmpty) {
      return null;
    }

    final primeiroNome = nome.trim().split(' ').first;

    try {
      final response = await Supabase.instance.client
          .from('clientes')
          .select()
          .ilike('nome', '$primeiroNome%')
          .ilike('rua', rua.trim())
          .eq('numero', numero.trim())
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return Cliente.fromMap(response);
      }

      return null;
    } catch (e) {
      debugPrint("Erro ao verificar cliente duplicado: $e");
      return null;
    }
  }
}
