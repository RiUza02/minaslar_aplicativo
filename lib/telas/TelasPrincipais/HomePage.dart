import 'package:flutter/material.dart';

import '../TelasPrincipais/Dashboard.dart';
import 'ListaCliente.dart';
import 'Calendario.dart';
import 'ListaOrcamentos.dart';
import 'OrcamentosDia.dart';
import '../AssistenteIA.dart';

class HomePage extends StatefulWidget {
  final bool isAdmin;

  const HomePage({super.key, required this.isAdmin});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController _pageController;
  late int _selectedIndex;

  late final List<Widget> _pages;
  late final List<BottomNavigationBarItem> _navBarItems;

  @override
  void initState() {
    super.initState();

    if (widget.isAdmin) {
      // Configuração para Administrador
      _selectedIndex = 3; // Inicia na tela "Painel"
      _pages = [
        const Dashboard(), // Index 0
        const AgendaCalendario(isAdmin: true), // Index 1
        TelaAssistente(isAdmin: widget.isAdmin), // Index 2
        OrcamentosDia(
          // Index 3
          dataSelecionada: DateTime.now(),
          isAdmin: true,
          apenasPendentes: true,
          mostrarConfiguracoes: true,
          mostrarTitulo: false,
        ),
        const ListaClientes(isAdmin: true), // Index 4
        const ListaOrcamentos(isAdmin: true), // Index 5
      ];
      _navBarItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month),
          label: 'Agenda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assistant),
          label: 'Assistente',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes'),
        BottomNavigationBarItem(
          icon: Icon(Icons.monetization_on),
          label: 'Orçamentos',
        ),
      ];
    } else {
      // Configuração para Usuário Comum
      _selectedIndex = 2; // Inicia na tela "Painel"
      _pages = [
        const AgendaCalendario(isAdmin: false), // Index 0
        TelaAssistente(isAdmin: widget.isAdmin), // Index 1
        OrcamentosDia(
          // Index 2
          dataSelecionada: DateTime.now(),
          isAdmin: false,
          apenasPendentes: true,
          mostrarConfiguracoes: true,
          mostrarTitulo: false,
        ),
        const ListaClientes(isAdmin: false), // Index 3
        const ListaOrcamentos(isAdmin: false), // Index 4
      ];
      _navBarItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month),
          label: 'Agenda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assistant),
          label: 'Assistente',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes'),
        BottomNavigationBarItem(
          icon: Icon(Icons.monetization_on),
          label: 'Orçamentos',
        ),
      ];
    }

    _pageController = PageController(initialPage: _selectedIndex);
  }

  void _navegarParaPagina(int index) {
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
    final Color navBarColor = widget.isAdmin
        ? Colors.red[900]!
        : Colors.blue[900]!;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _navegarParaPagina,
        backgroundColor: navBarColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        type: BottomNavigationBarType.fixed,
        items: _navBarItems,
      ),
    );
  }
}
