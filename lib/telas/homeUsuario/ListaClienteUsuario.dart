import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../modelos/Cliente.dart';
import '../TelasUsuario/DetalhesCliente.dart';
// Importação de AdicionarCliente removida

/// Define os critérios de ordenação da lista de clientes.
enum TipoOrdenacao { alfabetica, ultimoServico, bairro }

// ==================================================
// TELA DE LISTAGEM DE CLIENTES
// ==================================================
class ListaClientes extends StatefulWidget {
  const ListaClientes({super.key});

  @override
  State<ListaClientes> createState() => _ListaClientesState();
}

class _ListaClientesState extends State<ListaClientes> {
  // ==================================================
  // CONFIGURAÇÕES VISUAIS E ESTADO
  // ==================================================

  // TEMA ALTERADO PARA AZUL
  final Color corPrincipal = Colors.blue[900]!;
  final Color corSecundaria = Colors.blue[300]!;
  final Color corComplementar = Colors.green[400]!;
  final Color corAlerta = Colors.redAccent;
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corTextoCinza = Colors.grey[500]!;

  // Controladores e variáveis de estado
  final TextEditingController _searchController = TextEditingController();
  String _termoBuscaNome = '';
  List<Map<String, dynamic>> _listaClientes = [];
  bool _estaCarregando = true;
  TipoOrdenacao _ordenacaoAtual = TipoOrdenacao.ultimoServico;

  // Formatador para exibir o telefone
  final maskTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _carregarClientes();
  }

  // ==================================================
  // LÓGICA DE DADOS (SUPABASE)
  // ==================================================

  /// Busca os clientes e seus orçamentos vinculados no banco de dados.
  Future<void> _carregarClientes([bool isRefresh = false]) async {
    if (!mounted) return;

    if (!isRefresh) setState(() => _estaCarregando = true);

    try {
      final response = await Supabase.instance.client
          .from('clientes')
          .select('*, orcamentos(data_pega)');

      List<Map<String, dynamic>> dados = List<Map<String, dynamic>>.from(
        response,
      );

      _aplicarOrdenacao(dados);

      if (mounted) {
        setState(() {
          _listaClientes = dados;
          _estaCarregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _estaCarregando = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao carregar: $e")));
      }
    }
  }

  /// Ordena a lista localmente baseada no critério selecionado.
  void _aplicarOrdenacao(List<Map<String, dynamic>> lista) {
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

  /// Atualiza o estado de ordenação e reorganiza a lista.
  void _mudarOrdenacao(TipoOrdenacao novaOrdem) {
    if (_ordenacaoAtual != novaOrdem) {
      setState(() {
        _ordenacaoAtual = novaOrdem;
        _aplicarOrdenacao(_listaClientes);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _termoBuscaNome = value.toLowerCase());
  }

  // Função _confirmarExclusao removida daqui

  // ==================================================
  // CONSTRUÇÃO DA INTERFACE (UI)
  // ==================================================

  @override
  Widget build(BuildContext context) {
    final listaFiltrada = _termoBuscaNome.isEmpty
        ? _listaClientes
        : _listaClientes
              .where(
                (c) => c['nome'].toString().toLowerCase().contains(
                  _termoBuscaNome,
                ),
              )
              .toList();

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
            color: Colors.black.withValues(
              alpha: 0.3,
            ), // Fundo escuro translúcido
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: "Busca por nome...",
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

      // --- BOTÃO FLUTUANTE REMOVIDO ---

      // --- LISTA DE CLIENTES ---
      body: _estaCarregando
          ? Center(child: CircularProgressIndicator(color: corPrincipal))
          : RefreshIndicator(
              color: corPrincipal,
              backgroundColor: corCard,
              onRefresh: () async => await _carregarClientes(true),
              child: listaFiltrada.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: listaFiltrada.length,
                      itemBuilder: (context, index) {
                        if (index >= listaFiltrada.length) {
                          return const SizedBox.shrink();
                        }

                        final dados = listaFiltrada[index];
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 60, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text(
            "Nenhum cliente encontrado.",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// Constrói o cartão do cliente
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
              builder: (context) => DetalhesCliente(cliente: cliente),
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
                          // Botão de Excluir removido daqui
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
