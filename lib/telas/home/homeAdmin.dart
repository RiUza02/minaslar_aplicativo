import 'package:flutter/material.dart';
import '../../servicos/autenticacao.dart';
import 'ListaCliente.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  // ==========================================================
  // CONTROLADORES DE ESTADO PARA NAVEGAÇÃO
  // ==========================================================

  // Controlador para gerenciar o deslize das páginas
  final PageController _pageController = PageController();

  // Índice atual da navegação (0 = Painel, 1 = Novo Cliente)
  int _selectedIndex = 0;

  // Atualiza o índice e a página quando a aba inferior é clicada
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Animação suave ao trocar de aba clicando
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  // Atualiza o índice da barra inferior quando a tela é deslizada (Swipe)
  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ==========================================================
      // ESTRUTURA DE PÁGINAS COM DESLIZE (SWIPE)
      // ==========================================================
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          // --- PÁGINA 1: O PAINEL ANTIGO ---
          _buildConteudoPainel(),

          // --- PÁGINA 2: TELA DE ADICIONAR CLIENTE ---
          const ListaClientes(),
        ],
      ),

      // ==========================================================
      // BARRA DE NAVEGAÇÃO INFERIOR (HOTBAR)
      // ==========================================================
      bottomNavigationBar: Theme(
        // Envolvemos num Theme para garantir que o efeito de clique fique bonito no vermelho
        data: Theme.of(context).copyWith(canvasColor: Colors.red[900]),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,

          // --- CORES ATUALIZADAS AQUI ---
          backgroundColor: Colors.red[900], // Fundo Vermelho Escuro
          selectedItemColor: Colors.white, // Ícone/Texto Ativo: Branco Puro
          unselectedItemColor: Colors
              .white60, // Ícone/Texto Inativo: Branco levemente transparente
          type: BottomNavigationBarType
              .fixed, // Garante a renderização correta da cor
          // ------------------------------
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Painel',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_add),
              label: 'Clientes',
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CONTEÚDO ORIGINAL DA HOME (CONVERTIDO EM WIDGET)
  // ==========================================================
  Widget _buildConteudoPainel() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel Administrativo"),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              AuthService().deslogar();
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 64, color: Colors.red),
            SizedBox(height: 20),
            Text(
              "Bem-vindo, Administrador!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Deslize para > adicionar clientes",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
