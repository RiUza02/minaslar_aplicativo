import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../modelos/Cliente.dart';
import 'adicionarOrcamento.dart';
import 'EditarCliente.dart';
import 'EditarOrcamento.dart';

// ===========================================================================
// TELA DE DETALHES DO CLIENTE
// ===========================================================================
class DetalhesCliente extends StatefulWidget {
  final Cliente cliente;

  const DetalhesCliente({super.key, required this.cliente});

  @override
  State<DetalhesCliente> createState() => _DetalhesClienteState();
}

class _DetalhesClienteState extends State<DetalhesCliente> {
  late Cliente _clienteExibido;

  // ===========================================================================
  // PALETA DE CORES E ESTILOS
  // ===========================================================================
  final Color corPrincipal = Colors.red[900]!;
  final Color corSecundaria = Colors.blue[300]!;
  final Color corComplementar = Colors.green[400]!;
  final Color corAlerta = Colors.redAccent;
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corTextoClaro = Colors.white;
  final Color corTextoCinza = Colors.grey[400]!;

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================
  @override
  void initState() {
    super.initState();
    _clienteExibido = widget.cliente;
  }

  // ===========================================================================
  // LÓGICA DE NEGÓCIO E SUPABASE
  // ===========================================================================

  /// Recarrega os dados do cliente atual diretamente do Supabase
  Future<void> _atualizarTela() async {
    try {
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

  /// Navega para a tela de edição de orçamento
  void _editarOrcamento(Map<String, dynamic> orcamento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarOrcamento(orcamento: orcamento),
      ),
    );
  }

  /// Exibe diálogo de confirmação e executa a exclusão no banco
  Future<void> _confirmarExclusao(
    BuildContext ctx,
    Map<String, dynamic> orcamento,
  ) async {
    // 1. Exibe o Diálogo
    final confirmar = await showDialog<bool>(
      context: ctx,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!mounted || confirmar != true) return;

    // 2. Executa a exclusão no Supabase
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

  // ===========================================================================
  // INTERFACE DO USUÁRIO (UI)
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    // Definição de status visual (Cliente problemático ou Normal)
    final bool isProblematico = _clienteExibido.clienteProblematico;
    final Color corStatusAtual = isProblematico ? corAlerta : corComplementar;

    // Stream em tempo real dos orçamentos deste cliente
    final orcamentosStream = Supabase.instance.client
        .from('orcamentos')
        .stream(primaryKey: ['id'])
        .eq('cliente_id', _clienteExibido.id as Object)
        .order('data_pega', ascending: false);

    return Scaffold(
      backgroundColor: corFundo,
      // -- BARRA SUPERIOR --
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
      // -- BOTÃO FLUTUANTE (ADICIONAR) --
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
          // ==================================================
          // CARD DE INFORMAÇÕES DO CLIENTE
          // ==================================================
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: corCard,
              borderRadius: BorderRadius.circular(16),
              border: Border(left: BorderSide(color: corStatusAtual, width: 6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.05),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho do Card (Avatar, Nome, Status)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: corStatusAtual.withValues(alpha: 0.15),
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
                          // Badge de "Problemático" se necessário
                          if (_clienteExibido.clienteProblematico)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.2),
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
                    // Botão de Editar Cliente
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
                        if (atualizou == true) _atualizarTela();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white12),
                const SizedBox(height: 10),
                // Dados de Contato e Endereço
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
                // Campo de Observações
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

          // Título da Lista
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

          // ==================================================
          // LISTA DE ORÇAMENTOS (STREAM)
          // ==================================================
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: orcamentosStream,
              builder: (context, snapshot) {
                // Loading State
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
                  // Lista Vazia ou Lista Preenchida
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

                            // Extração de dados do Mapa
                            final titulo = orcamento['titulo'] ?? 'Serviço';
                            final descricao =
                                orcamento['descricao'] ?? 'Sem descrição';
                            final valor = orcamento['valor'];
                            final dataPegaString = orcamento['data_pega'];
                            final dataPega = dataPegaString != null
                                ? DateTime.parse(dataPegaString)
                                : DateTime.now();

                            final dataEntregaString = orcamento['data_entrega'];
                            final dataEntregaFormatada =
                                dataEntregaString != null
                                ? DateFormat(
                                    'dd/MM',
                                  ).format(DateTime.parse(dataEntregaString))
                                : '--/--';

                            // Destaque visual para o item mais recente
                            final bool isUltimo = index == 0;
                            final Color corDestaqueItem = isUltimo
                                ? (isProblematico
                                      ? Colors.redAccent
                                      : Colors.greenAccent)
                                : Colors.grey;

                            final Color corFundoIcone = isUltimo
                                ? (isProblematico
                                      ? Colors.red.withValues(alpha: 0.2)
                                      : Colors.green.withValues(alpha: 0.2))
                                : Colors.black26;

                            // -- Item da Lista --
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: corCard,
                                borderRadius: BorderRadius.circular(12),
                                border: isUltimo
                                    ? Border.all(
                                        color: corDestaqueItem.withValues(
                                          alpha: 0.5,
                                        ),
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
                                // Ícone de status
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
                                // Título e Menu Dropdown
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4.0,
                                        ),
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
                                    ),
                                    // Menu de Opções (Editar/Excluir)
                                    PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: corTextoCinza,
                                      ),
                                      color: corCard,
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      onSelected: (String choice) {
                                        if (choice == 'editar') {
                                          _editarOrcamento(orcamento);
                                        } else if (choice == 'excluir') {
                                          _confirmarExclusao(
                                            context,
                                            orcamento,
                                          );
                                        }
                                      },
                                      itemBuilder: (BuildContext context) => [
                                        const PopupMenuItem(
                                          value: 'editar',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.edit,
                                                color: Colors.blue,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Editar',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'excluir',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Excluir',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Detalhes do Orçamento
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        descricao,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        // Data Pega
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
                                        // Data Entrega
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
                                        Text(
                                          valor != null
                                              ? "R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '').format(valor)}"
                                              : "A combinar",
                                          style: TextStyle(
                                            color: valor != null
                                                ? Colors.amber
                                                : corTextoCinza,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
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

  // ===========================================================================
  // WIDGETS AUXILIARES
  // ===========================================================================

  /// Widget auxiliar para renderizar uma linha de ícone + texto
  Widget _linhaDado(
    IconData icon,
    String? text,
    Color corTexto,
    Color corIcone,
  ) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: corIcone, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: corTexto, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
