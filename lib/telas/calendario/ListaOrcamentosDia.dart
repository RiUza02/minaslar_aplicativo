import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exibe a lista detalhada de orçamentos para uma data específica.
class ListaOrcamentosDia extends StatefulWidget {
  final DateTime dataSelecionada;

  const ListaOrcamentosDia({super.key, required this.dataSelecionada});

  @override
  State<ListaOrcamentosDia> createState() => _ListaOrcamentosDiaState();
}

class _ListaOrcamentosDiaState extends State<ListaOrcamentosDia> {
  // ===========================================================================
  // PALETA DE CORES
  // ===========================================================================
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corPrincipal = Colors.red[900]!;

  late Future<List<Map<String, dynamic>>> _futureOrcamentos;

  @override
  void initState() {
    super.initState();
    _futureOrcamentos = _buscarOrcamentosDoDia();
  }

  /// Busca orçamentos filtrando pelo dia e trazendo dados do cliente (JOIN)
  Future<List<Map<String, dynamic>>> _buscarOrcamentosDoDia() async {
    // Define o intervalo de tempo do dia selecionado (00:00:00 até 23:59:59)
    final startOfDay = DateTime(
      widget.dataSelecionada.year,
      widget.dataSelecionada.month,
      widget.dataSelecionada.day,
    );
    final endOfDay = startOfDay
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));

    // Formatação para ISO string que o Supabase entende
    final startStr = startOfDay.toIso8601String();
    final endStr = endOfDay.toIso8601String();

    // Query: Selecione tudo de orçamentos, e traga nome, telefone e bairro de clientes
    final response = await Supabase.instance.client
        .from('orcamentos')
        .select('*, clientes(nome, telefone, bairro)')
        .gte('data_servico', startStr) // Maior ou igual ao início do dia
        .lte('data_servico', endStr) // Menor ou igual ao fim do dia
        .order('data_servico', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    // Formata a data para exibir no título (Ex: 25 de Outubro)
    final dataFormatada = DateFormat(
      "d 'de' MMMM",
      'pt_BR',
    ).format(widget.dataSelecionada);

    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: Text("Agenda: $dataFormatada"),
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureOrcamentos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: corPrincipal),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erro ao carregar: ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final orcamentos = snapshot.data ?? [];

          if (orcamentos.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orcamentos.length,
            itemBuilder: (context, index) {
              final item = orcamentos[index];
              return _buildOrcamentoCard(item);
            },
          );
        },
      ),
    );
  }

  // ===========================================================================
  // WIDGETS AUXILIARES
  // ===========================================================================

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            "Nenhum serviço para este dia.",
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildOrcamentoCard(Map<String, dynamic> orcamento) {
    // Extração segura dos dados do cliente (pode ser null se o cliente foi deletado)
    final cliente = orcamento['clientes'] ?? {};
    final nomeCliente = cliente['nome'] ?? 'Cliente Desconhecido';
    final telefone = cliente['telefone'] ?? 'Sem telefone';
    final bairro = cliente['bairro'] ?? 'Sem bairro';

    // Formatação da hora do serviço
    final dataServico = DateTime.parse(orcamento['data_servico']);
    final horaFormatada = DateFormat('HH:mm').format(dataServico);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[900]!.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            horaFormatada,
            style: const TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          nomeCliente,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIconText(Icons.phone, telefone),
              const SizedBox(height: 4),
              _buildIconText(Icons.location_city, bairro),
              const SizedBox(height: 8),
              // Exibe o título do orçamento (serviço a ser feito)
              Text(
                orcamento['titulo'] ?? 'Serviço sem título',
                style: const TextStyle(
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          // Ação ao tocar no card (pode ser expandida futuramente)
        },
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }
}
