import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../telas/homeUsuario/HomeUsuario.dart';
import '../telas/homeAdmin/HomeAdmin.dart';
import '../telas/criarConta/Login.dart';

class Roteador extends StatelessWidget {
  const Roteador({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      // Escuta as mudanças de estado (Login/Logout) em tempo real
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // 1. Carregando...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;

        // 2. Se não tem sessão (Usuário não logado), manda pro Login
        if (session == null) {
          return const Login();
        }

        // 3. Se tem sessão, verifica se é ADMIN
        // Usamos os metadados do token (JWT) que é rápido e seguro
        final metadata = session.user.appMetadata;

        // Verifica diferentes variações possíveis da flag de admin
        final bool isAdmin =
            metadata['role'] == 'admin' ||
            metadata['admin'] == true ||
            metadata['is_admin'] == true;

        // 4. Direciona para a tela correta
        if (isAdmin) {
          return const HomeAdmin();
        }

        return const HomeUsuario();
      },
    );
  }
}
