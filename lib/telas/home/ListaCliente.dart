import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../modelos/Cliente.dart';
import '../telasAdmin/adicionarOrcamento.dart';
import '../telasAdmin/DetalhesCliente.dart';
import '../telasAdmin/AdicionarCliente.dart';

/// Define os critérios de ordenação da lista de clientes
enum TipoOrdenacao { alfabetica, ultimoServico, bairro }

/// Tela responsável pela listagem e gerenciamento de clientes
class ListaClientes extends StatefulWidget {
  const ListaClientes({super.key});

  @override
  State<ListaClientes> createState() => _ListaClientesState();
}

class _ListaClientesState extends State<ListaClientes> {
  /// Definição da paleta de cores (Modo Escuro)
  final Color corPrincipal = Colors.red[900]!;
  final Color corSecundaria = Colors.blue[300]!;
  final Color corComplementar = Colors.green[400]!;
  final Color corAlerta = Colors.redAccent;
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);

  /// Controlador do campo de texto de busca
  final TextEditingController _searchController = TextEditingController();

  /// Termo atual utilizado para filtrar a lista
  String _termoBuscaNome = '';

  /// Lista local de clientes recuperados do banco
  List<Map<String, dynamic>> _listaClientes = [];

  /// Controla a exibição do indicador de carregamento
  bool _estaCarregando = true;

  /// Define a ordenação padrão inicial (Último Serviço)
  TipoOrdenacao _ordenacaoAtual = TipoOrdenacao.ultimoServico;

  /// Estilos de texto reutilizáveis
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

    // Inicia o carregamento dos dados ao montar a tela
    _carregarClientes();
  }

  /// Busca os clientes no Supabase e atualiza a lista
  Future<void> _carregarClientes([bool isRefresh = false]) async {
    if (!mounted) return;

    // Se não for um refresh manual, exibe o loading
    if (!isRefresh) setState(() => _estaCarregando = true);

    try {
      // Realiza a consulta no banco trazendo orçamentos para calcular a data
      final response = await Supabase.instance.client
          .from('clientes')
          .select('*, orcamentos(data_pega)');

      List<Map<String, dynamic>> dados = List<Map<String, dynamic>>.from(
        response,
      );

      // Ordena os dados conforme a configuração atual
      _aplicarOrdenacao(dados);

      if (mounted) {
        // ============================================================
        // Atualiza a lista na tela e remove o loading
        // ============================================================
        setState(() {
          _listaClientes = dados;
          _estaCarregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _estaCarregando = false);
        // Exibe feedback de erro ao usuário
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao carregar: $e")));
      }
    }
  }

  /// Aplica a lógica de ordenação na lista fornecida
  void _aplicarOrdenacao(List<Map<String, dynamic>> lista) {
    if (_ordenacaoAtual == TipoOrdenacao.alfabetica) {
      // Ordenação por Nome (A-Z)
      lista.sort((a, b) {
        final nomeA = (a['nome'] as String).toLowerCase();
        final nomeB = (b['nome'] as String).toLowerCase();
        return nomeA.compareTo(nomeB);
      });
    } else if (_ordenacaoAtual == TipoOrdenacao.bairro) {
      // Ordenação por Bairro (A-Z)
      lista.sort((a, b) {
        final bairroA = (a['bairro'] ?? '').toString().toLowerCase();
        final bairroB = (b['bairro'] ?? '').toString().toLowerCase();
        return bairroA.compareTo(bairroB);
      });
    } else {
      // Ordenação por Último Serviço (Mais recente primeiro)
      lista.sort((a, b) {
        final dataA = _obterUltimaData(a['orcamentos']);
        final dataB = _obterUltimaData(b['orcamentos']);
        return dataB.compareTo(dataA);
      });
    }
  }

  /// Auxiliar para extrair a data mais recente de uma lista de orçamentos
  DateTime _obterUltimaData(dynamic orcamentos) {
    if (orcamentos == null || (orcamentos as List).isEmpty) {
      return DateTime(1900);
    }
    DateTime maiorData = DateTime(1900);

    // Itera sobre os orçamentos para encontrar a maior data
    for (var orc in orcamentos) {
      if (orc['data_pega'] != null) {
        DateTime dataAtual = DateTime.parse(orc['data_pega']);
        if (dataAtual.isAfter(maiorData)) {
          maiorData = dataAtual;
        }
      }
    }
    return maiorData;
  }

  /// Altera o critério de ordenação e reordena a lista atual
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

  /// Exibe um diálogo de confirmação antes de excluir um cliente
  Future<void> _confirmarExclusao(Cliente cliente) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            "Excluir Cliente",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "Tem certeza que deseja excluir ${cliente.nome} permanentemente?",
            style: const TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text(
                "EXCLUIR",
                style: TextStyle(color: Colors.redAccent),
              ),
              onPressed: () async {
                Navigator.pop(context); // Fecha o diálogo
                try {
                  // Deleta o registro no banco
                  await Supabase.instance.client
                      .from('clientes')
                      .delete()
                      .eq('id', cliente.id as Object);

                  // Recarrega a lista se a tela ainda estiver montada
                  if (mounted) _carregarClientes();
                } catch (e) {
                  // Pode adicionar tratamento de erro aqui
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Atualiza o termo de busca conforme o usuário digita
  void _onSearchChanged(String value) {
    setState(() {
      _termoBuscaNome = value.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filtra a lista localmente com base na busca
    final listaFiltrada = _termoBuscaNome.isEmpty
        ? _listaClientes
        : _listaClientes.where((c) {
            final nome = c['nome'].toString().toLowerCase();
            return nome.contains(_termoBuscaNome);
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
            keyboardType: TextInputType.name,
            decoration: InputDecoration(
              hintText: "Busca por nome...",
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: corPrincipal),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        // Limpa a busca e restaura a lista
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
            ),
          ),
        ),
        actions: [
          /// Menu de ordenação
          PopupMenuButton<TipoOrdenacao>(
            icon: const Icon(Icons.sort, color: Colors.white, size: 28),
            tooltip: 'Ordenar',
            color: Colors.grey[900],
            onSelected: _mudarOrdenacao,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: TipoOrdenacao.alfabetica,
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, color: Colors.white),
                    SizedBox(width: 10),
                    Text("Nome (A-Z)", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TipoOrdenacao.bairro,
                child: Row(
                  children: [
                    Icon(Icons.location_city, color: Colors.white),
                    SizedBox(width: 10),
                    Text("Bairro (A-Z)", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TipoOrdenacao.ultimoServico,
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      "Último Serviço",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        onPressed: () {
          // Navega para tela de adicionar cliente e recarrega ao voltar
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdicionarCliente()),
          ).then((_) => _carregarClientes());
        },
        child: const Icon(Icons.person_add, size: 28),
      ),
      body: _estaCarregando
          ? Center(child: CircularProgressIndicator(color: corPrincipal))
          : RefreshIndicator(
              color: corPrincipal,
              backgroundColor: Colors.white,
              onRefresh: () async => await _carregarClientes(true),
              child: listaFiltrada.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: Center(
                            child: Text(
                              "Nenhum cliente encontrado.",
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
                        // ====================================================
                        // Construção do Card do Cliente
                        // ====================================================
                        final dados = listaFiltrada[index];
                        final cliente = Cliente.fromMap(dados);
                        final ultimaData = _obterUltimaData(
                          dados['orcamentos'],
                        );
                        final temServico = ultimaData.year > 1900;
                        final dataFormatada = temServico
                            ? DateFormat('dd/MM/yyyy').format(ultimaData)
                            : "--/--/----";

                        final Color corStatus = cliente.clienteProblematico
                            ? corAlerta
                            : corComplementar;

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.transparent,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                stops: const [0.02, 0.02],
                                colors: [corStatus, corCard],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                12,
                                12,
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8.0,
                                          ),
                                          child: Icon(
                                            Icons.warning_amber_rounded,
                                            color: corAlerta,
                                            size: 26,
                                          ),
                                        ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: Colors.red[300],
                                          size: 26,
                                        ),
                                        onPressed: () =>
                                            _confirmarExclusao(cliente),
                                      ),
                                    ],
                                  ),
                                  Divider(color: Colors.grey[800], height: 10),
                                  const SizedBox(height: 8),

                                  /// Exibição do Telefone
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone_in_talk,
                                        size: 20,
                                        color: corSecundaria,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        cliente.telefone,
                                        style: _estiloDados,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  /// Exibição do Bairro
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_city,
                                        size: 20,
                                        color: corSecundaria,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          cliente.bairro.isEmpty
                                              ? "Bairro não informado"
                                              : cliente.bairro,
                                          style: _estiloDados,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  /// Exibição do Último Serviço
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.history,
                                        size: 20,
                                        color: corSecundaria,
                                      ),
                                      const SizedBox(width: 8),
                                      Text("Último: ", style: _estiloDados),
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
                                  const SizedBox(height: 12),

                                  /// Botões de Ação (Orçamento e Detalhes)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: corSecundaria,
                                          side: BorderSide(
                                            color: corSecundaria,
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.post_add,
                                          size: 20,
                                        ),
                                        label: const Text("ORÇAMENTO"),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AdicionarOrcamento(
                                                    cliente: cliente,
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: corPrincipal,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  DetalhesCliente(
                                                    cliente: cliente,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          "DETALHES",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
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
}
