import 'package:flutter/material.dart';
import 'package:minaslar/modelos/Orcamento.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'EditarOrcamento.dart';
import 'DetalhesCliente.dart';
import '../../modelos/Cliente.dart';

// ==================================================
// TELA DE DETALHES DO ORÇAMENTO
// ==================================================
class DetalhesOrcamento extends StatefulWidget {
  final Map<String, dynamic> orcamentoInicial;
  final bool isAdmin;

  const DetalhesOrcamento({
    super.key,
    required this.orcamentoInicial,
    this.isAdmin =
        true, // Padrão para admin para não quebrar chamadas existentes
  });

  @override
  State<DetalhesOrcamento> createState() => _DetalhesOrcamentoState();
}

class _DetalhesOrcamentoState extends State<DetalhesOrcamento> {
  // ==================================================
  // ESTADO E VARIÁVEIS
  // ==================================================
  late Orcamento _orcamentoObj;
  Cliente? _clienteCompleto;
  String _nomeCliente = 'Cliente desconhecido';
  bool _isLoading = false;

  // Paleta de Cores (será definida no initState)
  late Color corPrincipal;
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corTextoClaro = Colors.white;
  final Color corTextoCinza = Colors.grey[400]!;

  @override
  void initState() {
    super.initState();
    // Define a cor principal com base no tipo de usuário
    corPrincipal = widget.isAdmin ? Colors.red[900]! : Colors.blue[900]!;

    _orcamentoObj = Orcamento.fromMap(widget.orcamentoInicial);
    _processarDadosCliente(widget.orcamentoInicial);
    _atualizarDados();
  }

  // ==================================================
  // LÓGICA DE DADOS
  // ==================================================

  /// Processa o mapa do cliente com tratamento de tipos seguro
  void _processarDadosCliente(Map<String, dynamic> map) {
    if (map['clientes'] != null && map['clientes'] is Map) {
      // Cast explícito para Map<String, dynamic> para evitar erro de tipo
      final Map<String, dynamic> dadosCliente = Map<String, dynamic>.from(
        map['clientes'],
      );

      setState(() {
        _nomeCliente = dadosCliente['nome'] ?? 'Sem Nome';
        try {
          if (dadosCliente.containsKey('telefone')) {
            _clienteCompleto = Cliente.fromMap(dadosCliente);
          }
        } catch (e) {
          debugPrint("Erro ao converter cliente: $e");
        }
      });
    }
  }

  /// Busca dados atualizados no Supabase
  Future<void> _atualizarDados() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('orcamentos')
          .select('*, clientes(*)')
          .eq('id', _orcamentoObj.id!)
          .single();

      if (mounted) {
        setState(() {
          _orcamentoObj = Orcamento.fromMap(data);
          _processarDadosCliente(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _alterarStatusEntrega(bool statusAtual) async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('orcamentos')
          .update({'entregue': !statusAtual})
          .eq('id', _orcamentoObj.id!);

      await _atualizarDados();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alterar status: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _excluirOrcamento() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: corCard,
        title: const Text(
          "Excluir Orçamento",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Tem certeza?",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("NÃO"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("SIM", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await Supabase.instance.client
          .from('orcamentos')
          .delete()
          .eq('id', _orcamentoObj.id!);
      if (mounted) Navigator.pop(context, true);
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

  void _navegarDetalhesCliente() {
    if (_clienteCompleto != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetalhesCliente(
            cliente: _clienteCompleto!,
            isAdmin: widget.isAdmin,
          ),
        ),
      ).then((_) => _atualizarDados());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dados do cliente incompletos.")),
      );
    }
  }

  // ==================================================
  // INTERFACE (BUILD)
  // ==================================================
  @override
  Widget build(BuildContext context) {
    // Tratamento de nulos para campos opcionais
    final bool isConcluido = _orcamentoObj.entregue;
    // Garante que horário tenha valor padrão se vier nulo
    final String horario = _orcamentoObj.horarioDoDia;
    final bool isTarde = horario.toLowerCase() == 'tarde';
    final bool ehRetorno = _orcamentoObj.ehRetorno;

    final IconData iconHorario = isTarde
        ? Icons.wb_twilight
        : Icons.wb_sunny_outlined;
    final Color corHorario = isTarde ? Colors.orangeAccent : Colors.amber;

    // Lógica de atraso
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

    // Lógica de valor opcional
    final String textoValor = _orcamentoObj.valor != null
        ? NumberFormat.currency(
            locale: 'pt_BR',
            symbol: 'R\$',
          ).format(_orcamentoObj.valor)
        : 'A Combinar';

    final Color corValor = _orcamentoObj.valor != null
        ? Colors.amber
        : Colors.white54;

    // Lógica de Cor da Borda Lateral (Consistente com a Lista)
    Color corBordaPrincipal;
    if (isConcluido) {
      corBordaPrincipal = Colors.blue; // Concluído
    } else if (ehRetorno) {
      corBordaPrincipal = Colors.green; // Garantia/Retorno
    } else if (isAtrasado) {
      corBordaPrincipal = Colors.redAccent; // Atrasado
    } else if (_orcamentoObj.dataEntrega == null) {
      corBordaPrincipal = Colors.grey; // Sem data definida
    } else {
      corBordaPrincipal = Colors.orange; // Em andamento
    }

    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: const Text("Detalhes do Orçamento"),
        backgroundColor: corPrincipal,
        centerTitle: true,
        actions: widget.isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _excluirOrcamento,
                ),
              ]
            : [],
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              backgroundColor: corPrincipal,
              foregroundColor: Colors.white,
              onPressed: _navegarEditar,
              child: const Icon(Icons.edit),
            )
          : null,
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
                        left: BorderSide(color: corBordaPrincipal, width: 6),
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
                            decoration: isConcluido
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (widget.isAdmin) ...[
                          const Text(
                            "VALOR DO ORÇAMENTO",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            textoValor,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: corValor,
                            ),
                          ),
                        ] else ...[
                          const Text(
                            "DESCRIÇÃO DO SERVIÇO",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (_orcamentoObj.descricao != null &&
                                    _orcamentoObj.descricao!.isNotEmpty)
                                ? _orcamentoObj.descricao!
                                : "Nenhuma descrição informada.",
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              color:
                                  (_orcamentoObj.descricao != null &&
                                      _orcamentoObj.descricao!.isNotEmpty)
                                  ? Colors.white70
                                  : Colors.white24,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // BOTÃO CLIENTE E TURNO
                  Row(
                    children: [
                      Expanded(flex: 3, child: _buildBotaoCliente()),
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

                  // STATUS
                  _buildStatusCard(isConcluido, ehRetorno),
                  const SizedBox(height: 20),

                  // DATAS
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

                  // DESCRIÇÃO (Agora aceita null e trata corretamente)
                  if (widget.isAdmin)
                    _secaoDescricao(_orcamentoObj.descricao, ehRetorno),

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  // ==================================================
  // WIDGETS AUXILIARES
  // ==================================================

  Widget _buildBotaoCliente() {
    return InkWell(
      onTap: _navegarDetalhesCliente,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: corCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(Icons.person, color: corPrincipal),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "CLIENTE",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    _nomeCliente,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
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
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// CORREÇÃO: Parâmetro `desc` agora é `String?` para aceitar nulos
  Widget _secaoDescricao(String? desc, bool ehRetorno) {
    final temDescricao = desc != null && desc.isNotEmpty;

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
          Row(
            children: [
              Icon(
                ehRetorno ? Icons.history : Icons.description_outlined,
                color: ehRetorno ? Colors.amber : Colors.blue[300],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                ehRetorno
                    ? "SERVIÇO DE GARANTIA/RETORNO"
                    : "DESCRIÇÃO DO SERVIÇO",
                style: TextStyle(
                  color: ehRetorno ? Colors.amber : Colors.blue[300],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          Text(
            temDescricao ? desc : "Nenhuma descrição informada.",
            style: TextStyle(
              color: temDescricao ? Colors.white70 : Colors.white24,
              fontSize: 16,
              fontStyle: temDescricao ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardData(String label, DateTime? data, IconData icon, Color cor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: cor),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          Text(
            data != null ? DateFormat('dd/MM').format(data) : '--/--',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isConcluido, bool ehRetorno) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isConcluido) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outline;
      statusText = "CONCLUÍDO";
    } else if (ehRetorno) {
      statusColor = Colors.amber;
      statusIcon = Icons.history;
      statusText = "GARANTIA";
    } else {
      statusColor = Colors.orangeAccent;
      statusIcon = Icons.hourglass_top;
      statusText = "PENDENTE";
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.isAdmin) ...[
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: corCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: IconButton(
              icon: const Icon(Icons.update, color: Colors.white54),
              tooltip: "Alterar Status",
              onPressed: () => _alterarStatusEntrega(isConcluido),
            ),
          ),
        ],
      ],
    );
  }
}
