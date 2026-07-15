import 'package:supabase_flutter/supabase_flutter.dart';

class OrcamentoRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> buscarTodos({
    required bool isAdmin,
    required String userId,
  }) async {
    dynamic query = _client
        .from('orcamentos')
        .select('*, clientes(*)')
        .order('created_at', ascending: false);

    if (!isAdmin) {
      query = query.eq('user_id', userId);
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<List<Map<String, dynamic>>> buscarParaCalendario(
    DateTime mesFocado,
  ) async {
    final inicioMes = DateTime(mesFocado.year, mesFocado.month, 1);
    final fimMes = DateTime(mesFocado.year, mesFocado.month + 1, 0);

    final response = await _client
        .from('orcamentos')
        .select('*, clientes(nome)')
        .gte('data_pega', inicioMes.toIso8601String())
        .lte('data_pega', fimMes.toIso8601String());

    return List<Map<String, dynamic>>.from(response);
  }
}
