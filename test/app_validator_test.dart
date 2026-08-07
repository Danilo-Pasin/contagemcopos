import 'package:contagem/core/utils/app_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppValidator.isValidGroupCode', () {
    test('aceita códigos >= 3 caracteres', () {
      expect(AppValidator.isValidGroupCode('ABC'), isTrue);
      expect(AppValidator.isValidGroupCode('ABCDEF'), isTrue);
    });

    test('rejeita < 3 ou vazio', () {
      expect(AppValidator.isValidGroupCode(''), isFalse);
      expect(AppValidator.isValidGroupCode('AB'), isFalse);
      expect(AppValidator.isValidGroupCode('  '), isFalse);
    });
  });

  group('AppValidator.isValidName', () {
    test('nome vazio (inclusive espaços) é inválido', () {
      expect(AppValidator.isValidName(''), isFalse);
      expect(AppValidator.isValidName('   '), isFalse);
    });

    test('nome com conteúdo real é válido', () {
      expect(AppValidator.isValidName('Maria'), isTrue);
      expect(AppValidator.isValidName('  Ana  '), isTrue);
    });
  });

  group('AppValidator.isValidPassword', () {
    test('senha mínima de 5 caracteres (regra de negócio do login)', () {
      expect(AppValidator.isValidPassword('1234'), isFalse);
      expect(AppValidator.isValidPassword('12345'), isTrue);
      expect(AppValidator.isValidPassword('abcde'), isTrue);
    });
  });

  group('AppValidator.canSubmitLogin', () {
    test('exige código + nome + senha válidos juntos', () {
      expect(
        AppValidator.canSubmitLogin(code: 'ABC', name: 'X', password: '12345'),
        isTrue,
      );
      expect(
        AppValidator.canSubmitLogin(code: 'AB', name: 'X', password: '12345'),
        isFalse,
      );
      expect(
        AppValidator.canSubmitLogin(code: 'ABC', name: '', password: '12345'),
        isFalse,
      );
      expect(
        AppValidator.canSubmitLogin(code: 'ABC', name: 'X', password: '123'),
        isFalse,
      );
    });
  });
}