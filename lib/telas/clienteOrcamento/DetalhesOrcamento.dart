import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'EditarOrcamento.dart';

class DetalhesOrcamento extends StatefulWidget {
  final Map<String, dynamic> orcamentoInicial;

  const DetalhesOrcamento({super.key, required this.orcamentoInicial});

  @override
  State<DetalhesOrcamento> createState() => _DetalhesOrcamentoState();
}

class _DetalhesOrcamentoState extends State<DetalhesOrcamento> {
  late Map<String, dynamic> _orcamento;
  bool _isLoading = false;

  // ===========================================================================
  // PALETA DE CORES
  // ===========================================================================
  final Color corPrincipal = Colors.red[900]!;
  final Color corSecundaria = Colors.blue[300]!;
  final Color corComplementar = Colors.green[400]!;
  final Color corAlerta = Colors.redAccent;
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corTextoClaro = Colors.white;
  final Color corTextoCinza = Colors.grey[400]!;

  @override
  void initState() {
    super.initState();
    _orcamento = widget.orcamentoInicial;
    _atualizarDados();
  }

  // ===========================================================================
  // LÓGICA DE NEGÓCIO
  // ===========================================================================

  Future<void> _atualizarDados() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('orcamentos')
          // ATENÇÃO: Adicionado ', clientes(nome)' para buscar o nome do cliente
          .select('*, clientes(nome)')
          .eq('id', _orcamento['id'])
          .single();

      if (mounted) {
        setState(() {
          _orcamento = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('Erro ao atualizar orçamento: $e');
      }
    }
  }

  Future<void> _excluirOrcamento() async {
    final confirmar = await showDialog<bool>(
      context: context,
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

    if (confirmar == true && mounted) {
      try {
        await Supabase.instance.client
            .from('orcamentos')
            .delete()
            .eq('id', _orcamento['id']);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Orçamento excluído.')));
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

  void _navegarEditar() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarOrcamento(orcamento: _orcamento),
      ),
    );

    if (resultado == true) {
      _atualizarDados();
    }
  }

  // ===========================================================================
  // INTERFACE (UI)
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    // Parsing básicos
    final titulo = _orcamento['titulo'] ?? 'Sem Título';
    final descricao = _orcamento['descricao'] ?? '';
    final valor = _orcamento['valor'];
    final dataPegaStr = _orcamento['data_pega'];
    final dataEntregaStr = _orcamento['data_entrega'];

    // Parsing Cliente e Horário (NOVOS)
    final horario = _orcamento['horario_do_dia'] ?? 'Não informado';
    String nomeCliente = 'Cliente desconhecido';

    // Verifica se existe a relação 'clientes' e se tem 'nome'
    if (_orcamento['clientes'] != null && _orcamento['clientes'] is Map) {
      nomeCliente = _orcamento['clientes']['nome'] ?? 'Sem Nome';
    }

    // Configuração visual do horário
    final bool isTarde = horario.toString().toLowerCase() == 'tarde';
    final IconData iconHorario = isTarde
        ? Icons.wb_twilight
        : Icons.wb_sunny_outlined;
    final Color corHorario = isTarde ? Colors.orangeAccent : Colors.amber;

    final DateTime? dataEntrega = dataEntregaStr != null
        ? DateTime.tryParse(dataEntregaStr)
        : null;
    final DateTime? dataPega = dataPegaStr != null
        ? DateTime.tryParse(dataPegaStr)
        : null;

    final bool isAtrasado =
        dataEntrega != null &&
        dataEntrega.isBefore(DateTime.now()) &&
        (_orcamento['status'] != 'Concluido');
    final corStatus = isAtrasado ? corAlerta : corComplementar;

    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: const Text(
          "Detalhes do Orçamento",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.delete),
            tooltip: 'Deletar Orçamento',
            color: corCard,
            onSelected: (value) {
              if (value == 'excluir') _excluirOrcamento();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'excluir',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Excluir', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        onPressed: _navegarEditar,
        icon: const Icon(Icons.edit),
        label: const Text("Editar"),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: corPrincipal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // CARD PRINCIPAL (Título e Valor)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: corCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border(
                        left: BorderSide(color: corStatus, width: 6),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                titulo,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: corTextoClaro,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.assignment,
                              color: corStatus.withOpacity(0.5),
                              size: 30,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "VALOR DO ORÇAMENTO",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          valor != null
                              ? NumberFormat.currency(
                                  locale: 'pt_BR',
                                  symbol: 'R\$',
                                ).format(valor)
                              : 'A Combinar',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: valor != null ? Colors.amber : corTextoCinza,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ===========================================================
                  // NOVA SEÇÃO: CLIENTE E HORÁRIO
                  // ===========================================================
                  Row(
                    children: [
                      // Card Cliente
                      Expanded(
                        flex:
                            3, // Ocupa um pouco mais de espaço se o nome for longo
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: corCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: corSecundaria,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    "CLIENTE",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                nomeCliente,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Card Horário
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: corCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: corHorario.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(iconHorario, color: corHorario, size: 24),
                              const SizedBox(height: 6),
                              Text(
                                horario.toString().toUpperCase(),
                                style: TextStyle(
                                  color: corHorario,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ===========================================================
                  const SizedBox(height: 20),

                  // SEÇÃO DE DATAS
                  Row(
                    children: [
                      Expanded(
                        child: _cardData(
                          "Entrada",
                          dataPega,
                          Icons.calendar_today_outlined,
                          Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _cardData(
                          "Entrega",
                          dataEntrega,
                          Icons.event_available,
                          isAtrasado ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // DESCRIÇÃO / SERVIÇOS
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: corCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              color: corSecundaria,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "DESCRIÇÃO DO SERVIÇO",
                              style: TextStyle(
                                color: corSecundaria,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 12),
                        Text(
                          descricao.isNotEmpty
                              ? descricao
                              : "Nenhuma descrição informada.",
                          style: TextStyle(
                            color: descricao.isNotEmpty
                                ? Colors.white70
                                : Colors.white24,
                            fontSize: 16,
                            height: 1.5,
                            fontStyle: descricao.isNotEmpty
                                ? FontStyle.normal
                                : FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _cardData(
    String label,
    DateTime? data,
    IconData icon,
    Color corDestaque,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: corDestaque, size: 24),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: corTextoCinza,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data != null ? DateFormat('dd/MM/yyyy').format(data) : '--/--/----',
            style: TextStyle(
              color: corTextoClaro,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
