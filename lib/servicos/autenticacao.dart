import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/usuario.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get usuarioAtual => _auth.currentUser;

  // ======================================================
  // 1. CADASTRO (Apenas Auth + Envio de E-mail)
  // ======================================================
  Future<String?> cadastrarUsuario({
    required String email,
    required String password,
  }) async {
    try {
      // Cria o usuário no Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        // Envia o e-mail de verificação
        await user.sendEmailVerification();
      }

      return null; // Sucesso
    } on FirebaseAuthException catch (e) {
      return _traduzirErro(e.code);
    } catch (e) {
      return "Erro desconhecido: $e";
    }
  }

  // ======================================================
  // 2. SALVAR DADOS NO FIRESTORE (ATUALIZADO COM TELEFONE)
  // ======================================================
  Future<String?> salvarDadosNoFirestore({
    required String uid,
    required String nome,
    required String email,
    required bool isAdmin,
    required String telefone, // <--- NOVO CAMPO OBRIGATÓRIO
  }) async {
    try {
      // Cria o objeto Usuario com todos os dados
      Usuario novoUsuario = Usuario(
        id: uid,
        nome: nome,
        email: email,
        isAdmin: isAdmin,
        telefone: telefone, // Passa o telefone para o modelo
      );

      // Salva na coleção 'usuarios' usando o método toMap() do modelo
      // Isso garante que os campos no banco fiquem iguais aos do código
      await _firestore.collection('usuarios').doc(uid).set(novoUsuario.toMap());

      return null; // Sucesso
    } on FirebaseException catch (e) {
      return e.message ?? 'Erro ao acessar o banco de dados.';
    } catch (e) {
      return 'Erro inesperado ao salvar dados: $e';
    }
  }

  // ======================================================
  // 3. RECUPERAÇÃO DE SENHA
  // ======================================================
  Future<String?> recuperarSenha({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _traduzirErro(e.code);
    }
  }

  // ======================================================
  // 4. OUTROS MÉTODOS (Login, Logout, Admin, etc)
  // ======================================================

  Future<String?> reenviarVerificacaoEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        return null;
      }
      return "Nenhum usuário logado.";
    } on FirebaseAuthException catch (e) {
      return _traduzirErro(e.code);
    }
  }

  Future<String?> loginUsuario({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _traduzirErro(e.code);
    }
  }

  Future<void> deslogar() async {
    await _auth.signOut();
  }

  Future<bool> isUsuarioAdmin() async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    try {
      DocumentSnapshot doc = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['isAdmin'] ?? false;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  String _traduzirErro(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'E-mail já cadastrado.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'weak-password':
        return 'A senha deve ter 6+ caracteres.';
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'invalid-credential':
        return 'Credenciais inválidas.';
      default:
        return 'Erro: $code';
    }
  }
}
