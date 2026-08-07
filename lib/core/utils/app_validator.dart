/// Regras de validação de entrada comuns ao fluxo de login/entrada.
class AppValidator {
  const AppValidator._();

  /// Código de grupo precisa ter pelo menos 3 caracteres (ignorando espaços).
  static bool isValidGroupCode(String code) =>
      code.trim().length >= 3;

  /// Nome não pode ser vazio.
  static bool isValidName(String name) => name.trim().isNotEmpty;

  /// Senha mínima de 5 caracteres (sem exigir complexidade).
  static bool isValidPassword(String password) => password.length >= 5;

  /// Validação composta usada no botão de Login.
  static bool canSubmitLogin({
    required String code,
    required String name,
    required String password,
  }) =>
      isValidGroupCode(code) &&
      isValidName(name) &&
      isValidPassword(password);
}