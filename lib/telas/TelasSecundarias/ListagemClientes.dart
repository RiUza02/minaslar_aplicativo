import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../modelos/Cliente.dart';
import '../../servicos/servicos.dart';
import 'DetalhesCliente.dart';
import 'AdicionarCliente.dart';

/// Define os critérios de ordenação da lista de clientes.
enum TipoOrdenacao { alfabetica, ultimoServico, bairro }

// ==================================================
// TELA DE LISTAGEM DE CLIENTES
// ==================================================
class ListagemClientes extends StatefulWidget {
  final bool isSelecao;
  final bool isAdmin;

  const ListagemClientes({
    super.key,
    this.isSelecao = false,
    this.isAdmin = false,
  });

  @override
  State<ListagemClientes> createState() => _ListagemClientesState();
}

class _ListagemClientesState extends State<ListagemClientes> {
  // ==================================================
  // CONFIGURAÇÕES VISUAIS E ESTADO
  // ==================================================
  late Color corPrincipal;
  final Color corSecundaria = Colors.blueAccent;
  final Color corComplementar = Colors.green[600]!;
  final Color corAlerta = Colors.redAccent;
  final Color corFundo = const Color(0xFF121212);
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corTextoCinza = Colors.grey[400]!;

  final TextEditingController _searchController = TextEditingController();

  // Armazena os clientes para exibição. A lista agora é sempre obtida do servidor.
  List<Map<String, dynamic>> _listaExibida = [];
  bool _estaCarregando = true;
  bool _semInternet = false;
  TipoOrdenacao _ordenacaoAtual = TipoOrdenacao.ultimoServico;

  // Debouncer para evitar buscas excessivas no banco ao digitar
  Timer? _debounce;

  final maskTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    corPrincipal = widget.isAdmin ? Colors.red[900]! : Colors.blue[900]!;
    _carregarClientes();
  }

  // ==================================================
  // LÓGICA DE DADOS (SUPABASE)
  // ==================================================

  /// **MELHORIA DE PERFORMANCE:** Busca os clientes no Supabase, aplicando
  /// filtros de busca e ordenação diretamente na query do banco de dados.
  Future<void> _carregarClientes() async {
    if (!mounted) return;

    setState(() {
      _estaCarregando = true;
      _semInternet = false;
    });

    if (!await Servicos.temConexao()) {
      if (mounted) {
        setState(() {
          _estaCarregando = false;
          _semInternet = true;
        });
      }
      return;
    }

    try {
      final termoBusca = _searchController.text.trim();

      dynamic query = Supabase.instance.client
          .from('clientes')
          .select('*, orcamentos(data_pega)');
      // 1. Aplica filtro de busca no servidor
      if (termoBusca.isNotEmpty) {
        final termoFormatado = '%$termoBusca%';
        query = query.or(
          'nome.ilike.$termoFormatado,bairro.ilike.$termoFormatado,telefone.ilike.$termoFormatado',
        );
      }

      // 2. Aplica ordenação no servidor
      switch (_ordenacaoAtual) {
        case TipoOrdenacao.alfabetica:
          query = query.order('nome', ascending: true);
          break;
        case TipoOrdenacao.bairro:
          query = query
              .order('bairro', ascending: true)
              .order('nome', ascending: true);
          break;
        case TipoOrdenacao.ultimoServico:
          break;
      }

      final dados = List<Map<String, dynamic>>.from(await query);

      if (mounted) {
        setState(() {
          _listaExibida = dados;
          _ordenarListaLocalmente(); // Aplica ordenações que ficaram no cliente
          _estaCarregando = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar clientes: $e');
      if (mounted) {
        setState(() => _estaCarregando = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao carregar: $e")));
      }
    }
  }

  /// Aplica ordenações que não foram feitas no servidor (ex: por data aninhada).
  void _ordenarListaLocalmente() {
    if (_ordenacaoAtual == TipoOrdenacao.ultimoServico) {
      _listaExibida.sort(
        (a, b) => _obterUltimaData(
          b['orcamentos'],
        ).compareTo(_obterUltimaData(a['orcamentos'])),
      );
    }
  }

  /// Percorre a lista de orçamentos aninhada para encontrar a data mais recente.
  DateTime _obterUltimaData(dynamic orcamentos) {
    if (orcamentos == null || (orcamentos as List).isEmpty) {
      return DateTime(1900);
    }
    DateTime maiorData = DateTime(1900);
    for (var orc in orcamentos) {
      if (orc['data_pega'] != null) {
        DateTime dataAtual = DateTime.parse(orc['data_pega']);
        if (dataAtual.isAfter(maiorData)) maiorData = dataAtual;
      }
    }
    return maiorData;
  }

  void _mudarOrdenacao(TipoOrdenacao novaOrdem) {
    if (_ordenacaoAtual != novaOrdem) {
      setState(() {
        _ordenacaoAtual = novaOrdem;
        _carregarClientes(); // Recarrega do servidor com a nova ordenação
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _carregarClientes);
  }

  Future<void> _confirmarExclusao(Cliente cliente) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text(
            'Confirmar Exclusão',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Tem certeza que deseja excluir o cliente "${cliente.nome}"?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'EXCLUIR',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true && cliente.id != null) {
      if (!mounted) return;
      try {
        await Supabase.instance.client
            .from('clientes')
            .delete()
            .eq('id', cliente.id as Object);
        _carregarClientes();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao excluir: $e")));
      }
    }
  }

  // ==================================================
  // UI
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        backgroundColor: corPrincipal,
        elevation: 0,
        toolbarHeight: 80,
        title: widget.isSelecao
            ? const Text("Selecione um Cliente")
            : const Text("Clientes"),
        centerTitle: true,
        bottom: _buildSearchBar(),
        actions: [
          PopupMenuButton<TipoOrdenacao>(
            icon: const Icon(Icons.sort, color: Colors.white, size: 28),
            color: corCard,
            onSelected: _mudarOrdenacao,
            itemBuilder: (context) => [
              _buildPopupItem(TipoOrdenacao.alfabetica, "Nome (A-Z)"),
              _buildPopupItem(TipoOrdenacao.bairro, "Bairro (A-Z)"),
              _buildPopupItem(TipoOrdenacao.ultimoServico, "Último Serviço"),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        elevation: 6,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdicionarCliente()),
        ).then((_) => _carregarClientes()),
        child: const Icon(Icons.person_add, size: 28),
      ),
      body: _estaCarregando
          ? Center(child: CircularProgressIndicator(color: corPrincipal))
          : _semInternet
          ? _semInternetWidget()
          : RefreshIndicator(
              color: corPrincipal,
              backgroundColor: corCard,
              onRefresh: _carregarClientes,
              child: _listaExibida.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _listaExibida.length,
                      itemBuilder: (context, index) {
                        final dados = _listaExibida[index];
                        final cliente = Cliente.fromMap(dados);
                        final ultimaData = _obterUltimaData(
                          dados['orcamentos'],
                        );

                        return _buildClienteCard(cliente, ultimaData);
                      },
                    ),
            ),
    );
  }

  PreferredSizeWidget _buildSearchBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: "Nome, Bairro ou Telefone...",
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
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
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String msg = _searchController.text.isNotEmpty
        ? "Nenhum resultado para \"${_searchController.text}\""
        : "Nenhum cliente cadastrado.";
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
                  Icons.person_off_outlined,
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
    return Center(
      child: Text("Sem internet", style: TextStyle(color: corTextoCinza)),
    );
  }

  Widget _buildClienteCard(Cliente cliente, DateTime ultimaData) {
    final temServico = ultimaData.year > 1900;
    final dataFormatada = temServico
        ? DateFormat('dd/MM/yyyy').format(ultimaData)
        : "Sem serviços";

    final Color corStatus = cliente.clienteProblematico
        ? corAlerta
        : corComplementar;

    void handleCardTap() {
      if (widget.isSelecao) {
        Navigator.pop(context, cliente);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DetalhesCliente(cliente: cliente, isAdmin: widget.isAdmin),
          ),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: handleCardTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: corStatus),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cliente.nome,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (cliente.clienteProblematico)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Tooltip(
                                message: "Cliente Problemático",
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orangeAccent,
                                  size: 24,
                                ),
                              ),
                            ),
                          if (!widget.isSelecao && widget.isAdmin)
                            IconButton(
                              icon: Icon(
                                Icons.delete_forever_outlined,
                                color: Colors.red[300],
                                size: 24,
                              ),
                              onPressed: () => _confirmarExclusao(cliente),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.phone_android_outlined,
                        maskTelefone.maskText(
                          cliente.telefone, // MUDANÇA: Propriedade
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        Icons.location_on_outlined,
                        cliente.bairro.isEmpty
                            ? "Bairro não informado"
                            : cliente.bairro,
                      ), // MUDANÇA: Propriedade
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.history,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "ÚLTIMO SERVIÇO:",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            dataFormatada,
                            style: TextStyle(
                              color: temServico
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey[300]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  PopupMenuItem<TipoOrdenacao> _buildPopupItem(
    TipoOrdenacao value,
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
            color: _ordenacaoAtual == value ? corPrincipal : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
