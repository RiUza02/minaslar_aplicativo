import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../funcionalidades/clientes/modelos/cliente_model.dart';
import '../modelos/usuario_model.dart';

class CacheTemporario {
  static List<Cliente> clientesComOrcamentos = [];
  static List<Cliente> orcamentosComClientes = [];
  static List<Usuario> usuarios = [];
  static final ValueNotifier<bool> isDataLoaded = ValueNotifier(false);

  static Future<void> carregarCacheGlobal() async {
    isDataLoaded.value = false;
    try {
      final responses = await Future.wait([
        Supabase.instance.client
            .from('clientes')
            .select('*, orcamentos(data_pega)'),
        Supabase.instance.client.from('orcamentos').select('*, clientes(*)'),
        Supabase.instance.client.from('usuarios').select(),
      ]);

      final clientesData = responses[0] as List? ?? [];
      final orcamentosData = responses[1] as List? ?? [];
      final usuariosData = responses[2] as List? ?? [];

      clientesComOrcamentos = clientesData
          .map((map) => Cliente.fromMap(map))
          .toList();

      orcamentosComClientes = orcamentosData
          .where((map) => map['clientes'] != null)
          .map((map) => Cliente.fromMap(map['clientes']))
          .toList();

      usuarios = usuariosData.map((map) => Usuario.fromMap(map)).toList();

      isDataLoaded.value = true;
    } catch (e) {
      isDataLoaded.value = false;
      rethrow;
    }
  }

  static void limparCache() {
    clientesComOrcamentos = [];
    orcamentosComClientes = [];
    usuarios = [];
    isDataLoaded.value = false;
  }
}
