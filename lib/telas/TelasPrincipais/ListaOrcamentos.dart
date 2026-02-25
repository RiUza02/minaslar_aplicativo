import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../modelos/Cliente.dart';
import '../TelasSecundarias/DetalhesOrcamento.dart';
import '../TelasSecundarias/AdicionarOrcamento.dart';
import '../TelasSecundarias/ListagemClientes.dart';
import '../../servicos/servicos.dart';

enum TipoOrdenacaoOrcamento { dataRecente, valorMaior, clienteAZ, atraso }

class ListaOrcamentos extends StatefulWidget {
  // VOLTAMOS A RECEBER O ISADMIN AQUI
  final bool isAdmin;

  const ListaOrcamentos({super.key, required this.isAdmin});

  @override
  State<ListaOrcamentos> createState() => _ListaOrcamentosState();
}

class _ListaOrcamentosState extends State<ListaOrcamentos>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ==================================================
  // CONFIGURAÇÕES VISUAIS E VARIÁVEIS DE ESTADO
  // ==================================================
  late Color corPrincipal;
  late Color corSecundaria;
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corTextoCinza = Colors.grey[500]!;

  final TextEditingController _searchController = TextEditingController();

  // Armazena a lista que é exibida na tela, agora vinda do servidor já filtrada.
  List<Map<String, dynamic>> _listaExibida = [];

  // Variável de controle de carregamento
  bool _isLoading = true;
  bool _semInternet = false;

  // Debouncer para a busca
  Timer? _debounce;
  TipoOrdenacaoOrcamento _ordenacaoAtual = TipoOrdenacaoOrcamento.dataRecente;

  // ==================================================
  // CICLO DE VIDA DO WIDGET
  // ==================================================
  @override
  void initState() {
    super.initState();
    // Define as cores com base no parâmetro do widget
    corPrincipal = widget.isAdmin ? Colors.red[900]! : Colors.blue[900]!;
    corSecundaria = widget.isAdmin ? Colors.blue[300]! : Colors.cyan[400]!;

    _carregarOrcamentos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ==================================================
  // LÓGICA DE DADOS (DIRETO NO ARQUIVO)
  // ==================================================

  /// **MELHORIA DE PERFORMANCE:** Busca os orçamentos no Supabase, aplicando
  /// filtros de busca e ordenação diretamente na query do banco de dados.
  /// Isso evita carregar todos os registros para a memória, tornando a tela
  /// muito mais rápida e eficiente.
  Future<void> _carregarOrcamentos() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _semInternet = false;
      });
    }

    if (!await Servicos.temConexao()) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _semInternet = true;
        });
      }
      return;
    }

    final client = Supabase.instance.client;

    try {
      final termoBusca = _searchController.text.trim();

      // Query Base
      dynamic query = client
          .from('orcamentos')
          .select('*, clientes(*)'); // Busca todos os dados do cliente

      // Filtro de busca por texto
      if (termoBusca.isNotEmpty) {
        // Para buscar no nome do cliente (tabela aninhada), a sintaxe é `tabela!coluna`
        query = query.or(
          'titulo.ilike.%$termoBusca%,descricao.ilike.%$termoBusca%,clientes.nome.ilike.%$termoBusca%',
          // Adiciona o foreignTable para indicar que parte do filtro
          // se aplica a uma tabela relacionada.
          referencedTable: 'clientes',
        );
      }

      // Ordenação
      switch (_ordenacaoAtual) {
        case TipoOrdenacaoOrcamento.clienteAZ:
          // Ordenação por coluna de tabela relacionada
          query = query.order(
            // CORREÇÃO: A sintaxe correta é 'tabela_estrangeira.coluna'
            'clientes.nome',
            ascending: true,
          );
          break;
        case TipoOrdenacaoOrcamento.valorMaior:
          query = query.order('valor', ascending: false, nullsFirst: false);
          break;
        case TipoOrdenacaoOrcamento.dataRecente:
          query = query.order('data_pega', ascending: false);
          break;
        case TipoOrdenacaoOrcamento.atraso:
          // Ordenação por atraso é complexa e mantida no cliente por enquanto.
          break;
      }

      final dados = List<Map<String, dynamic>>.from(await query);

      if (mounted) {
        setState(() {
          _listaExibida = dados;
          _ordenarLocalmente(); // Aplica ordenações complexas
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Erro ao carregar orçamentos: $e");
    }
  }

  // Lógica auxiliar de ordenação por atraso
  int _compararPorAtraso(Map<String, dynamic> a, Map<String, dynamic> b) {
    int getPrioridade(Map<String, dynamic> item) {
      final bool isConcluido = item['entregue'] ?? false;
      final bool ehRetorno = item['eh_retorno'] ?? false;
      final dataStr = item['data_entrega'];

      if (isConcluido) return 5; // Menor prioridade

      bool isAtrasado = false;
      if (dataStr != null) {
        final entrega = DateTime.parse(dataStr);
        final hoje = DateTime.now();
        // Remove horas para comparar apenas datas
        final dataEntrega = DateTime(entrega.year, entrega.month, entrega.day);
        final dataHoje = DateTime(hoje.year, hoje.month, hoje.day);

        if (dataEntrega.isBefore(dataHoje)) isAtrasado = true;
      }

      if (isAtrasado) return 1; // Máxima prioridade
      if (ehRetorno) return 2;
      if (dataStr == null) return 3;
      return 4;
    }

    int pA = getPrioridade(a);
    int pB = getPrioridade(b);
    return pA.compareTo(pB);
  }

  /// Aplica ordenações que são muito complexas para a query, como a de "Atraso".
  void _ordenarLocalmente() {
    if (_ordenacaoAtual == TipoOrdenacaoOrcamento.atraso) {
      _listaExibida.sort((a, b) => _compararPorAtraso(a, b));
    }
  }

  // ==================================================
  // AÇÕES DO USUÁRIO
  // ==================================================

  void _mudarOrdenacao(TipoOrdenacaoOrcamento novaOrdem) {
    if (_ordenacaoAtual != novaOrdem) {
      setState(() {
        _ordenacaoAtual = novaOrdem;
        _carregarOrcamentos(); // Recarrega do servidor com a nova ordenação
      });
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _carregarOrcamentos);
  }

  void _abrirNovoOrcamento() async {
    final Cliente? clienteEscolhido = await Navigator.push(
      context,
      MaterialPageRoute(
        // CORREÇÃO: A tela para selecionar um cliente é a 'ListagemClientes',
        // que é projetada para o modo de seleção. A tela 'ListaClientes' é
        // para visualização geral e não possui o parâmetro 'isSelecao'.
        builder: (context) =>
            ListagemClientes(isSelecao: true, isAdmin: widget.isAdmin),
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

    _carregarOrcamentos();
  }

  // ==================================================
  // CONSTRUÇÃO DA INTERFACE (BUILD)
  // ==================================================
  @override
  Widget build(BuildContext context) {
    super.build(context);

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
              hintText: "Título, cliente ou descrição...",
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
              if (widget.isAdmin)
                _buildPopupItem(
                  TipoOrdenacaoOrcamento.valorMaior,
                  "Maior Valor",
                ),
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
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              backgroundColor: corPrincipal,
              foregroundColor: Colors.white,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onPressed: _abrirNovoOrcamento,
              child: const Icon(Icons.post_add, size: 28),
            )
          : null,

      // --- CORPO DA LISTA ---
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: corPrincipal))
          : _semInternet
          ? _semInternetWidget()
          : RefreshIndicator(
              color: corPrincipal,
              backgroundColor: corCard,
              onRefresh: _carregarOrcamentos,
              child: _listaExibida.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _listaExibida.length,
                      itemBuilder: (context, index) {
                        return _buildOrcamentoCard(_listaExibida[index]);
                      },
                    ),
            ),
    );
  }

  // ==================================================
  // COMPONENTES UI
  // ==================================================

  Widget _buildEmptyState() {
    String msg = _searchController.text.isNotEmpty
        ? "Nenhum resultado para \"${_searchController.text}\""
        : "Nenhum orçamento cadastrado.";
    // Envolve com ListView para permitir o RefreshIndicator funcionar mesmo com a tela vazia.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 60,
                  color: Colors.grey[800],
                ),
                const SizedBox(height: 16),
                Text(
                  msg,
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _semInternetWidget() {
    return RefreshIndicator(
      onRefresh: _carregarOrcamentos,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_outlined,
                  size: 80,
                  color: Colors.grey[800],
                ),
                const SizedBox(height: 16),
                Text(
                  "Sem conexão com a internet.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 18),
                ),
              ],
            ),
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

    // Formatação de datas
    final dataEntradaFormatada = dataPegaStr != null
        ? DateFormat('dd/MM/yy').format(DateTime.parse(dataPegaStr))
        : '--/--';

    final dataEntregaFormatada = dataEntregaStr != null
        ? DateFormat('dd/MM/yy').format(DateTime.parse(dataEntregaStr))
        : '--/--';

    final valorFormatado = valor != null
        ? NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor)
        : 'A Combinar';

    // 2. Lógica reativa de status e cores
    Color corFaixaLateral;
    String textoAviso;
    Color corAviso;

    bool isAtrasado = false;
    if (!isConcluido && dataEntregaStr != null) {
      final dataEntrega = DateTime.parse(dataEntregaStr);
      final hoje = DateTime.now();
      final dataE = DateTime(
        dataEntrega.year,
        dataEntrega.month,
        dataEntrega.day,
      );
      final dataH = DateTime(hoje.year, hoje.month, hoje.day);
      if (dataE.isBefore(dataH)) isAtrasado = true;
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
      corFaixaLateral = corPrincipal;
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

    final Color corDataEntrega = isAtrasado
        ? corPrincipal
        : (isConcluido ? Colors.blue : Colors.white);

    // 3. Renderização do Card
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
              builder: (context) => DetalhesOrcamento(
                orcamentoInicial: orcamento,
                isAdmin: widget.isAdmin,
              ),
            ),
          ).then((_) => _carregarOrcamentos());
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: corFaixaLateral),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                          Row(
                            children: [
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
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(
                                  Icons.arrow_forward,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                              ),
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
