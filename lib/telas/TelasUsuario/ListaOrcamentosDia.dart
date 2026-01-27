import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'DetalhesOrcamento.dart';
import '../../servicos/autenticacao.dart';
import '../../servicos/CalculaRota.dart';

class ListaOrcamentosDia extends StatefulWidget {
  final DateTime dataSelecionada;
  // Flag para controlar se mostra tudo ou só pendentes
  final bool apenasPendentes;

  const ListaOrcamentosDia({
    super.key,
    required this.dataSelecionada,
    this.apenasPendentes = false, // Padrão false (mostra tudo)
  });

  @override
  State<ListaOrcamentosDia> createState() => _ListaOrcamentosDiaState();
}

class _ListaOrcamentosDiaState extends State<ListaOrcamentosDia> {
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corPrincipal = Colors.red[900]!;

  late Future<List<Map<String, dynamic>>> _futureOrcamentos;
  List<Map<String, dynamic>> _listaParaRota = [];

  @override
  void initState() {
    super.initState();
    _futureOrcamentos = _buscarOrcamentosDoDia();
  }

  void _atualizarLista() {
    setState(() {
      _futureOrcamentos = _buscarOrcamentosDoDia();
    });
  }

  Future<List<Map<String, dynamic>>> _buscarOrcamentosDoDia() async {
    final startOfDay = DateTime(
      widget.dataSelecionada.year,
      widget.dataSelecionada.month,
      widget.dataSelecionada.day,
    );
    final endOfDay = startOfDay
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));

    if (!(Supabase
            .instance
            .client
            .auth
            .currentSession
            ?.accessToken
            .isNotEmpty ??
        false)) {
      return [];
    }

    final filterEntrada =
        'data_pega.gte.${startOfDay.toIso8601String()},data_pega.lte.${endOfDay.toIso8601String()}';
    final filterEntrega =
        'data_entrega.gte.${startOfDay.toIso8601String()},data_entrega.lte.${endOfDay.toIso8601String()}';

    // 1. BUSCA O NÚMERO NA TABELA DE CLIENTES
    var query = Supabase.instance.client
        .from('orcamentos')
        .select('*, clientes(nome, telefone, bairro, rua, numero)')
        .or('and($filterEntrada),and($filterEntrega)');

    final response = await query.order('data_pega', ascending: true);
    var lista = List<Map<String, dynamic>>.from(response);

    // 2. FILTRAGEM CONDICIONAL (PAINEL vs CALENDÁRIO)
    if (widget.apenasPendentes) {
      // Se for Painel, remove os que já foram entregues (entregue == true)
      lista = lista.where((orcamento) {
        final bool foiEntregue = orcamento['entregue'] ?? false;
        return foiEntregue == false;
      }).toList();
    }

    // Ordenação Manhã/Tarde
    lista.sort((a, b) {
      final hA = (a['horario_do_dia'] ?? '').toString().toLowerCase();
      final hB = (b['horario_do_dia'] ?? '').toString().toLowerCase();
      if (hA == 'manhã' && hB != 'manhã') return -1;
      if (hB == 'manhã' && hA != 'manhã') return 1;
      return 0;
    });

    _listaParaRota = lista;
    return lista;
  }

  void _gerarRota() {
    if (_listaParaRota.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum atendimento na lista.")),
      );
      return;
    }

    // 3. ENVIA O NÚMERO PARA O GOOGLE MAPS/ROTA
    List<Map<String, dynamic>> listaFormatada = _listaParaRota.map((orc) {
      final cliente = orc['clientes'] ?? {};
      return {
        'id': orc['id'],
        'nome_cliente': cliente['nome'] ?? 'Cliente',
        'rua': cliente['rua'] ?? '',
        'numero': (cliente['numero'] ?? '').toString(), // Passa o número
        'bairro': cliente['bairro'] ?? '',
        'cidade': 'Juiz de Fora',
      };
    }).toList();

    ServicoRota.otimizarRotaDoDia(context, listaFormatada);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: const Text(
          "Orçamentos do Dia",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => AuthService().deslogar(),
            tooltip: 'Sair',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "btnRota",
        onPressed: _gerarRota,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        child: const Icon(Icons.map),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureOrcamentos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: corPrincipal),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erro: ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final orcamentos = snapshot.data ?? [];

          if (orcamentos.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _atualizarLista(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 80,
                            color: Colors.white12,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Nenhum serviço pendente.",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _atualizarLista(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: orcamentos.length,
              itemBuilder: (context, index) =>
                  _buildOrcamentoCard(orcamentos[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrcamentoCard(Map<String, dynamic> orcamento) {
    final cliente = orcamento['clientes'] ?? {};
    final nomeCliente = cliente['nome'] ?? 'Cliente';
    final rua = cliente['rua'] ?? '';
    final numero = cliente['numero'] ?? 'S/N'; // Recupera número
    final bairro = cliente['bairro'] ?? '';
    final tituloServico = orcamento['titulo'] ?? '';

    final horarioTexto = (orcamento['horario_do_dia'] ?? 'Manhã').toString();
    final isTarde = horarioTexto.toLowerCase() == 'tarde';
    final colorBanner = isTarde ? Colors.orangeAccent : Colors.yellowAccent;
    final iconHorario = isTarde ? Icons.wb_twilight : Icons.wb_sunny;

    return Card(
      color: corCard,
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DetalhesOrcamento(orcamentoInicial: orcamento),
            ),
          ).then((_) => _atualizarLista());
        },
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: colorBanner.withValues(alpha: 0.15),
              child: Row(
                children: [
                  Icon(iconHorario, size: 16, color: colorBanner),
                  const SizedBox(width: 8),
                  Text(
                    horarioTexto.toUpperCase(),
                    style: TextStyle(
                      color: colorBanner,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white10,
                    child: Text(
                      nomeCliente.isNotEmpty
                          ? nomeCliente[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nomeCliente,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          tituloServico,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 12),
                        // EXIBE RUA E NÚMERO
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "$rua, $numero - $bairro",
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
