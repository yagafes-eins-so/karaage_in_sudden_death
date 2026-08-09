import 'package:flutter_test/flutter_test.dart';
import 'package:karaage_in/viewmodels/game_view_model.dart';

void main() {
  group('GameViewModel sudden death', () {
    test('a miss ends the game immediately', () {
      final vm = GameViewModel()..startGame();
      vm.registerThrow(success: false);
      expect(vm.phase, SessionPhase.result);
      expect(vm.canThrow, false);
    });

    test('successes keep the game going with no throw limit', () {
      final vm = GameViewModel()..startGame();
      for (int i = 0; i < 10; i++) {
        vm.registerThrow(success: true);
      }
      expect(vm.phase, SessionPhase.playing);
      expect(vm.canThrow, true);
      expect(vm.landedInCup, 10);
    });

    test('throws registered after game over are ignored', () {
      final vm = GameViewModel()..startGame();
      vm.registerThrow(success: false);
      vm.registerThrow(success: true);
      expect(vm.landedInCup, 0);
      expect(vm.phase, SessionPhase.result);
    });

    test('the streak resets on retry', () {
      final vm = GameViewModel()..startGame();
      for (int i = 0; i < 5; i++) {
        vm.registerThrow(success: true);
      }
      vm.registerThrow(success: false);
      vm.retry();
      expect(vm.landedInCup, 0);
      expect(vm.phase, SessionPhase.playing);
    });
  });

  group('GameViewModel cup speed (sudden death step table)', () {
    test('1~5 consecutive successes stay at 1x the base speed', () {
      final vm = GameViewModel()..startGame();
      final baseSpeed = vm.currentDifficulty.speed;
      expect(vm.cupSpeed, baseSpeed);

      for (int i = 0; i < 5; i++) {
        vm.registerThrow(success: true);
        expect(vm.cupSpeed, baseSpeed);
      }
    });

    test('6~10 consecutive successes are 1.5x the base speed', () {
      final vm = GameViewModel()..startGame();
      final baseSpeed = vm.currentDifficulty.speed;
      for (int i = 0; i < 6; i++) {
        vm.registerThrow(success: true);
      }
      expect(vm.cupSpeed, closeTo(baseSpeed * 1.5, 0.0001));

      for (int i = 0; i < 4; i++) {
        vm.registerThrow(success: true);
      }
      expect(vm.landedInCup, 10);
      expect(vm.cupSpeed, closeTo(baseSpeed * 1.5, 0.0001));
    });

    test('11~15 consecutive successes are 2x the base speed', () {
      final vm = GameViewModel()..startGame();
      final baseSpeed = vm.currentDifficulty.speed;
      for (int i = 0; i < 11; i++) {
        vm.registerThrow(success: true);
      }
      expect(vm.cupSpeed, closeTo(baseSpeed * 2.0, 0.0001));
    });

    test('16~20 consecutive successes are 2.5x the base speed', () {
      final vm = GameViewModel()..startGame();
      final baseSpeed = vm.currentDifficulty.speed;
      for (int i = 0; i < 16; i++) {
        vm.registerThrow(success: true);
      }
      expect(vm.cupSpeed, closeTo(baseSpeed * 2.5, 0.0001));
    });

    test('21+ consecutive successes are capped at 3x the base speed', () {
      final vm = GameViewModel()..startGame();
      final baseSpeed = vm.currentDifficulty.speed;
      for (int i = 0; i < 21; i++) {
        vm.registerThrow(success: true);
      }
      expect(vm.cupSpeed, closeTo(baseSpeed * 3.0, 0.0001));

      for (int i = 0; i < 20; i++) {
        vm.registerThrow(success: true);
      }
      expect(vm.cupSpeed, closeTo(baseSpeed * 3.0, 0.0001));
    });

    test('resets to the base speed on retry', () {
      final vm = GameViewModel()..startGame();
      for (int i = 0; i < 6; i++) {
        vm.registerThrow(success: true);
      }
      vm.registerThrow(success: false);
      vm.retry();
      expect(vm.cupSpeed, vm.currentDifficulty.speed);
    });

    test('cupSpeedMultiplier tracks the same step table independent of difficulty', () {
      final vm = GameViewModel()..startGame();
      expect(vm.cupSpeedMultiplier, 1.0);
      for (int i = 0; i < 6; i++) {
        vm.registerThrow(success: true);
      }
      expect(vm.cupSpeedMultiplier, 1.5);
      expect(vm.cupSpeed, vm.currentDifficulty.speed * vm.cupSpeedMultiplier);
    });
  });
}
