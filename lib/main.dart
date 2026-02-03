import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import para initializeDateFormatting

// Telas
import 'servicos/Autenticacao.dart';
import 'telas/criarConta/Login.dart';
import 'telas/criarConta/Cadastro.dart';
import 'telas/homeUsuario/HomeUsuario.dart';
import 'telas/homeAdmin/HomeAdmin.dart';

// Permite navegação global (ainda útil para contextos onde não temos o BuildContext direto)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Supabase
  await Supabase.initialize(
    url: 'https://uwkxgmmjubpincteqckc.supabase.co',
    anonKey: 'sb_publishable_UxU085kaKfumrH-p6_oI8A_7CSzCJb8',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Inicializa a formatação de data
  await initializeDateFormatting('pt_BR', null);

  runApp(const MyApp());
}

/// Widget principal da aplicação
/// Simplificado para StatelessWidget pois a lógica de rotas é reativa via StreamBuilder
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MinasLar',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,

      // Configuração do Tema Escuro
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.blue,
        colorScheme: const ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white54),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
          border: OutlineInputBorder(),
        ),
      ),

      initialRoute: '/',
      routes: {'/': (context) => const RoteadorTelas()},
    );
  }
}

/// Gerencia o roteamento inicial baseado no estado da sessão do usuário
class RoteadorTelas extends StatelessWidget {
  const RoteadorTelas({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Loading inicial enquanto verifica sessão cacheada
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;

        // ==================================================
        // USUÁRIO LOGADO
        // ==================================================
        if (session != null) {
          // Verifica se é Admin
          return FutureBuilder<bool>(
            future: AuthService().isUsuarioAdmin(),
            builder: (context, snapshotAdmin) {
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

              final bool isAdmin = snapshotAdmin.data ?? false;
              // Redireciona para a Home correta
              return isAdmin ? const HomeAdmin() : const HomeUsuario();
            },
          );
        }

        // ==================================================
        // USUÁRIO NÃO LOGADO
        // ==================================================
        return const TelaApresentacao();
      },
    );
  }
}

/// Tela de Landing Page (Login ou Cadastro)
class TelaApresentacao extends StatelessWidget {
  const TelaApresentacao({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.home_work, size: 150, color: Colors.blue),
              ),
              const Spacer(),

              // Botão de Login
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shadowColor: Colors.blue.withValues(alpha: 0.4),
                  ),
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const Login()));
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

              // Botão de Cadastro
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
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const Cadastro()));
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
    );
  }
}
