import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../modelos/Cliente.dart';
import '../TelasSecundarias/DetalhesCliente.dart';
import '../TelasSecundarias/AdicionarCliente.dart';
import '../../servicos/servicos.dart';

/// Define os critérios de ordenação da lista de clientes.
enum TipoOrdenacao { alfabetica, ultimoServico, bairro }

// ==================================================
// TELA DE LISTAGEM DE CLIENTES
// ==================================================
class ListaClientes extends StatefulWidget {
  final bool isAdmin;

  const ListaClientes({super.key, this.isAdmin = false});

  @override
  State<ListaClientes> createState() => _ListaClientesState();
}

class _ListaClientesState extends State<ListaClientes>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ==================================================
  // CONFIGURAÇÕES VISUAIS E ESTADO
  // ==================================================

  // Paleta de cores da interface (Admin - Vermelho)
  late Color corPrincipal;
  late Color corSecundaria;
  final Color corComplementar = Colors.green[400]!;
  final Color corAlerta = Colors.redAccent;
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corTextoCinza = Colors.grey[500]!;

  // Controladores e variáveis de estado
  final TextEditingController _searchController = TextEditingController();

  // CACHE: Armazena todos os clientes vindos do banco
  List<Map<String, dynamic>> _listaCompleta = [];
  // TELA: Armazena os clientes filtrados e ordenados para exibição
  List<Map<String, dynamic>> _listaExibida = [];

  bool _estaCarregando = true;
  bool _semInternet = false;
  TipoOrdenacao _ordenacaoAtual = TipoOrdenacao.ultimoServico;

  // Formatador para exibir o telefone
  final maskTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    // Define as cores com base no perfil
    corPrincipal = widget.isAdmin ? Colors.red[900]! : Colors.blue[900]!;
    corSecundaria = widget.isAdmin ? Colors.blue[300]! : Colors.cyan[400]!;
    // Carrega tudo ao iniciar
    _carregarClientes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==================================================
  // LÓGICA DE DADOS (SUPABASE)
  // ==================================================

  /// Busca TODOS os clientes do banco de dados (sem filtro na query)
  Future<void> _carregarClientes() async {
    if (mounted) {
      setState(() {
        _estaCarregando = true;
        _semInternet = false;
      });
    }

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
      // Busca simples: Traz tudo.
      // O filtro será feito na memória do celular.
      final response = await Supabase.instance.client
          .from('clientes')
          .select('*, orcamentos(data_pega)')
          .order('nome', ascending: true); // Ordenação padrão do banco

      final dados = List<Map<String, dynamic>>.from(response);

      if (mounted) {
        setState(() {
          // Guarda os dados brutos na lista completa
          _listaCompleta = dados;

          // Aplica o filtro (caso já tenha algo digitado) e ordena
          _aplicarFiltrosLocais();

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

  /// Filtra a lista completa baseado no texto digitado e aplica ordenação
  void _aplicarFiltrosLocais() {
    final termo = _searchController.text.trim().toLowerCase();

    // Começa com uma cópia da lista completa
    List<Map<String, dynamic>> temp = List.from(_listaCompleta);

    // 1. FILTRAGEM
    if (termo.isNotEmpty) {
      temp = temp.where((cliente) {
        final nome = (cliente['nome'] ?? '').toString().toLowerCase();
        final bairro = (cliente['bairro'] ?? '').toString().toLowerCase();
        final telefone = (cliente['telefone'] ?? '').toString().toLowerCase();

        // Verifica se o termo existe em qualquer um dos campos
        return nome.contains(termo) ||
            bairro.contains(termo) ||
            telefone.contains(termo);
      }).toList();
    }

    // 2. ORDENAÇÃO
    _ordenarLista(temp);

    // Atualiza a tela
    setState(() {
      _listaExibida = temp;
    });
  }

  /// Lógica de ordenação (extraída para ficar mais organizado)
  void _ordenarLista(List<Map<String, dynamic>> lista) {
    if (_ordenacaoAtual == TipoOrdenacao.alfabetica) {
      lista.sort(
        (a, b) => (a['nome'] as String).toLowerCase().compareTo(
          (b['nome'] as String).toLowerCase(),
        ),
      );
    } else if (_ordenacaoAtual == TipoOrdenacao.bairro) {
      lista.sort(
        (a, b) => (a['bairro'] ?? '').toString().toLowerCase().compareTo(
          (b['bairro'] ?? '').toString().toLowerCase(),
        ),
      );
    } else {
      // Último Serviço (Mais complexo)
      lista.sort(
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

  // ==================================================
  // AÇÕES DO USUÁRIO
  // ==================================================

  void _mudarOrdenacao(TipoOrdenacao novaOrdem) {
    if (_ordenacaoAtual != novaOrdem) {
      _ordenacaoAtual = novaOrdem;
      _aplicarFiltrosLocais(); // Reordena a lista atual
    }
  }

  // Busca Instantânea (sem Timer/Debounce)
  void _onSearchChanged(String value) {
    _aplicarFiltrosLocais();
  }

  /// Exibe um diálogo de confirmação antes de excluir um cliente.
  Future<void> _confirmarExclusao(Cliente cliente) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: corCard,
          title: const Text(
            'Confirmar Exclusão',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Tem certeza que deseja excluir o cliente "${cliente.nome}"? Esta ação não pode ser desfeita.',
            style: TextStyle(color: Colors.grey[300]),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Excluir', style: TextStyle(color: corAlerta)),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      try {
        await Supabase.instance.client
            .from('clientes')
            .delete()
            .eq('id', cliente.id as Object);

        if (!context.mounted) return;
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        _carregarClientes(); // Recarrega do banco para garantir sincronia

        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text("Cliente excluído com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("Erro ao excluir cliente: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ==================================================
  // CONSTRUÇÃO DA INTERFACE (UI)
  // ==================================================

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Usamos _listaExibida (filtrada localmente)
    return Scaffold(
      backgroundColor: corFundo,

      // --- APP BAR CUSTOMIZADA ---
      appBar: AppBar(
        backgroundColor: corPrincipal,
        elevation: 0,
        toolbarHeight: 80,
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged, // Busca instantânea
            style: const TextStyle(color: Colors.white, fontSize: 16),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: "Nome, Bairro ou Telefone...",
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

      // --- BOTÃO FLUTUANTE ---
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              backgroundColor: corPrincipal,
              foregroundColor: Colors.white,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdicionarCliente(),
                ),
              ).then((_) => _carregarClientes()),
              child: const Icon(Icons.person_add, size: 28),
            )
          : null,

      // --- LISTA DE CLIENTES ---
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

  // ==================================================
  // WIDGETS AUXILIARES
  // ==================================================

  Widget _buildEmptyState() {
    String msg = _searchController.text.isNotEmpty
        ? "Nenhum resultado para \"${_searchController.text}\""
        : "Nenhum cliente cadastrado.";
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
    return RefreshIndicator(
      onRefresh: _carregarClientes,
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

  /// Constrói o cartão do cliente com o visual novo (Container com borda lateral)
  Widget _buildClienteCard(Cliente cliente, DateTime ultimaData) {
    final temServico = ultimaData.year > 1900;
    final dataFormatada = temServico
        ? DateFormat('dd/MM/yyyy').format(ultimaData)
        : "--/--/----";

    // Define cor baseada no status
    final Color corStatus = cliente.clienteProblematico
        ? corAlerta
        : corComplementar;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(12),
        // Sombra suave
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Clip AntiAlias para a borda lateral respeitar o arredondamento
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DetalhesCliente(cliente: cliente, isAdmin: widget.isAdmin),
            ),
          );
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Barra Lateral de Status
              Container(width: 6, color: corStatus),

              // 2. Conteúdo do Card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- CABEÇALHO DO ITEM ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cliente.nome,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (cliente.clienteProblematico)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: corAlerta.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: corAlerta.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        "PROBLEMÁTICO",
                                        style: TextStyle(
                                          color: corAlerta,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (widget.isAdmin)
                            // Botão de Excluir Discreto
                            InkWell(
                              onTap: () => _confirmarExclusao(cliente),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: Colors.grey[700],
                                  size: 22,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 12),

                      // --- INFORMAÇÕES SECUNDÁRIAS ---
                      _buildInfoRow(
                        Icons.phone_in_talk,
                        maskTelefone.maskText(cliente.telefone),
                        isSecundario: true,
                      ),
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        Icons.location_city,
                        cliente.bairro.isEmpty
                            ? "Bairro não informado"
                            : cliente.bairro,
                        isSecundario: true,
                      ),

                      const SizedBox(height: 16),

                      // --- DATA DO ÚLTIMO SERVIÇO (Destaque) ---
                      Row(
                        children: [
                          Icon(Icons.history, color: corSecundaria, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "ÚLTIMO SERVIÇO",
                            style: TextStyle(
                              color: corTextoCinza,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            dataFormatada,
                            style: TextStyle(
                              color: temServico
                                  ? Colors.white
                                  : Colors.grey[700],
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

  Widget _buildInfoRow(
    IconData icon,
    String text, {
    bool isSecundario = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isSecundario ? Colors.grey[600] : corSecundaria,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isSecundario ? Colors.grey[400] : Colors.white,
            ),
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
            color: _ordenacaoAtual == value ? corSecundaria : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
