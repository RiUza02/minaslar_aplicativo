import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter/services.dart'; // Necessário para formatadores
import '../../modelos/Cliente.dart';

class AdicionarCliente extends StatefulWidget {
  const AdicionarCliente({super.key});

  @override
  State<AdicionarCliente> createState() => _AdicionarClienteState();
}

class _AdicionarClienteState extends State<AdicionarCliente> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // ======================================================
  // DEFINIÇÃO DAS CORES
  // ======================================================
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corTextoClaro = Colors.white;
  final Color corPrincipal = Colors.red[900]!;
  final Color corSecundaria = Colors.blue[300]!;

  // Controladores
  final _nomeController = TextEditingController();
  // ATUALIZADO: Trocado Endereço por Rua e Bairro
  final _ruaController = TextEditingController();
  final _bairroController = TextEditingController();

  final _telefoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _observacaoController = TextEditingController();

  // Estados
  bool _isPessoaFisica = true;
  bool _isProblematico = false;

  // ======================================================
  // MÁSCARAS
  // ======================================================
  final maskTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final maskCPF = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final maskCNPJ = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // Importante: Dispose para evitar vazamento de memória
  @override
  void dispose() {
    _nomeController.dispose();
    _ruaController.dispose();
    _bairroController.dispose();
    _telefoneController.dispose();
    _cpfController.dispose();
    _cnpjController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _salvarCliente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? cpfFinal;
      if (_isPessoaFisica && _cpfController.text.trim().isNotEmpty) {
        cpfFinal = _cpfController.text.trim();
      }

      String? cnpjFinal;
      if (!_isPessoaFisica && _cnpjController.text.trim().isNotEmpty) {
        cnpjFinal = _cnpjController.text.trim();
      }

      // ATUALIZADO: Passando Rua e Bairro
      final novoCliente = Cliente(
        nome: _nomeController.text.trim(),
        rua: _ruaController.text.trim(), // Novo
        bairro: _bairroController.text.trim(), // Novo
        telefone: _telefoneController.text.trim(),
        cpf: cpfFinal,
        cnpj: cnpjFinal,
        observacao: _observacaoController.text.trim().isEmpty
            ? null
            : _observacaoController.text.trim(),
        clienteProblematico: _isProblematico,
      );

      await Supabase.instance.client
          .from('clientes')
          .insert(novoCliente.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente salvo com sucesso!')),
        );
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: const Text("Novo Cliente"),
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
              // CARD 1: DADOS PESSOAIS
              _buildCard(
                Column(
                  children: [
                    _buildTextField(
                      controller: _nomeController,
                      label: "Nome Completo",
                      icon: Icons.person,
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _telefoneController,
                      label: "Telefone",
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [maskTelefone],
                      validator: (v) =>
                          v!.length < 15 ? 'Telefone incompleto' : null,
                    ),
                    const SizedBox(height: 16),

                    // --- ATUALIZADO: CAMPO RUA ---
                    _buildTextField(
                      controller: _ruaController,
                      label: "Rua",
                      icon: Icons.add_road,
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),

                    const SizedBox(height: 16),

                    // --- ATUALIZADO: CAMPO BAIRRO ---
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

              // CARD 2: DOCUMENTAÇÃO (Com Toggle)
              _buildCard(
                Column(
                  children: [
                    // Toggle Customizado
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildRadioButton("Pessoa Física", true),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white10,
                          ),
                          Expanded(
                            child: _buildRadioButton("Pessoa Jurídica", false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Alternância entre inputs
                    AnimatedCrossFade(
                      firstChild: _buildTextField(
                        controller: _cpfController,
                        label: "CPF",
                        icon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [maskCPF],
                        validator: (v) {
                          if (!_isPessoaFisica) return null;
                          if (v != null && v.isNotEmpty && v.length < 14) {
                            return 'CPF incompleto';
                          }
                          return null;
                        },
                      ),
                      secondChild: _buildTextField(
                        controller: _cnpjController,
                        label: "CNPJ",
                        icon: Icons.domain,
                        keyboardType: TextInputType.number,
                        inputFormatters: [maskCNPJ],
                        validator: (v) {
                          if (_isPessoaFisica) return null;
                          if (v != null && v.isNotEmpty && v.length < 18) {
                            return 'CNPJ incompleto';
                          }
                          return null;
                        },
                      ),
                      crossFadeState: _isPessoaFisica
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // CARD 3: STATUS E OBSERVAÇÕES
              _buildCard(
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
                        "Marque se houver historico de problemas",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      value: _isProblematico,
                      onChanged: (val) => setState(() => _isProblematico = val),
                    ),
                    const Divider(color: Colors.white24),
                    _buildTextField(
                      controller: _observacaoController,
                      label: "Observações (Opcional)",
                      icon: Icons.note,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // BOTÃO SALVAR
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
                  onPressed: _isLoading ? null : _salvarCliente,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "CADASTRAR CLIENTE",
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

  // ======================================================
  // WIDGETS AUXILIARES
  // ======================================================

  Widget _buildCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

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
        prefixIcon: Icon(icon, color: corSecundaria),
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

  Widget _buildRadioButton(String title, bool valorEnum) {
    final isSelected = _isPessoaFisica == valorEnum;
    return InkWell(
      onTap: () => setState(() => _isPessoaFisica = valorEnum),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? corSecundaria : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
