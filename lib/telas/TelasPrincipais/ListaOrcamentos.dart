import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../modelos/Cliente.dart';
import '../TelasSecundarias/DetalhesOrcamento.dart';
import '../TelasSecundarias/AdicionarOrcamento.dart';
import '../TelasSecundarias/ListagemClientes.dart';

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

  // Armazena TODOS os dados vindos do banco
  List<Map<String, dynamic>> _listaCompleta = [];

  // Armazena a lista filtrada que é exibida na tela
  List<Map<String, dynamic>> _listaExibida = [];

  // Variável de controle de carregamento
  bool _isLoading = true;

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
    super.dispose();
  }

  // ==================================================
  // LÓGICA DE DADOS (DIRETO NO ARQUIVO)
  // ==================================================

  Future<void> _carregarOrcamentos() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    try {
      if (mounted) setState(() => _isLoading = true);

      // Query Base
      dynamic query = client
          .from('orcamentos')
          .select('*, clientes(nome, telefone, endereco)')
          .order('created_at', ascending: false);

      // Se NÃO for admin, filtra apenas os do usuário logado
      if (!widget.isAdmin && userId != null) {
        query = query.eq('user_id', userId);
      }

      final response = await query;
      final dados = List<Map<String, dynamic>>.from(response.data ?? []);

      if (mounted) {
        setState(() {
          _listaCompleta = dados;
          _filtrarOrcamentos(); // Aplica o filtro inicial
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Erro ao carregar: $e");
    }
  }

  /// Filtra e Ordena a lista localmente
  void _filtrarOrcamentos() {
    final termo = _searchController.text.trim().toLowerCase();
    List<Map<String, dynamic>> temp = List.from(_listaCompleta);

    // 1. BUSCA
    if (termo.isNotEmpty) {
      temp = temp.where((orcamento) {
        final titulo = (orcamento['titulo'] ?? '').toString().toLowerCase();
        final descricao = (orcamento['descricao'] ?? '')
            .toString()
            .toLowerCase();
        final nomeCliente = (orcamento['clientes']?['nome'] ?? '')
            .toString()
            .toLowerCase();

        return titulo.contains(termo) ||
            descricao.contains(termo) ||
            nomeCliente.contains(termo);
      }).toList();
    }

    // 2. ORDENAÇÃO
    switch (_ordenacaoAtual) {
      case TipoOrdenacaoOrcamento.atraso:
        temp.sort((a, b) => _compararPorAtraso(a, b));
        break;
      case TipoOrdenacaoOrcamento.clienteAZ:
        temp.sort((a, b) {
          final cA = (a['clientes']?['nome'] ?? '').toString().toLowerCase();
          final cB = (b['clientes']?['nome'] ?? '').toString().toLowerCase();
          return cA.compareTo(cB);
        });
        break;
      case TipoOrdenacaoOrcamento.valorMaior:
        temp.sort((a, b) {
          final vA = (a['valor'] as num?) ?? 0;
          final vB = (b['valor'] as num?) ?? 0;
          return vB.compareTo(vA);
        });
        break;
      case TipoOrdenacaoOrcamento.dataRecente:
        temp.sort((a, b) {
          final dA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
          final dB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
          return dB.compareTo(dA);
        });
        break;
    }

    setState(() {
      _listaExibida = temp;
    });
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

  // ==================================================
  // AÇÕES DO USUÁRIO
  // ==================================================

  void _mudarOrdenacao(TipoOrdenacaoOrcamento novaOrdem) {
    if (_ordenacaoAtual != novaOrdem) {
      _ordenacaoAtual = novaOrdem;
      _filtrarOrcamentos();
    }
  }

  void _onSearchChanged(String value) {
    _filtrarOrcamentos();
  }

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

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 60, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
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
