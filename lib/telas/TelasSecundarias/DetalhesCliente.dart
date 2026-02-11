import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../servicos/servicosGoogle.dart';
import '../../modelos/Cliente.dart';
import 'adicionarOrcamento.dart';
import 'EditarCliente.dart';
import 'EditarOrcamento.dart';

// ===========================================================================
// TELA DE DETALHES DO CLIENTE
// ===========================================================================
class DetalhesCliente extends StatefulWidget {
  final Cliente cliente;
  final bool isAdmin;

  const DetalhesCliente({
    super.key,
    required this.cliente,
    this.isAdmin = false, // Padrão admin
  });

  @override
  State<DetalhesCliente> createState() => _DetalhesClienteState();
}

class _DetalhesClienteState extends State<DetalhesCliente> {
  late Cliente _clienteExibido;

  // ===========================================================================
  // PALETA DE CORES E ESTILOS
  // ===========================================================================
  late Color corPrincipal;
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corTextoClaro = Colors.white;
  final Color corTextoCinza = Colors.grey[400]!;
  late Color corSecundaria;

  // Adiciona o formatador de máscara para exibir o telefone formatado
  final maskTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================
  @override
  void initState() {
    super.initState();
    corPrincipal = widget.isAdmin ? Colors.red[900]! : Colors.blue[900]!;
    corSecundaria = widget.isAdmin ? Colors.blue[300]! : Colors.cyan[400]!;
    _clienteExibido = widget.cliente;
  }

  // ===========================================================================
  // LÓGICA DE NEGÓCIO E SUPABASE
  // ===========================================================================

  /// Exclui o cliente e todos os seus dados associados.
  /// Exclui o cliente e todos os seus dados associados.
  Future<void> _excluirCliente() async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: corCard,
          title: const Text(
            'Confirmar Exclusão',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Tem certeza que deseja excluir o cliente "${_clienteExibido.nome}"? Todos os orçamentos vinculados também serão removidos. Esta ação não pode ser desfeita.',
            style: TextStyle(color: Colors.grey[300]),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Excluir',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      try {
        await Supabase.instance.client
            .from('clientes')
            .delete()
            .eq('id', _clienteExibido.id as Object);

        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text("Cliente excluído com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
        navigator.pop(true);
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("Erro ao excluir cliente: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

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

  /// Copia o texto para a área de transferência e avisa o usuário
  void _copiarParaClipboard(String texto, String item) {
    if (texto.isEmpty) return;

    Clipboard.setData(ClipboardData(text: texto));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$item copiado com sucesso!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Widget auxiliar para criar os cards de info (Endereço, CPF, etc)
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return Card(
      elevation: 0,
      color: corCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withValues(alpha: 0.2),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? corSecundaria, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        color: corTextoCinza,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(color: corTextoClaro, fontSize: 16),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                IconButton(
                  onPressed: onTap,
                  icon: const Icon(Icons.map_outlined),
                  color: Colors.blueAccent,
                  tooltip: 'Abrir no Mapa',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MÉTODOS AUXILIARES DE UI (ADICIONE ISTO À SUA CLASSE)
  // ===========================================================================
  Widget _buildOrcamentoItem(
    Map<String, dynamic> orcamento,
    List<Map<String, dynamic>> listaOrcamentos,
  ) {
    // 1. Extração de dados
    final titulo = orcamento['titulo'] ?? 'Serviço';
    final descricao = orcamento['descricao'] ?? 'Sem descrição';
    final valor = orcamento['valor'];

    // Tratamento de datas
    final dataPegaString = orcamento['data_pega'];
    final dataPega = dataPegaString != null
        ? DateTime.parse(dataPegaString)
        : DateTime.now();

    final dataEntregaString = orcamento['data_entrega'];
    final dataEntregaFormatada = dataEntregaString != null
        ? DateFormat('dd/MM').format(DateTime.parse(dataEntregaString))
        : '--/--'; // Mostra traços se não tiver data de entrega

    // Lógica de Destaque
    final bool isUltimo = listaOrcamentos.indexOf(orcamento) == 0;
    final bool isProblematico = _clienteExibido.clienteProblematico;

    final Color corDestaqueItem = isUltimo
        ? (isProblematico ? Colors.redAccent : Colors.greenAccent)
        : Colors.grey;

    final Color corFundoIcone = isUltimo
        ? (isProblematico
              ? Colors.red.withValues(alpha: 0.2)
              : Colors.green.withValues(alpha: 0.2))
        : Colors.black26;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(12),
        border: isUltimo
            ? Border.all(color: corDestaqueItem.withValues(alpha: 0.5))
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        isThreeLine: true,

        // Ícone Lateral
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
                isUltimo ? Icons.new_releases : Icons.build_circle_outlined,
                color: isUltimo ? corDestaqueItem : corTextoCinza,
                size: 20,
              ),
            ),
          ],
        ),

        // Título e Menu
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isUltimo ? corDestaqueItem : corTextoClaro,
                ),
              ),
            ),
            if (widget.isAdmin)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: corTextoCinza),
                color: corCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onSelected: (String choice) {
                  if (choice == 'editar') {
                    _editarOrcamento(orcamento);
                  } else if (choice == 'excluir') {
                    _confirmarExclusao(context, orcamento);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue, size: 18),
                        SizedBox(width: 8),
                        Text('Editar', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'excluir',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Excluir', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),

        // Descrição e Rodapé (Datas e Valor)
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Descrição
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                descricao,
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 12),

            // --- RODAPÉ: DATAS E VALOR ---
            Row(
              children: [
                // 1. Data de Entrada
                Icon(Icons.calendar_today, size: 14, color: corTextoCinza),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM').format(dataPega),
                  style: TextStyle(color: corTextoCinza, fontSize: 13),
                ),

                // 2. Seta e Data de Entrega (NOVO)
                const SizedBox(width: 6),
                Icon(Icons.arrow_right_alt, size: 16, color: corTextoCinza),
                const SizedBox(width: 6),
                Text(
                  dataEntregaFormatada,
                  style: TextStyle(
                    // Se tiver data de entrega definida, fica branco, senão cinza
                    color: dataEntregaString != null
                        ? Colors.white
                        : corTextoCinza,
                    fontSize: 13,
                    fontWeight: dataEntregaString != null
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),

                const Spacer(), // Empurra o valor para a direita
                // 3. Valor
                if (widget.isAdmin) ...[
                  Icon(
                    Icons.monetization_on_outlined,
                    size: 14,
                    color: valor != null ? Colors.amber : corTextoCinza,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    valor != null
                        ? "R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '').format(valor)}"
                        : "A combinar",
                    style: TextStyle(
                      color: valor != null ? Colors.amber : corTextoCinza,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Abre o Google Maps com o endereço do cliente.
  Future<void> _abrirGoogleMaps() async {
    final String rua = _clienteExibido.rua;
    final String numero = _clienteExibido.numero;
    final String? apto = _clienteExibido.apartamento;
    final String bairro = _clienteExibido.bairro;
    const String cidade = "Juiz de Fora"; // Assumindo cidade padrão

    // Constrói o endereço completo para a busca no mapa
    final String enderecoCompleto = [
      rua,
      numero,
      if (apto != null && apto.isNotEmpty) 'Apto $apto',
      bairro,
      cidade,
    ].where((s) => s.isNotEmpty).join(', ');

    if (rua.isEmpty && bairro.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Endereço do cliente não disponível.')),
        );
      }
      return;
    }

    // Codifica o endereço para ser usado na URL
    final Uri googleMapsUri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(enderecoCompleto)}",
    );

    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o Google Maps.'),
          ),
        );
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
    final Color corComplementar = Colors.green[400]!;
    const Color corAlerta = Colors.redAccent;
    final Color corStatusAtual = isProblematico ? corAlerta : corComplementar;

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
        actions: widget.isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
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
              ]
            : [],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      // -- BOTÃO FLUTUANTE (ADICIONAR) --
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              backgroundColor: corPrincipal,
              foregroundColor: Colors.white,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
            )
          : null,
      body: RefreshIndicator(
        color: corPrincipal,
        backgroundColor: corCard,
        onRefresh: _atualizarTela,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CARD DE CABEÇALHO DO CLIENTE
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: corCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border(
                    left: BorderSide(color: corStatusAtual, width: 6),
                  ),
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
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: corStatusAtual.withValues(
                            alpha: 0.15,
                          ),
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
                                      color: Colors.red.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.redAccent,
                                      ),
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
                        if (widget.isAdmin)
                          IconButton(
                            icon: const Icon(Icons.delete_forever_outlined),
                            color: corAlerta,
                            iconSize: 28,
                            tooltip: 'Excluir Cliente',
                            onPressed: _excluirCliente,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              if (_clienteExibido.telefone.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: corCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      splashColor: Colors.white.withValues(alpha: 0.2),
                      highlightColor: Colors.white.withValues(alpha: 0.1),
                      onLongPress: () => _copiarParaClipboard(
                        _clienteExibido.telefone,
                        'Telefone',
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone_android,
                              color: corSecundaria,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "TELEFONE",
                                    style: TextStyle(
                                      color: corTextoCinza,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    maskTelefone.maskText(
                                      _clienteExibido.telefone,
                                    ),
                                    style: TextStyle(
                                      color: corTextoClaro,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => Servicos.fazerLigacao(
                                    _clienteExibido.telefone,
                                  ),
                                  tooltip: 'Ligar',
                                  icon: const Icon(
                                    Icons.phone,
                                    color: Colors.white,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => Servicos.abrirWhatsApp(
                                    _clienteExibido.telefone,
                                  ),
                                  tooltip: 'WhatsApp',
                                  icon: const Icon(
                                    Icons.chat,
                                    color: Colors.greenAccent,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.green.withValues(
                                      alpha: 0.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              if (_clienteExibido.rua.isNotEmpty ||
                  _clienteExibido.bairro.isNotEmpty)
                _buildInfoCard(
                  icon: Icons.location_on_outlined,
                  label: "Endereço",
                  value: ([
                    [
                      _clienteExibido.rua,
                      _clienteExibido.numero,
                      if (_clienteExibido.apartamento?.isNotEmpty ?? false)
                        'Apto: ${_clienteExibido.apartamento!}',
                    ].where((s) => s.isNotEmpty).join(', '),
                    _clienteExibido.bairro,
                  ].where((s) => s.isNotEmpty).join(' - ')),
                  onTap: _abrirGoogleMaps,
                  onLongPress: () {
                    final String enderecoCompleto = ([
                      [
                        _clienteExibido.rua,
                        _clienteExibido.numero,
                        if (_clienteExibido.apartamento?.isNotEmpty ?? false)
                          'Apto: ${_clienteExibido.apartamento!}',
                      ].where((s) => s.isNotEmpty).join(', '),
                      _clienteExibido.bairro,
                    ].where((s) => s.isNotEmpty).join(' - '));
                    _copiarParaClipboard(enderecoCompleto, 'Endereço');
                  },
                ),

              if (_clienteExibido.cpf != null &&
                  _clienteExibido.cpf!.isNotEmpty)
                _buildInfoCard(
                  icon: Icons.badge_outlined,
                  label: "CPF",
                  value: _clienteExibido.cpf!,
                  onLongPress: () =>
                      _copiarParaClipboard(_clienteExibido.cpf!, 'CPF'),
                ),

              if (_clienteExibido.cnpj != null &&
                  _clienteExibido.cnpj!.isNotEmpty)
                _buildInfoCard(
                  icon: Icons.domain,
                  label: "CNPJ",
                  value: _clienteExibido.cnpj!,
                  onLongPress: () =>
                      _copiarParaClipboard(_clienteExibido.cnpj!, 'CNPJ'),
                ),

              if (_clienteExibido.observacao != null &&
                  _clienteExibido.observacao!.isNotEmpty)
                _buildInfoCard(
                  icon: Icons.comment_outlined,
                  label: "Observações",
                  value: _clienteExibido.observacao!,
                  iconColor: Colors.grey,
                ),

              const SizedBox(height: 20),

              // Título da Lista de Orçamentos
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
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

              // LISTA DE ORÇAMENTOS (Mantida igual, apenas colada aqui para completar)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client
                    .from('orcamentos')
                    .stream(primaryKey: ['id'])
                    .eq('cliente_id', _clienteExibido.id as Object)
                    .order('data_pega', ascending: false),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    );
                  }
                  final listaOrcamentos = snapshot.data!;
                  if (listaOrcamentos.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(30),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 40,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Nenhum orçamento registrado.",
                            style: TextStyle(color: corTextoCinza),
                          ),
                        ],
                      ),
                    );
                  }
                  // ... (Lógica de renderização dos itens da lista continua igual)
                  return Column(
                    children: listaOrcamentos.map((orcamento) {
                      return _buildOrcamentoItem(
                        orcamento,
                        listaOrcamentos,
                      ); // Exemplo de refatoração
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
