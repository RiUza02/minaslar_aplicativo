import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../servicos/autenticacao.dart';
import '../telas/home/HomeUsuario.dart';
import '../telas/home/HomeAdmin.dart';
import '../telas/criarConta/Login.dart';

/// Tela responsável por decidir qual página o usuário verá:
/// - Login (se não estiver autenticado)
/// - Home de Admin
/// - Home de Usuário comum
class Roteador extends StatelessWidget {
  const Roteador({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuta mudanças no estado de autenticação do Supabase
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Enquanto o Supabase ainda não respondeu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Obtém a sessão atual (null se não estiver logado)
        final session = snapshot.data?.session;

        // ======================================================
        // USUÁRIO LOGADO
        // ======================================================
        if (session != null) {
          // Verifica se o usuário possui permissão de administrador
          return FutureBuilder<bool>(
            future: AuthService().isUsuarioAdmin(),
            builder: (context, snapshotAdmin) {
              // Enquanto valida as permissões
              if (snapshotAdmin.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text("Verificando permissões..."),
                      ],
                    ),
                  ),
                );
              }

              // Se for admin, vai para a HomeAdmin
              if (snapshotAdmin.data == true) {
                return const HomeAdmin();
              }

              // Caso contrário, vai para a Home do usuário comum
              return const HomeUsuario();
            },
          );
        }

        // ======================================================
        // USUÁRIO NÃO LOGADO
        // ======================================================
        return const Login();
      },
    );
  }
}
