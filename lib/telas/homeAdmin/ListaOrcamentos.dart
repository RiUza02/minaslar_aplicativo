import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../TelasAdmin/DetalhesOrcamento.dart';
import '../TelasAdmin/AdicionarOrcamento.dart';
import '../../modelos/Cliente.dart';
import '../../servicos/ListagemClientes.dart';

/// Define os critérios disponíveis para ordenação da lista
enum TipoOrdenacaoOrcamento { dataRecente, valorMaior, clienteAZ, atraso }

class ListaOrcamentos extends StatefulWidget {
  const ListaOrcamentos({super.key});

  @override
  State<ListaOrcamentos> createState() => _ListaOrcamentosState();
}

class _ListaOrcamentosState extends State<ListaOrcamentos> {
  // ==================================================
  // CONFIGURAÇÕES VISUAIS E VARIÁVEIS DE ESTADO
  // ==================================================
  final Color corPrincipal = Colors.red[900]!;
  final Color corSecundaria = Colors.blue[300]!;
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corTextoCinza = Colors.grey[500]!;

  final TextEditingController _searchController = TextEditingController();

  // Estado da lista e controle de fluxo
  String _termoBusca = '';
  List<Map<String, dynamic>> _listaOrcamentos = [];
  bool _estaCarregando = true;
  TipoOrdenacaoOrcamento _ordenacaoAtual = TipoOrdenacaoOrcamento.dataRecente;

  // ==================================================
  // CICLO DE VIDA DO WIDGET
  // ==================================================
  @override
  void initState() {
    super.initState();
    _carregarOrcamentos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==================================================
  // LÓGICA DE DADOS E SUPABASE
  // ==================================================

  /// Busca os orçamentos no banco de dados e faz o join com a tabela de clientes.
  Future<void> _carregarOrcamentos([bool isRefresh = false]) async {
    if (!mounted) return;
    if (!isRefresh) setState(() => _estaCarregando = true);

    try {
      final response = await Supabase.instance.client
          .from('orcamentos')
          .select('*, clientes(nome, telefone, bairro)');

      List<Map<String, dynamic>> dados = List<Map<String, dynamic>>.from(
        response,
      );

      _aplicarOrdenacao(dados);

      if (mounted) {
        setState(() {
          _listaOrcamentos = dados;
          _estaCarregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _estaCarregando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao carregar: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Aplica a lógica de ordenação na lista local baseada no Enum selecionado.
  void _aplicarOrdenacao(List<Map<String, dynamic>> lista) {
    switch (_ordenacaoAtual) {
      case TipoOrdenacaoOrcamento.atraso:
        lista.sort((a, b) {
          int getPrioridade(Map<String, dynamic> item) {
            final bool isConcluido = item['entregue'] ?? false;
            final bool ehRetorno = item['eh_retorno'] ?? false;
            final dataStr = item['data_entrega'];

            if (isConcluido) return 5;

            bool isAtrasado = false;
            if (dataStr != null) {
              final entrega = DateTime.parse(dataStr);
              final agora = DateTime.now();
              final hoje = DateTime(agora.year, agora.month, agora.day);
              final dataEntrega = DateTime(
                entrega.year,
                entrega.month,
                entrega.day,
              );
              if (dataEntrega.isBefore(hoje)) {
                isAtrasado = true;
              }
            }

            if (isAtrasado) return 1;
            if (ehRetorno) return 2;
            if (dataStr == null) return 3;
            return 4;
          }

          int pA = getPrioridade(a);
          int pB = getPrioridade(b);

          if (pA != pB) return pA.compareTo(pB);

          final dataA =
              DateTime.tryParse(a['data_pega'] ?? '') ?? DateTime(1900);
          final dataB =
              DateTime.tryParse(b['data_pega'] ?? '') ?? DateTime(1900);
          return dataB.compareTo(dataA);
        });
        break;

      case TipoOrdenacaoOrcamento.clienteAZ:
        lista.sort((a, b) {
          final clienteA = (a['clientes']?['nome'] ?? '')
              .toString()
              .toLowerCase();
          final clienteB = (b['clientes']?['nome'] ?? '')
              .toString()
              .toLowerCase();
          return clienteA.compareTo(clienteB);
        });
        break;

      case TipoOrdenacaoOrcamento.valorMaior:
        lista.sort((a, b) {
          final valorA = (a['valor'] as num?) ?? 0;
          final valorB = (b['valor'] as num?) ?? 0;
          return valorB.compareTo(valorA);
        });
        break;

      case TipoOrdenacaoOrcamento.dataRecente:
        lista.sort((a, b) {
          final dataA =
              DateTime.tryParse(a['data_pega'] ?? '') ?? DateTime(1900);
          final dataB =
              DateTime.tryParse(b['data_pega'] ?? '') ?? DateTime(1900);
          return dataB.compareTo(dataA);
        });
        break;
    }
  }

  // ==================================================
  // AÇÕES DO USUÁRIO
  // ==================================================

  void _mudarOrdenacao(TipoOrdenacaoOrcamento novaOrdem) {
    if (_ordenacaoAtual != novaOrdem) {
      setState(() {
        _ordenacaoAtual = novaOrdem;
        _aplicarOrdenacao(_listaOrcamentos);
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _termoBusca = value.toLowerCase();
    });
  }

  /// Navega para seleção de cliente e depois para criação do orçamento.
  void _abrirNovoOrcamento() async {
    final Cliente? clienteEscolhido = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ListaClientes(isSelecao: true),
      ),
    );

    if (clienteEscolhido == null || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdicionarOrcamento(
          cliente: clienteEscolhido,
          dataSelecionada: DateTime.now(),
        ),
      ),
    );

    _carregarOrcamentos(true);
  }

  // ==================================================
  // CONSTRUÇÃO DA INTERFACE (BUILD)
  // ==================================================
  @override
  Widget build(BuildContext context) {
    final listaFiltrada = _termoBusca.isEmpty
        ? _listaOrcamentos
        : _listaOrcamentos.where((orc) {
            final titulo = (orc['titulo'] ?? '').toString().toLowerCase();
            final cliente = (orc['clientes']?['nome'] ?? '')
                .toString()
                .toLowerCase();
            return titulo.contains(_termoBusca) ||
                cliente.contains(_termoBusca);
          }).toList();

    return Scaffold(
      backgroundColor: corFundo,

      // --- APP BAR PADRONIZADA ---
      appBar: AppBar(
        backgroundColor: corPrincipal,
        elevation: 0,
        toolbarHeight: 80,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: "Buscar título ou cliente...",
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
          ),
        ),
        actions: [
          PopupMenuButton<TipoOrdenacaoOrcamento>(
            icon: const Icon(Icons.sort, color: Colors.white, size: 28),
            tooltip: 'Ordenar',
            color: corCard,
            onSelected: _mudarOrdenacao,
            itemBuilder: (context) => [
              _buildPopupItem(
                TipoOrdenacaoOrcamento.dataRecente,
                "Mais Recentes",
              ),
              _buildPopupItem(
                TipoOrdenacaoOrcamento.atraso,
                "Atraso (Urgente)",
              ),
              _buildPopupItem(TipoOrdenacaoOrcamento.valorMaior, "Maior Valor"),
              _buildPopupItem(
                TipoOrdenacaoOrcamento.clienteAZ,
                "Cliente (A-Z)",
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),

      // --- BOTÃO FLUTUANTE ---
      floatingActionButton: FloatingActionButton(
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: _abrirNovoOrcamento,
        child: const Icon(Icons.post_add, size: 28),
      ),

      // --- CORPO DA LISTA ---
      body: _estaCarregando
          ? Center(child: CircularProgressIndicator(color: corPrincipal))
          : RefreshIndicator(
              color: corPrincipal,
              backgroundColor: corCard,
              onRefresh: () async => await _carregarOrcamentos(true),
              child: listaFiltrada.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: listaFiltrada.length,
                      itemBuilder: (context, index) {
                        return _buildOrcamentoCard(listaFiltrada[index]);
                      },
                    ),
            ),
    );
  }

  // ==================================================
  // COMPONENTES UI
  // ==================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 60, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text(
            "Nenhum orçamento encontrado.",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<TipoOrdenacaoOrcamento> _buildPopupItem(
    TipoOrdenacaoOrcamento value,
    String text,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            _ordenacaoAtual == value
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: _ordenacaoAtual == value ? corSecundaria : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildOrcamentoCard(Map<String, dynamic> orcamento) {
    // 1. Extração segura de dados
    final titulo = orcamento['titulo'] ?? 'Sem Título';
    final valor = orcamento['valor'];
    final dataPegaStr = orcamento['data_pega'];
    final dataEntregaStr = orcamento['data_entrega'];
    final clienteNome =
        orcamento['clientes']?['nome'] ?? 'Cliente Desconhecido';
    final bool ehRetorno = orcamento['eh_retorno'] ?? false;
    final bool isConcluido = orcamento['entregue'] ?? false;

    // Formatação de datas (Apenas Dia/Mês para caber no card)
    final dataEntradaFormatada = dataPegaStr != null
        ? DateFormat('dd/MM').format(DateTime.parse(dataPegaStr))
        : '--/--';

    final dataEntregaFormatada = dataEntregaStr != null
        ? DateFormat('dd/MM').format(DateTime.parse(dataEntregaStr))
        : '--/--';

    final valorFormatado = valor != null
        ? NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor)
        : 'A Combinar';

    // 2. Lógica reativa de status e cores
    Color corFaixaLateral;
    String textoAviso;
    Color corAviso;

    // Lógica de Atraso
    bool isAtrasado = false;
    if (!isConcluido && dataEntregaStr != null) {
      final dataEntrega = DateTime.parse(dataEntregaStr);
      final agora = DateTime.now();
      final hoje = DateTime(agora.year, agora.month, agora.day);
      final entrega = DateTime(
        dataEntrega.year,
        dataEntrega.month,
        dataEntrega.day,
      );
      if (entrega.isBefore(hoje)) {
        isAtrasado = true;
      }
    }

    if (isConcluido) {
      corFaixaLateral = Colors.blue;
      textoAviso = "CONCLUÍDO";
      corAviso = Colors.blue;
    } else if (ehRetorno) {
      corFaixaLateral = Colors.green;
      textoAviso = "GARANTIA";
      corAviso = Colors.green;
    } else if (isAtrasado) {
      corFaixaLateral = corPrincipal; // Vermelho
      textoAviso = "ATRASADO";
      corAviso = corPrincipal;
    } else if (dataEntregaStr == null) {
      corFaixaLateral = Colors.grey;
      textoAviso = "SEM DATA";
      corAviso = Colors.grey;
    } else {
      corFaixaLateral = Colors.orange;
      textoAviso = "EM ANDAMENTO";
      corAviso = Colors.orange;
    }

    // Cor da data de entrega baseada no status
    final Color corDataEntrega = isAtrasado
        ? corPrincipal
        : (isConcluido ? Colors.blue : Colors.white);

    // 3. Renderização do Card (Design Novo)
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
          ).then((_) => _carregarOrcamentos(true));
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- BARRA LATERAL ---
              Container(width: 6, color: corFaixaLateral),

              // --- CONTEÚDO ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho: Status Badge e Datas (Entrada -> Entrega)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: corAviso.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: corAviso.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              textoAviso,
                              style: TextStyle(
                                color: corAviso,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),

                          // Datas: Entrada -> Seta -> Entrega
                          Row(
                            children: [
                              // Entrada
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: corTextoCinza,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dataEntradaFormatada,
                                style: TextStyle(
                                  color: corTextoCinza,
                                  fontSize: 12,
                                ),
                              ),

                              // Seta
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(
                                  Icons.arrow_forward,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                              ),

                              // Entrega
                              Icon(
                                Icons.event_available,
                                size: 12,
                                color: corTextoCinza,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dataEntregaFormatada,
                                style: TextStyle(
                                  color: corDataEntrega,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Título do Serviço
                      Text(
                        titulo,
                        style: TextStyle(
                          color: isConcluido ? Colors.white54 : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: isConcluido
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 6),

                      // Nome do Cliente
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: corSecundaria),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              clienteNome,
                              style: TextStyle(
                                color: corTextoCinza,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 8),

                      // Valor (Rodapé)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            valorFormatado,
                            style: TextStyle(
                              color: valor != null ? Colors.amber : Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
