import 'package:flutter/material.dart';
// Importe as telas que eram usadas no Admin (ajuste os caminhos se necessário)
import 'ListaClienteUsuario.dart';
import 'CalendarioUsuario.dart';
import 'ListaOrcamentos.dart';
import '../TelasUsuario/ListaOrcamentosDia.dart';

class HomeUsuario extends StatefulWidget {
  const HomeUsuario({super.key});

  @override
  State<HomeUsuario> createState() => _HomeUsuarioState();
}

class _HomeUsuarioState extends State<HomeUsuario> {
  // ==================================================
  // ESTADO E CONTROLADORES DE NAVEGAÇÃO
  // ==================================================

  // Inicia na página 1 (Painel)
  final PageController _pageController = PageController(initialPage: 1);

  // Índices:
  // 0: Agenda
  // 1: Painel (Orçamentos do Dia)
  // 2: Clientes
  // 3: Orçamentos (Lista Geral)
  int _selectedIndex = 1;

  // TEMA AZUL (Diferente do Admin que é Vermelho)
  final Color corTema = Colors.blue[900]!;

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

  // ==================================================
  // CONSTRUÇÃO DA TELA
  // ==================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fundo geral escuro
      // CORPO COM AS TELAS (PageView)
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics:
            const NeverScrollableScrollPhysics(), // Navegação apenas pela barra inferior
        children: [
          // 0: Agenda
          const AgendaCalendario(),

          // 1: Painel (Lista do Dia - Apenas Pendentes para foco)
          ListaOrcamentosDia(
            dataSelecionada: DateTime.now(),
            apenasPendentes: true,
          ),

          // 2: Clientes
          const ListaClientes(), // Usando a mesma lista do Admin
          // 3: Orçamentos (Geral)
          const ListaOrcamentos(),
        ],
      ),

      // BARRA DE NAVEGAÇÃO INFERIOR
      bottomNavigationBar: Theme(
        // Aplica o tema azul na barra
        data: Theme.of(context).copyWith(canvasColor: corTema),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _navegarParaPagina,
          backgroundColor: corTema,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
          type: BottomNavigationBarType.fixed,
          items: const [
            // Item 0
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Agenda',
            ),
            // Item 1
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Painel',
            ),
            // Item 2
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Clientes',
            ),
            // Item 3
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
