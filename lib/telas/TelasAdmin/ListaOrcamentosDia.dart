import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../servicos/servicos.dart';
import 'DetalhesOrcamento.dart';
import 'AdicionarOrcamento.dart';
import '../homeAdmin/configuracoes.dart';
import '../../modelos/Cliente.dart';
import '../../servicos/ListagemClientes.dart';
import '../../servicos/autenticacao.dart';
import '../../servicos/CalculaRota.dart';

class ListaOrcamentosDia extends StatefulWidget {
  final DateTime dataSelecionada;
  final bool apenasPendentes;
  final bool mostrarLogout;
  final bool mostrarConfiguracoes;
  final bool mostrarTitulo;

  const ListaOrcamentosDia({
    super.key,
    required this.dataSelecionada,
    this.apenasPendentes = false,
    this.mostrarLogout = false,
    this.mostrarConfiguracoes = false,
    this.mostrarTitulo = true,
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
        .select('*, clientes(nome, telefone, bairro, rua, numero, apartamento)')
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
        'apartamento': cliente['apartamento'] ?? '',
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

  Future<void> _abrirGoogleMapsIndividual(
    String rua,
    String numero,
    String apartamento,
    String bairro,
  ) async {
    final String enderecoCompleto = [
      rua,
      numero,
      if (apartamento.isNotEmpty) 'Apto $apartamento',
      bairro,
      'Juiz de Fora - MG',
    ].where((s) => s.isNotEmpty).join(', ');

    final Uri googleMapsUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(enderecoCompleto)}",
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
        title: widget.mostrarTitulo
            ? const Text("Orçamentos do Dia", style: TextStyle())
            : const Text("Orçamentos Pendentes", style: TextStyle()),
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        leading: widget.mostrarConfiguracoes
            ? IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Configuracoes(),
                  ),
                ),
                tooltip: 'Configurações',
              )
            : null,
        actions: [
          if (widget.mostrarLogout)
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

  // =========================================================
  // CARD DE ORÇAMENTO ATUALIZADO (ENDEREÇO EM LINHAS)
  // =========================================================
  Widget _buildOrcamentoCard(Map<String, dynamic> orcamento) {
    final cliente = orcamento['clientes'] ?? {};
    final nomeCliente = cliente['nome'] ?? 'Cliente';
    final telefone = cliente['telefone'] ?? '';
    final rua = cliente['rua'] ?? '';
    final numero = cliente['numero'] ?? 'S/N';
    final apartamento = cliente['apartamento'] ?? '';
    final bairro = cliente['bairro'] ?? '';
    final tituloServico = orcamento['titulo'] ?? '';

    final horarioTexto = (orcamento['horario_do_dia'] ?? 'Manhã').toString();
    final isTarde = horarioTexto.toLowerCase() == 'tarde';

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
              Container(width: 6, color: corFaixa),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho (Turno)
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

                      // Nome do Cliente
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

                      // Título do Serviço
                      const SizedBox(height: 4),
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

                      // =======================================================
                      // BLOCO DE ENDEREÇO E AÇÕES (ATUALIZADO)
                      // =======================================================
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Cabeçalho do Endereço
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
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // 1. RUA (Destaque Principal)
                                if (rua.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      rua,
                                      style: const TextStyle(
                                        color: Colors.white, // Cor de destaque
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                // 2. NÚMERO (Com ícone sutil)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.home_filled,
                                        size: 12,
                                        color: corTextoCinza,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Nº $numero",
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 3. APARTAMENTO (Se houver, linha exclusiva)
                                if (apartamento.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.apartment,
                                          size: 12,
                                          color: corTextoCinza,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Apt/Comp: $apartamento",
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // 4. BAIRRO (Linha exclusiva)
                                if (bairro.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.map,
                                          size: 12,
                                          color: corTextoCinza,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          bairro,
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                const SizedBox(height: 12),

                                // Telefone (Separado visualmente)
                                if (telefone.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.phone_android,
                                          size: 14,
                                          color: corTextoCinza,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          telefone,
                                          style: TextStyle(
                                            color: Colors.grey[300],
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // =================================================
                          // COLUNA DE BOTÕES (LADO DIREITO)
                          // =================================================
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              IconButton(
                                onPressed: () =>
                                    Servicos.fazerLigacao(telefone),
                                tooltip: 'Ligar',
                                icon: const Icon(
                                  Icons.phone,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.all(10),
                                ),
                              ),
                              const SizedBox(height: 10),
                              IconButton(
                                onPressed: () =>
                                    Servicos.abrirWhatsApp(telefone),
                                tooltip: 'WhatsApp',
                                icon: const Icon(
                                  Icons.chat,
                                  color: Colors.greenAccent,
                                  size: 20,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.green.withValues(
                                    alpha: 0.15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.all(10),
                                ),
                              ),
                              if (rua.isNotEmpty || bairro.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                IconButton(
                                  onPressed: () => _abrirGoogleMapsIndividual(
                                    rua,
                                    numero,
                                    apartamento,
                                    bairro,
                                  ),
                                  icon: const Icon(
                                    Icons.map_outlined,
                                    size: 20,
                                  ),
                                  color: Colors.blueAccent,
                                  tooltip: 'Abrir no Mapa',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.blue.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.all(10),
                                  ),
                                ),
                              ],
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
