import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'telas/login.dart';

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
      debugShowCheckedModeBanner: false, // Remove a faixa de debug
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // MUDANÇA 1: Agora começamos pela Tela de Apresentação
      home: const TelaApresentacao(),
    );
  }
}

// --- NOVA TELA DE APRESENTAÇÃO ---
class TelaApresentacao extends StatelessWidget {
  const TelaApresentacao({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fundo colorido para destacar
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Logo do Aplicativo (Usei um ícone por enquanto)
              const Spacer(),
              Image.asset('assets/logo.jpg', width: 400, height: 400),

              // 2. Botão para Ir para Login/Registro
              const Spacer(),
              SizedBox(
                width: double.infinity, // Botão ocupa a largura toda
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // Botão branco
                    foregroundColor: const Color.fromARGB(
                      255,
                      0,
                      94,
                      255,
                    ), // Texto azul
                    elevation: 5,
                  ),
                  onPressed: () {
                    // Navega para o Roteador, que decide se pede Login ou vai pra Home
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const logarRegistrar(),
                      ),
                    );
                  },
                  child: const Text(
                    'COMEÇAR',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- ROTEADOR (Mantido igual, mas agora é chamado pelo botão) ---
class logarRegistrar extends StatelessWidget {
  const logarRegistrar({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Usamos Scaffold aqui para a bolinha não ficar num fundo preto feio
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const MyHomePage(title: 'MinasLar');
        }
        return const LoginScreen();
      },
    );
  }
}

// --- SUA HOME PAGE (Mantida igual) ---
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _deslogar() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _deslogar,
            tooltip: 'Sair',
          ),
        ],
      ),
    );
  }
}
