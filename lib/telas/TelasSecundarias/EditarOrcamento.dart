import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==================================================
// TELA DE EDIÇÃO DE ORÇAMENTO
// ==================================================
class EditarOrcamento extends StatefulWidget {
  /// Recebe um Map com os dados do orçamento a ser editado
  final Map<String, dynamic> orcamento;

  const EditarOrcamento({super.key, required this.orcamento});

  @override
  State<EditarOrcamento> createState() => _EditarOrcamentoState();
}

class _EditarOrcamentoState extends State<EditarOrcamento> {
  // ==================================================
  // VARIÁVEIS DE ESTADO E CONTROLADORES
  // ==================================================

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  /// Controladores de texto para manipulação do formulário
  late TextEditingController _tituloController;
  late TextEditingController _descricaoController;
  late TextEditingController _valorController;

  /// Variáveis de controle de datas e status
  late DateTime _dataServico;
  DateTime? _dataEntrega;
  late String _horarioSelecionado;
  late bool _foiEntregue;
  late bool _ehRetorno;

  // ==================================================
  // DEFINIÇÃO DE CORES E TEMA LOCAL
  // ==================================================

  final Color corPrincipal = Colors.red[900]!;
  final Color corAlerta = Colors.redAccent;
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corTextoClaro = Colors.white;
  final Color corTextoCinza = Colors.grey[400]!;

  // ==================================================
  // CICLO DE VIDA (INIT & DISPOSE)
  // ==================================================

  @override
  void initState() {
    super.initState();

    // Inicializa os controladores com os dados vindos da tela anterior
    _tituloController = TextEditingController(
      text: widget.orcamento['titulo'] ?? '',
    );
    _descricaoController = TextEditingController(
      text: widget.orcamento['descricao'] ?? '',
    );

    final valor = widget.orcamento['valor'];
    _valorController = TextEditingController(text: valor?.toString() ?? '');

    // Parse das datas armazenadas como String no banco
    final dataServicoString = widget.orcamento['data_pega'];
    _dataServico = dataServicoString != null
        ? DateTime.parse(dataServicoString)
        : DateTime.now();

    final dataEntregaString = widget.orcamento['data_entrega'];
    _dataEntrega = dataEntregaString != null
        ? DateTime.parse(dataEntregaString)
        : null;

    // Inicializa status e horário
    _horarioSelecionado = widget.orcamento['horario_do_dia'] ?? 'Manhã';
    _foiEntregue = widget.orcamento['entregue'] ?? false;
    _ehRetorno = widget.orcamento['eh_retorno'] ?? false;
  }

  @override
  void dispose() {
    // Libera recursos dos controladores ao fechar a tela
    _tituloController.dispose();
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  // ==================================================
  // LÓGICA DE NEGÓCIO (SUPABASE)
  // ==================================================

  Future<void> _salvarEdicao() async {
    // 1. Validação do formulário
    if (!_formKey.currentState!.validate()) return;

    // Validação extra: Data de entrega não pode ser anterior à de entrada
    if (_dataEntrega != null &&
        _dataEntrega!.isBefore(DateUtils.dateOnly(_dataServico))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A data de entrega não pode ser anterior à de entrada.',
            ),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Conversão e tratamento do valor monetário (troca vírgula por ponto)
      final double? valorConvertido = double.tryParse(
        _valorController.text.replaceAll(',', '.'),
      );

      // 3. Atualização no banco de dados
      await Supabase.instance.client
          .from('orcamentos')
          .update({
            'titulo': _tituloController.text.trim(),
            'descricao': _descricaoController.text.trim(),
            'valor': valorConvertido,
            'data_pega': _dataServico.toIso8601String(),
            'data_entrega': _dataEntrega?.toIso8601String(), // Pode ser null
            'horario_do_dia': _horarioSelecionado,
            'entregue': _foiEntregue,
            'eh_retorno': _ehRetorno,
          })
          .eq('id', widget.orcamento['id']);

      if (mounted) {
        // 4. Feedback de sucesso e retorno
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orçamento atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        // 5. Tratamento de erro
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

  /// Abre o seletor de data para entrada ou entrega
  Future<void> _selecionarData({required bool isEntrega}) async {
    final initialDate = isEntrega
        ? (_dataEntrega ?? _dataServico)
        : _dataServico;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      // Impede que a data de entrega seja anterior à data de entrada
      firstDate: isEntrega ? _dataServico : DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: corPrincipal,
            surface: corCard,
          ),
        ),
        child: child!,
      ),
    );

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

  // ==================================================
  // INTERFACE VISUAL (UI)
  // ==================================================

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
            ),
            onPressed: _isLoading ? null : _salvarEdicao,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "SALVAR ALTERAÇÕES",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
            children: [
              // --- BLOCO 1: STATUS DO SERVIÇO ---
              _buildBlock(
                children: [
                  _tituloCampo("Status do Serviço"),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _foiEntregue
                          ? "ENTREGUE / FINALIZADO"
                          : "PENDENTE / EM ANDAMENTO",
                      style: TextStyle(
                        color: _foiEntregue
                            ? Colors.green
                            : Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      "Marque quando o cliente retirar o serviço",
                      style: TextStyle(color: corTextoCinza, fontSize: 12),
                    ),
                    secondary: Icon(
                      _foiEntregue ? Icons.check_circle : Icons.pending_actions,
                      color: _foiEntregue ? Colors.green : Colors.orangeAccent,
                    ),
                    value: _foiEntregue,
                    activeThumbColor: Colors.green,
                    onChanged: (bool value) {
                      setState(() {
                        _foiEntregue = value;
                      });
                    },
                  ),
                  const Divider(color: Colors.white10, height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _ehRetorno ? "É UM RETORNO" : "SERVIÇO NORMAL",
                      style: TextStyle(
                        color: _ehRetorno ? Colors.amber : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      "Marque se for um serviço de garantia/revisão.",
                      style: TextStyle(color: corTextoCinza, fontSize: 12),
                    ),
                    secondary: Icon(
                      Icons.history,
                      color: _ehRetorno ? Colors.amber : corTextoCinza,
                    ),
                    value: _ehRetorno,
                    activeThumbColor: Colors.amber,
                    onChanged: (value) => setState(() => _ehRetorno = value),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- BLOCO 2: INFORMAÇÕES BÁSICAS ---
              _buildBlock(
                children: [
                  _tituloCampo("Título do Serviço"),
                  TextFormField(
                    controller: _tituloController,
                    style: TextStyle(color: corTextoClaro),
                    decoration: _inputDecoration("Ex: Limpeza", Icons.title),
                  ),
                  const SizedBox(height: 20),
                  _tituloCampo("Descrição do Serviço"),
                  TextFormField(
                    controller: _descricaoController,
                    keyboardType: TextInputType.visiblePassword,
                    maxLines: 3,
                    style: TextStyle(color: corTextoClaro),
                    decoration: _inputDecoration(
                      "Descreva o serviço...",
                      Icons.description_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- BLOCO 3: VALORES ---
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
                      "0,00",
                      Icons.monetization_on_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- BLOCO 4: DATAS E HORÁRIOS ---
              _buildBlock(
                children: [
                  _tituloCampo("Preferência de Horário"),
                  Row(
                    children: [
                      _botaoSelecaoHorario(
                        valor: 'Manhã',
                        icon: Icons.wb_sunny_outlined,
                      ),
                      const SizedBox(width: 12),
                      _botaoSelecaoHorario(
                        valor: 'Tarde',
                        icon: Icons.wb_twilight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _tituloCampo("Data de Entrada"),
                  _botaoData(
                    icon: Icons.calendar_today,
                    texto: DateFormat('dd/MM/yyyy').format(_dataServico),
                    onTap: () => _selecionarData(isEntrega: false),
                  ),
                  const SizedBox(height: 20),

                  _tituloCampo("Data de Entrega / Previsão"),
                  Row(
                    children: [
                      Expanded(
                        child: _botaoData(
                          icon: Icons.event_available,
                          texto: _dataEntrega != null
                              ? DateFormat('dd/MM/yyyy').format(_dataEntrega!)
                              : "Definir data...",
                          onTap: () => _selecionarData(isEntrega: true),
                        ),
                      ),
                      // Exibe botão de remover apenas se houver data selecionada
                      if (_dataEntrega != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: IconButton(
                            onPressed: () =>
                                setState(() => _dataEntrega = null),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.redAccent,
                            ),
                            tooltip: "Remover data",
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black26,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
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

  // ==================================================
  // WIDGETS AUXILIARES E COMPONENTES
  // ==================================================

  /// Cria um container padronizado para agrupar campos
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

  /// Títulos padronizados para os inputs
  Widget _tituloCampo(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(texto, style: TextStyle(color: corTextoCinza, fontSize: 14)),
  );

  /// Botão customizado para seleção de turno (Manhã/Tarde)
  Widget _botaoSelecaoHorario({required String valor, required IconData icon}) {
    final bool isSelected = _horarioSelecionado == valor;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _horarioSelecionado = valor),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? corPrincipal : Colors.black26,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.redAccent : Colors.white10,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : corTextoCinza),
              Text(
                valor,
                style: TextStyle(
                  color: isSelected ? Colors.white : corTextoCinza,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Botão visual que simula um input para abrir o DatePicker
  Widget _botaoData({
    required IconData icon,
    required String texto,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: corTextoCinza, size: 20),
            const SizedBox(width: 12),
            Text(texto, style: TextStyle(color: corTextoClaro)),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  /// Estilização padrão dos inputs de texto
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      prefixIcon: Icon(icon, color: corTextoCinza),
      filled: true,
      fillColor: Colors.black26,
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
