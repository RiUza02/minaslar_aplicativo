import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../modelos/Cliente.dart';
import 'adicionarOrcamento.dart';
import 'EditarCliente.dart';
import 'EditarOrcamento.dart';

/// Tela responsável por exibir os detalhes de um cliente e seu histórico de orçamentos.
class DetalhesCliente extends StatefulWidget {
  final Cliente cliente;

  const DetalhesCliente({super.key, required this.cliente});

  @override
  State<DetalhesCliente> createState() => _DetalhesClienteState();
}

class _DetalhesClienteState extends State<DetalhesCliente> {
  /// Variável para controlar os dados do cliente (que podem ser atualizados)
  late Cliente _clienteExibido;

  // ===========================================================================
  // PALETA DE CORES
  // ===========================================================================
  final Color corPrincipal = Colors.red[900]!;
  final Color corSecundaria = Colors.blue[300]!;
  final Color corComplementar = Colors.green[400]!; // Verde padrão
  final Color corAlerta = Colors.redAccent; // Nova cor de alerta
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
  // LÓGICA DE NEGÓCIO
  // ===========================================================================

  /// Recarrega os dados do cliente do banco (Pull to Refresh)
  Future<void> _atualizarTela() async {
    try {
      // Busca os dados atualizados no Supabase
      final data = await Supabase.instance.client
          .from('clientes')
          .select()
          .eq('id', _clienteExibido.id as Object)
          .single();

      if (mounted) {
        setState(() {
          _clienteExibido = Cliente.fromMap(data);
        });
      }
      // Pequeno delay para suavizar a animação de refresh
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao atualizar: $e')));
      }
    }
  }

  /// Exibe diálogo de confirmação e exclui um orçamento específico
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
        // Remove do banco de dados
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

  // ===========================================================================
  // INTERFACE (UI)
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    // Define a cor de status baseada se o cliente é problemático ou não
    final bool isProblematico = _clienteExibido.clienteProblematico;
    final Color corStatusAtual = isProblematico ? corAlerta : corComplementar;

    // Stream para ouvir mudanças nos orçamentos em tempo real
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
          // Navega para adicionar novo orçamento
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
          // ============================================================
          // CARD SUPERIOR COM DADOS DO CLIENTE
          // ============================================================
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: corCard,
              borderRadius: BorderRadius.circular(16),
              border: Border(
                // A borda lateral muda para vermelho se for problemático
                left: BorderSide(color: corStatusAtual, width: 6),
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
                      // Fundo do ícone muda sutilmente
                      backgroundColor: corStatusAtual.withOpacity(0.15),
                      child: Icon(
                        Icons.person,
                        color: corStatusAtual,
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
                        // Abre tela de edição e atualiza se houve mudança
                        final bool? atualizou = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditarCliente(cliente: _clienteExibido),
                          ),
                        );
                        if (atualizou == true) _atualizarTela();
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
                  _clienteExibido.bairro,
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

          // ============================================================
          // TÍTULO DA LISTA
          // ============================================================
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

          // ============================================================
          // LISTAGEM DE ORÇAMENTOS
          // ============================================================
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

                return RefreshIndicator(
                  color: corPrincipal,
                  backgroundColor: corCard,
                  onRefresh: _atualizarTela,
                  child: listaOrcamentos.isEmpty
                      ? ListView(
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
                            final titulo = orcamento['titulo'] ?? 'Serviço';
                            final descricao =
                                orcamento['descricao'] ?? 'Sem descrição';
                            final valor = orcamento['valor'];
                            final dataPegaString = orcamento['data_pega'];
                            final dataPega = dataPegaString != null
                                ? DateTime.parse(dataPegaString)
                                : DateTime.now();

                            // Lógica de Data de Entrega (Novo requisito)
                            final dataEntregaString = orcamento['data_entrega'];
                            final dataEntregaFormatada =
                                dataEntregaString != null
                                ? DateFormat(
                                    'dd/MM',
                                  ).format(DateTime.parse(dataEntregaString))
                                : '--/--';

                            final bool isUltimo = index == 0;

                            // Se for o item mais recente e o cliente for problemático, usa vermelho.
                            // Se for recente e normal, usa verde. Se for antigo, usa cinza.
                            final Color corDestaqueItem = isUltimo
                                ? (isProblematico
                                      ? Colors.redAccent
                                      : Colors.greenAccent)
                                : Colors.grey;

                            final Color corFundoIcone = isUltimo
                                ? (isProblematico
                                      ? Colors.red.withOpacity(0.2)
                                      : Colors.green.withOpacity(0.2))
                                : Colors.black26;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: corCard,
                                borderRadius: BorderRadius.circular(12),
                                border: isUltimo
                                    ? Border.all(
                                        color: corDestaqueItem.withOpacity(0.5),
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
                                leading: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: corFundoIcone,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isUltimo
                                            ? Icons.new_releases
                                            : Icons.build_circle_outlined,
                                        color: isUltimo
                                            ? corDestaqueItem
                                            : corTextoCinza,
                                      ),
                                    ),
                                  ],
                                ),
                                title: Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Text(
                                    titulo,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isUltimo
                                          ? corDestaqueItem
                                          : corTextoClaro,
                                    ),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // CONTAINER NOVO PARA A DESCRIÇÃO
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: Colors
                                            .black26, // "Caixa" mais escura
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        descricao,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13,
                                          fontStyle: FontStyle.normal,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Linha de Detalhes (Datas e Valor)
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        // Data de Entrada
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
                                        const SizedBox(width: 12),

                                        // Data de Entrega
                                        Icon(
                                          Icons.local_shipping_outlined,
                                          size: 14,
                                          color: corTextoCinza,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          dataEntregaFormatada,
                                          style: TextStyle(
                                            color: corTextoCinza,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 50),

                                        // Valor
                                        Icon(
                                          Icons.monetization_on_outlined,
                                          size: 14,
                                          color: valor != null
                                              ? Colors.amber
                                              : corTextoCinza,
                                        ),
                                        const SizedBox(width: 4),
                                        // Usamos RichText ou Row para garantir que o símbolo fique na mesma linha
                                        Text(
                                          valor != null
                                              ? "R\$ ${NumberFormat.currency(
                                                  locale: 'pt_BR',
                                                  symbol: '', // Removemos o símbolo automático
                                                  decimalDigits: 2,
                                                ).format(valor).trim()}"
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
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
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
                                        if (result == true) _atualizarTela();
                                      },
                                    ),
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

  /// Widget auxiliar para criar linhas de informações com ícone
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
