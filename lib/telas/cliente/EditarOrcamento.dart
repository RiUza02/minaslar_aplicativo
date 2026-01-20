import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tela responsável pela edição de um orçamento existente.
/// Recebe um Map com os dados do orçamento para pré-popular os campos.
class EditarOrcamento extends StatefulWidget {
  final Map<String, dynamic> orcamento;

  const EditarOrcamento({super.key, required this.orcamento});

  @override
  State<EditarOrcamento> createState() => _EditarOrcamentoState();
}

class _EditarOrcamentoState extends State<EditarOrcamento> {
  // ===========================================================================
  // VARIÁVEIS DE ESTADO E CONTROLADORES
  // ===========================================================================

  /// Chave global para validação do formulário
  final _formKey = GlobalKey<FormState>();

  /// Controladores de texto para os campos do formulário
  late TextEditingController _tituloController;
  late TextEditingController _descricaoController;
  late TextEditingController _valorController;

  /// Data de entrada do serviço (Obrigatória, padrão: agora ou vinda do banco)
  late DateTime _dataServico;

  /// Data de previsão de entrega (Opcional)
  DateTime? _dataEntrega;

  /// Controla o estado de carregamento durante o salvamento
  bool _isLoading = false;

  // ===========================================================================
  // PALETA DE CORES
  // ===========================================================================

  final Color corPrincipal = Colors.red[900]!;
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corTextoClaro = Colors.white;
  final Color corTextoCinza = Colors.grey[400]!;

  @override
  void initState() {
    super.initState();

    // Inicializa o Título com valor existente ou vazio
    _tituloController = TextEditingController(
      text: widget.orcamento['titulo'] ?? '',
    );

    // Inicializa a Descrição
    _descricaoController = TextEditingController(
      text: widget.orcamento['descricao'] ?? '',
    );

    // Inicializa o Valor convertendo para string
    final valor = widget.orcamento['valor'];
    _valorController = TextEditingController(text: valor?.toString() ?? '');

    // Carrega a Data do Serviço (data_pega)
    final dataServicoString = widget.orcamento['data_pega'];
    _dataServico = dataServicoString != null
        ? DateTime.parse(dataServicoString)
        : DateTime.now();

    // Carrega a Data de Entrega (se existir no banco)
    final dataEntregaString = widget.orcamento['data_entrega'];
    _dataEntrega = dataEntregaString != null
        ? DateTime.parse(dataEntregaString)
        : null;
  }

  @override
  void dispose() {
    // Libera os recursos dos controladores ao fechar a tela
    _tituloController.dispose();
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // LÓGICA DE NEGÓCIO
  // ===========================================================================

  /// Valida o formulário e envia os dados atualizados para o Supabase
  Future<void> _salvarEdicao() async {
    // Verifica se os campos obrigatórios estão preenchidos
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Converte o valor monetário, aceitando vírgula como separador decimal
      final double? valorConvertido = double.tryParse(
        _valorController.text.replaceAll(',', '.'),
      );

      // Atualiza o registro na tabela 'orcamentos'
      await Supabase.instance.client
          .from('orcamentos')
          .update({
            'titulo': _tituloController.text.trim(),
            'descricao': _descricaoController.text.trim(),
            'valor': valorConvertido,
            'data_pega': _dataServico.toIso8601String(),
            'data_entrega': _dataEntrega?.toIso8601String(), // Permite null
          })
          .eq('id', widget.orcamento['id']);

      if (mounted) {
        // Exibe feedback de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orçamento atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        // Fecha a tela retornando 'true' para indicar que houve atualização
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        // Exibe feedback de erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Abre o seletor de data para Entrada ou Entrega
  Future<void> _selecionarData({required bool isEntrega}) async {
    // Define a data inicial baseada em qual campo foi clicado
    final initialDate = isEntrega
        ? (_dataEntrega ?? DateTime.now())
        : _dataServico;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        // Customiza o tema do DatePicker para dark mode
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: corPrincipal,
              onPrimary: Colors.white,
              surface: corCard,
              onSurface: Colors.white,
            ),
            dialogTheme: DialogThemeData(backgroundColor: corCard),
          ),
          child: child!,
        );
      },
    );

    // Atualiza o estado apenas se uma data for selecionada
    if (picked != null) {
      setState(() {
        if (isEntrega) {
          _dataEntrega = picked;
        } else {
          _dataServico = picked;
        }
      });
    }
  }

  // ===========================================================================
  // INTERFACE (UI)
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: const Text(
          "Editar Orçamento",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),

      // Botão de salvar fixo na parte inferior
      bottomNavigationBar: Container(
        color: corCard,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: corPrincipal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            onPressed: _isLoading ? null : _salvarEdicao,
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    "SALVAR ALTERAÇÕES",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ============================================================
              // BLOCO 1: DADOS DO SERVIÇO (Título e Descrição)
              // ============================================================
              _buildBlock(
                children: [
                  _tituloCampo("Título do Serviço"),
                  TextFormField(
                    controller: _tituloController,
                    style: TextStyle(color: corTextoClaro),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Informe um título'
                        : null,
                    decoration: _inputDecoration("Ex: Formatação", Icons.title),
                  ),
                  const SizedBox(height: 20),
                  _tituloCampo("Descrição do Serviço"),
                  TextFormField(
                    controller: _descricaoController,
                    maxLines: 3,
                    style: TextStyle(color: corTextoClaro),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Obrigatório' : null,
                    decoration: _inputDecoration(
                      "Ex: Troca de tela",
                      Icons.description_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ============================================================
              // BLOCO 2: FINANCEIRO (Valor)
              // ============================================================
              _buildBlock(
                children: [
                  _tituloCampo("Valor (R\$)"),
                  TextFormField(
                    controller: _valorController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(color: corTextoClaro),
                    decoration: _inputDecoration(
                      "0.00",
                      Icons.monetization_on_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ============================================================
              // BLOCO 3: PRAZOS (Datas)
              // ============================================================
              _buildBlock(
                children: [
                  _tituloCampo("Data de Entrada (Serviço)"),
                  _botaoData(
                    icon: Icons.calendar_today,
                    texto: DateFormat('dd/MM/yyyy').format(_dataServico),
                    onTap: () => _selecionarData(isEntrega: false),
                  ),
                  const SizedBox(height: 20),
                  _tituloCampo("Data de Entrega / Previsão"),
                  _botaoData(
                    icon: Icons.event_available,
                    texto: _dataEntrega != null
                        ? DateFormat('dd/MM/yyyy').format(_dataEntrega!)
                        : "Definir data de entrega...",
                    corTexto: _dataEntrega != null
                        ? corTextoClaro
                        : Colors.white54,
                    onTap: () => _selecionarData(isEntrega: true),
                  ),

                  // Botão opcional para remover a data de entrega
                  if (_dataEntrega != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => setState(() => _dataEntrega = null),
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          label: const Text(
                            "Remover Data de Entrega",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget auxiliar para construir os blocos (cards) de conteúdo
  Widget _buildBlock({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  /// Widget auxiliar para exibir o rótulo acima dos campos
  Widget _tituloCampo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(texto, style: TextStyle(color: corTextoCinza, fontSize: 14)),
    );
  }

  /// Widget auxiliar para criar botões simulando campos de data
  Widget _botaoData({
    required IconData icon,
    required String texto,
    required VoidCallback onTap,
    Color? corTexto,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black26, // Ligeiramente mais escuro dentro do card
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: corTextoCinza, size: 20),
            const SizedBox(width: 12),
            Text(
              texto,
              style: TextStyle(color: corTexto ?? corTextoClaro, fontSize: 16),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  /// Estilo padrão dos inputs do formulário
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      prefixIcon: Icon(icon, color: corTextoCinza),
      filled: true,
      fillColor: Colors.black26, // Ajustado para contraste dentro do card
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: corPrincipal, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }
}
