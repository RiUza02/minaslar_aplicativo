import 'package:flutter/material.dart';

import 'CriarConta.dart';

/// Tela responsável por permitir a escolha
/// do tipo de conta a ser criada
class Cadastro extends StatelessWidget {
  const Cadastro({super.key});

  @override
  Widget build(BuildContext context) {
    // Cores do padrão visual
    const Color corFundo = Colors.black;
    const Color corCard = Color(0xFF1E1E1E);
    final Color corTextoCinza = Colors.grey[500]!;

    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: const Text(
          'TIPO DE CONTA',
          style: TextStyle(
            fontSize: 14,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(flex: 1),

            // Título e Subtítulo
            const Text(
              'Vamos começar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha como você deseja se cadastrar no sistema.',
              style: TextStyle(color: corTextoCinza, fontSize: 16),
            ),

            const SizedBox(height: 40),

            // ==================================================
            // CARD: ADMINISTRADOR
            // ==================================================
            _buildSelectionCard(
              context: context,
              title: "Administrador",
              subtitle: "Gerenciar sistema",
              icon: Icons.admin_panel_settings,
              color: Colors.red[900]!,
              cardColor: corCard,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CriarConta(
                      isAdmin: true,
                      corPrincipal: Colors.red[900]!,
                      corSecundaria: Colors.blue[300]!,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // ==================================================
            // CARD: USUÁRIO COMUM
            // ==================================================
            _buildSelectionCard(
              context: context,
              title: "Usuário Comum",
              subtitle: "Acesso padrão",
              icon: Icons.person,
              color: Colors.blue[900]!,
              cardColor: corCard,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CriarConta(
                      isAdmin: false,
                      corPrincipal: Colors.blue[900]!,
                      corSecundaria: Colors.cyan[400]!,
                    ),
                  ),
                );
              },
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  /// Widget auxiliar para construir os cartões de seleção
  Widget _buildSelectionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color cardColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Ícone Circular
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color, // Usa a cor principal (Vermelho ou Azul)
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),

              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Seta indicativa
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey[600],
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
