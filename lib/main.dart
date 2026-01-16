import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'servicos/autenticacao.dart'; // Certifique-se de importar seu AuthService
import 'telas/login.dart';
import 'telas/cadastro.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MinasLar',
      debugShowCheckedModeBanner: false,

      // =========================
      // TEMA GLOBAL
      // =========================
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

      // O app começa aqui
      home: const RoteadorTelas(),
    );
  }
}

// ==========================================
// ROTEADOR DE TELAS (Lógica de Redirecionamento)
// ==========================================
class RoteadorTelas extends StatelessWidget {
  const RoteadorTelas({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Monitora o Login (Auth)
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Carregando autenticação...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Se tem usuário logado...
        if (snapshot.hasData) {
          // 2. Verifica se é Admin ou Comum (Firestore)
          return FutureBuilder<bool>(
            future: AuthService().isUsuarioAdmin(), // Busca no banco
            builder: (context, snapshotAdmin) {
              // Carregando verificação de admin...
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

              // Define qual tela abrir
              final bool isAdmin = snapshotAdmin.data ?? false;

              if (isAdmin) {
                return const HomeAdminScreen(); // TELA 2 (ADMIN)
              } else {
                return const HomeUsuarioScreen(); // TELA 1 (COMUM)
              }
            },
          );
        }

        // Se não está logado, mostra apresentação
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
        backgroundColor: Colors.red[900], // Cor diferente para diferenciar
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
// TELA DE APRESENTAÇÃO (Login/Cadastro)
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
