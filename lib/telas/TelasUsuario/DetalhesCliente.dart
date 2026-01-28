import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../modelos/Cliente.dart';

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
  final Color corPrincipal = Colors.blue[900]!;
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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
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
                    // Cabeçalho do Card (Avatar, Nome, Status)
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
                      ],
                    ),
                  ],
                ),
              ),

              // --- CARD DE TELEFONE COM WHATSAPP ---
              if (_clienteExibido.telefone.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: corCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
                        // Ícone e Texto (Esquerda)
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
                                maskTelefone.maskText(_clienteExibido.telefone),
                                style: TextStyle(
                                  color: corTextoClaro,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Botões de Ação (Direita)
                        Row(
                          children: [
                            // Botão Ligar
                            IconButton(
                              onPressed: _ligarParaCliente,
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
                            // Botão WhatsApp
                            IconButton(
                              onPressed: _abrirWhatsApp,
                              tooltip: 'WhatsApp',
                              icon: const Icon(
                                Icons.chat, // Ou Icons.message
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

              // --- FIM DO CARD TELEFONE ---
              if (_clienteExibido.rua.isNotEmpty ||
                  _clienteExibido.bairro.isNotEmpty)
                _buildInfoCard(
                  icon: Icons.location_on_outlined,
                  label: "Endereço",
                  value: [
                    _clienteExibido.rua,
                    _clienteExibido.numero,
                    _clienteExibido.bairro,
                  ].where((s) => s.isNotEmpty).join(', '),
                  onTap: _abrirGoogleMaps, // Adiciona a ação de abrir o mapa
                ),

              if (_clienteExibido.cpf != null &&
                  _clienteExibido.cpf!.isNotEmpty)
                _buildInfoCard(
                  icon: Icons.badge_outlined,
                  label: "CPF",
                  value: _clienteExibido.cpf!,
                ),

              if (_clienteExibido.cnpj != null &&
                  _clienteExibido.cnpj!.isNotEmpty)
                _buildInfoCard(
                  icon: Icons.domain,
                  label: "CNPJ",
                  value: _clienteExibido.cnpj!,
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

              // Título da Lista
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
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

              // LISTA DE ORÇAMENTOS (STREAM)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client
                    .from('orcamentos')
                    .stream(primaryKey: ['id'])
                    .eq('cliente_id', _clienteExibido.id as Object)
                    .order('data_pega', ascending: false),
                builder: (context, snapshot) {
                  // Loading State
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    );
                  }

                  final listaOrcamentos = snapshot.data!;

                  if (listaOrcamentos.isEmpty) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.2,
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
                    );
                  }

                  return Column(
                    children: listaOrcamentos.map((orcamento) {
                      // Extração de dados do Mapa
                      final titulo = orcamento['titulo'] ?? 'Serviço';
                      final descricao =
                          orcamento['descricao'] ?? 'Sem descrição';
                      final dataPegaString = orcamento['data_pega'];
                      final dataPega = dataPegaString != null
                          ? DateTime.parse(dataPegaString)
                          : DateTime.now();

                      final dataEntregaString = orcamento['data_entrega'];
                      final dataEntregaFormatada = dataEntregaString != null
                          ? DateFormat(
                              'dd/MM',
                            ).format(DateTime.parse(dataEntregaString))
                          : '--/--';

                      // Destaque visual para o item mais recente
                      final bool isUltimo =
                          listaOrcamentos.indexOf(orcamento) == 0;
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
                                  color: corDestaqueItem.withValues(alpha: 0.5),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Padding(
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
                                crossAxisAlignment: WrapCrossAlignment.center,
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
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
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

  // ===========================================================================
  // WIDGETS AUXILIARES
  // ===========================================================================
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      color: corCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                Icon(Icons.launch, color: corTextoCinza, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
