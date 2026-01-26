import 'dart:async'; // Gerenciamento de assinaturas de eventos (Streams)
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'servicos/Autenticacao.dart';
import 'telas/criarConta/Login.dart';
import 'telas/criarConta/Cadastro.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import para initializeDateFormatting
import 'telas/homeUsuario/HomeUsuario.dart';
import 'telas/homeAdmin/HomeAdmin.dart';
import 'servicos/RedefinirSenha.dart';

// Permite navegação global sem necessidade de 'BuildContext' (essencial para callbacks assíncronos)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Supabase. O fluxo PKCE é obrigatório para Deep Links seguros em mobile.
  await Supabase.initialize(
    url: 'https://uwkxgmmjubpincteqckc.supabase.co',
    anonKey: 'sb_publishable_UxU085kaKfumrH-p6_oI8A_7CSzCJb8',
    // Certifique-se de que esta é a sua anonKey real.
    // Se for um placeholder, substitua-o pela chave pública do seu projeto Supabase.
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  // Inicializa a formatação de data para pt_BR globalmente, uma única vez.
  await initializeDateFormatting('pt_BR', null);

  runApp(const MyApp());
}

/// Widget principal com estado para gerenciar ouvintes de Deep Links
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  /// Monitora eventos de autenticação externos (ex: link de recuperação de senha clicado no e-mail)
  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      final AuthChangeEvent event = data.event;

      // Se o app foi aberto via link de recuperação, força a navegação para a tela de nova senha
      if (event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => const RedefinirSenhaScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel(); // Evita vazamento de memória ao fechar o app
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MinasLar',
      navigatorKey: navigatorKey, // Vincula a chave global
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
        // Exibe loading enquanto verifica se existe sessão cacheada
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
          // Verifica no banco de dados se o usuário possui permissão de Admin
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
              // Redireciona para a Home correta baseada na role
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
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                  ),
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const Login()));
                  },
                  child: const Text(
                    'Fazer Login',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Botão de Cadastro
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const Cadastro()));
                  },
                  child: const Text(
                    'Criar Conta',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
