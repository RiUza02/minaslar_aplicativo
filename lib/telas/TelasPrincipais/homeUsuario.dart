import 'package:flutter/material.dart';
import 'ListaCliente.dart';
import 'ListaOrcamentos.dart';
import 'Calendario.dart';
import 'OrcamentosDia.dart'; // Import unificado

class HomeUsuario extends StatefulWidget {
  const HomeUsuario({super.key});

  @override
  State<HomeUsuario> createState() => _HomeUsuarioState();
}

class _HomeUsuarioState extends State<HomeUsuario> {
  // ==================================================
  // ESTADO E CONTROLADORES DE NAVEGAÇÃO
  // ==================================================

  // Agora inicia na página 0 (Painel/Dashboard)
  final PageController _pageController = PageController(
    initialPage: 1,
  ); // Dashboard continua sendo o primeiro item

  // 0: Painel | 1: Agenda | 2: Clientes | 3: Orçamentos
  int _selectedIndex = 1;

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
          const AgendaCalendario(isAdmin: false),
          // Index 1: Novo Painel (Placeholder)
          OrcamentosDia(
            dataSelecionada: DateTime.now(),
            isAdmin: false,
            apenasPendentes: true, // Isso faz o Painel filtrar os entregues
            mostrarConfiguracoes:
                true, // Mostra o botão de configurações na AppBar do Painel
            mostrarTitulo: false, // Não mostra o título na AppBar do Painel
          ), // Index 2: Gestão de Clientes
          const ListaClientes(isAdmin: false),
          // Index 3: Gestão de Orçamentos
          const ListaOrcamentos(isAdmin: false),
        ],
      ),

      // ==================================================
      // BARRA DE NAVEGAÇÃO INFERIOR
      // ==================================================
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: Colors.blue[900]),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _navegarParaPagina,
          backgroundColor: Colors.blue[900],
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
          type: BottomNavigationBarType.fixed,
          items: const [
            // Item 0: Agenda
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Agenda',
            ),
            // Item 1: Novo Painel
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), // Ícone diferente para distinção
              label: 'Painel',
            ),
            // Item 2: Clientes (Deslocado)
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Clientes',
            ),
            // Item 3: Orçamentos (Deslocado)
            BottomNavigationBarItem(
              icon: Icon(Icons.monetization_on),
              label: 'Orçamentos',
            ),
          ],
        ),
      ),
    );
  }
}
