import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necessário para TextInputFormatter
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart'; // Import do pacote
import '../../modelos/Cliente.dart';

/// Tela responsável pela edição dos dados de um cliente existente
class EditarCliente extends StatefulWidget {
  /// Objeto cliente contendo os dados a serem editados
  final Cliente cliente;

  const EditarCliente({super.key, required this.cliente});

  @override
  State<EditarCliente> createState() => _EditarClienteState();
}

class _EditarClienteState extends State<EditarCliente> {
  // ===========================================================================
  // VARIÁVEIS DE ESTADO E CONTROLADORES
  // ===========================================================================

  /// Chave global para validação do formulário
  final _formKey = GlobalKey<FormState>();

  /// Controla o estado de carregamento da operação de salvamento
  bool _isLoading = false;

  /// Controladores de texto para os campos
  late TextEditingController _nomeController;
  late TextEditingController _telefoneController;
  late TextEditingController _ruaController;
  late TextEditingController _bairroController;
  late TextEditingController _cpfController;
  late TextEditingController _cnpjController;
  late TextEditingController _obsController;

  /// Estado do switch de cliente problemático
  late bool _isProblematico;

  // ===========================================================================
  // MÁSCARAS DE FORMATAÇÃO
  // ===========================================================================

  /// Máscara para telefone: (##) #####-####
  final maskTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  /// Máscara para CPF: ###.###.###-##
  final maskCPF = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  /// Máscara para CNPJ: ##.###.###/####-##
  final maskCNPJ = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void initState() {
    super.initState();
    // Inicializa os campos com os dados vindos do objeto cliente
    _nomeController = TextEditingController(text: widget.cliente.nome);
    _ruaController = TextEditingController(text: widget.cliente.rua);
    _bairroController = TextEditingController(text: widget.cliente.bairro);
    _obsController = TextEditingController(
      text: widget.cliente.observacao ?? '',
    );
    _isProblematico = widget.cliente.clienteProblematico;

    // Aplica as máscaras nos valores iniciais
    _telefoneController = TextEditingController(
      text: maskTelefone.maskText(widget.cliente.telefone),
    );
    _cpfController = TextEditingController(
      text: maskCPF.maskText(widget.cliente.cpf ?? ''),
    );
    _cnpjController = TextEditingController(
      text: maskCNPJ.maskText(widget.cliente.cnpj ?? ''),
    );
  }

  @override
  void dispose() {
    // Libera recursos dos controladores
    _nomeController.dispose();
    _telefoneController.dispose();
    _ruaController.dispose();
    _bairroController.dispose();
    _cpfController.dispose();
    _cnpjController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // LÓGICA DE NEGÓCIO
  // ===========================================================================

  /// Valida e salva as alterações do cliente no banco de dados
  Future<void> _salvarAlteracoes() async {
    // Valida o formulário antes de prosseguir
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Atualiza o registro na tabela 'clientes'
      await Supabase.instance.client
          .from('clientes')
          .update({
            'nome': _nomeController.text.trim(),
            'telefone': _telefoneController.text.trim(),
            'rua': _ruaController.text.trim(),
            'bairro': _bairroController.text.trim(),
            // Envia null se os campos opcionais estiverem vazios
            'cpf': _cpfController.text.isEmpty
                ? null
                : _cpfController.text.trim(),
            'cnpj': _cnpjController.text.isEmpty
                ? null
                : _cnpjController.text.trim(),
            'observacao': _obsController.text.trim(),
            'cliente_problematico': _isProblematico,
          })
          .eq('id', widget.cliente.id as Object);

      if (mounted) {
        // Exibe feedback de sucesso e fecha a tela
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente atualizado com sucesso!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        // Exibe erro caso falhe
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

  // ===========================================================================
  // INTERFACE (UI)
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    // Definição de cores locais
    final Color corFundo = Colors.black;
    final Color corCard = const Color(0xFF1E1E1E);
    final Color corTextoClaro = Colors.white;
    final Color corPrincipal = Colors.red[900]!;

    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: const Text("Editar Cliente"),
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Card com informações pessoais e de endereço
              _buildCard(
                corCard,
                corTextoClaro,
                Column(
                  children: [
                    _buildTextField(
                      controller: _nomeController,
                      label: "Nome Completo",
                      icon: Icons.person,
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    // Campo de telefone com máscara
                    _buildTextField(
                      controller: _telefoneController,
                      label: "Telefone",
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [maskTelefone],
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    // Campo Rua
                    _buildTextField(
                      controller: _ruaController,
                      label: "Rua",
                      icon: Icons.add_road,
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    // Campo Bairro
                    _buildTextField(
                      controller: _bairroController,
                      label: "Bairro",
                      icon: Icons.location_city,
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card com documentos (CPF/CNPJ)
              _buildCard(
                corCard,
                corTextoClaro,
                Column(
                  children: [
                    _buildTextField(
                      controller: _cpfController,
                      label: "CPF (Opcional)",
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [maskCPF],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _cnpjController,
                      label: "CNPJ (Opcional)",
                      icon: Icons.domain,
                      keyboardType: TextInputType.number,
                      inputFormatters: [maskCNPJ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Card de Status e Observações
              _buildCard(
                corCard,
                corTextoClaro,
                Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: Colors.redAccent,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        "Cliente Problemático?",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        "Marque se houver histórico de problemas",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      value: _isProblematico,
                      onChanged: (val) => setState(() => _isProblematico = val),
                    ),
                    const Divider(color: Colors.white24),
                    _buildTextField(
                      controller: _obsController,
                      label: "Observações",
                      icon: Icons.note,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Botão de salvar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: corPrincipal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _salvarAlteracoes,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "SALVAR ALTERAÇÕES",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget auxiliar para construção dos Cards de agrupamento
  Widget _buildCard(Color color, Color textColor, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  /// Widget auxiliar para construção dos campos de texto padronizados
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.blue[300]),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.circular(10),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.redAccent),
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.black26,
      ),
    );
  }
}
