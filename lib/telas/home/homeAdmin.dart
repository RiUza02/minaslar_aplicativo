import 'package:flutter/material.dart';
import '../../servicos/autenticacao.dart';
import 'ListaClienteAdmin.dart';
import 'CalendarioAdmin.dart';
import 'ListaOrcamentos.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  // ==================================================
  // ESTADO E CONTROLADORES DE NAVEGAÇÃO
  // ==================================================

  // Inicia na página 1 (Painel) ao invés da 0 (Agenda)
  final PageController _pageController = PageController(initialPage: 1);

  // Controle do índice ativo na BottomNavigationBar
  // 0: Agenda | 1: Painel | 2: Clientes | 3: Orçamentos
  int _selectedIndex = 1;

  /// Atualiza o estado e anima a transição do PageView
  void _navegarParaPagina(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  /// Sincroniza o ícone da barra inferior quando o usuário desliza a tela (swipe)
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
      // ==================================================
      // ESTRUTURA DE PÁGINAS (BODY)
      // ==================================================
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          // Index 0: Visualização do Calendário
          const AgendaCalendario(),

          // Index 1: Tela Inicial (Dashboard)
          _buildConteudoPainel(),

          // Index 2: Gestão de Clientes
          const ListaClientes(),

          // Index 3: Gestão de Orçamentos
          const ListaOrcamentos(),
        ],
      ),

      // ==================================================
      // BARRA DE NAVEGAÇÃO INFERIOR
      // ==================================================
      bottomNavigationBar: Theme(
        // Força a cor vermelha no canvas para cobrir toda a área da barra
        data: Theme.of(context).copyWith(canvasColor: Colors.red[900]),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _navegarParaPagina,
          backgroundColor: Colors.red[900],
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,

          // 'fixed' impede que os ícones fiquem brancos/invisíveis quando há mais de 3 itens
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
            BottomNavigationBarItem(
              icon: Icon(Icons.monetization_on),
              label: 'Orçamentos',
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // WIDGETS AUXILIARES (DASHBOARD)
  // ==================================================
  Widget _buildConteudoPainel() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel Administrativo"),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          // Botão de Logout
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              AuthService().deslogar();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              "Bem-vindo, Administrador!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Indicador visual de navegação (Setas)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_left, color: Colors.grey),
                const Text("Agenda", style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 20),

                // Divisor vertical sutil
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),

                const SizedBox(width: 20),
                const Text(
                  "Clientes > Orçamentos",
                  style: TextStyle(color: Colors.grey),
                ),
                const Icon(Icons.arrow_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
