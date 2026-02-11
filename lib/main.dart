import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Telas
import 'servicos/Autenticacao.dart';
import 'telas/criarConta/Login.dart';
import 'telas/criarConta/Cadastro.dart';
import 'telas/homeUsuario/HomeUsuario.dart';
import 'telas/homeAdmin/HomeAdmin.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://uwkxgmmjubpincteqckc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV3a3hnbW1qdWJwaW5jdGVxY2tjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg2ODUzNzksImV4cCI6MjA4NDI2MTM3OX0.nILR04gZURU_i1EC9YJihTIITtm-sKQkGZWVIEcm3ck',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  await initializeDateFormatting('pt_BR', null);

  // =========================================================
  // LÓGICA DE INICIALIZAÇÃO RÁPIDA (CACHE-FIRST)
  // =========================================================
  final prefs = await SharedPreferences.getInstance();

  // Verifica se tem sessão ativa no Supabase
  final bool existeSessao =
      Supabase.instance.client.auth.currentSession != null;

  // Lê a permissão salva no disco (0ms de delay na UI)
  final bool ehAdminCache = prefs.getBool('IS_ADMIN') ?? false;

  // Decide a tela inicial antes de rodar o app
  final Widget telaInicialDecidida = existeSessao
      ? (ehAdminCache ? const HomeAdmin() : const HomeUsuario())
      : const TelaApresentacao();

  runApp(MyApp(rotaInicial: telaInicialDecidida));
}

class MyApp extends StatelessWidget {
  final Widget rotaInicial;

  const MyApp({super.key, required this.rotaInicial});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MinasLar',
      home: rotaInicial,
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
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
      // Agora a classe RoteadorTelas existe lá embaixo ↓
      routes: {'/roteador': (context) => const RoteadorTelas()},
    );
  }
}

// ============================================================
// CLASSE ROTEADORTELAS (Estava faltando esta parte)
// ============================================================
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

        // USUÁRIO LOGADO
        if (session != null) {
          // Usa a verificação síncrona que criamos no AuthService
          final bool isAdmin = AuthService().isUsuarioAdmin();

          if (isAdmin) {
            return const HomeAdmin();
          } else {
            return const HomeUsuario();
          }
        }

        // USUÁRIO NÃO LOGADO
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
