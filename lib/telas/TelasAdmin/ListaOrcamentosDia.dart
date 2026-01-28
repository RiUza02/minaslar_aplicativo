import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // Importante para ações rápidas
import 'DetalhesOrcamento.dart';
import 'AdicionarOrcamento.dart';
import '../../modelos/Cliente.dart';
import '../../servicos/ListagemClientes.dart';
import '../../servicos/autenticacao.dart';
import '../../servicos/CalculaRota.dart';

class ListaOrcamentosDia extends StatefulWidget {
  final DateTime dataSelecionada;
  // Flag para controlar se mostra tudo ou só pendentes
  final bool apenasPendentes;

  const ListaOrcamentosDia({
    super.key,
    required this.dataSelecionada,
    this.apenasPendentes = false, // Padrão false (mostra tudo)
  });

  @override
  State<ListaOrcamentosDia> createState() => _ListaOrcamentosDiaState();
}

class _ListaOrcamentosDiaState extends State<ListaOrcamentosDia> {
  // ==================================================
  // CONFIGURAÇÕES VISUAIS
  // ==================================================
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corPrincipal = Colors.red[900]!;
  final Color corTextoCinza = Colors.grey[500]!;

  late Future<List<Map<String, dynamic>>> _futureOrcamentos;
  List<Map<String, dynamic>> _listaParaRota = [];

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
  // LÓGICA DE DADOS (Inalterada)
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

    var query = Supabase.instance.client
        .from('orcamentos')
        .select('*, clientes(nome, telefone, bairro, rua, numero)')
        .or('and($filterEntrada),and($filterEntrega)');

    final response = await query.order('data_pega', ascending: true);
    var lista = List<Map<String, dynamic>>.from(response);

    if (widget.apenasPendentes) {
      lista = lista.where((orcamento) {
        final bool foiEntregue = orcamento['entregue'] ?? false;
        return foiEntregue == false;
      }).toList();
    }

    lista.sort((a, b) {
      final hA = (a['horario_do_dia'] ?? '').toString().toLowerCase();
      final hB = (b['horario_do_dia'] ?? '').toString().toLowerCase();
      if (hA == 'manhã' && hB != 'manhã') return -1;
      if (hB == 'manhã' && hA != 'manhã') return 1;
      return 0;
    });

    _listaParaRota = lista;
    return lista;
  }

  void _gerarRota() {
    if (_listaParaRota.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum atendimento na lista.")),
      );
      return;
    }

    List<Map<String, dynamic>> listaFormatada = _listaParaRota.map((orc) {
      final cliente = orc['clientes'] ?? {};
      return {
        'id': orc['id'],
        'nome_cliente': cliente['nome'] ?? 'Cliente',
        'rua': cliente['rua'] ?? '',
        'numero': (cliente['numero'] ?? '').toString(),
        'bairro': cliente['bairro'] ?? '',
        'cidade': 'Juiz de Fora',
      };
    }).toList();

    ServicoRota.otimizarRotaDoDia(context, listaFormatada);
  }

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

  // --- AÇÕES RÁPIDAS NO CARD ---

  Future<void> _abrirWhatsApp(String telefone) async {
    final numero = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = Uri.parse('https://wa.me/55$numero');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // Nova função para abrir o mapa individualmente
  Future<void> _abrirGoogleMapsIndividual(
    String rua,
    String numero,
    String bairro,
  ) async {
    // Monta a query de busca
    final String query = Uri.encodeComponent(
      '$rua, $numero - $bairro, Juiz de Fora - MG',
    );
    final Uri googleMapsUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$query",
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Não foi possível abrir o mapa.")),
        );
      }
    }
  }

  // ==================================================
  // CONSTRUÇÃO DA UI
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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => AuthService().deslogar(),
            tooltip: 'Sair',
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "btnRota",
            onPressed: _gerarRota,
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            elevation: 6,
            child: const Icon(Icons.map),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "btnAdd",
            onPressed: _abrirNovoOrcamento,
            backgroundColor: corPrincipal,
            foregroundColor: Colors.white,
            elevation: 6,
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
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: corPrincipal,
            backgroundColor: corCard,
            onRefresh: () async => _atualizarLista(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: orcamentos.length,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) =>
                  _buildOrcamentoCard(orcamentos[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () async => _atualizarLista(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_available_outlined,
                  size: 80,
                  color: Colors.grey[800],
                ),
                const SizedBox(height: 16),
                Text(
                  "Agenda livre para hoje.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrcamentoCard(Map<String, dynamic> orcamento) {
    final cliente = orcamento['clientes'] ?? {};
    final nomeCliente = cliente['nome'] ?? 'Cliente';
    final telefone = cliente['telefone'] ?? '';
    final rua = cliente['rua'] ?? '';
    final numero = cliente['numero'] ?? 'S/N';
    final bairro = cliente['bairro'] ?? '';
    final tituloServico = orcamento['titulo'] ?? '';

    final horarioTexto = (orcamento['horario_do_dia'] ?? 'Manhã').toString();
    final isTarde = horarioTexto.toLowerCase() == 'tarde';

    // Cores baseadas no turno
    final Color corFaixa = isTarde ? Colors.orange[800]! : Colors.yellow[700]!;
    final IconData iconHorario = isTarde ? Icons.wb_twilight : Icons.wb_sunny;
    final String labelTurno = isTarde ? "TARDE" : "MANHÃ";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
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
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Barra Lateral Colorida (Turno)
              Container(width: 6, color: corFaixa),

              // 2. Conteúdo Principal
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho: Turno e Nome do Cliente
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: corFaixa.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(iconHorario, size: 14, color: corFaixa),
                                const SizedBox(width: 6),
                                Text(
                                  labelTurno,
                                  style: TextStyle(
                                    color: corFaixa,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Nome do Cliente em Destaque
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              nomeCliente,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Título do Serviço
                      Padding(
                        padding: const EdgeInsets.only(left: 26),
                        child: Text(
                          tituloServico,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 12),

                      // Rodapé: Endereço/Telefone e Botões de Ação
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Coluna de Informações (Esq)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Endereço
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: corTextoCinza,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "ENDEREÇO",
                                      style: TextStyle(
                                        color: corTextoCinza,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "$rua, $numero",
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  bairro,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 10),

                                // Telefone (Novo)
                                if (telefone.isNotEmpty)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        size: 14,
                                        color: corTextoCinza,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        telefone, // Exibe o telefone
                                        style: TextStyle(
                                          color: Colors.grey[300],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),

                          // Coluna de Botões (Dir)
                          Column(
                            children: [
                              // Botão WhatsApp
                              if (telefone.isNotEmpty)
                                IconButton(
                                  onPressed: () => _abrirWhatsApp(telefone),
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  color: Colors.greenAccent,
                                  tooltip: 'WhatsApp',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.green.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                ),

                              // Botão Google Maps (Novo)
                              if (rua.isNotEmpty || bairro.isNotEmpty)
                                IconButton(
                                  onPressed: () => _abrirGoogleMapsIndividual(
                                    rua,
                                    numero,
                                    bairro,
                                  ),
                                  icon: const Icon(Icons.map_outlined),
                                  color: Colors.blueAccent,
                                  tooltip: 'Abrir no Mapa',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.blue.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
