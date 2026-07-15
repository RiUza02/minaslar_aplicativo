import 'package:supabase_flutter/supabase_flutter.dart';
import '../modelos/cliente_model.dart';

class ClienteRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Cliente?> verificarClienteDuplicado({
    required String nome,
    required String rua,
    required String numero,
  }) async {
    if (nome.trim().isEmpty || rua.trim().isEmpty || numero.trim().isEmpty) {
      return null;
    }

    final primeiroNome = nome.trim().split(' ').first;

    try {
      final response = await _supabase
          .from('clientes')
          .select()
          .ilike('nome', '$primeiroNome%')
          .ilike('rua', rua.trim())
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return Cliente.fromMap(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
