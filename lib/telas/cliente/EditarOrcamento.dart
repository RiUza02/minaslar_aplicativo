import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _formKey = GlobalKey<FormState>();

  // Controladores
  late TextEditingController _tituloController; // Adicionado
  late TextEditingController _descricaoController;
  late TextEditingController _valorController;

  // Data do Serviço (Obrigatória, default now)
  late DateTime _dataServico;

  // Data de Entrega (Opcional)
  DateTime? _dataEntrega;

  bool _isLoading = false;

  // ===========================================================================
  // CORES
  // ===========================================================================
  final Color corPrincipal = Colors.red[900]!;
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corTextoClaro = Colors.white;
  final Color corTextoCinza = Colors.grey[400]!;

  @override
  void initState() {
    super.initState();

    // Inicializa Título
    _tituloController = TextEditingController(
      text: widget.orcamento['titulo'] ?? '',
    );

    // Inicializa Descrição
    _descricaoController = TextEditingController(
      text: widget.orcamento['descricao'] ?? '',
    );

    // Inicializa Valor
    final valor = widget.orcamento['valor'];
    _valorController = TextEditingController(text: valor?.toString() ?? '');

    // Carrega Data do Serviço (data_pega)
    final dataServicoString = widget.orcamento['data_pega'];
    _dataServico = dataServicoString != null
        ? DateTime.parse(dataServicoString)
        : DateTime.now();

    // Carrega Data de Entrega (se existir)
    final dataEntregaString = widget.orcamento['data_entrega'];
    _dataEntrega = dataEntregaString != null
        ? DateTime.parse(dataEntregaString)
        : null;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // LÓGICA
  // ===========================================================================

  Future<void> _salvarEdicao() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final double? valorConvertido = double.tryParse(
        _valorController.text.replaceAll(',', '.'),
      );

      await Supabase.instance.client
          .from('orcamentos')
          .update({
            'titulo': _tituloController.text.trim(), // Salva o título
            'descricao': _descricaoController.text.trim(),
            'valor': valorConvertido,
            'data_pega': _dataServico.toIso8601String(),
            'data_entrega': _dataEntrega?.toIso8601String(), // Pode ser null
          })
          .eq('id', widget.orcamento['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orçamento atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // Retorna true para atualizar a lista anterior
      }
    } catch (e) {
      if (mounted) {
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

  // Seletor genérico de data
  Future<void> _selecionarData({required bool isEntrega}) async {
    final initialDate = isEntrega
        ? (_dataEntrega ?? DateTime.now())
        : _dataServico;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
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
  // TELA
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

      // BOTÃO DE SALVAR FIXO NO FUNDO
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
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Campo Título (Novo) ---
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

              // --- Campo Descrição ---
              _tituloCampo("Descrição do Serviço"),
              TextFormField(
                controller: _descricaoController,
                maxLines: 3, // Aumentado para facilitar edição de textos longos
                style: TextStyle(color: corTextoClaro),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Obrigatório' : null,
                decoration: _inputDecoration(
                  "Ex: Troca de tela",
                  Icons.description_outlined,
                ),
              ),
              const SizedBox(height: 20),

              // --- Campo Valor ---
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
              const SizedBox(height: 20),

              // --- Data do Serviço ---
              _tituloCampo("Data de Entrada (Serviço)"),
              _botaoData(
                icon: Icons.calendar_today,
                texto: DateFormat('dd/MM/yyyy').format(_dataServico),
                onTap: () => _selecionarData(isEntrega: false),
              ),
              const SizedBox(height: 20),

              // --- Data de Entrega ---
              _tituloCampo("Data de Entrega / Previsão"),
              _botaoData(
                icon: Icons.event_available,
                texto: _dataEntrega != null
                    ? DateFormat('dd/MM/yyyy').format(_dataEntrega!)
                    : "Definir data de entrega...",
                corTexto: _dataEntrega != null ? corTextoClaro : Colors.white54,
                onTap: () => _selecionarData(isEntrega: true),
              ),

              // Botão para limpar a data de entrega (opcional)
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

              // Espaço extra no final para scroll
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tituloCampo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(texto, style: TextStyle(color: corTextoCinza, fontSize: 14)),
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
          color: corCard,
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
      fillColor: corCard,
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
