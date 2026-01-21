import 'package:flutter/material.dart';
import '../../servicos/autenticacao.dart';
import 'ListaClienteAdmin.dart';
import 'CalendarioAdmin.dart';

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
  // initialPage: 1 define que o Painel (índice 1) é a tela inicial
  final PageController _pageController = PageController(initialPage: 1);

  // Índice atual da navegação (0 = Agenda, 1 = Painel, 2 = Clientes)
  int _selectedIndex = 1;

  // Atualiza o índice e a página quando a aba inferior ou ícone é clicado
  void _navegarParaPagina(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Animação suave ao trocar de tela
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
          // --- PÁGINA 0 (ESQUERDA): AGENDA / CALENDÁRIO ---
          const AgendaCalendario(),

          // --- PÁGINA 1 (CENTRO): O PAINEL PRINCIPAL ---
          _buildConteudoPainel(),

          // --- PÁGINA 2 (DIREITA): LISTA DE CLIENTES ---
          const ListaClientes(),
        ],
      ),

      // ==========================================================
      // BARRA DE NAVEGAÇÃO INFERIOR (HOTBAR)
      // ==========================================================
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: Colors.red[900]),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _navegarParaPagina,

          // --- CORES ---
          backgroundColor: Colors.red[900],
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
          type: BottomNavigationBarType.fixed,

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Agenda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Painel',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Clientes',
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CONTEÚDO DO PAINEL (CONVERTIDO EM WIDGET)
  // ==========================================================
  Widget _buildConteudoPainel() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel Administrativo"),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        centerTitle: true,
        // Ícone à esquerda para acessar a Agenda rapidamente
        leading: IconButton(
          icon: const Icon(Icons.calendar_month),
          tooltip: "Ver Agenda",
          onPressed: () =>
              _navegarParaPagina(0), // Vai para o índice 0 (Agenda)
        ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_left, color: Colors.grey),
                Text("Agenda", style: TextStyle(color: Colors.grey)),
                SizedBox(width: 20),
                Text("Clientes", style: TextStyle(color: Colors.grey)),
                Icon(Icons.arrow_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
