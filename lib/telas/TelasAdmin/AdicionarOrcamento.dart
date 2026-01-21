import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../modelos/Cliente.dart';

/// Tela responsável pela criação de um novo orçamento para um cliente específico.
class AdicionarOrcamento extends StatefulWidget {
  final Cliente cliente;
  final DateTime? dataSelecionada;

  const AdicionarOrcamento({
    super.key,
    required this.cliente,
    this.dataSelecionada,
  }); // Adicionado aqui

  @override
  State<AdicionarOrcamento> createState() => _AdicionarOrcamentoState();
}

class _AdicionarOrcamentoState extends State<AdicionarOrcamento> {
  final _formKey = GlobalKey<FormState>();

  // ===========================================================================
  // CORES
  // ===========================================================================
  final Color corPrincipal = Colors.red[900]!;
  final Color corSecundaria = Colors.blue[300]!;
  final Color corComplementar = Colors.amber;
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corTextoClaro = Colors.white;
  final Color corTextoCinza = Colors.grey[400]!;

  // ===========================================================================
  // CONTROLADORES E ESTADO
  // ===========================================================================
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();

  late DateTime _dataPega;
  DateTime? _dataEntrega;

  // Novo estado para o horário
  String _horarioSelecionado = 'Manhã';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dataPega = widget.dataSelecionada ?? DateTime.now();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // LÓGICA DE NEGÓCIO
  // ===========================================================================

  /// Abre o seletor de data para Entrada ou Entrega
  Future<void> _selecionarData({required bool isEntrega}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isEntrega ? (_dataEntrega ?? DateTime.now()) : _dataPega,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: corPrincipal,
              onPrimary: Colors.white,
              surface: corCard,
              onSurface: corTextoClaro,
            ),
            dialogTheme: DialogThemeData(backgroundColor: corCard),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isEntrega) {
          _dataEntrega = picked;
        } else {
          _dataPega = picked;
        }
      });
    }
  }

  /// Valida e insere o novo orçamento no Supabase
  Future<void> _salvarOrcamento() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> dadosNovoOrcamento = {
        'cliente_id': widget.cliente.id,
        'titulo': _tituloController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'valor': _valorController.text.isNotEmpty
            ? double.parse(_valorController.text.replaceAll(',', '.'))
            : null,
        'data_pega': _dataPega.toIso8601String(),
        'data_entrega': _dataEntrega?.toIso8601String(),

        // --- NOVO CAMPO SALVO NO SUPABASE ---
        'horario_do_dia': _horarioSelecionado,
      };

      await Supabase.instance.client
          .from('orcamentos')
          .insert(dadosNovoOrcamento);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Orçamento adicionado com sucesso!'),
            backgroundColor: Colors.green[700],
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===========================================================================
  // WIDGETS AUXILIARES
  // ===========================================================================

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

  Widget _tituloCampo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(texto, style: TextStyle(color: corTextoCinza, fontSize: 14)),
    );
  }

  // Widget auxiliar para criar os botões de seleção de horário
  Widget _botaoSelecaoHorario({required String valor, required IconData icon}) {
    final bool isSelected = _horarioSelecionado == valor;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _horarioSelecionado = valor;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? corPrincipal : Colors.black26,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: Colors.redAccent, width: 2)
                : Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : corTextoCinza,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                valor,
                style: TextStyle(
                  color: isSelected ? Colors.white : corTextoCinza,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          color: Colors.black26,
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

  // ===========================================================================
  // TELA PRINCIPAL
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: const Text(
          "Novo Orçamento",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      bottomNavigationBar: Container(
        color: corCard,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: corPrincipal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            onPressed: _isLoading ? null : _salvarOrcamento,
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
                    "ADICIONAR ORÇAMENTO",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.1,
                    ),
                  ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cliente Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: corCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(color: corComplementar, width: 4),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: corComplementar.withValues(alpha: 0.15),
                      child: Icon(
                        Icons.person,
                        color: corComplementar,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "CLIENTE SELECIONADO",
                            style: TextStyle(
                              fontSize: 12,
                              color: corTextoCinza,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.cliente.nome,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: corTextoClaro,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // BLOCO 1: Título e Descrição
              _buildBlock(
                children: [
                  _tituloCampo("Título do Serviço"),
                  TextFormField(
                    controller: _tituloController,
                    style: TextStyle(color: corTextoClaro),
                    decoration: _inputDecoration('Ex: Limpeza', Icons.title),
                    validator: (v) => v!.isEmpty ? 'Informe um título' : null,
                  ),
                  const SizedBox(height: 20),
                  _tituloCampo("Descrição"),
                  TextFormField(
                    controller: _descricaoController,
                    maxLines: 3,
                    style: TextStyle(color: corTextoClaro),
                    decoration: _inputDecoration(
                      'Descreva o serviço...',
                      Icons.description_outlined,
                    ),
                    validator: (v) => v!.isEmpty ? 'Descreva o serviço' : null,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // BLOCO 2: Financeiro
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
                      '12.34',
                      Icons.monetization_on_outlined,
                    ),
                    validator: (v) => v!.isEmpty ? 'Informe o valor' : null,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // BLOCO 3: PRAZOS (Com os novos botões)
              _buildBlock(
                children: [
                  // --- NOVOS CAMPOS: MANHÃ / TARDE ---
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
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 20),

                  _tituloCampo("Data de Entrada"),
                  _botaoData(
                    icon: Icons.calendar_today,
                    texto: DateFormat('dd/MM/yyyy').format(_dataPega),
                    onTap: () => _selecionarData(isEntrega: false),
                  ),

                  const SizedBox(height: 20),

                  // --- FIM DOS NOVOS CAMPOS ---
                  _tituloCampo("Data de Entrega"),
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

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
