import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter/services.dart';
import '../../modelos/Cliente.dart';

class AdicionarCliente extends StatefulWidget {
  const AdicionarCliente({super.key});

  @override
  State<AdicionarCliente> createState() => _AdicionarClienteState();
}

class _AdicionarClienteState extends State<AdicionarCliente> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // ==================================================
  // CONFIGURAÇÕES E VARIÁVEIS DE ESTADO
  // ==================================================

  // Paleta de Cores
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corTextoClaro = Colors.white;
  final Color corPrincipal = Colors.red[900]!;
  final Color corSecundaria = Colors.blue[300]!;

  // Controladores de Texto
  final _nomeController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _observacaoController = TextEditingController();

  // Estados de Controle Lógico
  bool _isPessoaFisica = true;
  bool _isProblematico = false;

  // ==================================================
  // FORMATADORES E MÁSCARAS
  // ==================================================
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

  @override
  void dispose() {
    _nomeController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _telefoneController.dispose();
    _cpfController.dispose();
    _cnpjController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  // ==================================================
  // NOVA FUNCIONALIDADE: IMPORTAÇÃO DE TEXTO
  // ==================================================
  void _mostrarModalImportacao() {
    final importarController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          backgroundColor: corCard,
          title: Row(
            children: [
              Icon(Icons.paste, color: corSecundaria),
              const SizedBox(width: 10),
              const Text(
                "Importar Dados",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Cole o texto abaixo na seguinte ordem:\n1. Nome\n2. Telefone\n3. Rua\n4. Número\n5. Bairro",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: importarController,
                maxLines: 8,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black26,
                  hintText: "Cole o texto aqui...",
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: corPrincipal),
              onPressed: () {
                _processarTextoImportado(importarController.text);
                Navigator.pop(context);
              },
              child: const Text(
                "Preencher Campos",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _processarTextoImportado(String texto) {
    if (texto.trim().isEmpty) return;

    // Separa as linhas e remove espaços em branco das pontas
    List<String> linhas = texto.split('\n').map((l) => l.trim()).toList();

    // =========================================================
    // ETAPA DE VALIDAÇÃO (Bloqueia se não for numérico)
    // =========================================================

    // 1. Validar Linha 2 (Telefone) - Index 1
    if (linhas.length > 1) {
      String linhaTel = linhas[1];
      // Verifica se contém alguma letra (a-z ou A-Z)
      bool temLetras = RegExp(r'[a-zA-Z]').hasMatch(linhaTel);

      if (temLetras) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Erro: A 2ª linha (Telefone) contém letras. Corrija para apenas números.",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return; // Para a execução aqui, não preenche nada
      }
    }

    // 2. Validar Linha 4 (Número da Casa) - Index 3
    if (linhas.length > 3) {
      String linhaNum = linhas[3];
      // Verifica se a linha INTEIRA é composta apenas por dígitos (0 a 9)
      // Se tiver espaço, letra ou traço, retorna falso.
      bool soNumeros = RegExp(r'^[0-9]+$').hasMatch(linhaNum);

      if (!soNumeros) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Erro: A 4ª linha (Número) deve conter APENAS números (sem letras, espaços ou S/N).",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return; // Para a execução aqui
      }
    }

    // =========================================================
    // PREENCHIMENTO DOS CAMPOS (Só chega aqui se validou)
    // =========================================================
    setState(() {
      // Linha 1 - Nome
      if (linhas.isNotEmpty) _nomeController.text = linhas[0];

      // Linha 2 - Telefone
      if (linhas.length > 1) {
        String telLimpo = linhas[1].replaceAll(RegExp(r'[^0-9]'), '');
        if (telLimpo.length >= 10) {
          var mascaraAplicada = maskTelefone.maskText(telLimpo);
          _telefoneController.text = mascaraAplicada;
        } else {
          _telefoneController.text =
              telLimpo; // Cola o que tiver se for curto (mas sem letras)
        }
      }

      // Linha 3 - Rua
      if (linhas.length > 2) _ruaController.text = linhas[2];

      // Linha 4 - Número
      if (linhas.length > 3) _numeroController.text = linhas[3];

      // Linha 5 - Bairro
      if (linhas.length > 4) _bairroController.text = linhas[4];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Dados importados com sucesso!"),
        backgroundColor: Colors.green[800],
      ),
    );
  }

  // ==================================================
  // LÓGICA DE PERSISTÊNCIA (SUPABASE)
  // ==================================================
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

      final novoCliente = Cliente(
        nome: _nomeController.text.trim(),
        rua: _ruaController.text.trim(),
        numero: _numeroController.text.trim(),
        bairro: _bairroController.text.trim(),
        telefone: maskTelefone.getUnmaskedText(), // Pega apenas números
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

  // ==================================================
  // INTERFACE (BUILD)
  // ==================================================
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
              // ==========================================
              // BOTÃO DE IMPORTAÇÃO (NOVO)
              // ==========================================
              InkWell(
                onTap: _mostrarModalImportacao,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.blue[900]!.withValues(
                      alpha: 0.3,
                    ), // Azul sutil
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blueAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.content_paste_go, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Text(
                        "Importar Dados de Texto",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ------------------------------------------
              // SEÇÃO 1: DADOS CADASTRAIS BÁSICOS
              // ------------------------------------------
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
                    Row(
                      children: [
                        Expanded(
                          flex: 10,
                          child: _buildTextField(
                            controller: _ruaController,
                            label: 'Rua',
                            icon: Icons.add_road,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Obrigatório' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 6,
                          child: _buildTextField(
                            controller: _numeroController,
                            keyboardType: TextInputType
                                .text, // Mudado para text caso tenha letras (Ex: 10A)
                            label: 'Nº',
                            icon: Icons.home_filled,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Req.' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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

              // ------------------------------------------
              // SEÇÃO 2: DOCUMENTAÇÃO (TOGGLE CPF/CNPJ)
              // ------------------------------------------
              _buildCard(
                Column(
                  children: [
                    // Seletor Pessoa Física vs Jurídica
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

                    // Alternância animada entre os campos de documento
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

              // ------------------------------------------
              // SEÇÃO 3: STATUS E OBSERVAÇÕES
              // ------------------------------------------
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

              // ------------------------------------------
              // BOTÃO DE AÇÃO
              // ------------------------------------------
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

  // ==================================================
  // WIDGETS AUXILIARES
  // ==================================================

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
