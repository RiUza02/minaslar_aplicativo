import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListaClientes extends StatefulWidget {
  const ListaClientes({Key? key}) : super(key: key);

  @override
  State<ListaClientes> createState() => _ListaClientesState();
}

// Preservação de estado com AutomaticKeepAliveClientMixin para não perder
// o scroll e os dados ao navegar pelo PageView da HomePage
class _ListaClientesState extends State<ListaClientes>
    with AutomaticKeepAliveClientMixin {
  final _supabase = Supabase.instance.client;

  // Controle de Dados e Paginação
  final List<Map<String, dynamic>> _clientes = [];
  final int _tamanhoPagina = 20;
  int _paginaAtual = 0;

  // Controle de Estados da Interface
  bool _isLoadingInicial = true;
  bool _isFetchingMore = false;
  bool _temMaisDados = true;
  bool _semConexao = false;

  // Controladores
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _termoBusca = '';

  @override
  bool get wantKeepAlive => true; // Obrigatório para o mixin de preservação de estado

  @override
  void initState() {
    super.initState();
    _buscarClientes(reiniciar: true);

    // Listener para rolagem infinita: dispara quando faltam 200 pixels para o fim da lista
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingInicial &&
            !_isFetchingMore &&
            _temMaisDados &&
            !_semConexao) {
          _buscarClientes(reiniciar: false);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Lógica principal de consulta paginada ao Supabase
  Future<void> _buscarClientes({required bool reiniciar}) async {
    if (reiniciar) {
      setState(() {
        _isLoadingInicial = true;
        _paginaAtual = 0;
        _temMaisDados = true;
        _semConexao = false;
        _clientes.clear();
      });
    } else {
      setState(() {
        _isFetchingMore = true;
      });
    }

    try {
      // Cálculo dos índices para o método .range() do Supabase
      final int inicio = _paginaAtual * _tamanhoPagina;
      final int fim = inicio + _tamanhoPagina - 1;

      // Query base trazendo os orçamentos aninhados
      var query = _supabase.from('clientes').select('*, orcamentos(...)');

      // Aplica o filtro de busca textual se houver texto digitado
      if (_termoBusca.isNotEmpty) {
        query = query.or(
          'nome.ilike.%$_termoBusca%,telefone.ilike.%$_termoBusca%',
        );
      }

      // IMPORTANTE: A ordenação DEVE ocorrer no banco antes do corte da paginação (.range)
      final resposta = await query
          .order('nome', ascending: true)
          .range(inicio, fim);

      final List<Map<String, dynamic>> novosDados =
          List<Map<String, dynamic>>.from(resposta);

      setState(() {
        // Se a busca retornou menos itens que o limite da página, o banco chegou ao fim
        if (novosDados.length < _tamanhoPagina) {
          _temMaisDados = false;
        }

        _clientes.addAll(novosDados);
        _paginaAtual++;
        _semConexao = false;
      });
    } catch (e) {
      debugPrint('Erro na busca paginada de clientes: $e');
      setState(() {
        if (reiniciar) _semConexao = true;
      });
    } finally {
      setState(() {
        _isLoadingInicial = false;
        _isFetchingMore = false;
      });
    }
  }

  // Controle de requisições ao digitar (Debouncer de 400ms)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      final termoLimpo = query.trim();
      if (_termoBusca != termoLimpo) {
        _termoBusca = termoLimpo;
        _buscarClientes(reiniciar: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necessário pelo AutomaticKeepAliveClientMixin

    return Scaffold(
      body: Column(
        children: [
          // Barra de Busca
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou telefone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _termoBusca.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Corpo da Lista
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingInicial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_semConexao) {
      return _buildSemInternetState();
    }

    if (_clientes.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _buscarClientes(reiniciar: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        // Adiciona um item extra ao final apenas quando estiver baixando mais dados
        itemCount: _clientes.length + (_isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Renderiza o indicador de carregamento no último índice da lista
          if (index == _clientes.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final cliente = _clientes[index];
          return _buildCardCliente(cliente);
        },
      ),
    );
  }

  // Componente visual do Cliente (Substitua pelo seu Card customizado)
  Widget _buildCardCliente(Map<String, dynamic> cliente) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(cliente['nome'].toString().substring(0, 1).toUpperCase()),
        ),
        title: Text(
          cliente['nome'] ?? 'Sem nome',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(cliente['telefone'] ?? 'Sem telefone cadastrado'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navegação para detalhes do cliente
        },
      ),
    );
  }

  // Widgets de Estado (Candidatos à modularização no Ponto B)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.person_off_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Nenhum cliente encontrado.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSemInternetState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          const Text('Erro ao carregar dados ou sem conexão.'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _buscarClientes(reiniciar: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
