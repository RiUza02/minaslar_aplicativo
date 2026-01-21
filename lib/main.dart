import 'dart:async'; // Import necessário para StreamSubscription
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'servicos/Autenticacao.dart';
import 'telas/criarConta/Login.dart';
import 'telas/criarConta/Cadastro.dart';
import 'telas/home/HomeUsuario.dart';
import 'telas/home/HomeAdmin.dart';
import 'servicos/RedefinirSenha.dart';

// 1. Chave Global de Navegação (Permite navegar sem context)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicialização com PKCE (Obrigatório para Deep Links mobile funcionarem bem)
  await Supabase.initialize(
    url: 'https://uwkxgmmjubpincteqckc.supabase.co',
    anonKey: 'sb_publishable_UxU085kaKfumrH-p6_oI8A_7CSzCJb8',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const MyApp());
}

/// Transformei em Stateful para poder usar o initState e ouvir o Deep Link
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Variável para controlar a assinatura do ouvinte e cancelar se o app fechar
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  /// Configura o "Porteiro" que vigia se chegou um link de recuperação de senha
  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      final AuthChangeEvent event = data.event;

      // Se o evento for RECUPERAÇÃO DE SENHA
      if (event == AuthChangeEvent.passwordRecovery) {
        // Usa a chave global para empurrar a tela de Nova Senha
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => const RedefinirSenhaScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel(); // Boa prática: parar de ouvir ao fechar o app
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MinasLar',
      navigatorKey: navigatorKey, // <--- Conecta a chave global aqui
      debugShowCheckedModeBanner: false,

      // Tema global do app
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

      // Tela inicial controlada pelo roteador
      initialRoute: '/',
      routes: {'/': (context) => const RoteadorTelas()},
    );
  }
}

/// Responsável por decidir qual tela será exibida
class RoteadorTelas extends StatelessWidget {
  const RoteadorTelas({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
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

/// Tela inicial exibida para usuários não autenticados
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
              // Logo do aplicativo
              Image.asset(
                'assets/logo.jpg',
                width: 300,
                height: 300,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.home_work, size: 150, color: Colors.blue),
              ),
              const Spacer(),
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
