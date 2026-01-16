import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/usuario.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get usuarioAtual => _auth.currentUser;

  // =========================
  // 1. CADASTRO (Apenas Auth + E-mail)
  // =========================
  Future<String?> cadastrarUsuario({
    required String email,
    required String password,
    // Nota: Nome e isAdmin não são usados aqui agora, pois serão passados
    // para a tela de verificação para serem salvos depois.
  }) async {
    try {
      // Cria o usuário no Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        // Envia o e-mail e não salva nada no banco ainda
        await user.sendEmailVerification();
      }

      return null; // Sucesso
    } on FirebaseAuthException catch (e) {
      return _traduzirErro(e.code);
    } catch (e) {
      return "Erro desconhecido: $e";
    }
  }

  // =========================
  // 2. SALVAR DADOS (Novo Método)
  // =========================
  // Este método é chamado pela VerificacaoEmailScreen após o e-mail ser validado
  Future<String?> salvarDadosUsuario({
    required String uid,
    required String nome,
    required String email,
    required bool isAdmin,
  }) async {
    try {
      Usuario novoUsuario = Usuario(
        id: uid,
        nome: nome,
        email: email,
        isAdmin: isAdmin,
      );

      await _firestore.collection('usuarios').doc(uid).set(novoUsuario.toMap());

      return null; // Sucesso
    } catch (e) {
      return 'Erro ao salvar dados no banco: $e';
    }
  }

  // ======================================================
  // SALVAR DADOS APÓS VERIFICAÇÃO
  // ======================================================
  Future<String?> salvarDadosNoFirestore({
    required String uid,
    required String nome,
    required String email,
    required bool isAdmin,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'nome': nome,
        'email': email,
        'isAdmin': isAdmin,
        // Opcional: Data de criação para ordenação futura
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null; // Sucesso (null significa sem erros)
    } on FirebaseException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro desconhecido ao salvar dados do usuário.';
    }
  }

  // =========================
  // REENVIAR E-MAIL
  // =========================
  Future<String?> reenviarVerificacaoEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        return null;
      } else {
        return "Nenhum usuário logado.";
      }
    } on FirebaseAuthException catch (e) {
      return _traduzirErro(e.code);
    } catch (e) {
      return "Erro: $e";
    }
  }

  // =========================
  // LOGIN, LOGOUT E RECUPERAÇÃO (Mantidos iguais)
  // =========================
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

  Future<String?> recuperarSenha({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'E-mail não encontrado.';
      if (e.code == 'invalid-email') return 'E-mail inválido.';
      return 'Erro: ${e.message}';
    }
  }

  // =========================
  // VERIFICAÇÃO DE ADMIN
  // =========================
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
      // Em caso de erro de leitura (ex: regras de segurança antes de ter o doc), retorna false
      return false;
    }
    return false;
  }

  // =========================
  // TRATAMENTO DE ERROS
  // =========================
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
      case 'invalid-credential':
        return 'Credenciais inválidas.';
      default:
        return 'Erro: $code';
    }
  }
}
