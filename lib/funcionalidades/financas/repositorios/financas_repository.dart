import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../modelos/financas_model.dart';

class FinancasRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>> buscarDadosDashboard() async {
    final agora = DateTime.now();
    final List<String> mesesOrdenados = [];
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(agora.year, agora.month - i, 1);
      mesesOrdenados.add(DateFormat('MMM', 'pt_BR').format(monthDate));
    }

    final filtroOr = mesesOrdenados
        .asMap()
        .entries
        .map((entry) {
          final monthDate = DateTime(agora.year, agora.month - (5 - entry.key));
          return 'and(mes.eq.${monthDate.month},ano.eq.${monthDate.year})';
        })
        .join(',');

    final response = await _client.from('financas').select().or(filtroOr);
    final List<dynamic> dados = response as List? ?? [];

    final Map<String, Financas> financasPorMes = {
      for (var item in dados)
        '${item['mes']}-${item['ano']}': Financas.fromMap(item),
    };

    final chaveMesAtual = '${agora.month}-${agora.year}';
    final financasMesAtual =
        financasPorMes[chaveMesAtual] ??
        Financas(mes: agora.month, ano: agora.year);

    final double faturamentoMesAtual = financasMesAtual.faturamento;
    final Map<String, int> servicosPorTurno = {
      'Manhã': financasMesAtual.orcamentosDia,
      'Tarde': financasMesAtual.orcamentosTarde,
    };

    final List<Map<String, dynamic>> listaFaturamento = [];
    final List<Map<String, dynamic>> listaStats6Meses = [];

    for (int i = 0; i < mesesOrdenados.length; i++) {
      final monthDate = DateTime(agora.year, agora.month - (5 - i));
      final chave = '${monthDate.month}-${monthDate.year}';
      final financaDoMes =
          financasPorMes[chave] ??
          Financas(mes: monthDate.month, ano: monthDate.year);

      listaFaturamento.add({
        'month': mesesOrdenados[i],
        'value': financaDoMes.faturamento,
      });

      listaStats6Meses.add({
        'month': mesesOrdenados[i],
        'orcamentos': financaDoMes.totalOrcamentos,
        'clientes': financaDoMes.novosClientes,
        'retornos': financaDoMes.retornosGarantia,
      });
    }

    return {
      'faturamentoMesAtual': faturamentoMesAtual,
      'graficoFaturamento': listaFaturamento,
      'turnos': servicosPorTurno,
      'graficoBarras': listaStats6Meses,
    };
  }

  Future<int> sincronizarFinancas() async {
    final mesesAtualizados = await _client.rpc('sincronizar_dados_financeiros');
    return mesesAtualizados as int? ?? 0;
  }
}
