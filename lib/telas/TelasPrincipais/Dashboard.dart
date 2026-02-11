import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Estados
  bool isLoading = true;

  // Métricas
  double faturamentoMesAtual = 0;
  List<Map<String, dynamic>> faturamento6Meses = [];
  List<Map<String, dynamic>> stats6Meses = [];
  Map<String, int> servicosPorTurno = {'Manhã': 0, 'Tarde': 0};

  // Cores para os gráficos
  final Color corOrcamentos = Colors.blue;
  final Color corClientes = Colors.green;
  final Color corRetornos = Colors.orange;

  // Formatter para os meses
  final monthFormat = DateFormat('MMM', 'pt_BR');

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  /// Busca e processa os dados do Supabase para alimentar os gráficos
  void _carregarDados() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    if (!(Supabase
            .instance
            .client
            .auth
            .currentSession
            ?.accessToken
            .isNotEmpty ??
        false)) {
      debugPrint(
        "Supabase client not initialized when _carregarDados (Dashboard) was called.",
      );
      if (mounted) setState(() => isLoading = false);
      return;
    }
    try {
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);

      final response = await Supabase.instance.client
          .from('orcamentos')
          .select(
            'valor, data_pega, eh_retorno, cliente_id, horario_do_dia, entregue',
          )
          .gte('data_pega', sixMonthsAgo.toIso8601String());

      // O 'response' já é uma lista do tipo correto, a conversão é desnecessária.
      final List<Map<String, dynamic>> orcamentos = response;

      // --- Processamento dos Dados ---
      double faturadoMesAtualCalculado = 0;
      Map<String, int> turnos = {'Manhã': 0, 'Tarde': 0};
      List<Map<String, dynamic>> faturamentoMensal = [];
      List<Map<String, dynamic>> statsMensal = [];

      for (int i = 5; i >= 0; i--) {
        final targetMonth = DateTime(now.year, now.month - i, 1);
        final monthName = monthFormat.format(targetMonth);

        final orcamentosDoMes = orcamentos.where((o) {
          // Adicionada verificação para datas nulas para maior robustez
          if (o['data_pega'] == null) return false;
          final dataPega = DateTime.parse(o['data_pega']);
          return dataPega.year == targetMonth.year &&
              dataPega.month == targetMonth.month;
        }).toList();

        // 1. Faturamento
        double faturamentoDoMes = orcamentosDoMes
            .where((o) => o['entregue'] == true) // Filtra apenas os entregues
            .fold(0.0, (sum, item) {
              final valor = item['valor'];
              return sum + (valor is num ? valor : 0.0);
            });
        faturamentoMensal.add({'month': monthName, 'value': faturamentoDoMes});

        // 2. Stats para Gráfico de Barras
        statsMensal.add({
          'month': monthName,
          'orcamentos': orcamentosDoMes.length,
          'clientes': orcamentosDoMes
              .map((o) => o['cliente_id'])
              .toSet()
              .length,
          'retornos': orcamentosDoMes
              .where((o) => o['eh_retorno'] == true)
              .length,
        });

        // 3. Faturamento do Mês Atual
        if (targetMonth.year == now.year && targetMonth.month == now.month) {
          faturadoMesAtualCalculado = faturamentoDoMes;
        }
      }

      // 4. Contagem de Turnos
      for (var o in orcamentos) {
        final horario = o['horario_do_dia']?.toString() ?? 'Manhã';
        turnos[horario] = (turnos[horario] ?? 0) + 1;
      }

      if (mounted) {
        setState(() {
          faturamentoMesAtual = faturadoMesAtualCalculado;
          faturamento6Meses = faturamentoMensal;
          stats6Meses = statsMensal;
          servicosPorTurno = turnos;
          isLoading = false;
        });
      }
    } catch (e, s) {
      debugPrint("Erro ao carregar dados do Dashboard: $e");
      debugPrint("Stacktrace: $s");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível carregar os dados do dashboard. Verifique sua conexão e tente novamente.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.red[900],
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Faturamento do Mês
                  _buildFaturamentoMesCard(),
                  const SizedBox(height: 24),

                  // 2. Gráfico de Linha
                  _buildSectionTitle("Faturamento (Últimos 6 Meses)"),
                  const SizedBox(height: 16),
                  _buildLineChart(),
                  const SizedBox(height: 24),

                  // 3. Gráfico de Barras
                  _buildSectionTitle("Visão Geral (Últimos 6 Meses)"),
                  const SizedBox(height: 16),
                  _buildBarChart(),
                  const SizedBox(height: 24),

                  // 4. Gráfico de Pizza
                  _buildSectionTitle("Distribuição de Serviços por Turno"),
                  const SizedBox(height: 16),
                  _buildPieChart(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFaturamentoMesCard() {
    final valorFormatado = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(faturamentoMesAtual);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "FATURAMENTO DO MÊS",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valorFormatado,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 250, // Aumentei um pouco a altura para caber os numeros
          padding: const EdgeInsets.only(top: 24, right: 24, left: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.blueGrey.withValues(alpha: 0.8),
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      return LineTooltipItem(
                        NumberFormat.currency(
                          locale: 'pt_BR',
                          symbol: 'R\$',
                        ).format(barSpot.y),
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) =>
                    const FlLine(color: Colors.white10, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                // ATIVADO: Títulos na Esquerda (Valores Monetários)
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval:
                        null, // Deixa automático ou defina um intervalo fixo
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      // Formatação compacta (ex: 1.5k)
                      String text;
                      if (value >= 1000) {
                        text = '${(value / 1000).toStringAsFixed(1)}k';
                      } else {
                        text = value.toInt().toString();
                      }
                      return Text(
                        text,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      // Proteção contra índice fora da lista
                      if (value.toInt() >= 0 &&
                          value.toInt() < faturamento6Meses.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            faturamento6Meses[value.toInt()]['month'],
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: faturamento6Meses.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value['value']);
                  }).toList(),
                  isCurved: true,
                  color: Colors.greenAccent,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true), // Mostra os pontos
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.greenAccent.withValues(alpha: 0.3),
                        Colors.greenAccent.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildLegend([
          _LegendItem(color: Colors.greenAccent, text: 'Faturamento'),
        ]),
      ],
    );
  }

  Widget _buildBarChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 250,
          padding: const EdgeInsets.only(top: 24, right: 16, left: 0),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: BarChart(
            BarChartData(
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.grey[800],
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    String label;
                    switch (rodIndex) {
                      case 0:
                        label = 'Orçamentos';
                        break;
                      case 1:
                        label = 'Clientes';
                        break;
                      case 2:
                        label = 'Retornos';
                        break;
                      default:
                        throw Error();
                    }
                    return BarTooltipItem(
                      '$label\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: (rod.toY).toInt().toString(),
                          style: TextStyle(color: rod.color, fontSize: 16),
                        ),
                      ],
                    );
                  },
                ),
              ),
              alignment: BarChartAlignment.spaceAround,
              gridData: const FlGridData(show: false), // Grid limpo para barras
              titlesData: FlTitlesData(
                // ATIVADO: Títulos na Esquerda (Quantidades)
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1, // Mostra de 1 em 1 se possível, ou automático
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      // Se o valor for inteiro, mostra
                      if (value % 1 == 0) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 &&
                          value.toInt() < stats6Meses.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            stats6Meses[value.toInt()]['month'],
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: stats6Meses.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: data['orcamentos'].toDouble(),
                      color: corOrcamentos,
                      width: 8,
                    ),
                    BarChartRodData(
                      toY: data['clientes'].toDouble(),
                      color: corClientes,
                      width: 8,
                    ),
                    BarChartRodData(
                      toY: data['retornos'].toDouble(),
                      color: corRetornos,
                      width: 8,
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildLegend([
          _LegendItem(color: corOrcamentos, text: 'Orçamentos'),
          _LegendItem(color: corClientes, text: 'Clientes'),
          _LegendItem(color: corRetornos, text: 'Retornos'),
        ]),
      ],
    );
  }

  Widget _buildPieChart() {
    final int total = servicosPorTurno.values.fold(
      0,
      (sum, item) => sum + item,
    );
    if (total == 0) return const SizedBox.shrink();

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: servicosPorTurno.entries.map((entry) {
                  final isManha = entry.key == 'Manhã';
                  final percentage = (entry.value / total) * 100;
                  return PieChartSectionData(
                    color: isManha ? Colors.amber : Colors.indigoAccent,
                    value: entry.value.toDouble(),
                    // Título melhorado: Valor + Porcentagem
                    title:
                        '${entry.value}\n(${percentage.toStringAsFixed(0)}%)',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildLegend(
              servicosPorTurno.entries.map((entry) {
                final isManha = entry.key == 'Manhã';
                return _LegendItem(
                  color: isManha ? Colors.amber : Colors.indigoAccent,
                  text: '${entry.key} (${entry.value})',
                );
              }).toList(),
              isColumn: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(List<_LegendItem> items, {bool isColumn = false}) {
    return isColumn
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: _buildLegendItem(item),
                  ),
                )
                .toList(),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: _buildLegendItem(item),
                  ),
                )
                .toList(),
          );
  }

  Widget _buildLegendItem(_LegendItem item) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: item.color),
        const SizedBox(width: 8),
        Text(item.text, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

class _LegendItem {
  final Color color;
  final String text;
  _LegendItem({required this.color, required this.text});
}
