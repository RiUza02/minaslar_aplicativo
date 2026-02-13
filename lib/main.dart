import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- 1. A Classe Usuario ---
class Usuario {
  final String nome;

  Usuario({required this.nome});

  // O Supabase precisa receber os dados em formato de Mapa (JSON)
  Map<String, dynamic> toMap() {
    return {'nome': nome};
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- 2. Inicialização do Supabase ---
  await Supabase.initialize(
    // SUBSTITUA PELOS SEUS DADOS DO DASHBOARD DO SUPABASE
    url: 'https://jhhikbhqmsbxylttrtbx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpoaGlrYmhxbXNieHlsdHRydGJ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5OTQyODEsImV4cCI6MjA4NjU3MDI4MX0.PTBW_OdAxIKSRxDZXPShoXizPM6DFw0lrvdG7e_m9ic',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Cadastro Supabase')),
        body: const CadastroScreen(),
      ),
    );
  }
}

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _nomeController = TextEditingController();

  // Acesso ao cliente do Supabase
  final supabase = Supabase.instance.client;
  Future<void> _salvarUsuario() async {
    final nomeDigitado = _nomeController.text;

    if (nomeDigitado.isEmpty) return;

    try {
      // --- MUDANÇA AQUI ---
      // Em vez de insert manual, nós criamos o Login (Sign Up).
      // O Trigger no banco vai detectar isso e salvar o nome na tabela 'usuarios'.

      // Obs: Para teste rápido, estou gerando um email aleatório baseado no tempo
      // Em um app real, você pediria o email e senha ao usuário.
      final emailFicticio =
          '${DateTime.now().millisecondsSinceEpoch}@teste.com';

      await supabase.auth.signUp(
        email: emailFicticio,
        password: 'senha123456', // Senha de teste
        data: {
          'nome': nomeDigitado, // <--- O Trigger vai pegar esse dado aqui!
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário cadastrado e Trigger disparado!'),
          ),
        );
        _nomeController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _nomeController,
            decoration: const InputDecoration(
              labelText: 'Digite o nome do usuário',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _salvarUsuario,
            child: const Text('Salvar no Banco de Dados'),
          ),
        ],
      ),
    );
  }
}
