import 'package:flutter/material.dart';
import '../TelasAdmin/Dashboard.dart';
import 'ListaClienteAdmin.dart';
import 'CalendarioAdmin.dart';
import 'ListaOrcamentos.dart';
import '../TelasAdmin/ListaOrcamentosDia.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  // ==================================================
  // ESTADO E CONTROLADORES DE NAVEGAÇÃO
  // ==================================================

  // Agora inicia na página 0 (Painel/Dashboard)
  final PageController _pageController = PageController(
    initialPage: 2,
  ); // Dashboard continua sendo o primeiro item

  // 0: Painel | 1: Agenda | 2: Clientes | 3: Orçamentos
  int _selectedIndex = 2;

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
          // Index 0: Dashboard (Agora à esquerda da agenda)
          const Dashboard(),
          // Index 1: Visualização do Calendário
          const AgendaCalendario(),
          // Index 2: Novo Painel (Placeholder)
          ListaOrcamentosDia(dataSelecionada: DateTime.now()),
          // Index 3: Gestão de Clientes
          const ListaClientes(),
          // Index 4: Gestão de Orçamentos
          const ListaOrcamentos(),
        ],
      ),

      // ==================================================
      // BARRA DE NAVEGAÇÃO INFERIOR
      // ==================================================
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: Colors.red[900]),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _navegarParaPagina,
          backgroundColor: Colors.red[900],
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
          type: BottomNavigationBarType.fixed,
          items: const [
            // Item 0
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard', // Label renomeado
            ),
            // Item 1
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Agenda',
            ),
            // Item 2: Novo Painel
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), // Ícone diferente para distinção
              label: 'Painel',
            ),
            // Item 3: Clientes (Deslocado)
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Clientes',
            ),
            // Item 4: Orçamentos (Deslocado)
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
