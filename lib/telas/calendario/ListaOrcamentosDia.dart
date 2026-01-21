import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../clienteOrcamento/DetalhesOrcamento.dart';
import '../clienteOrcamento/AdicionarOrcamento.dart';
import '../../modelos/Cliente.dart';
import '../../servicos/ListagemClientes.dart';

class ListaOrcamentosDia extends StatefulWidget {
  final DateTime dataSelecionada;

  const ListaOrcamentosDia({super.key, required this.dataSelecionada});

  @override
  State<ListaOrcamentosDia> createState() => _ListaOrcamentosDiaState();
}

class _ListaOrcamentosDiaState extends State<ListaOrcamentosDia> {
  // Cores
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corPrincipal = Colors.red[900]!;

  late Future<List<Map<String, dynamic>>> _futureOrcamentos;

  @override
  void initState() {
    super.initState();
    _atualizarLista();
  }

  void _atualizarLista() {
    setState(() {
      _futureOrcamentos = _buscarOrcamentosDoDia();
    });
  }

  Future<List<Map<String, dynamic>>> _buscarOrcamentosDoDia() async {
    // Define o intervalo do dia (00:00 até 23:59)
    final startOfDay = DateTime(
      widget.dataSelecionada.year,
      widget.dataSelecionada.month,
      widget.dataSelecionada.day,
    );
    final endOfDay = startOfDay
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));

    // CORREÇÃO: Usando 'data_pega' em vez de 'data_servico'
    final response = await Supabase.instance.client
        .from('orcamentos')
        .select('*, clientes(nome, telefone, bairro)')
        .gte('data_pega', startOfDay.toIso8601String())
        .lte('data_pega', endOfDay.toIso8601String())
        .order('data_pega', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // Função para navegar para a tela de criação
  void _abrirNovoOrcamento() async {
    // 1. Escolher Cliente
    final Cliente? clienteEscolhido = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ListaClientes(isSelecao: true),
      ),
    );

    if (clienteEscolhido == null) return;
    if (!mounted) return;

    // 2. Criar Orçamento (Passando o cliente e a data)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdicionarOrcamento(
          cliente: clienteEscolhido,
          dataSelecionada: widget.dataSelecionada,
        ),
      ),
    );

    if (result == true) {
      _atualizarLista();
    }
  }

  @override
  Widget build(BuildContext context) {
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNovoOrcamento,
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Novo Agendamento"),
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
                "Erro: ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final orcamentos = snapshot.data ?? [];

          if (orcamentos.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orcamentos.length,
            itemBuilder: (context, index) =>
                _buildOrcamentoCard(orcamentos[index]),
          );
        },
      ),
    );
  }

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
    // Dados do Cliente (segurança contra null)
    final cliente = orcamento['clientes'] ?? {};
    final nome = cliente['nome'] ?? 'Cliente Desconhecido';
    final bairro = cliente['bairro'] ?? 'Bairro n/a';

    // Dados do Orçamento
    // CORREÇÃO: Usando 'data_pega'
    DateTime.parse(orcamento['data_pega']);

    // Lógica visual Manhã/Tarde
    final horarioTexto = orcamento['horario_do_dia'] ?? 'Manhã';
    final isTarde = horarioTexto.toString() == 'Tarde';
    final iconHorario = isTarde ? Icons.wb_twilight : Icons.wb_sunny_outlined;
    final colorHorario = isTarde ? Colors.orangeAccent : Colors.yellowAccent;

    return Card(
      color: corCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // Ícone indicando horário (Visualmente mais rico que apenas texto)
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorHorario.withOpacity(0.3)),
          ),
          child: Icon(iconHorario, color: colorHorario, size: 24),
        ),
        title: Text(
          nome,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              orcamento['titulo'] ?? 'Sem título',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  bairro,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              horarioTexto.toUpperCase(),
              style: TextStyle(
                color: colorHorario,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white24,
              size: 14,
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DetalhesOrcamento(orcamentoInicial: orcamento),
            ),
          ).then((_) {
            // Atualiza a lista quando voltar (caso tenha editado ou excluído)
            _atualizarLista();
          });
        },
      ),
    );
  }
}
