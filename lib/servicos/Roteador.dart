import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importe suas telas
import '../telas/TelasPrincipais/HomeUsuario.dart';
import '../Telas/TelasPrincipais/HomeAdmin.dart';
import '../telas/criarConta/Login.dart';
import '../telas/criarConta/CriarConta.dart';
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
        return FutureBuilder<bool>(
          future: AuthService().verificarStatusAdmin(),
          builder: (context, adminSnapshot) {
            // Enquanto busca no banco, mostra loading
            if (adminSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: CircularProgressIndicator(color: Colors.blue),
                ),
              );
            }

            // Se deu erro na verificação, manda para a tela de usuário como fallback seguro
            if (adminSnapshot.hasError) {
              return const HomeUsuario();
            }

            final bool isAdmin = adminSnapshot.data ?? false;

            // 4. VERIFICAÇÃO FINAL USANDO SEU MODELO
            if (isAdmin) {
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
                          MaterialPageRoute(
                            builder: (_) => const CriarConta(isAdmin: false),
                          ),
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
