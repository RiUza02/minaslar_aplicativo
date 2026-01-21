import 'package:flutter/material.dart';
import 'package:minaslar/modelos/Orcamento.dart';
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
  late Orcamento _orcamentoObj;
  String _nomeCliente = 'Cliente desconhecido';
  bool _isLoading = false;

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
    _orcamentoObj = Orcamento.fromMap(widget.orcamentoInicial);
    _processarNomeCliente(widget.orcamentoInicial);
    _atualizarDados();
  }

  void _processarNomeCliente(Map<String, dynamic> map) {
    if (map['clientes'] != null && map['clientes'] is Map) {
      _nomeCliente = map['clientes']['nome'] ?? 'Sem Nome';
    }
  }

  Future<void> _atualizarDados() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('orcamentos')
          .select('*, clientes(nome)')
          .eq('id', _orcamentoObj.id!)
          .single();

      if (mounted) {
        setState(() {
          _orcamentoObj = Orcamento.fromMap(data);
          _processarNomeCliente(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ===========================================================================
  // MÉTODO DE EXCLUSÃO (CORRIGIDO)
  // ===========================================================================
  Future<void> _excluirOrcamento() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: corCard,
        title: Text(
          "Excluir Orçamento",
          style: TextStyle(color: corTextoClaro),
        ),
        content: Text(
          "Tem certeza que deseja apagar este orçamento permanentemente?",
          style: TextStyle(color: corTextoCinza),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCELAR"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("EXCLUIR", style: TextStyle(color: corAlerta)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _isLoading = true);
      try {
        await Supabase.instance.client
            .from('orcamentos')
            .delete()
            .eq('id', _orcamentoObj.id!);

        if (mounted) {
          Navigator.pop(
            context,
            true,
          ); // Volta para a lista informando que houve alteração
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Orçamento excluído com sucesso!")),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Erro ao excluir: $e")));
        }
      }
    }
  }

  void _navegarEditar() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarOrcamento(
          orcamento: _orcamentoObj.toMap()..['id'] = _orcamentoObj.id,
        ),
      ),
    );

    if (resultado == true) {
      _atualizarDados();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isConcluido = _orcamentoObj.entregue;
    final String horario = _orcamentoObj.horarioDoDia;
    final bool isTarde = horario.toLowerCase() == 'tarde';

    final IconData iconHorario = isTarde
        ? Icons.wb_twilight
        : Icons.wb_sunny_outlined;
    final Color corHorario = isTarde ? Colors.orangeAccent : Colors.amber;

    final DateTime hoje = DateTime.now();
    final DateTime dataHojeApenas = DateTime(hoje.year, hoje.month, hoje.day);
    bool isAtrasado = false;

    if (_orcamentoObj.dataEntrega != null) {
      final DateTime entrega = _orcamentoObj.dataEntrega!;
      final DateTime dataEntregaApenas = DateTime(
        entrega.year,
        entrega.month,
        entrega.day,
      );
      isAtrasado = !isConcluido && dataEntregaApenas.isBefore(dataHojeApenas);
    }

    final corStatus = isAtrasado
        ? corAlerta
        : (isConcluido ? corComplementar : corSecundaria);

    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: const Text("Detalhes do Orçamento"),
        backgroundColor: corPrincipal,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _excluirOrcamento,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        onPressed: _navegarEditar,
        child: const Icon(Icons.edit),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: corPrincipal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: corCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border(
                        left: BorderSide(color: corStatus, width: 6),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _orcamentoObj.titulo,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: corTextoClaro,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "VALOR DO ORÇAMENTO",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          _orcamentoObj.valor != null
                              ? NumberFormat.currency(
                                  locale: 'pt_BR',
                                  symbol: 'R\$',
                                ).format(_orcamentoObj.valor)
                              : 'A Combinar',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _infoTile(
                          "CLIENTE",
                          _nomeCliente,
                          Icons.person,
                          corSecundaria,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _infoTile(
                          "TURNO",
                          horario.toUpperCase(),
                          iconHorario,
                          corHorario,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: corCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isConcluido
                            ? corComplementar.withValues(alpha: 0.4)
                            : corAlerta.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isConcluido
                              ? Icons.check_circle
                              : Icons.pending_actions,
                          color: isConcluido ? corComplementar : corAlerta,
                          size: 30,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "SITUAÇÃO DO SERVIÇO",
                              style: TextStyle(
                                color: corTextoCinza,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              isConcluido
                                  ? "ENTREGUE / FINALIZADO"
                                  : "NÃO ENTREGUE / PENDENTE",
                              style: TextStyle(
                                color: isConcluido
                                    ? corComplementar
                                    : corAlerta,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _cardData(
                          "Entrada",
                          _orcamentoObj.dataPega,
                          Icons.calendar_today,
                          Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _cardData(
                          "Entrega",
                          _orcamentoObj.dataEntrega,
                          Icons.event_available,
                          isAtrasado ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _secaoDescricao(_orcamentoObj.descricao),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon, Color color) {
    return Container(
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
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _secaoDescricao(String desc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "DESCRIÇÃO DO SERVIÇO",
            style: TextStyle(
              color: corSecundaria,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const Divider(color: Colors.white10, height: 24),
          Text(
            desc.isNotEmpty ? desc : "Nenhuma descrição.",
            style: TextStyle(
              color: desc.isNotEmpty ? Colors.white70 : Colors.white24,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardData(String label, DateTime? data, IconData icon, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: cor, size: 24),
          Text(
            label.toUpperCase(),
            style: TextStyle(color: corTextoCinza, fontSize: 10),
          ),
          Text(
            data != null ? DateFormat('dd/MM/yyyy').format(data) : '--/--/----',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
