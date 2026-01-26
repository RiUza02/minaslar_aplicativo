import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'DetalhesOrcamento.dart';
import 'AdicionarOrcamento.dart';
import '../../modelos/Cliente.dart';
import '../../servicos/ListagemClientes.dart';
import '../../servicos/autenticacao.dart';
import '../../servicos/CalculaRota.dart';

class ListaOrcamentosDia extends StatefulWidget {
  final DateTime dataSelecionada;

  const ListaOrcamentosDia({super.key, required this.dataSelecionada});

  @override
  State<ListaOrcamentosDia> createState() => _ListaOrcamentosDiaState();
}

class _ListaOrcamentosDiaState extends State<ListaOrcamentosDia> {
  // ==================================================
  // CONFIGURAÇÕES VISUAIS E ESTADO
  // ==================================================
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corPrincipal = Colors.red[900]!;

  late Future<List<Map<String, dynamic>>> _futureOrcamentos;

  // Lista em memória para passar para o gerador de rotas
  List<Map<String, dynamic>> _listaParaRota = [];

  // ==================================================
  // CICLO DE VIDA
  // ==================================================
  @override
  void initState() {
    super.initState();
    _futureOrcamentos = _buscarOrcamentosDoDia();
  }

  void _atualizarLista() {
    setState(() {
      _futureOrcamentos = _buscarOrcamentosDoDia();
    });
  }

  // ==================================================
  // LÓGICA DE NEGÓCIO (SUPABASE)
  // ==================================================
  Future<List<Map<String, dynamic>>> _buscarOrcamentosDoDia() async {
    final startOfDay = DateTime(
      widget.dataSelecionada.year,
      widget.dataSelecionada.month,
      widget.dataSelecionada.day,
    );
    final endOfDay = startOfDay
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));

    if (!(Supabase
            .instance
            .client
            .auth
            .currentSession
            ?.accessToken
            .isNotEmpty ??
        false)) {
      return [];
    }

    final filterEntrada =
        'data_pega.gte.${startOfDay.toIso8601String()},data_pega.lte.${endOfDay.toIso8601String()}';
    final filterEntrega =
        'data_entrega.gte.${startOfDay.toIso8601String()},data_entrega.lte.${endOfDay.toIso8601String()}';

    // ---------------------------------------------------------
    // ATUALIZAÇÃO: Buscando apenas os campos que existem no Modelo Cliente
    // (nome, telefone, bairro, rua)
    // ---------------------------------------------------------
    final response = await Supabase.instance.client
        .from('orcamentos')
        .select('*, clientes(nome, telefone, bairro, rua)')
        .or('and($filterEntrada),and($filterEntrega)')
        .order('data_pega', ascending: true);

    final lista = List<Map<String, dynamic>>.from(response);

    // Ordenação Manhã/Tarde
    lista.sort((a, b) {
      final hA = (a['horario_do_dia'] ?? '').toString().toLowerCase();
      final hB = (b['horario_do_dia'] ?? '').toString().toLowerCase();
      if (hA == 'manhã' && hB != 'manhã') return -1;
      if (hB == 'manhã' && hA != 'manhã') return 1;
      return 0;
    });

    // Salva a lista carregada na variável de classe para usar no botão de Rota
    _listaParaRota = lista;

    return lista;
  }

  // ==================================================
  // LÓGICA DO BOTÃO DE ROTA
  // ==================================================
  void _gerarRota() {
    if (_listaParaRota.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum atendimento na lista.")),
      );
      return;
    }

    // Adapta os dados do Supabase para o formato que o ServicoRota entende
    List<Map<String, dynamic>> listaFormatada = _listaParaRota.map((orc) {
      final cliente = orc['clientes'] ?? {};
      return {
        'id': orc['id'],
        'nome_cliente': cliente['nome'] ?? 'Cliente',
        // Como seu modelo não tem numero, passamos vazio.
        // O ServicoRota vai montar: "Rua Tal, - Bairro Tal, Juiz de Fora"
        'rua': cliente['rua'] ?? '',
        'numero': '',
        'bairro': cliente['bairro'] ?? '',
        // Defina sua cidade padrão aqui
        'cidade': 'Juiz de Fora',
      };
    }).toList();

    ServicoRota.otimizarRotaDoDia(context, listaFormatada);
  }

  // ==================================================
  // NAVEGAÇÃO E AÇÕES
  // ==================================================
  void _abrirNovoOrcamento() async {
    final Cliente? clienteEscolhido = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ListaClientes(isSelecao: true),
      ),
    );

    if (clienteEscolhido == null || !mounted) return;

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

  // ==================================================
  // INTERFACE PRINCIPAL (BUILD)
  // ==================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: const Text(
          "Orçamentos do Dia",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => AuthService().deslogar(),
            tooltip: 'Sair',
          ),
        ],
      ),

      // ---------------------------------------------------------
      // FLOATING ACTION BUTTON DUPLO (ROTA + NOVO)
      // ---------------------------------------------------------
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 1. Botão de Rota
          FloatingActionButton.extended(
            heroTag: "btnRota",
            onPressed: _gerarRota,
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            icon: const Icon(Icons.map),
            label: const Text("Rota"),
          ),
          const SizedBox(height: 16),
          // 2. Botão de Adicionar
          FloatingActionButton(
            heroTag: "btnAdd",
            onPressed: _abrirNovoOrcamento,
            backgroundColor: corPrincipal,
            foregroundColor: Colors.white,
            child: const Icon(Icons.post_add),
          ),
        ],
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

          if (orcamentos.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _atualizarLista(),
              child: _buildEmptyState(),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _atualizarLista(),
            child: ListView.builder(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 90,
              ), // Espaço extra bottom
              itemCount: orcamentos.length,
              itemBuilder: (context, index) =>
                  _buildOrcamentoCard(orcamentos[index]),
            ),
          );
        },
      ),
    );
  }

  // ==================================================
  // COMPONENTES VISUAIS
  // ==================================================
  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: const Center(
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
          ),
        ),
      ],
    );
  }

  Widget _buildOrcamentoCard(Map<String, dynamic> orcamento) {
    // Extração segura baseada no seu Modelo Cliente
    final cliente = orcamento['clientes'] ?? {};
    final nomeCliente = cliente['nome'] ?? 'Cliente Desconhecido';
    final telefone = cliente['telefone'] ?? 'Sem telefone';
    final bairro =
        cliente['bairro'] ?? 'Bairro n/a'; // Pegando do modelo correto
    final rua = cliente['rua'] ?? ''; // Pegando do modelo correto

    final tituloServico = orcamento['titulo'] ?? 'Serviço sem título';

    final horarioTexto = (orcamento['horario_do_dia'] ?? 'Manhã').toString();
    final isTarde = horarioTexto.toLowerCase() == 'tarde';
    final colorBanner = isTarde ? Colors.orangeAccent : Colors.yellowAccent;
    final iconHorario = isTarde ? Icons.wb_twilight : Icons.wb_sunny;

    // Lógica de Entrada vs Entrega
    String tipoAgendamento = '';
    Color corAgendamento = Colors.grey;
    final selectedDay = widget.dataSelecionada;

    final dataPegaStr = orcamento['data_pega'];
    if (dataPegaStr != null) {
      final dataPega = DateTime.parse(dataPegaStr);
      if (dataPega.year == selectedDay.year &&
          dataPega.month == selectedDay.month &&
          dataPega.day == selectedDay.day) {
        tipoAgendamento = 'ENTRADA';
        corAgendamento = Colors.lightBlueAccent;
      }
    }

    final dataEntregaStr = orcamento['data_entrega'];
    if (tipoAgendamento.isEmpty && dataEntregaStr != null) {
      final dataEntrega = DateTime.parse(dataEntregaStr);
      if (dataEntrega.year == selectedDay.year &&
          dataEntrega.month == selectedDay.month &&
          dataEntrega.day == selectedDay.day) {
        tipoAgendamento = 'ENTREGA';
        corAgendamento = Colors.greenAccent;
      }
    }

    return Card(
      color: corCard,
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
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
            // Banner Manhã/Tarde
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: colorBanner.withValues(alpha: 0.15),
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
                  if (tipoAgendamento.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: corAgendamento, width: 1),
                      ),
                      child: Text(
                        tipoAgendamento,
                        style: TextStyle(
                          color: corAgendamento,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Dados do Cliente
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 12),

                        // Exibe Rua e Bairro (conforme seu modelo)
                        _buildInfoRow(
                          Icons.location_on_outlined,
                          "$rua - $bairro",
                        ),
                        const SizedBox(height: 6),
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
