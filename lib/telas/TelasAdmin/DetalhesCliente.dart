import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
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
            ),
          ],
        ),
      ),
    );
  }

  /// Abre o discador do celular com o número do cliente.
  Future<void> _ligarParaCliente() async {
    if (_clienteExibido.telefone.isEmpty) return;

    // Garante que o número esteja limpo, removendo formatação (parênteses, traços, etc.)
    final String numeroLimpo = _clienteExibido.telefone.replaceAll(
      RegExp(r'[^\d]'),
      '',
    );
    final Uri telUri = Uri(scheme: 'tel', path: numeroLimpo);

    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o discador.')),
        );
      }
    }
  }

  /// Abre o WhatsApp com o número do cliente
  Future<void> _abrirWhatsApp() async {
    if (_clienteExibido.telefone.isEmpty) return;

    // 1. Limpa o número (remove parênteses, traços, espaços)
    var numeroLimpo = _clienteExibido.telefone.replaceAll(RegExp(r'[^\d]'), '');

    // 2. Verifica se precisa adicionar o código do Brasil (55)
    // Se o número tiver 10 ou 11 dígitos (DDD + Número), adicionamos 55.
    if (numeroLimpo.length >= 10 && !numeroLimpo.startsWith('55')) {
      numeroLimpo = '55$numeroLimpo';
    }

    // 3. Cria a URL (usando https://wa.me para compatibilidade universal)
    final Uri whatsappUri = Uri.parse("https://wa.me/$numeroLimpo");

    // 4. Tenta abrir
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  /// Abre o Google Maps com o endereço do cliente.
  Future<void> _abrirGoogleMaps() async {
    final String rua = _clienteExibido.rua;
    final String numero = _clienteExibido.numero;
    final String bairro = _clienteExibido.bairro;
    const String cidade = "Juiz de Fora"; // Assumindo cidade padrão

    // Constrói o endereço completo para a busca no mapa
    final String enderecoCompleto = "$rua, $numero - $bairro, $cidade";

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

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // ===========================================================================
  // INTERFACE DO USUÁRIO (UI)
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    // Definição de status visual (Cliente problemático ou Normal)
    final bool isProblematico = _clienteExibido.clienteProblematico;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar Cliente',
            onPressed: () async {
              final bool? atualizou = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditarCliente(cliente: _clienteExibido),
                ),
              );
              if (atualizou == true) _atualizarTela();
            },
          ),
        ],
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
              // ===============================================================
              // BLOCO ÚNICO: INFORMAÇÕES DO CLIENTE (CORRIGIDO)
              // ===============================================================
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                // Removemos o padding daqui e passamos para dentro (para não afastar a barra lateral)
                decoration: BoxDecoration(
                  color: corCard,
                  borderRadius: BorderRadius.circular(16),
                  // Removemos a propriedade 'border' que causava o erro
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                // Clip.antiAlias garante que a barra lateral respeite o arredondamento do Container
                clipBehavior: Clip.antiAlias,
                child: IntrinsicHeight(
                  // Garante que a barra lateral estique a altura toda
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. A BARRA LATERAL COLORIDA (Simulando a borda esquerda)
                      Container(width: 6, color: corStatusAtual),

                      // 2. O CONTEÚDO DO CARD
                      Expanded(
                        child: Container(
                          // Adicionamos as bordas finas apenas internamente ou removemos para simplificar
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                              right: BorderSide(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                              bottom: BorderSide(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.all(
                            20,
                          ), // Padding do conteúdo
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- TÍTULO DA SEÇÃO ---
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    color: corTextoCinza,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "INFORMAÇÕES DO CLIENTE",
                                    style: TextStyle(
                                      color: corTextoCinza,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // --- 1. CABEÇALHO (Avatar + Nome) ---
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: corStatusAtual.withValues(
                                      alpha: 0.15,
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: corStatusAtual,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _clienteExibido.nome,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: corTextoClaro,
                                          ),
                                        ),
                                        if (_clienteExibido.clienteProblematico)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withValues(
                                                  alpha: 0.2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: Colors.redAccent
                                                      .withValues(alpha: 0.5),
                                                ),
                                              ),
                                              child: const Text(
                                                "PROBLEMÁTICO",
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),
                              const Divider(color: Colors.white10),
                              const SizedBox(height: 16),

                              // --- 2. TELEFONE & AÇÕES ---
                              if (_clienteExibido.telefone.isNotEmpty) ...[
                                Text(
                                  "CONTATO",
                                  style: TextStyle(
                                    color: corTextoCinza,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        maskTelefone.maskText(
                                          _clienteExibido.telefone,
                                        ),
                                        style: TextStyle(
                                          color: corTextoClaro,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        _buildActionButton(
                                          Icons.phone,
                                          Colors.white,
                                          _ligarParaCliente,
                                        ),
                                        const SizedBox(width: 12),
                                        _buildActionButton(
                                          Icons.chat,
                                          Colors.greenAccent,
                                          _abrirWhatsApp,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(color: Colors.white10),
                                const SizedBox(height: 16),
                              ],

                              // --- 3. ENDEREÇO ---
                              if (_clienteExibido.rua.isNotEmpty ||
                                  _clienteExibido.bairro.isNotEmpty) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      color: corSecundaria,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "ENDEREÇO",
                                            style: TextStyle(
                                              color: corTextoCinza,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            [
                                                  _clienteExibido.rua,
                                                  _clienteExibido.numero,
                                                  _clienteExibido.bairro,
                                                ]
                                                .where((s) => s.isNotEmpty)
                                                .join(', '),
                                            style: TextStyle(
                                              color: corTextoClaro,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.map,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      onPressed: _abrirGoogleMaps,
                                      tooltip: "Abrir no Mapa",
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(color: Colors.white10),
                                const SizedBox(height: 16),
                              ],

                              // --- 4. DOCUMENTOS ---
                              if ((_clienteExibido.cpf != null &&
                                      _clienteExibido.cpf!.isNotEmpty) ||
                                  (_clienteExibido.cnpj != null &&
                                      _clienteExibido.cnpj!.isNotEmpty)) ...[
                                Row(
                                  children: [
                                    Icon(
                                      Icons.badge_outlined,
                                      color: corSecundaria,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "DOCUMENTO",
                                            style: TextStyle(
                                              color: corTextoCinza,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _clienteExibido.cpf?.isNotEmpty ==
                                                    true
                                                ? "CPF: ${_clienteExibido.cpf}"
                                                : "CNPJ: ${_clienteExibido.cnpj}",
                                            style: TextStyle(
                                              color: corTextoClaro,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(color: Colors.white10),
                                const SizedBox(height: 16),
                              ],

                              // --- 5. OBSERVAÇÕES ---
                              if (_clienteExibido.observacao != null &&
                                  _clienteExibido.observacao!.isNotEmpty) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.notes,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "OBSERVAÇÕES",
                                            style: TextStyle(
                                              color: corTextoCinza,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _clienteExibido.observacao!,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ===============================================================
              // FIM DO BLOCO DE INFORMAÇÕES
              // ===============================================================

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
                      // ... (Seu código de build do Card de Orçamento aqui)
                      // Para economizar espaço na resposta, assumo que você mantém
                      // o código do `ListTile` do orçamento que já estava funcionando.
                      // Se precisar dele, me avise!
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
