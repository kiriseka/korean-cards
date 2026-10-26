/// Trainable grammar and number skills, scheduled like flashcards (Gym, smart review).
enum SkillGroup {
  particles('Particles', '🧲'),
  tenses('Verb tenses', '⏳'),
  numbers('Numbers & money', '🔢');

  const SkillGroup(this.title, this.emoji);
  final String title;
  final String emoji;
}

class Skill {
  const Skill(this.id, this.group, this.label, this.hint, {this.lessons = const []});
  final String id;
  final SkillGroup group;

  /// Short name: "은/는", "Past".
  final String label;

  /// What it is: "topic — what you're talking about".
  final String hint;

  /// Grammar lessons that teach it; finishing one starts its review schedule.
  final List<String> lessons;
}

const skills = <Skill>[
  Skill('p_topic', SkillGroup.particles, '은/는', 'topic — what the sentence is about', lessons: ['p1']),
  Skill('p_subject', SkillGroup.particles, '이/가', 'subject — who/what does it (new info)', lessons: ['p2', 'b4']),
  Skill('p_object', SkillGroup.particles, '을/를', 'object — what gets done', lessons: ['p3']),
  Skill('p_also', SkillGroup.particles, '도', 'also, too', lessons: ['p4']),
  Skill('p_to', SkillGroup.particles, '에', 'to / at a place or time', lessons: ['p5']),
  Skill('p_at', SkillGroup.particles, '에서', 'at a place, doing something', lessons: ['p6']),
  Skill('p_by', SkillGroup.particles, '(으)로', 'by (bus, subway…)', lessons: ['p9']),
  Skill('t_present', SkillGroup.tenses, 'Present', '-아요/어요 · I eat', lessons: ['t1', 't2']),
  Skill('t_past', SkillGroup.tenses, 'Past', '-았어요/었어요 · I ate', lessons: ['t3']),
  Skill('t_future', SkillGroup.tenses, 'Future', '-(으)ㄹ 거예요 · I will eat', lessons: ['t4']),
  Skill('t_progressive', SkillGroup.tenses, 'Right now', '-고 있어요 · I am eating', lessons: ['t5']),
  Skill('t_negative', SkillGroup.tenses, 'Not', '안 / -지 않아요 · I don\'t eat', lessons: ['t7']),
  Skill('t_formal', SkillGroup.tenses, 'Formal', '-ㅂ니다/습니다', lessons: ['t6']),
  Skill('t_context', SkillGroup.tenses, 'Which tense?', 'pick the tense from 어제 / 내일 / 지금', lessons: ['t4']),
  Skill('n_sino', SkillGroup.numbers, '일, 이, 삼', 'Sino-Korean numbers (dates, money, minutes)'),
  Skill('n_native', SkillGroup.numbers, '하나, 둘, 셋', 'native numbers (counting, age, hours)'),
  Skill('n_time', SkillGroup.numbers, 'Time', '세 시 삼십 분'),
  Skill('n_money', SkillGroup.numbers, 'Money', '만 오천 원'),
  Skill('n_counter', SkillGroup.numbers, 'Counters', '개, 명, 잔, 권, 장, 살'),
];

final skillsById = {for (final s in skills) s.id: s};

/// Skills a grammar lesson teaches.
List<Skill> skillsForLesson(String lessonId) => [for (final s in skills) if (s.lessons.contains(lessonId)) s];
