import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../modelos/Cliente.dart';
import 'DetalhesCliente.dart';
import 'AdicionarCliente.dart';

/// Define os critérios de ordenação da lista de clientes.
enum TipoOrdenacao { alfabetica, ultimoServico, bairro }

// ==================================================
// TELA DE LISTAGEM DE CLIENTES
// ==================================================
class ListaClientes extends StatefulWidget {
  final bool isSelecao;

  const ListaClientes({super.key, this.isSelecao = false});

  @override
  State<ListaClientes> createState() => _ListaClientesState();
}

class _ListaClientesState extends State<ListaClientes> {
  // ==================================================
  // CONFIGURAÇÕES VISUAIS E ESTADO
  // ==================================================
  final Color corPrincipal = Colors.red[900]!;
  final Color corSecundaria = Colors.blueAccent;
  final Color corComplementar = Colors.green[600]!;
  final Color corAlerta = Colors.redAccent;
  final Color corFundo = const Color(0xFF121212);
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corTextoCinza = Colors.grey[400]!;

  final TextEditingController _searchController = TextEditingController();

  // MUDANÇA 1: Lista tipada com o Objeto
  List<Cliente> _listaClientes = [];

  // AUXILIAR: Guarda a data do último serviço vinculada ao ID do cliente
  // Isso permite ordenar sem sujar o Model Cliente com dados de relatório
  final Map<String, DateTime> _cacheUltimasDatas = {};

  String _termoBuscaNome = '';
  bool _estaCarregando = true;
  TipoOrdenacao _ordenacaoAtual = TipoOrdenacao.ultimoServico;

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

  Future<void> _carregarClientes([bool isRefresh = false]) async {
    if (!mounted) return;

    if (!isRefresh) setState(() => _estaCarregando = true);

    try {
      // Busca dados brutos (Maps)
      final response = await Supabase.instance.client
          .from('clientes')
          .select('*, orcamentos(data_pega)');

      final List<Map<String, dynamic>> dadosBrutos =
          List<Map<String, dynamic>>.from(response);

      // Limpa listas atuais
      final List<Cliente> novosClientes = [];
      _cacheUltimasDatas.clear();

      // Processa os dados: Converte Map -> Cliente e extrai a Data
      for (var json in dadosBrutos) {
        // 1. Cria o objeto
        final cliente = Cliente.fromMap(json);

        // 2. Calcula a data (Lógica extraída para manter o Model limpo)
        final dataUltimoServico = _calcularUltimaData(json['orcamentos']);

        // 3. Guarda no cache se o cliente tiver ID
        if (cliente.id != null) {
          _cacheUltimasDatas[cliente.id!] = dataUltimoServico;
        }

        novosClientes.add(cliente);
      }

      // Aplica ordenação na lista de Objetos
      _aplicarOrdenacao(novosClientes);

      if (mounted) {
        setState(() {
          _listaClientes = novosClientes;
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

  // Helper para extrair data do JSON bruto
  DateTime _calcularUltimaData(dynamic orcamentos) {
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

  void _aplicarOrdenacao(List<Cliente> lista) {
    if (_ordenacaoAtual == TipoOrdenacao.alfabetica) {
      lista.sort(
        (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
      );
    } else if (_ordenacaoAtual == TipoOrdenacao.bairro) {
      lista.sort(
        (a, b) => a.bairro.toLowerCase().compareTo(b.bairro.toLowerCase()),
      );
    } else {
      // Ordenação por data usando o Cache Auxiliar
      lista.sort((a, b) {
        final dataA = _cacheUltimasDatas[a.id] ?? DateTime(1900);
        final dataB = _cacheUltimasDatas[b.id] ?? DateTime(1900);
        return dataB.compareTo(dataA); // Mais recente primeiro
      });
    }
  }

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
      try {
        await Supabase.instance.client
            .from('clientes')
            .delete()
            .eq('id', cliente.id!); // MUDANÇA: Acesso seguro ao ID

        if (!mounted) return;
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
    // Filtragem agora usa as propriedades do objeto Cliente
    final listaFiltrada = _termoBuscaNome.isEmpty
        ? _listaClientes
        : _listaClientes
              .where(
                (cliente) =>
                    cliente.nome.toLowerCase().contains(_termoBuscaNome),
              )
              .toList();

    return Scaffold(
      backgroundColor: corFundo,
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
          : RefreshIndicator(
              color: corPrincipal,
              backgroundColor: corCard,
              onRefresh: () async => await _carregarClientes(true),
              child: listaFiltrada.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 90),
                      itemCount: listaFiltrada.length,
                      itemBuilder: (context, index) {
                        final cliente = listaFiltrada[index];
                        // Recupera a data do cache auxiliar
                        final ultimaData =
                            _cacheUltimasDatas[cliente.id] ?? DateTime(1900);

                        return _buildClienteCard(cliente, ultimaData);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 80, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text(
            "Nenhum cliente encontrado.",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
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
            builder: (context) => DetalhesCliente(cliente: cliente),
          ),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [corCard, const Color(0xFF252525)],
        ),
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
                              cliente.nome, // MUDANÇA: Acesso via propriedade
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
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
                                  color: corAlerta,
                                  size: 24,
                                ),
                              ),
                            ),
                          if (!widget.isSelecao)
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red[300]!.withValues(alpha: 0.7),
                                size: 24,
                              ),
                              onPressed: () => _confirmarExclusao(cliente),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.phone_iphone,
                        maskTelefone.maskText(
                          cliente.telefone,
                        ), // MUDANÇA: Propriedade
                      ),
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        Icons.location_on_outlined,
                        cliente.bairro.isEmpty
                            ? "Bairro não informado"
                            : cliente.bairro,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.history,
                            size: 18,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Último serviço: ",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            dataFormatada,
                            style: TextStyle(
                              color: temServico
                                  ? corSecundaria
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: corSecundaria,
                            side: BorderSide(
                              color: corSecundaria.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: Icon(
                            widget.isSelecao
                                ? Icons.check
                                : Icons.arrow_forward,
                            size: 18,
                          ),
                          label: Text(
                            widget.isSelecao ? "SELECIONAR" : "Detalhes",
                          ),
                          onPressed: handleCardTap,
                        ),
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
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 15, color: Colors.grey[300]),
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
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
