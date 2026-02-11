import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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
        .select(
          '*, clientes(nome, telefone, endereco)',
        ) // Traz dados do cliente junto
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
    // Busca orçamentos dos últimos 6 meses
    final dataLimite = DateTime.now().subtract(const Duration(days: 180));
    final String dataFormatada = DateFormat('yyyy-MM-dd').format(dataLimite);

    final response = await _client
        .from('orcamentos')
        .select('valor, status, created_at, turno, data_servico')
        .gte('created_at', dataFormatada)
        .order('created_at', ascending: true);

    final List<dynamic> dados = response as List? ?? [];

    // --- Processamento dos Dados (Antes estava na UI) ---
    double faturamentoMesAtual = 0;
    final agora = DateTime.now();

    // Mapas auxiliares
    Map<String, double> faturamentoPorMes = {};
    Map<String, int> contagemStatus = {'Pendentes': 0, 'Concluídos': 0};
    Map<String, int> servicosPorTurno = {'Manhã': 0, 'Tarde': 0};

    for (var item in dados) {
      final valor = (item['valor'] ?? 0).toDouble();
      final status = item['status'] ?? 'Pendente';
      final dataCriacao = DateTime.parse(item['created_at']);
      final turno = item['turno'] ?? 'Manhã';

      // 1. Faturamento Mês Atual
      if (dataCriacao.month == agora.month && dataCriacao.year == agora.year) {
        if (status == 'Concluído' || status == 'Entregue') {
          faturamentoMesAtual += valor;
        }
      }

      // 2. Gráfico de Barras (6 meses)
      String chaveMes = DateFormat('MMM', 'pt_BR').format(dataCriacao);
      if (status == 'Concluído' || status == 'Entregue') {
        faturamentoPorMes[chaveMes] =
            (faturamentoPorMes[chaveMes] ?? 0) + valor;
      }

      // 3. Status Pizza
      if (status == 'Concluído' || status == 'Entregue') {
        contagemStatus['Concluídos'] = (contagemStatus['Concluídos'] ?? 0) + 1;
      } else {
        contagemStatus['Pendentes'] = (contagemStatus['Pendentes'] ?? 0) + 1;
      }

      // 4. Turnos
      if (turno == 'Manhã') {
        servicosPorTurno['Manhã'] = (servicosPorTurno['Manhã'] ?? 0) + 1;
      }
      if (turno == 'Tarde') {
        servicosPorTurno['Tarde'] = (servicosPorTurno['Tarde'] ?? 0) + 1;
      }
    }

    // Prepara listas para os gráficos
    List<Map<String, dynamic>> listaFaturamento = faturamentoPorMes.entries
        .map((e) => {'mes': e.key, 'valor': e.value})
        .toList();

    List<Map<String, dynamic>> listaStatus = [
      {'status': 'Pendentes', 'quantidade': contagemStatus['Pendentes']},
      {'status': 'Concluídos', 'quantidade': contagemStatus['Concluídos']},
    ];

    return {
      'faturamentoMesAtual': faturamentoMesAtual,
      'graficoFaturamento': listaFaturamento,
      'graficoStatus': listaStatus,
      'turnos': servicosPorTurno,
    };
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
        .gte('data_servico', DateFormat('yyyy-MM-dd').format(inicioMes))
        .lte('data_servico', DateFormat('yyyy-MM-dd').format(fimMes));

    return List<Map<String, dynamic>>.from(response);
  }
}
