import 'package:flutter/material.dart';
import '../../servicos/Autenticacao.dart';
import 'Login.dart';

/// Tela exibida após o cadastro, solicitando a confirmação do e-mail
class VerificacaoEmail extends StatelessWidget {
  /// E-mail utilizado no cadastro
  final String email;

  const VerificacaoEmail({super.key, required this.email});

  // ============================================================
  // REALIZA LOGOUT E RETORNA PARA A TELA DE LOGIN
  // ============================================================
  Future<void> _voltarParaLogin(BuildContext context) async {
    // Força o logout para evitar que o AuthGate
    // redirecione automaticamente o usuário
    await AuthService().deslogar();

    if (context.mounted) {
      // Remove todas as rotas anteriores e abre a tela de login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmação Necessária"),
        centerTitle: true,
        backgroundColor: Colors.blue[900],
        // Remove o botão de voltar para impedir navegação indevida
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// Ícone ilustrativo de confirmação de e-mail
            const Icon(Icons.mark_email_unread, size: 100, color: Colors.blue),

            const SizedBox(height: 30),

            /// Título principal da tela
            const Text(
              "Verifique sua caixa de entrada",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 15),

            /// Texto explicativo sobre a confirmação
            Text(
              "Para sua segurança, saia do aplicativo e confirme o link que enviamos para:",
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            /// Destaque visual para o e-mail cadastrado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                email,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 40),

            /// Orientação final ao usuário
            const Text(
              "Após confirmar, volte aqui e faça login.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            // ==================================================
            // AÇÃO ÚNICA: RETORNAR PARA O LOGIN
            // ==================================================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _voltarParaLogin(context),
                child: const Text("Voltar para Tela de Login"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
