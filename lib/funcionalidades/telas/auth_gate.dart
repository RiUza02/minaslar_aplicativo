import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importe suas telas
import '../telas/TelasPrincipais/HomePage.dart';
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
              return const HomePage(isAdmin: false);
            }

            final bool isAdmin = adminSnapshot.data ?? false;

            // 4. VERIFICAÇÃO FINAL USANDO SEU MODELO
            if (isAdmin) {
              return const HomePage(isAdmin: true);
            } else {
              return const HomePage(isAdmin: false);
            }
          },
        );
      },
    );
  }
}

// ... (Mantenha a classe TelaApresentacao aqui embaixo igual estava) ...
