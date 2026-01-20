import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../modelos/Cliente.dart';
import 'adicionarOrcamento.dart';
import 'EditarCliente.dart';
import 'EditarOrcamento.dart';

class DetalhesCliente extends StatefulWidget {
  final Cliente cliente;

  const DetalhesCliente({super.key, required this.cliente});

  @override
  State<DetalhesCliente> createState() => _DetalhesClienteState();
}

class _DetalhesClienteState extends State<DetalhesCliente> {
  // Variável para controlar os dados do cliente (que podem ser atualizados)
  late Cliente _clienteExibido;

  // Cores (Movidas para o State para acesso fácil)
  final Color corPrincipal = Colors.red[900]!;
  final Color corSecundaria = Colors.blue[300]!;
  final Color corComplementar = Colors.green[400]!;
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corTextoClaro = Colors.white;
  final Color corTextoCinza = Colors.grey[400]!;

  @override
  void initState() {
    super.initState();
    _clienteExibido = widget.cliente;
  }

  // ===========================================================================
  // LÓGICA DE ATUALIZAÇÃO (PULL TO REFRESH)
  // ===========================================================================
  Future<void> _atualizarTela() async {
    try {
      // 1. Recarrega os dados do Cliente do Supabase
      final data = await Supabase.instance.client
          .from('clientes')
          .select()
          .eq('id', _clienteExibido.id as Object)
          .single();

      // 2. Atualiza o estado da tela
      if (mounted) {
        setState(() {
          _clienteExibido = Cliente.fromMap(data);
        });
      }

      // Nota: A lista de orçamentos é um Stream, então ela se mantém atualizada sozinha,
      // mas o delay abaixo dá a sensação tátil de carregamento para o usuário.
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao atualizar: $e')));
      }
    }
  }

  // ===========================================================================
  // LÓGICA DE EXCLUSÃO
  // ===========================================================================
  Future<void> _confirmarExclusao(
    BuildContext context,
    Map<String, dynamic> orcamento,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: corCard,
        title: const Text(
          'Excluir Orçamento',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Tem certeza que deseja apagar este orçamento permanentemente?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await Supabase.instance.client
            .from('orcamentos')
            .delete()
            .eq('id', orcamento['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Orçamento excluído com sucesso.'),
              backgroundColor: Colors.grey,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orcamentosStream = Supabase.instance.client
        .from('orcamentos')
        .stream(primaryKey: ['id'])
        .eq('cliente_id', _clienteExibido.id as Object)
        .order('data_pega', ascending: false);

    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: const Text(
          "Detalhes do Cliente",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.post_add, size: 28),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AdicionarOrcamento(cliente: _clienteExibido),
            ),
          );
        },
      ),
      body: Column(
        children: [
          // CARD SUPERIOR COM DADOS DO CLIENTE
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: corCard,
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(color: corComplementar, width: 6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.05),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: corComplementar.withOpacity(0.15),
                      child: Icon(
                        Icons.person,
                        color: corComplementar,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _clienteExibido.nome,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: corTextoClaro,
                            ),
                          ),
                          if (_clienteExibido.clienteProblematico)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.redAccent),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.warning_amber,
                                      color: Colors.redAccent,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "Problemático",
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: corTextoCinza),
                      tooltip: 'Editar Cliente',
                      onPressed: () async {
                        final bool? atualizou = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditarCliente(cliente: _clienteExibido),
                          ),
                        );
                        // Se editou, atualiza os dados na tela
                        if (atualizou == true) {
                          _atualizarTela();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white12),
                const SizedBox(height: 10),
                _linhaDado(
                  Icons.phone_android,
                  _clienteExibido.telefone,
                  corTextoClaro,
                  corSecundaria,
                ),
                _linhaDado(
                  Icons.location_on_outlined,
                  _clienteExibido.endereco,
                  corTextoClaro,
                  corSecundaria,
                ),
                if (_clienteExibido.cpf != null)
                  _linhaDado(
                    Icons.badge_outlined,
                    "CPF: ${_clienteExibido.cpf}",
                    corTextoClaro,
                    corSecundaria,
                  ),
                if (_clienteExibido.cnpj != null)
                  _linhaDado(
                    Icons.domain,
                    "CNPJ: ${_clienteExibido.cnpj}",
                    corTextoClaro,
                    corSecundaria,
                  ),
                if (_clienteExibido.observacao != null &&
                    _clienteExibido.observacao!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Observações:",
                          style: TextStyle(
                            color: corTextoCinza,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _clienteExibido.observacao!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // TÍTULO DA LISTA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Row(
              children: [
                Icon(Icons.history, color: corTextoCinza, size: 18),
                const SizedBox(width: 8),
                Text(
                  "HISTÓRICO DE ORÇAMENTOS",
                  style: TextStyle(
                    color: corTextoCinza,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // LISTAGEM DE ORÇAMENTOS (COM REFRESH INDICATOR)
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: orcamentosStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  );
                }

                final listaOrcamentos = snapshot.data!;

                // RefreshIndicator envolve o conteúdo da lista
                // RefreshIndicator envolve o conteúdo da lista
                return RefreshIndicator(
                  color: corPrincipal,
                  backgroundColor: corCard,
                  onRefresh: _atualizarTela,
                  child: listaOrcamentos.isEmpty
                      ? ListView(
                          // Physics necessário para permitir o refresh mesmo vazia
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.3,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.assignment_outlined,
                                      size: 60,
                                      color: Colors.grey[800],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "Nenhum orçamento registrado.",
                                      style: TextStyle(
                                        color: corTextoCinza,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: listaOrcamentos.length,
                          itemBuilder: (context, index) {
                            final orcamento = listaOrcamentos[index];

                            // --- DADOS DO ITEM ---
                            final titulo =
                                orcamento['titulo'] ?? 'Serviço'; // Novo campo
                            final descricao =
                                orcamento['descricao'] ?? 'Sem descrição';
                            final valor = orcamento['valor'];
                            final dataPegaString = orcamento['data_pega'];

                            final dataPega = dataPegaString != null
                                ? DateTime.parse(dataPegaString)
                                : DateTime.now();

                            final bool isUltimo = index == 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: corCard,
                                borderRadius: BorderRadius.circular(12),
                                border: isUltimo
                                    ? Border.all(
                                        color: Colors.green.withOpacity(0.5),
                                      )
                                    : null,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.only(
                                  left: 16,
                                  right: 8,
                                  top: 8,
                                  bottom: 8,
                                ),
                                isThreeLine: true,
                                // ÍCONE LATERAL ESQUERDO
                                leading: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isUltimo
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.black26,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isUltimo
                                            ? Icons.new_releases
                                            : Icons.build_circle_outlined,
                                        color: isUltimo
                                            ? Colors.greenAccent
                                            : corTextoCinza,
                                      ),
                                    ),
                                  ],
                                ),

                                // TÍTULO DO CARD (Novo campo Título)
                                title: Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Text(
                                    titulo,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isUltimo
                                          ? Colors.greenAccent
                                          : corTextoClaro,
                                    ),
                                  ),
                                ),

                                // CONTEÚDO (Descrição + Data + Valor)
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Descrição
                                    Text(
                                      descricao,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Linha Data e Valor
                                    Row(
                                      children: [
                                        // Data
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: corTextoCinza,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('dd/MM').format(dataPega),
                                          style: TextStyle(
                                            color: corTextoCinza,
                                            fontSize: 13,
                                          ),
                                        ),

                                        const SizedBox(width: 16),

                                        // Valor
                                        Icon(
                                          Icons.monetization_on_outlined,
                                          size: 14,
                                          color: valor != null
                                              ? Colors.amber
                                              : corTextoCinza,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          valor != null
                                              ? NumberFormat.currency(
                                                  locale: 'pt_BR',
                                                  symbol: 'R\$',
                                                ).format(valor)
                                              : 'A combinar',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: valor != null
                                                ? Colors.white
                                                : Colors.amber,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                // BOTÕES DE AÇÃO (LADO A LADO PARA NÃO QUEBRAR O LAYOUT)
                                trailing: Row(
                                  mainAxisSize: MainAxisSize
                                      .min, // Ocupa apenas o espaço necessário
                                  children: [
                                    // Botão Editar
                                    IconButton(
                                      visualDensity: VisualDensity
                                          .compact, // Remove espaços extras
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blueGrey,
                                        size: 22,
                                      ),
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditarOrcamento(
                                                  orcamento: orcamento,
                                                ),
                                          ),
                                        );
                                        // Se retornou true, atualiza a lista
                                        if (result == true) {
                                          _atualizarTela();
                                        }
                                      },
                                    ),

                                    // Botão Excluir
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                        size: 22,
                                      ),
                                      onPressed: () => _confirmarExclusao(
                                        context,
                                        orcamento,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaDado(
    IconData icon,
    String texto,
    Color corTexto,
    Color corIcone,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: corIcone),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texto, style: TextStyle(fontSize: 15, color: corTexto)),
          ),
        ],
      ),
    );
  }
}
