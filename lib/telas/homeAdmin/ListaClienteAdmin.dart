import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../modelos/Cliente.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../TelasAdmin/DetalhesCliente.dart';
import '../TelasAdmin/AdicionarCliente.dart';

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

  // Paleta de cores da interface
  final Color corPrincipal = Colors.red[900]!;
  final Color corSecundaria = Colors.blue[300]!;
  final Color corComplementar = Colors.green[400]!;
  final Color corAlerta = Colors.redAccent;
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);

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

  // Estilos de texto inicializados no initState
  late final TextStyle _estiloNome;
  late final TextStyle _estiloDados;

  @override
  void initState() {
    super.initState();
    _estiloNome = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: corSecundaria,
    );
    _estiloDados = TextStyle(fontSize: 16, color: Colors.grey[400]);
    _carregarClientes();
  }

  // ==================================================
  // LÓGICA DE DADOS (SUPABASE)
  // ==================================================

  /// Busca os clientes e seus orçamentos vinculados no banco de dados.
  Future<void> _carregarClientes([bool isRefresh = false]) async {
    if (!mounted) return;

    // Apenas mostra loading se não for um 'pull-to-refresh'
    if (!isRefresh) setState(() => _estaCarregando = true);

    try {
      // Faz o join com a tabela de orçamentos para obter as datas
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
      // Ordenação A-Z pelo nome
      lista.sort(
        (a, b) => (a['nome'] as String).toLowerCase().compareTo(
          (b['nome'] as String).toLowerCase(),
        ),
      );
    } else if (_ordenacaoAtual == TipoOrdenacao.bairro) {
      // Ordenação A-Z pelo bairro
      lista.sort(
        (a, b) => (a['bairro'] ?? '').toString().toLowerCase().compareTo(
          (b['bairro'] ?? '').toString().toLowerCase(),
        ),
      );
    } else {
      // Ordenação pela data do serviço mais recente (Decrescente)
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
      return DateTime(1900); // Data padrão para clientes sem serviço
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

  // ==================================================
  // CONSTRUÇÃO DA INTERFACE (UI)
  // ==================================================

  @override
  Widget build(BuildContext context) {
    // Aplica o filtro de busca sobre a lista carregada
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
      // Cabeçalho com campo de busca e menu de ordenação
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
              hintText: "Busca por nome...",
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
          PopupMenuButton<TipoOrdenacao>(
            icon: const Icon(Icons.sort, color: Colors.white, size: 28),
            color: Colors.grey[900],
            onSelected: _mudarOrdenacao,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: TipoOrdenacao.alfabetica,
                child: Text(
                  "Nome (A-Z)",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const PopupMenuItem(
                value: TipoOrdenacao.bairro,
                child: Text(
                  "Bairro (A-Z)",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const PopupMenuItem(
                value: TipoOrdenacao.ultimoServico,
                child: Text(
                  "Último Serviço",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      // Botão flutuante para adicionar novo cliente
      floatingActionButton: FloatingActionButton(
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdicionarCliente()),
        ).then((_) => _carregarClientes()),
        child: const Icon(Icons.person_add, size: 28),
      ),
      body: _estaCarregando
          ? Center(child: CircularProgressIndicator(color: corPrincipal))
          : RefreshIndicator(
              onRefresh: () async => await _carregarClientes(true),
              child: listaFiltrada.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              "Nenhum cliente encontrado.",
                              style: TextStyle(color: Colors.grey[500]),
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
                        // Segurança contra acesso a índice inválido
                        if (index >= listaFiltrada.length) {
                          return const SizedBox.shrink();
                        }

                        final dados = listaFiltrada[index];
                        final cliente = Cliente.fromMap(dados);

                        // Processamento da data do último serviço para exibição
                        final ultimaData = _obterUltimaData(
                          dados['orcamentos'],
                        );
                        final temServico = ultimaData.year > 1900;
                        final dataFormatada = temServico
                            ? DateFormat('dd/MM/yyyy').format(ultimaData)
                            : "--/--/----";

                        // Definição visual baseada em status problemático
                        final Color corStatus = cliente.clienteProblematico
                            ? corAlerta
                            : corComplementar;

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: corCard,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DetalhesCliente(cliente: cliente),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: corStatus, width: 6),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                cliente.nome,
                                                style: _estiloNome,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (cliente.clienteProblematico)
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                color: corAlerta,
                                                size: 26,
                                              ),
                                            // Botão de Exclusão
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete_outline,
                                                color: Colors.red[300],
                                                size: 26,
                                              ),
                                              onPressed: () async {
                                                // 1. Captura o Messenger antes do 'await' (segurança de contexto)
                                                final scaffoldMessenger =
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    );

                                                // 2. Fecha a tela ou diálogo atual imediatamente
                                                Navigator.pop(context);

                                                try {
                                                  // 3. Executa a exclusão no banco
                                                  await Supabase.instance.client
                                                      .from('clientes')
                                                      .delete()
                                                      .eq(
                                                        'id',
                                                        cliente.id as Object,
                                                      );

                                                  // 4. Se o widget ainda existir, atualiza a lista
                                                  if (!mounted) return;
                                                  _carregarClientes();

                                                  scaffoldMessenger.showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        "Cliente excluído com sucesso!",
                                                      ),
                                                      backgroundColor:
                                                          Colors.green,
                                                    ),
                                                  );
                                                } catch (e) {
                                                  // Tratamento de erro com a referência segura do Messenger
                                                  if (!mounted) return;
                                                  scaffoldMessenger.showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        "Erro ao excluir cliente: $e",
                                                      ),
                                                      backgroundColor:
                                                          Colors.redAccent,
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                        Divider(
                                          color: Colors.grey[800],
                                          height: 10,
                                        ),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          Icons.phone_in_talk,
                                          maskTelefone.maskText(
                                            cliente.telefone,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          Icons.location_city,
                                          cliente.bairro.isEmpty
                                              ? "Bairro não informado"
                                              : cliente.bairro,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.history,
                                              size: 20,
                                              color: corSecundaria,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Último: ",
                                              style: _estiloDados,
                                            ),
                                            Text(
                                              dataFormatada,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: temServico
                                                    ? Colors.white
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Seta indicativa à direita
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey,
                                    size: 28,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  /// Helper widget para criar linhas de informação com ícone e texto.
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: corSecundaria),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: _estiloDados,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
