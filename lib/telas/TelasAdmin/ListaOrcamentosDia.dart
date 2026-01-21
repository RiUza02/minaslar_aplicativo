import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'DetalhesOrcamento.dart';
import 'AdicionarOrcamento.dart';
import '../../modelos/Cliente.dart';
import '../../servicos/ListagemClientes.dart';

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
  final Color corSecundaria = Colors.blueAccent;

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
    final startOfDay = DateTime(
      widget.dataSelecionada.year,
      widget.dataSelecionada.month,
      widget.dataSelecionada.day,
    );
    final endOfDay = startOfDay
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));

    final response = await Supabase.instance.client
        .from('orcamentos')
        .select('*, clientes(nome, telefone, bairro)')
        .gte('data_pega', startOfDay.toIso8601String())
        .lte('data_pega', endOfDay.toIso8601String())
        .order(
          'data_pega',
          ascending: true,
        ); // Ordena por data de criação primeiro

    // Converte para lista manipulável
    final lista = List<Map<String, dynamic>>.from(response);

    // --- NOVA LÓGICA DE ORDENAÇÃO (Manhã antes de Tarde) ---
    lista.sort((a, b) {
      final hA = (a['horario_do_dia'] ?? '').toString().toLowerCase();
      final hB = (b['horario_do_dia'] ?? '').toString().toLowerCase();

      // Se A é manhã e B não é, A vem primeiro
      if (hA == 'manhã' && hB != 'manhã') return -1;
      // Se B é manhã e A não é, B vem primeiro
      if (hB == 'manhã' && hA != 'manhã') return 1;

      return 0; // Mantém a ordem original se forem iguais
    });

    return lista;
  }

  void _abrirNovoOrcamento() async {
    final Cliente? clienteEscolhido = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ListaClientes(isSelecao: true),
      ),
    );

    if (clienteEscolhido == null) return;
    if (!mounted) return;

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
        title: Text(
          "Agenda: $dataFormatada",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirNovoOrcamento,
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.post_add),
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
          Icon(Icons.event_busy, size: 80, color: Colors.white12),
          SizedBox(height: 16),
          Text(
            "Nenhum serviço para este dia.",
            style: TextStyle(color: Colors.white38, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildOrcamentoCard(Map<String, dynamic> orcamento) {
    // Extração de Dados
    final cliente = orcamento['clientes'] ?? {};
    final nomeCliente = cliente['nome'] ?? 'Cliente Desconhecido';
    final telefone = cliente['telefone'] ?? 'Sem telefone';
    final bairro = cliente['bairro'] ?? 'Bairro n/a';
    final tituloServico = orcamento['titulo'] ?? 'Serviço sem título';

    // Lógica de Horário e Cores
    final horarioTexto = (orcamento['horario_do_dia'] ?? 'Manhã').toString();
    final isTarde = horarioTexto.toLowerCase() == 'tarde';

    // DEFINIÇÃO DAS CORES: Amarelo para Manhã, Laranja para Tarde
    final colorBanner = isTarde ? Colors.orangeAccent : Colors.yellowAccent;
    final iconHorario = isTarde ? Icons.wb_twilight : Icons.wb_sunny;

    return Card(
      color: corCard,
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DetalhesOrcamento(orcamentoInicial: orcamento),
            ),
          ).then((_) => _atualizarLista());
        },
        child: Column(
          children: [
            // =========================
            // BANNER DE HORÁRIO (TOPO)
            // =========================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: colorBanner.withOpacity(0.15),
              child: Row(
                children: [
                  Icon(iconHorario, size: 16, color: colorBanner),
                  const SizedBox(width: 8),
                  Text(
                    horarioTexto.toUpperCase(),
                    style: TextStyle(
                      color: colorBanner,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: colorBanner.withOpacity(0.5),
                    size: 18,
                  ),
                ],
              ),
            ),

            // =========================
            // CONTEÚDO DO CARD
            // =========================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ícone Lateral (Avatar)
                  CircleAvatar(
                    backgroundColor: Colors.white10,
                    radius: 24,
                    child: Text(
                      nomeCliente.isNotEmpty
                          ? nomeCliente[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Informações Centrais
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nomeCliente,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tituloServico,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 12),

                        // Linha de Detalhes (Bairro e Telefone)
                        _buildInfoRow(Icons.location_on_outlined, bairro),
                        const SizedBox(height: 6),
                        // CORRIGIDO: Ícone de telefone
                        _buildInfoRow(Icons.phone_outlined, telefone),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
