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
  /// Retorna o número de meses que foram efetivamente atualizados.
  Future<int> sincronizarFinancas() async {
    final agora = DateTime.now();
    int mesesAtualizados = 0;

    // Itera sobre o mês atual e os 5 anteriores
    for (int i = 0; i < 6; i++) {
      final dataAlvo = DateTime(agora.year, agora.month - i, 1);
      final mes = dataAlvo.month;
      final ano = dataAlvo.year;

      final inicioMes = DateTime(ano, mes, 1);
      final fimMes = DateTime(ano, mes + 1, 0, 23, 59, 59);

      // 1. CALCULA OS DADOS DO MÊS ATUAL A PARTIR DAS FONTES PRIMÁRIAS

      // Busca orçamentos do mês para os cálculos
      final orcamentosDoMes = await _client
          .from('orcamentos')
          .select(
            'entregue, valor, horario_do_dia, eh_retorno',
          ) // O filtro é feito no DB, não precisa selecionar a data
          .gte(
            'data_pega',
            inicioMes.toIso8601String(),
          ) // Filtra pela data de início do serviço
          .lte(
            'data_pega',
            fimMes.toIso8601String(),
          ); // E não pela data de criação do registro

      // Calcula as métricas a partir dos orçamentos
      double faturamento = 0;
      int orcamentosDia = 0;
      int orcamentosTarde = 0;
      int retornosGarantia = 0;

      for (var orc in orcamentosDoMes) {
        if (orc['entregue'] == true) {
          faturamento += (orc['valor'] ?? 0.0).toDouble();
        }
        if (orc['horario_do_dia'] == 'Manhã') {
          orcamentosDia++;
        } else if (orc['horario_do_dia'] == 'Tarde') {
          orcamentosTarde++;
        }
        if (orc['eh_retorno'] == true) {
          retornosGarantia++;
        }
      }

      // Conta quantos clientes novos foram criados no mês
      final novosClientesCount = await _client
          .from('clientes')
          .count(CountOption.exact)
          .gte('created_at', inicioMes.toIso8601String())
          .lte('created_at', fimMes.toIso8601String());

      // Cria um objeto 'Financas' com os dados recém-calculados
      final financasCalculado = Financas(
        mes: mes,
        ano: ano,
        faturamento: faturamento,
        orcamentosDia: orcamentosDia,
        orcamentosTarde: orcamentosTarde,
        totalOrcamentos: orcamentosDoMes.length,
        novosClientes: novosClientesCount,
        retornosGarantia: retornosGarantia,
      );

      // 2. BUSCA O REGISTRO EXISTENTE NA TABELA 'financas'
      final registroExistenteMap = await _client
          .from('financas')
          .select()
          .eq('mes', mes)
          .eq('ano', ano)
          .maybeSingle();

      // 3. COMPARA E ATUALIZA OU INSERE
      if (registroExistenteMap == null) {
        await _client.from('financas').insert(financasCalculado.toMap());
        mesesAtualizados++;
      } else {
        final financasDoBanco = Financas.fromMap(registroExistenteMap);
        // Compara campo a campo para ver se houve mudança
        bool hasChanged =
            financasDoBanco.faturamento != financasCalculado.faturamento ||
            financasDoBanco.orcamentosDia != financasCalculado.orcamentosDia ||
            financasDoBanco.orcamentosTarde !=
                financasCalculado.orcamentosTarde ||
            financasDoBanco.totalOrcamentos !=
                financasCalculado.totalOrcamentos ||
            financasDoBanco.novosClientes != financasCalculado.novosClientes ||
            financasDoBanco.retornosGarantia !=
                financasCalculado.retornosGarantia;

        if (hasChanged) {
          await _client
              .from('financas')
              .update(financasCalculado.toMap())
              .eq('id', financasDoBanco.id!);
          mesesAtualizados++;
        }
      }
    }
    return mesesAtualizados;
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
