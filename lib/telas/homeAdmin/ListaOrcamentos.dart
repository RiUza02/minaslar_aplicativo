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
  final Color corTextoCinza = Colors.grey[400]!;

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
          // Define a prioridade de exibição
          int getPrioridade(Map<String, dynamic> item) {
            final bool isConcluido = item['entregue'] ?? false;
            final bool ehRetorno = item['eh_retorno'] ?? false;
            final dataStr = item['data_entrega'];

            if (isConcluido) return 5; // 5. Concluído

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

            if (isAtrasado) return 1; // 1. Atraso
            if (ehRetorno) return 2; // 2. Garantia
            if (dataStr == null) return 3; // 3. Sem data
            return 4; // 4. Em prazo
          }

          int pA = getPrioridade(a);
          int pB = getPrioridade(b);

          if (pA != pB) return pA.compareTo(pB);

          // Se a prioridade for a mesma, desempata pela data de criação
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
    // Filtra a lista localmente baseada no input de busca (Título ou Cliente)
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.black, fontSize: 16),
            decoration: InputDecoration(
              hintText: "Buscar título ou cliente...",
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: corPrincipal),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
            ),
          ),
        ),
        actions: [
          PopupMenuButton<TipoOrdenacaoOrcamento>(
            icon: const Icon(Icons.sort, color: Colors.white, size: 28),
            tooltip: 'Ordenar',
            color: Colors.grey[900],
            onSelected: _mudarOrdenacao,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: TipoOrdenacaoOrcamento.dataRecente,
                child: Text("Mais Recentes"),
              ),
              const PopupMenuItem(
                value: TipoOrdenacaoOrcamento.atraso,
                child: Text("Atraso (Urgente)"),
              ),
              const PopupMenuItem(
                value: TipoOrdenacaoOrcamento.valorMaior,
                child: Text("Maior Valor"),
              ),
              const PopupMenuItem(
                value: TipoOrdenacaoOrcamento.clienteAZ,
                child: Text("Cliente (A-Z)"),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        onPressed: _abrirNovoOrcamento,
        child: const Icon(Icons.post_add, size: 28),
      ),
      body: _estaCarregando
          ? Center(child: CircularProgressIndicator(color: corPrincipal))
          : RefreshIndicator(
              color: corPrincipal,
              backgroundColor: Colors.white,
              onRefresh: () async => await _carregarOrcamentos(true),
              child: listaFiltrada.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: Center(
                            child: Text(
                              "Nenhum orçamento encontrado.",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
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
  // COMPONENTES UI (CARD DE ORÇAMENTO)
  // ==================================================

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

    final dataFormatada = dataPegaStr != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(dataPegaStr))
        : '--/--';

    final valorFormatado = valor != null
        ? NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor)
        : 'A Combinar';

    final Color corValor = valor != null ? Colors.amber : Colors.grey;

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
      corFaixaLateral = corSecundaria; // Azul
      textoAviso = "Concluído";
      corAviso = corSecundaria;
    } else if (ehRetorno) {
      corFaixaLateral = Colors.green[400]!; // Verde
      textoAviso = "Garantia";
      corAviso = Colors.green[400]!;
    } else if (isAtrasado) {
      corFaixaLateral = corPrincipal; // Vermelho
      textoAviso = "Atrasado";
      corAviso = corPrincipal;
    } else if (dataEntregaStr == null) {
      corFaixaLateral = Colors.white;
      textoAviso = "Sem data";
      corAviso = Colors.white;
    } else {
      corFaixaLateral = corSecundaria; // Azul
      textoAviso = "Em prazo";
      corAviso = corSecundaria;
    }

    // 3. Renderização do Card
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DetalhesOrcamento(orcamentoInicial: orcamento),
            ),
          ).then((_) => _carregarOrcamentos(true));
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              stops: const [0.02, 0.02], // Cria o efeito de faixa lateral
              colors: [corFaixaLateral, corCard],
            ),
            border: Border.all(
              color: isConcluido
                  ? corAviso.withValues(alpha: 0.2)
                  : Colors.white10,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nome do Cliente
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 16,
                                color: corSecundaria,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  clienteNome,
                                  style: TextStyle(
                                    color: corTextoCinza,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          // Badge de Status (Texto + Ícone pequeno)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                Icon(
                                  isConcluido
                                      ? Icons.check_circle
                                      : Icons.info_outline,
                                  color: corAviso,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  textoAviso.toUpperCase(),
                                  style: TextStyle(
                                    color: corAviso,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Data de Criação
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        dataFormatada,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 8),
                // Título do Orçamento
                Text(
                  titulo,
                  style: TextStyle(
                    color: isConcluido ? Colors.white70 : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: isConcluido ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 12),
                // Valor e Seta
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      valorFormatado,
                      style: TextStyle(
                        color: isConcluido ? corAviso : corValor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
