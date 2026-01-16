import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/usuario.dart';

class AuthService {
  // Acesso às ferramentas do Firebase: Auth (Login) e Firestore (Banco de Dados)
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Atalho para pegar o usuário logado agora (retorna null se ninguém estiver logado)
  User? get usuarioAtual => _auth.currentUser;

  // --- CADASTRAR (Cria conta no Auth + Salva dados no Banco) ---
  Future<String?> cadastrarUsuario({
    required String nome,
    required String email,
    required String password,
    bool isAdmin = false,
  }) async {
    try {
      // 1. Cria a conta de segurança (E-mail e Senha) no Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // 2. Obtém o ID único (UID) que o Firebase gerou para este usuário
      String uid = userCredential.user!.uid;

      // 3. Monta o objeto Usuario com os dados extras
      Usuario novoUsuario = Usuario(
        id: uid,
        nome: nome,
        email: email,
        isAdmin: isAdmin,
      );

      // 4. Grava no banco de dados (coleção 'usuarios') usando o mesmo UID
      // Isso permite vincular o login aos dados pessoais (nome, admin, etc)
      await _firestore.collection('usuarios').doc(uid).set(novoUsuario.toMap());

      return null; // Retorna null indicando SUCESSO
    } on FirebaseAuthException catch (e) {
      return _traduzirErro(e.code); // Retorna erro traduzido
    } catch (e) {
      return "Erro desconhecido: $e";
    }
  }

  // --- LOGIN (Apenas autentica) ---
  Future<String?> loginUsuario({
    required String email,
    required String password,
  }) async {
    try {
      // Tenta bater no Firebase Auth com email e senha
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Sucesso
    } on FirebaseAuthException catch (e) {
      return _traduzirErro(e.code); // Erro tratado
    }
  }

  // --- LOGOUT ---
  Future<void> deslogar() async {
    await _auth.signOut(); // Desconecta o usuário do app
  }

  // --- VERIFICAR PERMISSÃO (Admin) ---
  // Consulta o banco de dados para saber se o usuário tem poderes de Admin
  Future<bool> isUsuarioAdmin() async {
    User? user = _auth.currentUser;
    if (user == null) return false; // Se não tem usuário, não é admin

    // Busca o documento deste usuário na coleção 'usuarios'
    DocumentSnapshot doc = await _firestore
        .collection('usuarios')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      // Lê o campo 'isAdmin'. Se não existir, assume false.
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return data['isAdmin'] ?? false;
    }
    return false;
  }

  // --- TRADUTOR DE ERROS ---
  // Converte códigos técnicos do Firebase (inglês) para mensagens legíveis
  String _traduzirErro(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este e-mail já está sendo usado.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      default:
        return 'Erro ao acessar: $code';
    }
  }
}
