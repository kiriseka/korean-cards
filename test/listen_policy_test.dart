import 'package:flutter_test/flutter_test.dart';
import 'package:korean_cards/speech/listen_policy.dart';

void main() {
  const policy = ListenPolicy();
  final start = DateTime(2026, 10, 26, 9);
  DateTime at(int ms) => start.add(Duration(milliseconds: ms));

  test('waits patiently for the first word', () {
    expect(policy.shouldStop(started: start, lastHeard: null, now: at(4000)), isFalse);
    expect(policy.shouldStop(started: start, lastHeard: null, now: at(8000)), isTrue);
  });

  test('a natural pause mid-sentence keeps listening; a longer quiet ends it', () {
    expect(policy.shouldStop(started: start, lastHeard: at(5000), now: at(6500)), isFalse);
    expect(policy.shouldStop(started: start, lastHeard: at(5000), now: at(8000)), isTrue);
    expect(policy.shouldStop(started: start, lastHeard: at(9000), now: at(10000)), isFalse, reason: 'past the start grace while talking');
  });

  test('never listens longer than the cap', () {
    expect(policy.shouldStop(started: start, lastHeard: at(24900), now: at(25000)), isTrue);
  });
}
