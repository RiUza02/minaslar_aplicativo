import 'package:supabase_flutter/supabase_flutter.dart';

class IaService {
  // Pega a instância do Supabase que já está rodando no seu app
  final _supabase = Supabase.instance.client;

  /// Envia a pergunta para a nossa Edge Function e retorna a resposta da IA
  Future<String> perguntarParaIA({
    required String perguntaUsuario,
    required bool isAdmin,
  }) async {
    try {
      final resposta = await _supabase.functions.invoke(
        'assistente-ia',
        body: {
          'pergunta': perguntaUsuario,
          'isAdmin': isAdmin, // Agora o status é dinâmico!
        },
      );

      return resposta.data['resposta'];
    } catch (erro) {
      return "Desculpe, ocorreu um erro na comunicação com o assistente.";
    }
  }
}
