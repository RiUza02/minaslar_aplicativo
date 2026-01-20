import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../modelos/Cliente.dart';
import '../cliente/AdicionarCliente.dart';
import '../cliente/adicionarOrcamento.dart';
import '../cliente/DetalhesCliente.dart';

enum TipoOrdenacao { alfabetica, ultimoServico }

class ListaClientes extends StatefulWidget {
  const ListaClientes({super.key});

  @override
  State<ListaClientes> createState() => _ListaClientesState();
}

class _ListaClientesState extends State<ListaClientes> {
  // --- PALETA DE CORES (MODO ESCURO) ---
  final Color corPrincipal = Colors.red[900]!;
  final Color corSecundaria = Colors.blue[300]!;
  final Color corComplementar = Colors.green[400]!;
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);

  final TextEditingController _searchController = TextEditingController();
  String _termoBuscaNome = '';

  List<Map<String, dynamic>> _listaClientes = [];
  bool _estaCarregando = true;

  // Padrão: Último Serviço (o que você pediu)
  TipoOrdenacao _ordenacaoAtual = TipoOrdenacao.ultimoServico;

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

  // --- NOVA LÓGICA DE CARREGAMENTO E ORDENAÇÃO ---
  Future<void> _carregarClientes([bool isRefresh = false]) async {
    if (!mounted) return;
    if (!isRefresh) setState(() => _estaCarregando = true);

    try {
      // 1. Buscamos o cliente E os orçamentos (apenas a data) aninhados
      final response = await Supabase.instance.client
          .from('clientes')
          .select('*, orcamentos(data_pega)');
      // O Supabase entende a relação e traz uma lista de orçamentos dentro de cada cliente

      List<Map<String, dynamic>> dados = List<Map<String, dynamic>>.from(
        response,
      );

      // 2. Aplicamos a ordenação no Dart (Localmente)
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

  // Função auxiliar para ordenar a lista em memória
  void _aplicarOrdenacao(List<Map<String, dynamic>> lista) {
    if (_ordenacaoAtual == TipoOrdenacao.alfabetica) {
      // Ordena por Nome A-Z
      lista.sort((a, b) {
        final nomeA = (a['nome'] as String).toLowerCase();
        final nomeB = (b['nome'] as String).toLowerCase();
        return nomeA.compareTo(nomeB);
      });
    } else {
      // Ordena por Data do Último Serviço (Do mais recente para o mais antigo)
      lista.sort((a, b) {
        final dataA = _obterUltimaData(a['orcamentos']);
        final dataB = _obterUltimaData(b['orcamentos']);
        // compareTo invertido (b compareTo a) para ficar decrescente (mais recente primeiro)
        return dataB.compareTo(dataA);
      });
    }
  }

  // Descobre a data mais recente dentro da lista de orçamentos do cliente
  DateTime _obterUltimaData(dynamic orcamentos) {
    if (orcamentos == null || (orcamentos as List).isEmpty) {
      // Se não tem serviço, retorna uma data muito antiga (ano 1900) para ficar no final da lista
      return DateTime(1900);
    }

    // Varre a lista de orçamentos e pega a maior data
    DateTime maiorData = DateTime(1900);
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

  // Função chamada ao clicar no menu de ordenar
  void _mudarOrdenacao(TipoOrdenacao novaOrdem) {
    if (_ordenacaoAtual != novaOrdem) {
      setState(() {
        _ordenacaoAtual = novaOrdem;
        // Não precisa ir no banco de novo, só reordena a lista que já temos!
        _aplicarOrdenacao(_listaClientes);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ... (Função _confirmarExclusao permanece igual) ...
  Future<void> _confirmarExclusao(Cliente cliente) async {
    // (Mantenha seu código de exclusão aqui, idêntico ao anterior)
    // Apenas lembre de chamar _carregarClientes() ao final do sucesso.
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
                Navigator.pop(context);
                try {
                  await Supabase.instance.client
                      .from('clientes')
                      .delete()
                      .eq('id', cliente.id as Object);
                  if (mounted) _carregarClientes();
                } catch (e) {
                  // trata erro
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- LÓGICA DE BUSCA ---
  void _onSearchChanged(String value) {
    setState(() {
      _termoBuscaNome = value.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
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
              hintText: "Pesquisar...",
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
            ),
          ),
        ),
        // --- BOTÃO DE ORDENAR ---
        actions: [
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
                    Text("A-Z", style: TextStyle(color: Colors.white)),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add, size: 28),
        label: const Text(
          "NOVO",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdicionarCliente()),
          ).then((_) => _carregarClientes());
        },
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
                        final dados = listaFiltrada[index];
                        final cliente = Cliente.fromMap(dados);

                        // Pegamos a data JÁ CALCULADA e disponível na memória
                        final ultimaData = _obterUltimaData(
                          dados['orcamentos'],
                        );
                        // Verifica se é data válida (diferente de 1900) para exibição
                        final temServico = ultimaData.year > 1900;
                        final dataFormatada = temServico
                            ? DateFormat('dd/MM/yyyy').format(ultimaData)
                            : "--/--/----";

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
                                colors: [corComplementar, corCard],
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
                                  // Linha Nome + Excluir
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
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.green,
                                          size: 26,
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

                                  // Telefone
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

                                  // --- DATA DO ÚLTIMO SERVIÇO (Agora instantâneo!) ---
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

                                  // Botões
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
