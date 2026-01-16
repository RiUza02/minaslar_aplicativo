import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../servicos/autenticacao.dart';

class VerificacaoEmailScreen extends StatefulWidget {
  final String? emailUsuario;
  final String? nomeUsuario;
  final String? telefoneUsuario; // <--- 1. Novo parâmetro
  final bool? isAdmin;

  const VerificacaoEmailScreen({
    super.key,
    this.emailUsuario,
    this.nomeUsuario,
    this.telefoneUsuario, // <--- Adicionado aqui
    this.isAdmin,
  });

  @override
  State<VerificacaoEmailScreen> createState() => _VerificacaoEmailScreenState();
}

class _VerificacaoEmailScreenState extends State<VerificacaoEmailScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // =========================
  // LÓGICA: REENVIAR E-MAIL
  // =========================
  Future<void> _reenviarEmail() async {
    setState(() => _isLoading = true);
    String? erro = await _authService.reenviarVerificacaoEmail();
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erro ?? 'E-mail reenviado com sucesso!'),
          backgroundColor: erro == null ? Colors.green : Colors.red,
        ),
      );
    }
  }

  // =======================================================
  // LÓGICA: CHECAR VERIFICAÇÃO E FINALIZAR CADASTRO (BD)
  // =======================================================
  Future<void> _checarVerificacao() async {
    setState(() => _isLoading = true);

    try {
      User? user = _authService.usuarioAtual;

      // Força o recarregamento para obter o status atualizado do emailVerified
      await user?.reload();
      user = _authService.usuarioAtual; // Atualiza a referência

      if (user != null && user.emailVerified) {
        // ---------------------------------------------------
        // SUCESSO: E-MAIL VERIFICADO -> SALVAR NO FIRESTORE
        // ---------------------------------------------------

        // 1. Recuperar dados (Parâmetros OU SharedPreferences)
        final prefs = await SharedPreferences.getInstance();

        String nomeFinal =
            widget.nomeUsuario ?? prefs.getString('temp_nome') ?? 'Usuário';

        // <--- 2. Recupera o Telefone
        String telefoneFinal =
            widget.telefoneUsuario ?? prefs.getString('temp_telefone') ?? '';

        bool adminFinal =
            widget.isAdmin ?? prefs.getBool('temp_isAdmin') ?? false;

        // 3. Chamar o serviço para salvar os dados finais no Firestore
        String? erroSalvar = await _authService.salvarDadosNoFirestore(
          uid: user.uid,
          nome: nomeFinal,
          email: user.email!,
          telefone: telefoneFinal, // <--- 3. Envia o telefone para o BD
          isAdmin: adminFinal,
        );

        if (erroSalvar == null) {
          // 4. Limpar dados temporários
          await prefs.remove('temp_nome');
          await prefs.remove('temp_email');
          await prefs.remove('temp_telefone'); // <--- 4. Limpa o backup
          await prefs.remove('temp_isAdmin');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Conta verificada e criada com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );

            // Navega para a Home
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (route) => false);
          }
        } else {
          throw Exception(erroSalvar);
        }
      } else {
        // ---------------------------------------------------
        // AINDA NÃO VERIFICADO
        // ---------------------------------------------------
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'E-mail ainda não verificado. Cheque sua caixa de entrada.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao finalizar cadastro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color corPrimaria = Colors.blueAccent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar E-mail'),
        centerTitle: true,
        backgroundColor: corPrimaria,
        automaticallyImplyLeading: false, // Sem botão de voltar
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: corPrimaria.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_outlined,
                          size: 80,
                          color: corPrimaria,
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        'Verifique seu e-mail',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Enviamos um link de confirmação para:\n'
                        '${widget.emailUsuario ?? "seu e-mail"}.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Toque no link recebido e depois clique no botão abaixo "JÁ CONFIRMEI".',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),

                      const Spacer(),
                      const SizedBox(height: 30),

                      // Botão Checar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: corPrimaria,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: _isLoading ? null : _checarVerificacao,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('JÁ CONFIRMEI'),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Botão Reenviar
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            side: const BorderSide(color: corPrimaria),
                            foregroundColor: corPrimaria,
                          ),
                          onPressed: _isLoading ? null : _reenviarEmail,
                          icon: const Icon(Icons.refresh),
                          label: const Text('REENVIAR E-MAIL'),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: () {
                          _authService.deslogar();
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                        child: const Text(
                          "Sair / Trocar conta",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
