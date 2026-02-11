import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importe suas telas
import '../telas/TelasPrincipais/HomeUsuario.dart';
import '../Telas/TelasPrincipais/HomeAdmin.dart';
import '../telas/criarConta/Login.dart';
import '../telas/criarConta/Cadastro.dart';
import '../modelos/Usuario.dart';
import 'Autenticacao.dart';

class Roteador extends StatelessWidget {
  const Roteador({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      // 1. Ouve se o usuário está logado ou não (Auth)
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Estado de Loading do Auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.blue)),
          );
        }

        final session = snapshot.data?.session;

        // 2. Se NÃO estiver logado -> Tela de Apresentação
        if (session == null) {
          return const TelaApresentacao();
        }

        // 3. Se ESTIVER logado -> Busca os dados no Banco (Tabela Usuarios)
        // Usamos FutureBuilder para aguardar a leitura do banco de dados
        return FutureBuilder<Usuario?>(
          future: AuthService().recuperarDadosUsuario(),
          builder: (context, userSnapshot) {
            // Enquanto busca no banco, mostra loading
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: CircularProgressIndicator(color: Colors.red),
                ),
              );
            }

            final usuarioModelo = userSnapshot.data;

            // Se não achou o usuário na tabela (erro de cadastro) ou deu erro
            // Manda para HomeUsuario por segurança (ou tela de erro)
            if (usuarioModelo == null) {
              return const HomeUsuario();
            }

            // 4. VERIFICAÇÃO FINAL USANDO SEU MODELO
            if (usuarioModelo.isAdmin) {
              return const HomeAdmin();
            } else {
              return const HomeUsuario();
            }
          },
        );
      },
    );
  }
}

// ... (Mantenha a classe TelaApresentacao aqui embaixo igual estava) ...
class TelaApresentacao extends StatelessWidget {
  const TelaApresentacao({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Image.asset(
                    'assets/logo.jpg',
                    width: 300,
                    height: 300,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.home_work,
                      size: 150,
                      color: Colors.blue,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const Login()),
                        );
                      },
                      child: const Text(
                        'ACESSAR MINHA CONTA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const Cadastro()),
                        );
                      },
                      child: const Text(
                        'CRIAR UMA NOVA CONTA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
