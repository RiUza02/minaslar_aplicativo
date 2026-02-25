import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../modelos/Financas.dart';

class ProcessaOrcamentos {
  final SupabaseClient _client = Supabase.instance.client;

  // ==============================================================================
  // 1. LISTAGEM GERAL (Para ListaOrcamentos.dart)
  // ==============================================================================
  Future<List<Map<String, dynamic>>> buscarTodos({
    required bool isAdmin,
    required String userId,
  }) async {
    dynamic query = _client
        .from('orcamentos')
        .select('*, clientes(*)') // Traz dados do cliente junto
        .order('created_at', ascending: false);

    // Regra de Negócio: Se não for admin, só vê os seus
    if (!isAdmin) {
      query = query.eq('user_id', userId);
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  // ==============================================================================
  // 2. DADOS DO DASHBOARD (Lógica pesada movida da UI para cá)
  // ==============================================================================
  Future<Map<String, dynamic>> buscarDadosDashboard() async {
    // 1. Define os 6 meses que serão buscados (mês atual e 5 anteriores)
    final agora = DateTime.now();
    final List<String> mesesOrdenados = [];
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(agora.year, agora.month - i, 1);
      mesesOrdenados.add(DateFormat('MMM', 'pt_BR').format(monthDate));
    }

    // 2. Monta o filtro 'OR' para a query do Supabase
    final filtroOr = mesesOrdenados
        .asMap()
        .entries
        .map((entry) {
          final monthDate = DateTime(agora.year, agora.month - (5 - entry.key));
          return 'and(mes.eq.${monthDate.month},ano.eq.${monthDate.year})';
        })
        .join(',');

    // 3. Executa a query na tabela 'financas'
    final response = await _client.from('financas').select().or(filtroOr);
    final List<dynamic> dados = response as List? ?? [];

    // 4. Processa os dados em um mapa para fácil acesso
    final Map<String, Financas> financasPorMes = {
      for (var item in dados)
        '${item['mes']}-${item['ano']}': Financas.fromMap(item),
    };

    // 5. Extrai os dados do mês atual
    final chaveMesAtual = '${agora.month}-${agora.year}';
    final financasMesAtual =
        financasPorMes[chaveMesAtual] ??
        Financas(mes: agora.month, ano: agora.year);

    final double faturamentoMesAtual = financasMesAtual.faturamento;
    final Map<String, int> servicosPorTurno = {
      'Manhã': financasMesAtual.orcamentosDia,
      'Tarde': financasMesAtual.orcamentosTarde,
    };

    // 6. Prepara as listas para os gráficos
    final List<Map<String, dynamic>> listaFaturamento = [];
    final List<Map<String, dynamic>> listaStats6Meses = [];

    for (int i = 0; i < mesesOrdenados.length; i++) {
      final monthDate = DateTime(agora.year, agora.month - (5 - i));
      final chave = '${monthDate.month}-${monthDate.year}';
      final financaDoMes =
          financasPorMes[chave] ??
          Financas(mes: monthDate.month, ano: monthDate.year);

      // Gráfico de Linha (Faturamento)
      listaFaturamento.add({
        'month': mesesOrdenados[i],
        'value': financaDoMes.faturamento,
      });

      // Gráfico de Barras (Visão Geral)
      listaStats6Meses.add({
        'month': mesesOrdenados[i],
        'orcamentos': financaDoMes.totalOrcamentos,
        'clientes': financaDoMes.novosClientes,
        'retornos': financaDoMes.retornosGarantia,
      });
    }

    // 7. Retorna o mapa de dados processado para o Dashboard
    return {
      'faturamentoMesAtual': faturamentoMesAtual,
      'graficoFaturamento': listaFaturamento,
      'turnos': servicosPorTurno,
      'graficoBarras': listaStats6Meses,
    };
  }

  // ==============================================================================
  // 3. SINCRONIZAÇÃO (Calcula e atualiza a tabela 'financas')
  // ==============================================================================
  /// Calcula os dados financeiros dos últimos 6 meses e atualiza a tabela 'financas'.
  ///
  /// **MELHORIA DE PERFORMANCE E ARQUITETURA:**
  /// A lógica complexa de cálculo foi movida do aplicativo para uma **Função de Banco de Dados (RPC)**
  /// no Supabase chamada `sincronizar_dados_financeiros`.
  ///
  /// Isso resolve o problema de performance "N+1", onde o app fazia múltiplas
  /// chamadas de rede em um loop. Agora, uma única chamada resolve tudo no servidor,
  /// de forma muito mais rápida e segura.
  ///
  /// Retorna o número de meses que foram efetivamente atualizados.
  Future<int> sincronizarFinancas() async {
    // Chama a função no banco de dados que faz todo o trabalho pesado.
    final mesesAtualizados = await _client.rpc('sincronizar_dados_financeiros');
    return mesesAtualizados as int? ?? 0;
  }

  // ==============================================================================
  // 3. CALENDÁRIO
  // ==============================================================================
  Future<List<Map<String, dynamic>>> buscarParaCalendario(
    DateTime mesFocado,
  ) async {
    final inicioMes = DateTime(mesFocado.year, mesFocado.month, 1);
    final fimMes = DateTime(mesFocado.year, mesFocado.month + 1, 0);

    final response = await _client
        .from('orcamentos')
        .select('*, clientes(nome)')
        // CORREÇÃO DE BUG: O campo 'data_servico' não existe.
        // A busca agora é feita pelo campo 'data_pega', que representa o início do serviço.
        .gte('data_pega', inicioMes.toIso8601String())
        .lte('data_pega', fimMes.toIso8601String());

    return List<Map<String, dynamic>>.from(response);
  }
}
