import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'servicos/autenticacao.dart';
import 'telas/login.dart';
import 'telas/cadastro.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // ⚠️ COLOQUE SUAS CHAVES AQUI
    url: 'https://uwkxgmmjubpincteqckc.supabase.co',
    anonKey: 'sb_publishable_UxU085kaKfumrH-p6_oI8A_7CSzCJb8',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MinasLar',
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
      initialRoute: '/',
      routes: {'/': (context) => const RoteadorTelas()},
    );
  }
}

// ==========================================
// ROTEADOR DE TELAS (CORRIGIDO PARA SUPABASE)
// ==========================================
class RoteadorTelas extends StatelessWidget {
  const RoteadorTelas({super.key});

  @override
  Widget build(BuildContext context) {
    // MUDANÇA CRÍTICA: Ouvindo Supabase em vez de Firebase
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Verifica se existe uma sessão válida (Usuário logado)
        final session = snapshot.data?.session;

        if (session != null) {
          // Usuário está logado -> Verifica se é Admin
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

              if (isAdmin) {
                return const HomeAdminScreen();
              } else {
                return const HomeUsuarioScreen();
              }
            },
          );
        }

        // Se session for nula, usuário não está logado
        return const TelaApresentacao();
      },
    );
  }
}

// =========================
// TELA 1: HOME USUÁRIO
// =========================
class HomeUsuarioScreen extends StatelessWidget {
  const HomeUsuarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Área do Usuário"),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => AuthService().deslogar(),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            Text("Bem-vindo, Usuário!", style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}

// =========================
// TELA 2: HOME ADMIN
// =========================
class HomeAdminScreen extends StatelessWidget {
  const HomeAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel Admin"),
        backgroundColor: Colors.red[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => AuthService().deslogar(),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 80, color: Colors.red),
            SizedBox(height: 20),
            Text("Bem-vindo, Administrador!", style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}

// =========================
// TELA DE APRESENTAÇÃO
// =========================
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
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EscolhaTipoCadastroScreen(),
                      ),
                    );
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
