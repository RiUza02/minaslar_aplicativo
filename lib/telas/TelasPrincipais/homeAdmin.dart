import 'package:flutter/material.dart';

import '../TelasPrincipais/Dashboard.dart';
import 'ListaCliente.dart';
import 'Calendario.dart';
import 'ListaOrcamentos.dart';
import 'OrcamentosDia.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  // ==================================================
  // ESTADO E CONTROLADORES DE NAVEGAÇÃO
  // ==================================================

  final PageController _pageController = PageController(
    initialPage: 2, // Começa no Painel
  );

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
        // IMPORTANTE: Impede que o usuário troque arrastando o dedo (padrão em abas)
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Index 0: Dashboard
          const Dashboard(),

          // Index 1: Visualização do Calendário
          const AgendaCalendario(isAdmin: true),

          // Index 2: Novo Painel (Painel do Dia)
          OrcamentosDia(
            dataSelecionada: DateTime.now(),
            isAdmin: true,
            apenasPendentes: true,
            mostrarConfiguracoes: true,
            mostrarTitulo: false,
          ),

          // Index 3: Gestão de Clientes
          const ListaClientes(isAdmin: true),

          // Index 4: Gestão de Orçamentos
          const ListaOrcamentos(isAdmin: true),
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
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Agenda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
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
}
