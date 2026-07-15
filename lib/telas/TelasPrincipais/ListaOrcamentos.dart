import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListaOrcamentos extends StatefulWidget {
  const ListaOrcamentos({Key? key}) : super(key: key);

  @override
  State<ListaOrcamentos> createState() => _ListaOrcamentosState();
}

// Preservação de estado com AutomaticKeepAliveClientMixin para manter
// o scroll e dados intactos na navegação pela HomePage
class _ListaOrcamentosState extends State<ListaOrcamentos>
    with AutomaticKeepAliveClientMixin {
  final _supabase = Supabase.instance.client;

  // Controle de Dados e Paginação
  final List<Map<String, dynamic>> _orcamentos = [];
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
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _buscarOrcamentos(reiniciar: true);

    // Monitora a rolagem para disparar a paginação perto do fim da lista
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingInicial &&
            !_isFetchingMore &&
            _temMaisDados &&
            !_semConexao) {
          _buscarOrcamentos(reiniciar: false);
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

  // Consulta paginada ao Supabase
  Future<void> _buscarOrcamentos({required bool reiniciar}) async {
    if (reiniciar) {
      setState(() {
        _isLoadingInicial = true;
        _paginaAtual = 0;
        _temMaisDados = true;
        _semConexao = false;
        _orcamentos.clear();
      });
    } else {
      setState(() {
        _isFetchingMore = true;
      });
    }

    try {
      final int inicio = _paginaAtual * _tamanhoPagina;
      final int fim = inicio + _tamanhoPagina - 1;

      // Query base trazendo os dados do cliente relacional (adapte ao seu schema)
      var query = _supabase
          .from('orcamentos')
          .select('*, clientes(nome, telefone)');

      // Filtro textual na descrição do serviço ou no status
      if (_termoBusca.isNotEmpty) {
        query = query.or(
          'descricao.ilike.%$_termoBusca%,status.ilike.%$_termoBusca%',
        );
      }

      // Ordenação no banco: priorizamos os mais recentes pela data de agendamento ou criação
      final resposta = await query
          .order('data_agendamento', ascending: false)
          .range(inicio, fim);

      final List<Map<String, dynamic>> novosDados =
          List<Map<String, dynamic>>.from(resposta);

      setState(() {
        if (novosDados.length < _tamanhoPagina) {
          _temMaisDados = false;
        }

        _orcamentos.addAll(novosDados);
        _paginaAtual++;
        _semConexao = false;
      });
    } catch (e) {
      debugPrint('Erro na busca paginada de orçamentos: $e');
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

  // Debouncer de 400ms para evitar chamadas em cascata ao banco
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      final termoLimpo = query.trim();
      if (_termoBusca != termoLimpo) {
        _termoBusca = termoLimpo;
        _buscarOrcamentos(reiniciar: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
                hintText: 'Buscar por serviço ou status...',
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

    if (_orcamentos.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _buscarOrcamentos(reiniciar: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _orcamentos.length + (_isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _orcamentos.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final orcamento = _orcamentos[index];
          return _buildCardOrcamento(orcamento);
        },
      ),
    );
  }

  // Lógica visual para determinar a cor do card com base no status ou atraso
  Color _obterCorStatus(Map<String, dynamic> orcamento) {
    final status = (orcamento['status'] ?? '').toString().toLowerCase();

    if (status == 'concluido') return Colors.green;
    if (status == 'em_andamento') return Colors.blue;
    if (status == 'garantia') return Colors.orange;

    // Verificação simples de atraso (adapte à sua regra de negócio)
    final dataAgendamentoStr = orcamento['data_agendamento'];
    if (dataAgendamentoStr != null && status != 'concluido') {
      final dataAgendamento = DateTime.tryParse(dataAgendamentoStr.toString());
      if (dataAgendamento != null && dataAgendamento.isBefore(DateTime.now())) {
        return Colors.red; // Atrasado
      }
    }

    return Colors.grey;
  }

  // Componente do Card mantendo a legibilidade operacional e status reativos
  Widget _buildCardOrcamento(Map<String, dynamic> orcamento) {
    final corStatus = _obterCorStatus(orcamento);
    final cliente = orcamento['clientes'] as Map<String, dynamic>?;
    final nomeCliente = cliente != null
        ? cliente['nome']
        : 'Cliente não identificado';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: corStatus.withOpacity(0.5), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: corStatus,
                width: 6,
              ), // Indicador visual lateral
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            title: Text(
              orcamento['descricao'] ?? 'Serviço sem descrição',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Cliente: $nomeCliente'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: corStatus.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (orcamento['status'] ?? 'Pendente')
                            .toString()
                            .toUpperCase(),
                        style: TextStyle(
                          color: corStatus,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      orcamento['data_agendamento'] != null
                          ? orcamento['data_agendamento']
                                .toString()
                                .split('T')
                                .first
                          : 'Sem data',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navegação para a tela de edição ou detalhes do orçamento
            },
          ),
        ),
      ),
    );
  }

  // Widgets de Estado (Prontos para serem extraídos para um arquivo de componentes globais - Ponto B)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Nenhum orçamento encontrado.',
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
          const Text('Erro ao carregar orçamentos ou sem conexão.'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _buscarOrcamentos(reiniciar: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
