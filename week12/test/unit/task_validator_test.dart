import 'package:flutter_test/flutter_test.dart';
import 'package:week12_testing_qa/validators/task_validator.dart';

void main() {
  group('1. TaskValidator - isValidTaskTitle (Unit Test & Edge Cases)', () {
    test('Arrange: Judul normal, Act: isValidTaskTitle, Assert: Mengembalikan true', () {
      // Arrange
      const title = 'Belajar Testing Flutter';

      // Act
      final result = TaskValidator.isValidTaskTitle(title);

      // Assert
      expect(result, isTrue);
    });

    test('Edge Case: Menolak string kosong', () {
      expect(TaskValidator.isValidTaskTitle(''), isFalse);
    });

    test('Edge Case: Menolak string yang hanya berisi spasi', () {
      expect(TaskValidator.isValidTaskTitle('   '), isFalse);
    });

    test('Edge Case: Menolak string yang hanya berisi karakter tab atau newline', () {
      expect(TaskValidator.isValidTaskTitle('\t\n  '), isFalse);
    });

    test('Edge Case: Menolak judul di bawah batas minimum (1 atau 2 karakter)', () {
      expect(TaskValidator.isValidTaskTitle('A'), isFalse);
      expect(TaskValidator.isValidTaskTitle('AB'), isFalse);
      expect(TaskValidator.isValidTaskTitle('  A  '), isFalse);
    });

    test('Boundary Value: Menerima judul tepat di batas minimum (3 karakter)', () {
      expect(TaskValidator.isValidTaskTitle('ABC'), isTrue);
      expect(TaskValidator.isValidTaskTitle('  ABC  '), isTrue);
    });

    test('Boundary Value: Menerima judul tepat di batas maksimum (60 karakter)', () {
      final sixtyChars = 'A' * 60;
      expect(TaskValidator.isValidTaskTitle(sixtyChars), isTrue);
    });

    test('Boundary Value: Menolak judul yang melebihi batas maksimum (61 karakter)', () {
      final sixtyOneChars = 'A' * 61;
      expect(TaskValidator.isValidTaskTitle(sixtyOneChars), isFalse);
    });
  });

  group('2. TaskValidator - validateTaskTitle Error Messages', () {
    test('Mengembalikan pesan error jika null atau kosong', () {
      expect(
        TaskValidator.validateTaskTitle(null),
        equals('Judul tugas tidak boleh kosong'),
      );
      expect(
        TaskValidator.validateTaskTitle(''),
        equals('Judul tugas tidak boleh kosong'),
      );
      expect(
        TaskValidator.validateTaskTitle('   '),
        equals('Judul tugas tidak boleh kosong'),
      );
    });

    test('Mengembalikan pesan error jika kurang dari 3 karakter', () {
      expect(
        TaskValidator.validateTaskTitle('AB'),
        equals('Judul tugas minimal 3 karakter'),
      );
    });

    test('Mengembalikan pesan error jika lebih dari 60 karakter', () {
      final tooLong = 'X' * 61;
      expect(
        TaskValidator.validateTaskTitle(tooLong),
        equals('Judul tugas maksimal 60 karakter'),
      );
    });

    test('Mengembalikan null jika judul memenuhi seluruh kriteria', () {
      expect(
        TaskValidator.validateTaskTitle('Mengerjakan Tugas QA'),
        isNull,
      );
    });
  });

  group('3. TaskValidator - validateDescription', () {
    test('Menerima deskripsi null atau kosong (field opsional)', () {
      expect(TaskValidator.validateDescription(null), isNull);
      expect(TaskValidator.validateDescription(''), isNull);
    });

    test('Menerima deskripsi dalam batas 200 karakter', () {
      expect(TaskValidator.validateDescription('Deskripsi ringkas'), isNull);
      expect(TaskValidator.validateDescription('D' * 200), isNull);
    });

    test('Menolak deskripsi yang melebihi 200 karakter', () {
      expect(
        TaskValidator.validateDescription('D' * 201),
        equals('Deskripsi maksimal 200 karakter'),
      );
    });
  });
}
