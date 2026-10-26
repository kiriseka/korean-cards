// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $WordsTable extends Words with TableInfo<$WordsTable, Word> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _homonymMeta = const VerificationMeta(
    'homonym',
  );
  @override
  late final GeneratedColumn<int> homonym = GeneratedColumn<int>(
    'homonym',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _posMeta = const VerificationMeta('pos');
  @override
  late final GeneratedColumn<String> pos = GeneratedColumn<String>(
    'pos',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hanjaMeta = const VerificationMeta('hanja');
  @override
  late final GeneratedColumn<String> hanja = GeneratedColumn<String>(
    'hanja',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pronunciationMeta = const VerificationMeta(
    'pronunciation',
  );
  @override
  late final GeneratedColumn<String> pronunciation = GeneratedColumn<String>(
    'pronunciation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sensesMeta = const VerificationMeta('senses');
  @override
  late final GeneratedColumn<String> senses = GeneratedColumn<String>(
    'senses',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rankMeta = const VerificationMeta('rank');
  @override
  late final GeneratedColumn<int> rank = GeneratedColumn<int>(
    'rank',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCustomMeta = const VerificationMeta(
    'isCustom',
  );
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
    'is_custom',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_custom" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _starredMeta = const VerificationMeta(
    'starred',
  );
  @override
  late final GeneratedColumn<bool> starred = GeneratedColumn<bool>(
    'starred',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("starred" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formsMeta = const VerificationMeta('forms');
  @override
  late final GeneratedColumn<String> forms = GeneratedColumn<String>(
    'forms',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    word,
    homonym,
    pos,
    level,
    hanja,
    pronunciation,
    category,
    senses,
    rank,
    isCustom,
    starred,
    note,
    unit,
    forms,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words';
  @override
  VerificationContext validateIntegrity(
    Insertable<Word> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('homonym')) {
      context.handle(
        _homonymMeta,
        homonym.isAcceptableOrUnknown(data['homonym']!, _homonymMeta),
      );
    }
    if (data.containsKey('pos')) {
      context.handle(
        _posMeta,
        pos.isAcceptableOrUnknown(data['pos']!, _posMeta),
      );
    } else if (isInserting) {
      context.missing(_posMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('hanja')) {
      context.handle(
        _hanjaMeta,
        hanja.isAcceptableOrUnknown(data['hanja']!, _hanjaMeta),
      );
    }
    if (data.containsKey('pronunciation')) {
      context.handle(
        _pronunciationMeta,
        pronunciation.isAcceptableOrUnknown(
          data['pronunciation']!,
          _pronunciationMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('senses')) {
      context.handle(
        _sensesMeta,
        senses.isAcceptableOrUnknown(data['senses']!, _sensesMeta),
      );
    } else if (isInserting) {
      context.missing(_sensesMeta);
    }
    if (data.containsKey('rank')) {
      context.handle(
        _rankMeta,
        rank.isAcceptableOrUnknown(data['rank']!, _rankMeta),
      );
    } else if (isInserting) {
      context.missing(_rankMeta);
    }
    if (data.containsKey('is_custom')) {
      context.handle(
        _isCustomMeta,
        isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta),
      );
    }
    if (data.containsKey('starred')) {
      context.handle(
        _starredMeta,
        starred.isAcceptableOrUnknown(data['starred']!, _starredMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('forms')) {
      context.handle(
        _formsMeta,
        forms.isAcceptableOrUnknown(data['forms']!, _formsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Word map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Word(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      homonym: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}homonym'],
      )!,
      pos: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pos'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      hanja: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hanja'],
      ),
      pronunciation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pronunciation'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      senses: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}senses'],
      )!,
      rank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rank'],
      )!,
      isCustom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_custom'],
      )!,
      starred: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}starred'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      forms: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}forms'],
      ),
    );
  }

  @override
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }
}

class Word extends DataClass implements Insertable<Word> {
  final int id;
  final String word;
  final int homonym;
  final String pos;
  final String level;
  final String? hanja;
  final String? pronunciation;
  final String? category;

  /// JSON list of {meanings: [..], definition, example}.
  final String senses;
  final int rank;
  final bool isCustom;
  final bool starred;
  final String? note;

  /// Topic unit id from curriculum.json ("food", "custom", ...).
  final String? unit;

  /// KRDict conjugation forms for verbs/adjectives, JSON {"a": "들어", "euni": "들으니"}.
  final String? forms;
  const Word({
    required this.id,
    required this.word,
    required this.homonym,
    required this.pos,
    required this.level,
    this.hanja,
    this.pronunciation,
    this.category,
    required this.senses,
    required this.rank,
    required this.isCustom,
    required this.starred,
    this.note,
    this.unit,
    this.forms,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word'] = Variable<String>(word);
    map['homonym'] = Variable<int>(homonym);
    map['pos'] = Variable<String>(pos);
    map['level'] = Variable<String>(level);
    if (!nullToAbsent || hanja != null) {
      map['hanja'] = Variable<String>(hanja);
    }
    if (!nullToAbsent || pronunciation != null) {
      map['pronunciation'] = Variable<String>(pronunciation);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['senses'] = Variable<String>(senses);
    map['rank'] = Variable<int>(rank);
    map['is_custom'] = Variable<bool>(isCustom);
    map['starred'] = Variable<bool>(starred);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || forms != null) {
      map['forms'] = Variable<String>(forms);
    }
    return map;
  }

  WordsCompanion toCompanion(bool nullToAbsent) {
    return WordsCompanion(
      id: Value(id),
      word: Value(word),
      homonym: Value(homonym),
      pos: Value(pos),
      level: Value(level),
      hanja: hanja == null && nullToAbsent
          ? const Value.absent()
          : Value(hanja),
      pronunciation: pronunciation == null && nullToAbsent
          ? const Value.absent()
          : Value(pronunciation),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      senses: Value(senses),
      rank: Value(rank),
      isCustom: Value(isCustom),
      starred: Value(starred),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      forms: forms == null && nullToAbsent
          ? const Value.absent()
          : Value(forms),
    );
  }

  factory Word.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Word(
      id: serializer.fromJson<int>(json['id']),
      word: serializer.fromJson<String>(json['word']),
      homonym: serializer.fromJson<int>(json['homonym']),
      pos: serializer.fromJson<String>(json['pos']),
      level: serializer.fromJson<String>(json['level']),
      hanja: serializer.fromJson<String?>(json['hanja']),
      pronunciation: serializer.fromJson<String?>(json['pronunciation']),
      category: serializer.fromJson<String?>(json['category']),
      senses: serializer.fromJson<String>(json['senses']),
      rank: serializer.fromJson<int>(json['rank']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
      starred: serializer.fromJson<bool>(json['starred']),
      note: serializer.fromJson<String?>(json['note']),
      unit: serializer.fromJson<String?>(json['unit']),
      forms: serializer.fromJson<String?>(json['forms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'word': serializer.toJson<String>(word),
      'homonym': serializer.toJson<int>(homonym),
      'pos': serializer.toJson<String>(pos),
      'level': serializer.toJson<String>(level),
      'hanja': serializer.toJson<String?>(hanja),
      'pronunciation': serializer.toJson<String?>(pronunciation),
      'category': serializer.toJson<String?>(category),
      'senses': serializer.toJson<String>(senses),
      'rank': serializer.toJson<int>(rank),
      'isCustom': serializer.toJson<bool>(isCustom),
      'starred': serializer.toJson<bool>(starred),
      'note': serializer.toJson<String?>(note),
      'unit': serializer.toJson<String?>(unit),
      'forms': serializer.toJson<String?>(forms),
    };
  }

  Word copyWith({
    int? id,
    String? word,
    int? homonym,
    String? pos,
    String? level,
    Value<String?> hanja = const Value.absent(),
    Value<String?> pronunciation = const Value.absent(),
    Value<String?> category = const Value.absent(),
    String? senses,
    int? rank,
    bool? isCustom,
    bool? starred,
    Value<String?> note = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    Value<String?> forms = const Value.absent(),
  }) => Word(
    id: id ?? this.id,
    word: word ?? this.word,
    homonym: homonym ?? this.homonym,
    pos: pos ?? this.pos,
    level: level ?? this.level,
    hanja: hanja.present ? hanja.value : this.hanja,
    pronunciation: pronunciation.present
        ? pronunciation.value
        : this.pronunciation,
    category: category.present ? category.value : this.category,
    senses: senses ?? this.senses,
    rank: rank ?? this.rank,
    isCustom: isCustom ?? this.isCustom,
    starred: starred ?? this.starred,
    note: note.present ? note.value : this.note,
    unit: unit.present ? unit.value : this.unit,
    forms: forms.present ? forms.value : this.forms,
  );
  Word copyWithCompanion(WordsCompanion data) {
    return Word(
      id: data.id.present ? data.id.value : this.id,
      word: data.word.present ? data.word.value : this.word,
      homonym: data.homonym.present ? data.homonym.value : this.homonym,
      pos: data.pos.present ? data.pos.value : this.pos,
      level: data.level.present ? data.level.value : this.level,
      hanja: data.hanja.present ? data.hanja.value : this.hanja,
      pronunciation: data.pronunciation.present
          ? data.pronunciation.value
          : this.pronunciation,
      category: data.category.present ? data.category.value : this.category,
      senses: data.senses.present ? data.senses.value : this.senses,
      rank: data.rank.present ? data.rank.value : this.rank,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
      starred: data.starred.present ? data.starred.value : this.starred,
      note: data.note.present ? data.note.value : this.note,
      unit: data.unit.present ? data.unit.value : this.unit,
      forms: data.forms.present ? data.forms.value : this.forms,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Word(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('homonym: $homonym, ')
          ..write('pos: $pos, ')
          ..write('level: $level, ')
          ..write('hanja: $hanja, ')
          ..write('pronunciation: $pronunciation, ')
          ..write('category: $category, ')
          ..write('senses: $senses, ')
          ..write('rank: $rank, ')
          ..write('isCustom: $isCustom, ')
          ..write('starred: $starred, ')
          ..write('note: $note, ')
          ..write('unit: $unit, ')
          ..write('forms: $forms')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    word,
    homonym,
    pos,
    level,
    hanja,
    pronunciation,
    category,
    senses,
    rank,
    isCustom,
    starred,
    note,
    unit,
    forms,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Word &&
          other.id == this.id &&
          other.word == this.word &&
          other.homonym == this.homonym &&
          other.pos == this.pos &&
          other.level == this.level &&
          other.hanja == this.hanja &&
          other.pronunciation == this.pronunciation &&
          other.category == this.category &&
          other.senses == this.senses &&
          other.rank == this.rank &&
          other.isCustom == this.isCustom &&
          other.starred == this.starred &&
          other.note == this.note &&
          other.unit == this.unit &&
          other.forms == this.forms);
}

class WordsCompanion extends UpdateCompanion<Word> {
  final Value<int> id;
  final Value<String> word;
  final Value<int> homonym;
  final Value<String> pos;
  final Value<String> level;
  final Value<String?> hanja;
  final Value<String?> pronunciation;
  final Value<String?> category;
  final Value<String> senses;
  final Value<int> rank;
  final Value<bool> isCustom;
  final Value<bool> starred;
  final Value<String?> note;
  final Value<String?> unit;
  final Value<String?> forms;
  const WordsCompanion({
    this.id = const Value.absent(),
    this.word = const Value.absent(),
    this.homonym = const Value.absent(),
    this.pos = const Value.absent(),
    this.level = const Value.absent(),
    this.hanja = const Value.absent(),
    this.pronunciation = const Value.absent(),
    this.category = const Value.absent(),
    this.senses = const Value.absent(),
    this.rank = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.starred = const Value.absent(),
    this.note = const Value.absent(),
    this.unit = const Value.absent(),
    this.forms = const Value.absent(),
  });
  WordsCompanion.insert({
    this.id = const Value.absent(),
    required String word,
    this.homonym = const Value.absent(),
    required String pos,
    required String level,
    this.hanja = const Value.absent(),
    this.pronunciation = const Value.absent(),
    this.category = const Value.absent(),
    required String senses,
    required int rank,
    this.isCustom = const Value.absent(),
    this.starred = const Value.absent(),
    this.note = const Value.absent(),
    this.unit = const Value.absent(),
    this.forms = const Value.absent(),
  }) : word = Value(word),
       pos = Value(pos),
       level = Value(level),
       senses = Value(senses),
       rank = Value(rank);
  static Insertable<Word> custom({
    Expression<int>? id,
    Expression<String>? word,
    Expression<int>? homonym,
    Expression<String>? pos,
    Expression<String>? level,
    Expression<String>? hanja,
    Expression<String>? pronunciation,
    Expression<String>? category,
    Expression<String>? senses,
    Expression<int>? rank,
    Expression<bool>? isCustom,
    Expression<bool>? starred,
    Expression<String>? note,
    Expression<String>? unit,
    Expression<String>? forms,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (word != null) 'word': word,
      if (homonym != null) 'homonym': homonym,
      if (pos != null) 'pos': pos,
      if (level != null) 'level': level,
      if (hanja != null) 'hanja': hanja,
      if (pronunciation != null) 'pronunciation': pronunciation,
      if (category != null) 'category': category,
      if (senses != null) 'senses': senses,
      if (rank != null) 'rank': rank,
      if (isCustom != null) 'is_custom': isCustom,
      if (starred != null) 'starred': starred,
      if (note != null) 'note': note,
      if (unit != null) 'unit': unit,
      if (forms != null) 'forms': forms,
    });
  }

  WordsCompanion copyWith({
    Value<int>? id,
    Value<String>? word,
    Value<int>? homonym,
    Value<String>? pos,
    Value<String>? level,
    Value<String?>? hanja,
    Value<String?>? pronunciation,
    Value<String?>? category,
    Value<String>? senses,
    Value<int>? rank,
    Value<bool>? isCustom,
    Value<bool>? starred,
    Value<String?>? note,
    Value<String?>? unit,
    Value<String?>? forms,
  }) {
    return WordsCompanion(
      id: id ?? this.id,
      word: word ?? this.word,
      homonym: homonym ?? this.homonym,
      pos: pos ?? this.pos,
      level: level ?? this.level,
      hanja: hanja ?? this.hanja,
      pronunciation: pronunciation ?? this.pronunciation,
      category: category ?? this.category,
      senses: senses ?? this.senses,
      rank: rank ?? this.rank,
      isCustom: isCustom ?? this.isCustom,
      starred: starred ?? this.starred,
      note: note ?? this.note,
      unit: unit ?? this.unit,
      forms: forms ?? this.forms,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (homonym.present) {
      map['homonym'] = Variable<int>(homonym.value);
    }
    if (pos.present) {
      map['pos'] = Variable<String>(pos.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (hanja.present) {
      map['hanja'] = Variable<String>(hanja.value);
    }
    if (pronunciation.present) {
      map['pronunciation'] = Variable<String>(pronunciation.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (senses.present) {
      map['senses'] = Variable<String>(senses.value);
    }
    if (rank.present) {
      map['rank'] = Variable<int>(rank.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (starred.present) {
      map['starred'] = Variable<bool>(starred.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (forms.present) {
      map['forms'] = Variable<String>(forms.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsCompanion(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('homonym: $homonym, ')
          ..write('pos: $pos, ')
          ..write('level: $level, ')
          ..write('hanja: $hanja, ')
          ..write('pronunciation: $pronunciation, ')
          ..write('category: $category, ')
          ..write('senses: $senses, ')
          ..write('rank: $rank, ')
          ..write('isCustom: $isCustom, ')
          ..write('starred: $starred, ')
          ..write('note: $note, ')
          ..write('unit: $unit, ')
          ..write('forms: $forms')
          ..write(')'))
        .toString();
  }
}

class $CardsTable extends Cards with TableInfo<$CardsTable, StudyCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<int> direction = GeneratedColumn<int>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<int> state = GeneratedColumn<int>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(CardState.newCard),
  );
  static const VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedColumn<int> step = GeneratedColumn<int>(
    'step',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stabilityMeta = const VerificationMeta(
    'stability',
  );
  @override
  late final GeneratedColumn<double> stability = GeneratedColumn<double>(
    'stability',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
    'difficulty',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueMeta = const VerificationMeta('due');
  @override
  late final GeneratedColumn<DateTime> due = GeneratedColumn<DateTime>(
    'due',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastReviewMeta = const VerificationMeta(
    'lastReview',
  );
  @override
  late final GeneratedColumn<DateTime> lastReview = GeneratedColumn<DateTime>(
    'last_review',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _suspendedMeta = const VerificationMeta(
    'suspended',
  );
  @override
  late final GeneratedColumn<bool> suspended = GeneratedColumn<bool>(
    'suspended',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("suspended" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    wordId,
    direction,
    state,
    step,
    stability,
    difficulty,
    due,
    lastReview,
    reps,
    lapses,
    suspended,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudyCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('step')) {
      context.handle(
        _stepMeta,
        step.isAcceptableOrUnknown(data['step']!, _stepMeta),
      );
    }
    if (data.containsKey('stability')) {
      context.handle(
        _stabilityMeta,
        stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('due')) {
      context.handle(
        _dueMeta,
        due.isAcceptableOrUnknown(data['due']!, _dueMeta),
      );
    }
    if (data.containsKey('last_review')) {
      context.handle(
        _lastReviewMeta,
        lastReview.isAcceptableOrUnknown(data['last_review']!, _lastReviewMeta),
      );
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('lapses')) {
      context.handle(
        _lapsesMeta,
        lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta),
      );
    }
    if (data.containsKey('suspended')) {
      context.handle(
        _suspendedMeta,
        suspended.isAcceptableOrUnknown(data['suspended']!, _suspendedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {wordId, direction},
  ];
  @override
  StudyCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudyCard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}direction'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state'],
      )!,
      step: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step'],
      ),
      stability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stability'],
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty'],
      ),
      due: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due'],
      )!,
      lastReview: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_review'],
      ),
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
      suspended: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}suspended'],
      )!,
    );
  }

  @override
  $CardsTable createAlias(String alias) {
    return $CardsTable(attachedDatabase, alias);
  }
}

class StudyCard extends DataClass implements Insertable<StudyCard> {
  final int id;
  final int wordId;
  final int direction;
  final int state;
  final int? step;
  final double? stability;
  final double? difficulty;
  final DateTime due;
  final DateTime? lastReview;
  final int reps;
  final int lapses;
  final bool suspended;
  const StudyCard({
    required this.id,
    required this.wordId,
    required this.direction,
    required this.state,
    this.step,
    this.stability,
    this.difficulty,
    required this.due,
    this.lastReview,
    required this.reps,
    required this.lapses,
    required this.suspended,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word_id'] = Variable<int>(wordId);
    map['direction'] = Variable<int>(direction);
    map['state'] = Variable<int>(state);
    if (!nullToAbsent || step != null) {
      map['step'] = Variable<int>(step);
    }
    if (!nullToAbsent || stability != null) {
      map['stability'] = Variable<double>(stability);
    }
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<double>(difficulty);
    }
    map['due'] = Variable<DateTime>(due);
    if (!nullToAbsent || lastReview != null) {
      map['last_review'] = Variable<DateTime>(lastReview);
    }
    map['reps'] = Variable<int>(reps);
    map['lapses'] = Variable<int>(lapses);
    map['suspended'] = Variable<bool>(suspended);
    return map;
  }

  CardsCompanion toCompanion(bool nullToAbsent) {
    return CardsCompanion(
      id: Value(id),
      wordId: Value(wordId),
      direction: Value(direction),
      state: Value(state),
      step: step == null && nullToAbsent ? const Value.absent() : Value(step),
      stability: stability == null && nullToAbsent
          ? const Value.absent()
          : Value(stability),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
      due: Value(due),
      lastReview: lastReview == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReview),
      reps: Value(reps),
      lapses: Value(lapses),
      suspended: Value(suspended),
    );
  }

  factory StudyCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudyCard(
      id: serializer.fromJson<int>(json['id']),
      wordId: serializer.fromJson<int>(json['wordId']),
      direction: serializer.fromJson<int>(json['direction']),
      state: serializer.fromJson<int>(json['state']),
      step: serializer.fromJson<int?>(json['step']),
      stability: serializer.fromJson<double?>(json['stability']),
      difficulty: serializer.fromJson<double?>(json['difficulty']),
      due: serializer.fromJson<DateTime>(json['due']),
      lastReview: serializer.fromJson<DateTime?>(json['lastReview']),
      reps: serializer.fromJson<int>(json['reps']),
      lapses: serializer.fromJson<int>(json['lapses']),
      suspended: serializer.fromJson<bool>(json['suspended']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wordId': serializer.toJson<int>(wordId),
      'direction': serializer.toJson<int>(direction),
      'state': serializer.toJson<int>(state),
      'step': serializer.toJson<int?>(step),
      'stability': serializer.toJson<double?>(stability),
      'difficulty': serializer.toJson<double?>(difficulty),
      'due': serializer.toJson<DateTime>(due),
      'lastReview': serializer.toJson<DateTime?>(lastReview),
      'reps': serializer.toJson<int>(reps),
      'lapses': serializer.toJson<int>(lapses),
      'suspended': serializer.toJson<bool>(suspended),
    };
  }

  StudyCard copyWith({
    int? id,
    int? wordId,
    int? direction,
    int? state,
    Value<int?> step = const Value.absent(),
    Value<double?> stability = const Value.absent(),
    Value<double?> difficulty = const Value.absent(),
    DateTime? due,
    Value<DateTime?> lastReview = const Value.absent(),
    int? reps,
    int? lapses,
    bool? suspended,
  }) => StudyCard(
    id: id ?? this.id,
    wordId: wordId ?? this.wordId,
    direction: direction ?? this.direction,
    state: state ?? this.state,
    step: step.present ? step.value : this.step,
    stability: stability.present ? stability.value : this.stability,
    difficulty: difficulty.present ? difficulty.value : this.difficulty,
    due: due ?? this.due,
    lastReview: lastReview.present ? lastReview.value : this.lastReview,
    reps: reps ?? this.reps,
    lapses: lapses ?? this.lapses,
    suspended: suspended ?? this.suspended,
  );
  StudyCard copyWithCompanion(CardsCompanion data) {
    return StudyCard(
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      direction: data.direction.present ? data.direction.value : this.direction,
      state: data.state.present ? data.state.value : this.state,
      step: data.step.present ? data.step.value : this.step,
      stability: data.stability.present ? data.stability.value : this.stability,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      due: data.due.present ? data.due.value : this.due,
      lastReview: data.lastReview.present
          ? data.lastReview.value
          : this.lastReview,
      reps: data.reps.present ? data.reps.value : this.reps,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      suspended: data.suspended.present ? data.suspended.value : this.suspended,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudyCard(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('direction: $direction, ')
          ..write('state: $state, ')
          ..write('step: $step, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('due: $due, ')
          ..write('lastReview: $lastReview, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('suspended: $suspended')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    wordId,
    direction,
    state,
    step,
    stability,
    difficulty,
    due,
    lastReview,
    reps,
    lapses,
    suspended,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudyCard &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.direction == this.direction &&
          other.state == this.state &&
          other.step == this.step &&
          other.stability == this.stability &&
          other.difficulty == this.difficulty &&
          other.due == this.due &&
          other.lastReview == this.lastReview &&
          other.reps == this.reps &&
          other.lapses == this.lapses &&
          other.suspended == this.suspended);
}

class CardsCompanion extends UpdateCompanion<StudyCard> {
  final Value<int> id;
  final Value<int> wordId;
  final Value<int> direction;
  final Value<int> state;
  final Value<int?> step;
  final Value<double?> stability;
  final Value<double?> difficulty;
  final Value<DateTime> due;
  final Value<DateTime?> lastReview;
  final Value<int> reps;
  final Value<int> lapses;
  final Value<bool> suspended;
  const CardsCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.direction = const Value.absent(),
    this.state = const Value.absent(),
    this.step = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.due = const Value.absent(),
    this.lastReview = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.suspended = const Value.absent(),
  });
  CardsCompanion.insert({
    this.id = const Value.absent(),
    required int wordId,
    required int direction,
    this.state = const Value.absent(),
    this.step = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.due = const Value.absent(),
    this.lastReview = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.suspended = const Value.absent(),
  }) : wordId = Value(wordId),
       direction = Value(direction);
  static Insertable<StudyCard> custom({
    Expression<int>? id,
    Expression<int>? wordId,
    Expression<int>? direction,
    Expression<int>? state,
    Expression<int>? step,
    Expression<double>? stability,
    Expression<double>? difficulty,
    Expression<DateTime>? due,
    Expression<DateTime>? lastReview,
    Expression<int>? reps,
    Expression<int>? lapses,
    Expression<bool>? suspended,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (direction != null) 'direction': direction,
      if (state != null) 'state': state,
      if (step != null) 'step': step,
      if (stability != null) 'stability': stability,
      if (difficulty != null) 'difficulty': difficulty,
      if (due != null) 'due': due,
      if (lastReview != null) 'last_review': lastReview,
      if (reps != null) 'reps': reps,
      if (lapses != null) 'lapses': lapses,
      if (suspended != null) 'suspended': suspended,
    });
  }

  CardsCompanion copyWith({
    Value<int>? id,
    Value<int>? wordId,
    Value<int>? direction,
    Value<int>? state,
    Value<int?>? step,
    Value<double?>? stability,
    Value<double?>? difficulty,
    Value<DateTime>? due,
    Value<DateTime?>? lastReview,
    Value<int>? reps,
    Value<int>? lapses,
    Value<bool>? suspended,
  }) {
    return CardsCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      direction: direction ?? this.direction,
      state: state ?? this.state,
      step: step ?? this.step,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      due: due ?? this.due,
      lastReview: lastReview ?? this.lastReview,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      suspended: suspended ?? this.suspended,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<int>(direction.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(state.value);
    }
    if (step.present) {
      map['step'] = Variable<int>(step.value);
    }
    if (stability.present) {
      map['stability'] = Variable<double>(stability.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (due.present) {
      map['due'] = Variable<DateTime>(due.value);
    }
    if (lastReview.present) {
      map['last_review'] = Variable<DateTime>(lastReview.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (suspended.present) {
      map['suspended'] = Variable<bool>(suspended.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsCompanion(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('direction: $direction, ')
          ..write('state: $state, ')
          ..write('step: $step, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('due: $due, ')
          ..write('lastReview: $lastReview, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('suspended: $suspended')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogsTable extends ReviewLogs
    with TableInfo<$ReviewLogsTable, ReviewLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<int> cardId = GeneratedColumn<int>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cards (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateBeforeMeta = const VerificationMeta(
    'stateBefore',
  );
  @override
  late final GeneratedColumn<int> stateBefore = GeneratedColumn<int>(
    'state_before',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elapsedMsMeta = const VerificationMeta(
    'elapsedMs',
  );
  @override
  late final GeneratedColumn<int> elapsedMs = GeneratedColumn<int>(
    'elapsed_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cardId,
    rating,
    stateBefore,
    reviewedAt,
    elapsedMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('state_before')) {
      context.handle(
        _stateBeforeMeta,
        stateBefore.isAcceptableOrUnknown(
          data['state_before']!,
          _stateBeforeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stateBeforeMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('elapsed_ms')) {
      context.handle(
        _elapsedMsMeta,
        elapsedMs.isAcceptableOrUnknown(data['elapsed_ms']!, _elapsedMsMeta),
      );
    } else if (isInserting) {
      context.missing(_elapsedMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_id'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      stateBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state_before'],
      )!,
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      )!,
      elapsedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_ms'],
      )!,
    );
  }

  @override
  $ReviewLogsTable createAlias(String alias) {
    return $ReviewLogsTable(attachedDatabase, alias);
  }
}

class ReviewLog extends DataClass implements Insertable<ReviewLog> {
  final int id;
  final int cardId;
  final int rating;
  final int stateBefore;
  final DateTime reviewedAt;
  final int elapsedMs;
  const ReviewLog({
    required this.id,
    required this.cardId,
    required this.rating,
    required this.stateBefore,
    required this.reviewedAt,
    required this.elapsedMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['card_id'] = Variable<int>(cardId);
    map['rating'] = Variable<int>(rating);
    map['state_before'] = Variable<int>(stateBefore);
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    map['elapsed_ms'] = Variable<int>(elapsedMs);
    return map;
  }

  ReviewLogsCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogsCompanion(
      id: Value(id),
      cardId: Value(cardId),
      rating: Value(rating),
      stateBefore: Value(stateBefore),
      reviewedAt: Value(reviewedAt),
      elapsedMs: Value(elapsedMs),
    );
  }

  factory ReviewLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewLog(
      id: serializer.fromJson<int>(json['id']),
      cardId: serializer.fromJson<int>(json['cardId']),
      rating: serializer.fromJson<int>(json['rating']),
      stateBefore: serializer.fromJson<int>(json['stateBefore']),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
      elapsedMs: serializer.fromJson<int>(json['elapsedMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cardId': serializer.toJson<int>(cardId),
      'rating': serializer.toJson<int>(rating),
      'stateBefore': serializer.toJson<int>(stateBefore),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
      'elapsedMs': serializer.toJson<int>(elapsedMs),
    };
  }

  ReviewLog copyWith({
    int? id,
    int? cardId,
    int? rating,
    int? stateBefore,
    DateTime? reviewedAt,
    int? elapsedMs,
  }) => ReviewLog(
    id: id ?? this.id,
    cardId: cardId ?? this.cardId,
    rating: rating ?? this.rating,
    stateBefore: stateBefore ?? this.stateBefore,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    elapsedMs: elapsedMs ?? this.elapsedMs,
  );
  ReviewLog copyWithCompanion(ReviewLogsCompanion data) {
    return ReviewLog(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      rating: data.rating.present ? data.rating.value : this.rating,
      stateBefore: data.stateBefore.present
          ? data.stateBefore.value
          : this.stateBefore,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      elapsedMs: data.elapsedMs.present ? data.elapsedMs.value : this.elapsedMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLog(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('rating: $rating, ')
          ..write('stateBefore: $stateBefore, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('elapsedMs: $elapsedMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, cardId, rating, stateBefore, reviewedAt, elapsedMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewLog &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.rating == this.rating &&
          other.stateBefore == this.stateBefore &&
          other.reviewedAt == this.reviewedAt &&
          other.elapsedMs == this.elapsedMs);
}

class ReviewLogsCompanion extends UpdateCompanion<ReviewLog> {
  final Value<int> id;
  final Value<int> cardId;
  final Value<int> rating;
  final Value<int> stateBefore;
  final Value<DateTime> reviewedAt;
  final Value<int> elapsedMs;
  const ReviewLogsCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.rating = const Value.absent(),
    this.stateBefore = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.elapsedMs = const Value.absent(),
  });
  ReviewLogsCompanion.insert({
    this.id = const Value.absent(),
    required int cardId,
    required int rating,
    required int stateBefore,
    required DateTime reviewedAt,
    required int elapsedMs,
  }) : cardId = Value(cardId),
       rating = Value(rating),
       stateBefore = Value(stateBefore),
       reviewedAt = Value(reviewedAt),
       elapsedMs = Value(elapsedMs);
  static Insertable<ReviewLog> custom({
    Expression<int>? id,
    Expression<int>? cardId,
    Expression<int>? rating,
    Expression<int>? stateBefore,
    Expression<DateTime>? reviewedAt,
    Expression<int>? elapsedMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (rating != null) 'rating': rating,
      if (stateBefore != null) 'state_before': stateBefore,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (elapsedMs != null) 'elapsed_ms': elapsedMs,
    });
  }

  ReviewLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? cardId,
    Value<int>? rating,
    Value<int>? stateBefore,
    Value<DateTime>? reviewedAt,
    Value<int>? elapsedMs,
  }) {
    return ReviewLogsCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      rating: rating ?? this.rating,
      stateBefore: stateBefore ?? this.stateBefore,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      elapsedMs: elapsedMs ?? this.elapsedMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<int>(cardId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (stateBefore.present) {
      map['state_before'] = Variable<int>(stateBefore.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (elapsedMs.present) {
      map['elapsed_ms'] = Variable<int>(elapsedMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogsCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('rating: $rating, ')
          ..write('stateBefore: $stateBefore, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('elapsedMs: $elapsedMs')
          ..write(')'))
        .toString();
  }
}

class $ActivitiesTable extends Activities
    with TableInfo<$ActivitiesTable, Activity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xpMeta = const VerificationMeta('xp');
  @override
  late final GeneratedColumn<int> xp = GeneratedColumn<int>(
    'xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _refMeta = const VerificationMeta('ref');
  @override
  late final GeneratedColumn<String> ref = GeneratedColumn<String>(
    'ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, kind, xp, value, ref, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activities';
  @override
  VerificationContext validateIntegrity(
    Insertable<Activity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('xp')) {
      context.handle(_xpMeta, xp.isAcceptableOrUnknown(data['xp']!, _xpMeta));
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    if (data.containsKey('ref')) {
      context.handle(
        _refMeta,
        ref.isAcceptableOrUnknown(data['ref']!, _refMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Activity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Activity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      xp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      )!,
      ref: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ActivitiesTable createAlias(String alias) {
    return $ActivitiesTable(attachedDatabase, alias);
  }
}

class Activity extends DataClass implements Insertable<Activity> {
  final int id;

  /// One of [ActivityKind].
  final String kind;
  final int xp;

  /// Kind-specific number: the rating, combo, stars or game score.
  final int value;

  /// Kind-specific id: lesson id, unit id, game id or quest id.
  final String? ref;
  final DateTime createdAt;
  const Activity({
    required this.id,
    required this.kind,
    required this.xp,
    required this.value,
    this.ref,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    map['xp'] = Variable<int>(xp);
    map['value'] = Variable<int>(value);
    if (!nullToAbsent || ref != null) {
      map['ref'] = Variable<String>(ref);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ActivitiesCompanion toCompanion(bool nullToAbsent) {
    return ActivitiesCompanion(
      id: Value(id),
      kind: Value(kind),
      xp: Value(xp),
      value: Value(value),
      ref: ref == null && nullToAbsent ? const Value.absent() : Value(ref),
      createdAt: Value(createdAt),
    );
  }

  factory Activity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Activity(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      xp: serializer.fromJson<int>(json['xp']),
      value: serializer.fromJson<int>(json['value']),
      ref: serializer.fromJson<String?>(json['ref']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'xp': serializer.toJson<int>(xp),
      'value': serializer.toJson<int>(value),
      'ref': serializer.toJson<String?>(ref),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Activity copyWith({
    int? id,
    String? kind,
    int? xp,
    int? value,
    Value<String?> ref = const Value.absent(),
    DateTime? createdAt,
  }) => Activity(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    xp: xp ?? this.xp,
    value: value ?? this.value,
    ref: ref.present ? ref.value : this.ref,
    createdAt: createdAt ?? this.createdAt,
  );
  Activity copyWithCompanion(ActivitiesCompanion data) {
    return Activity(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      xp: data.xp.present ? data.xp.value : this.xp,
      value: data.value.present ? data.value.value : this.value,
      ref: data.ref.present ? data.ref.value : this.ref,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Activity(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('xp: $xp, ')
          ..write('value: $value, ')
          ..write('ref: $ref, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, xp, value, ref, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Activity &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.xp == this.xp &&
          other.value == this.value &&
          other.ref == this.ref &&
          other.createdAt == this.createdAt);
}

class ActivitiesCompanion extends UpdateCompanion<Activity> {
  final Value<int> id;
  final Value<String> kind;
  final Value<int> xp;
  final Value<int> value;
  final Value<String?> ref;
  final Value<DateTime> createdAt;
  const ActivitiesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.xp = const Value.absent(),
    this.value = const Value.absent(),
    this.ref = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ActivitiesCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    this.xp = const Value.absent(),
    this.value = const Value.absent(),
    this.ref = const Value.absent(),
    required DateTime createdAt,
  }) : kind = Value(kind),
       createdAt = Value(createdAt);
  static Insertable<Activity> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<int>? xp,
    Expression<int>? value,
    Expression<String>? ref,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (xp != null) 'xp': xp,
      if (value != null) 'value': value,
      if (ref != null) 'ref': ref,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ActivitiesCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<int>? xp,
    Value<int>? value,
    Value<String?>? ref,
    Value<DateTime>? createdAt,
  }) {
    return ActivitiesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      xp: xp ?? this.xp,
      value: value ?? this.value,
      ref: ref ?? this.ref,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (xp.present) {
      map['xp'] = Variable<int>(xp.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (ref.present) {
      map['ref'] = Variable<String>(ref.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivitiesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('xp: $xp, ')
          ..write('value: $value, ')
          ..write('ref: $ref, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LessonProgressTable extends LessonProgress
    with TableInfo<$LessonProgressTable, LessonProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _starsMeta = const VerificationMeta('stars');
  @override
  late final GeneratedColumn<int> stars = GeneratedColumn<int>(
    'stars',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bestAccuracyMeta = const VerificationMeta(
    'bestAccuracy',
  );
  @override
  late final GeneratedColumn<double> bestAccuracy = GeneratedColumn<double>(
    'best_accuracy',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completionsMeta = const VerificationMeta(
    'completions',
  );
  @override
  late final GeneratedColumn<int> completions = GeneratedColumn<int>(
    'completions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _firstCompletedAtMeta = const VerificationMeta(
    'firstCompletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> firstCompletedAt =
      GeneratedColumn<DateTime>(
        'first_completed_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastCompletedAtMeta = const VerificationMeta(
    'lastCompletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastCompletedAt =
      GeneratedColumn<DateTime>(
        'last_completed_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    lessonId,
    stars,
    bestAccuracy,
    completions,
    firstCompletedAt,
    lastCompletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<LessonProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('stars')) {
      context.handle(
        _starsMeta,
        stars.isAcceptableOrUnknown(data['stars']!, _starsMeta),
      );
    } else if (isInserting) {
      context.missing(_starsMeta);
    }
    if (data.containsKey('best_accuracy')) {
      context.handle(
        _bestAccuracyMeta,
        bestAccuracy.isAcceptableOrUnknown(
          data['best_accuracy']!,
          _bestAccuracyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bestAccuracyMeta);
    }
    if (data.containsKey('completions')) {
      context.handle(
        _completionsMeta,
        completions.isAcceptableOrUnknown(
          data['completions']!,
          _completionsMeta,
        ),
      );
    }
    if (data.containsKey('first_completed_at')) {
      context.handle(
        _firstCompletedAtMeta,
        firstCompletedAt.isAcceptableOrUnknown(
          data['first_completed_at']!,
          _firstCompletedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstCompletedAtMeta);
    }
    if (data.containsKey('last_completed_at')) {
      context.handle(
        _lastCompletedAtMeta,
        lastCompletedAt.isAcceptableOrUnknown(
          data['last_completed_at']!,
          _lastCompletedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastCompletedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lessonId};
  @override
  LessonProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonProgressData(
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      )!,
      stars: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stars'],
      )!,
      bestAccuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}best_accuracy'],
      )!,
      completions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completions'],
      )!,
      firstCompletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_completed_at'],
      )!,
      lastCompletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_completed_at'],
      )!,
    );
  }

  @override
  $LessonProgressTable createAlias(String alias) {
    return $LessonProgressTable(attachedDatabase, alias);
  }
}

class LessonProgressData extends DataClass
    implements Insertable<LessonProgressData> {
  final String lessonId;
  final int stars;
  final double bestAccuracy;
  final int completions;
  final DateTime firstCompletedAt;
  final DateTime lastCompletedAt;
  const LessonProgressData({
    required this.lessonId,
    required this.stars,
    required this.bestAccuracy,
    required this.completions,
    required this.firstCompletedAt,
    required this.lastCompletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lesson_id'] = Variable<String>(lessonId);
    map['stars'] = Variable<int>(stars);
    map['best_accuracy'] = Variable<double>(bestAccuracy);
    map['completions'] = Variable<int>(completions);
    map['first_completed_at'] = Variable<DateTime>(firstCompletedAt);
    map['last_completed_at'] = Variable<DateTime>(lastCompletedAt);
    return map;
  }

  LessonProgressCompanion toCompanion(bool nullToAbsent) {
    return LessonProgressCompanion(
      lessonId: Value(lessonId),
      stars: Value(stars),
      bestAccuracy: Value(bestAccuracy),
      completions: Value(completions),
      firstCompletedAt: Value(firstCompletedAt),
      lastCompletedAt: Value(lastCompletedAt),
    );
  }

  factory LessonProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonProgressData(
      lessonId: serializer.fromJson<String>(json['lessonId']),
      stars: serializer.fromJson<int>(json['stars']),
      bestAccuracy: serializer.fromJson<double>(json['bestAccuracy']),
      completions: serializer.fromJson<int>(json['completions']),
      firstCompletedAt: serializer.fromJson<DateTime>(json['firstCompletedAt']),
      lastCompletedAt: serializer.fromJson<DateTime>(json['lastCompletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lessonId': serializer.toJson<String>(lessonId),
      'stars': serializer.toJson<int>(stars),
      'bestAccuracy': serializer.toJson<double>(bestAccuracy),
      'completions': serializer.toJson<int>(completions),
      'firstCompletedAt': serializer.toJson<DateTime>(firstCompletedAt),
      'lastCompletedAt': serializer.toJson<DateTime>(lastCompletedAt),
    };
  }

  LessonProgressData copyWith({
    String? lessonId,
    int? stars,
    double? bestAccuracy,
    int? completions,
    DateTime? firstCompletedAt,
    DateTime? lastCompletedAt,
  }) => LessonProgressData(
    lessonId: lessonId ?? this.lessonId,
    stars: stars ?? this.stars,
    bestAccuracy: bestAccuracy ?? this.bestAccuracy,
    completions: completions ?? this.completions,
    firstCompletedAt: firstCompletedAt ?? this.firstCompletedAt,
    lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
  );
  LessonProgressData copyWithCompanion(LessonProgressCompanion data) {
    return LessonProgressData(
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      stars: data.stars.present ? data.stars.value : this.stars,
      bestAccuracy: data.bestAccuracy.present
          ? data.bestAccuracy.value
          : this.bestAccuracy,
      completions: data.completions.present
          ? data.completions.value
          : this.completions,
      firstCompletedAt: data.firstCompletedAt.present
          ? data.firstCompletedAt.value
          : this.firstCompletedAt,
      lastCompletedAt: data.lastCompletedAt.present
          ? data.lastCompletedAt.value
          : this.lastCompletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressData(')
          ..write('lessonId: $lessonId, ')
          ..write('stars: $stars, ')
          ..write('bestAccuracy: $bestAccuracy, ')
          ..write('completions: $completions, ')
          ..write('firstCompletedAt: $firstCompletedAt, ')
          ..write('lastCompletedAt: $lastCompletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    lessonId,
    stars,
    bestAccuracy,
    completions,
    firstCompletedAt,
    lastCompletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonProgressData &&
          other.lessonId == this.lessonId &&
          other.stars == this.stars &&
          other.bestAccuracy == this.bestAccuracy &&
          other.completions == this.completions &&
          other.firstCompletedAt == this.firstCompletedAt &&
          other.lastCompletedAt == this.lastCompletedAt);
}

class LessonProgressCompanion extends UpdateCompanion<LessonProgressData> {
  final Value<String> lessonId;
  final Value<int> stars;
  final Value<double> bestAccuracy;
  final Value<int> completions;
  final Value<DateTime> firstCompletedAt;
  final Value<DateTime> lastCompletedAt;
  final Value<int> rowid;
  const LessonProgressCompanion({
    this.lessonId = const Value.absent(),
    this.stars = const Value.absent(),
    this.bestAccuracy = const Value.absent(),
    this.completions = const Value.absent(),
    this.firstCompletedAt = const Value.absent(),
    this.lastCompletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LessonProgressCompanion.insert({
    required String lessonId,
    required int stars,
    required double bestAccuracy,
    this.completions = const Value.absent(),
    required DateTime firstCompletedAt,
    required DateTime lastCompletedAt,
    this.rowid = const Value.absent(),
  }) : lessonId = Value(lessonId),
       stars = Value(stars),
       bestAccuracy = Value(bestAccuracy),
       firstCompletedAt = Value(firstCompletedAt),
       lastCompletedAt = Value(lastCompletedAt);
  static Insertable<LessonProgressData> custom({
    Expression<String>? lessonId,
    Expression<int>? stars,
    Expression<double>? bestAccuracy,
    Expression<int>? completions,
    Expression<DateTime>? firstCompletedAt,
    Expression<DateTime>? lastCompletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lessonId != null) 'lesson_id': lessonId,
      if (stars != null) 'stars': stars,
      if (bestAccuracy != null) 'best_accuracy': bestAccuracy,
      if (completions != null) 'completions': completions,
      if (firstCompletedAt != null) 'first_completed_at': firstCompletedAt,
      if (lastCompletedAt != null) 'last_completed_at': lastCompletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LessonProgressCompanion copyWith({
    Value<String>? lessonId,
    Value<int>? stars,
    Value<double>? bestAccuracy,
    Value<int>? completions,
    Value<DateTime>? firstCompletedAt,
    Value<DateTime>? lastCompletedAt,
    Value<int>? rowid,
  }) {
    return LessonProgressCompanion(
      lessonId: lessonId ?? this.lessonId,
      stars: stars ?? this.stars,
      bestAccuracy: bestAccuracy ?? this.bestAccuracy,
      completions: completions ?? this.completions,
      firstCompletedAt: firstCompletedAt ?? this.firstCompletedAt,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (stars.present) {
      map['stars'] = Variable<int>(stars.value);
    }
    if (bestAccuracy.present) {
      map['best_accuracy'] = Variable<double>(bestAccuracy.value);
    }
    if (completions.present) {
      map['completions'] = Variable<int>(completions.value);
    }
    if (firstCompletedAt.present) {
      map['first_completed_at'] = Variable<DateTime>(firstCompletedAt.value);
    }
    if (lastCompletedAt.present) {
      map['last_completed_at'] = Variable<DateTime>(lastCompletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressCompanion(')
          ..write('lessonId: $lessonId, ')
          ..write('stars: $stars, ')
          ..write('bestAccuracy: $bestAccuracy, ')
          ..write('completions: $completions, ')
          ..write('firstCompletedAt: $firstCompletedAt, ')
          ..write('lastCompletedAt: $lastCompletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AchievementsTable extends Achievements
    with TableInfo<$AchievementsTable, Achievement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AchievementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unlockedAtMeta = const VerificationMeta(
    'unlockedAt',
  );
  @override
  late final GeneratedColumn<DateTime> unlockedAt = GeneratedColumn<DateTime>(
    'unlocked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, unlockedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'achievements';
  @override
  VerificationContext validateIntegrity(
    Insertable<Achievement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('unlocked_at')) {
      context.handle(
        _unlockedAtMeta,
        unlockedAt.isAcceptableOrUnknown(data['unlocked_at']!, _unlockedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_unlockedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Achievement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Achievement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      unlockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}unlocked_at'],
      )!,
    );
  }

  @override
  $AchievementsTable createAlias(String alias) {
    return $AchievementsTable(attachedDatabase, alias);
  }
}

class Achievement extends DataClass implements Insertable<Achievement> {
  final String id;
  final DateTime unlockedAt;
  const Achievement({required this.id, required this.unlockedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['unlocked_at'] = Variable<DateTime>(unlockedAt);
    return map;
  }

  AchievementsCompanion toCompanion(bool nullToAbsent) {
    return AchievementsCompanion(id: Value(id), unlockedAt: Value(unlockedAt));
  }

  factory Achievement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Achievement(
      id: serializer.fromJson<String>(json['id']),
      unlockedAt: serializer.fromJson<DateTime>(json['unlockedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'unlockedAt': serializer.toJson<DateTime>(unlockedAt),
    };
  }

  Achievement copyWith({String? id, DateTime? unlockedAt}) =>
      Achievement(id: id ?? this.id, unlockedAt: unlockedAt ?? this.unlockedAt);
  Achievement copyWithCompanion(AchievementsCompanion data) {
    return Achievement(
      id: data.id.present ? data.id.value : this.id,
      unlockedAt: data.unlockedAt.present
          ? data.unlockedAt.value
          : this.unlockedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Achievement(')
          ..write('id: $id, ')
          ..write('unlockedAt: $unlockedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, unlockedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Achievement &&
          other.id == this.id &&
          other.unlockedAt == this.unlockedAt);
}

class AchievementsCompanion extends UpdateCompanion<Achievement> {
  final Value<String> id;
  final Value<DateTime> unlockedAt;
  final Value<int> rowid;
  const AchievementsCompanion({
    this.id = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AchievementsCompanion.insert({
    required String id,
    required DateTime unlockedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       unlockedAt = Value(unlockedAt);
  static Insertable<Achievement> custom({
    Expression<String>? id,
    Expression<DateTime>? unlockedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AchievementsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? unlockedAt,
    Value<int>? rowid,
  }) {
    return AchievementsCompanion(
      id: id ?? this.id,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (unlockedAt.present) {
      map['unlocked_at'] = Variable<DateTime>(unlockedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AchievementsCompanion(')
          ..write('id: $id, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuestClaimsTable extends QuestClaims
    with TableInfo<$QuestClaimsTable, QuestClaim> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestClaimsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questIdMeta = const VerificationMeta(
    'questId',
  );
  @override
  late final GeneratedColumn<String> questId = GeneratedColumn<String>(
    'quest_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [day, questId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quest_claims';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestClaim> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('quest_id')) {
      context.handle(
        _questIdMeta,
        questId.isAcceptableOrUnknown(data['quest_id']!, _questIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day, questId};
  @override
  QuestClaim map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestClaim(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}day'],
      )!,
      questId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quest_id'],
      )!,
    );
  }

  @override
  $QuestClaimsTable createAlias(String alias) {
    return $QuestClaimsTable(attachedDatabase, alias);
  }
}

class QuestClaim extends DataClass implements Insertable<QuestClaim> {
  /// Start of the study day the quest belongs to.
  final DateTime day;
  final String questId;
  const QuestClaim({required this.day, required this.questId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<DateTime>(day);
    map['quest_id'] = Variable<String>(questId);
    return map;
  }

  QuestClaimsCompanion toCompanion(bool nullToAbsent) {
    return QuestClaimsCompanion(day: Value(day), questId: Value(questId));
  }

  factory QuestClaim.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestClaim(
      day: serializer.fromJson<DateTime>(json['day']),
      questId: serializer.fromJson<String>(json['questId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<DateTime>(day),
      'questId': serializer.toJson<String>(questId),
    };
  }

  QuestClaim copyWith({DateTime? day, String? questId}) =>
      QuestClaim(day: day ?? this.day, questId: questId ?? this.questId);
  QuestClaim copyWithCompanion(QuestClaimsCompanion data) {
    return QuestClaim(
      day: data.day.present ? data.day.value : this.day,
      questId: data.questId.present ? data.questId.value : this.questId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestClaim(')
          ..write('day: $day, ')
          ..write('questId: $questId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(day, questId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestClaim &&
          other.day == this.day &&
          other.questId == this.questId);
}

class QuestClaimsCompanion extends UpdateCompanion<QuestClaim> {
  final Value<DateTime> day;
  final Value<String> questId;
  final Value<int> rowid;
  const QuestClaimsCompanion({
    this.day = const Value.absent(),
    this.questId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestClaimsCompanion.insert({
    required DateTime day,
    required String questId,
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       questId = Value(questId);
  static Insertable<QuestClaim> custom({
    Expression<DateTime>? day,
    Expression<String>? questId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (questId != null) 'quest_id': questId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestClaimsCompanion copyWith({
    Value<DateTime>? day,
    Value<String>? questId,
    Value<int>? rowid,
  }) {
    return QuestClaimsCompanion(
      day: day ?? this.day,
      questId: questId ?? this.questId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (questId.present) {
      map['quest_id'] = Variable<String>(questId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestClaimsCompanion(')
          ..write('day: $day, ')
          ..write('questId: $questId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SkillsTable extends Skills with TableInfo<$SkillsTable, SkillRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SkillsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<int> state = GeneratedColumn<int>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(CardState.newCard),
  );
  static const VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedColumn<int> step = GeneratedColumn<int>(
    'step',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stabilityMeta = const VerificationMeta(
    'stability',
  );
  @override
  late final GeneratedColumn<double> stability = GeneratedColumn<double>(
    'stability',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
    'difficulty',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueMeta = const VerificationMeta('due');
  @override
  late final GeneratedColumn<DateTime> due = GeneratedColumn<DateTime>(
    'due',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastReviewMeta = const VerificationMeta(
    'lastReview',
  );
  @override
  late final GeneratedColumn<DateTime> lastReview = GeneratedColumn<DateTime>(
    'last_review',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _correctMeta = const VerificationMeta(
    'correct',
  );
  @override
  late final GeneratedColumn<int> correct = GeneratedColumn<int>(
    'correct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    state,
    step,
    stability,
    difficulty,
    due,
    lastReview,
    reps,
    lapses,
    correct,
    attempts,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'skills';
  @override
  VerificationContext validateIntegrity(
    Insertable<SkillRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('step')) {
      context.handle(
        _stepMeta,
        step.isAcceptableOrUnknown(data['step']!, _stepMeta),
      );
    }
    if (data.containsKey('stability')) {
      context.handle(
        _stabilityMeta,
        stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('due')) {
      context.handle(
        _dueMeta,
        due.isAcceptableOrUnknown(data['due']!, _dueMeta),
      );
    }
    if (data.containsKey('last_review')) {
      context.handle(
        _lastReviewMeta,
        lastReview.isAcceptableOrUnknown(data['last_review']!, _lastReviewMeta),
      );
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('lapses')) {
      context.handle(
        _lapsesMeta,
        lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta),
      );
    }
    if (data.containsKey('correct')) {
      context.handle(
        _correctMeta,
        correct.isAcceptableOrUnknown(data['correct']!, _correctMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SkillRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SkillRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state'],
      )!,
      step: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step'],
      ),
      stability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stability'],
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty'],
      ),
      due: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due'],
      )!,
      lastReview: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_review'],
      ),
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
      correct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
    );
  }

  @override
  $SkillsTable createAlias(String alias) {
    return $SkillsTable(attachedDatabase, alias);
  }
}

class SkillRow extends DataClass implements Insertable<SkillRow> {
  final String id;
  final int state;
  final int? step;
  final double? stability;
  final double? difficulty;
  final DateTime due;
  final DateTime? lastReview;
  final int reps;
  final int lapses;

  /// Exercises answered right / attempted, first tries only.
  final int correct;
  final int attempts;
  const SkillRow({
    required this.id,
    required this.state,
    this.step,
    this.stability,
    this.difficulty,
    required this.due,
    this.lastReview,
    required this.reps,
    required this.lapses,
    required this.correct,
    required this.attempts,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['state'] = Variable<int>(state);
    if (!nullToAbsent || step != null) {
      map['step'] = Variable<int>(step);
    }
    if (!nullToAbsent || stability != null) {
      map['stability'] = Variable<double>(stability);
    }
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<double>(difficulty);
    }
    map['due'] = Variable<DateTime>(due);
    if (!nullToAbsent || lastReview != null) {
      map['last_review'] = Variable<DateTime>(lastReview);
    }
    map['reps'] = Variable<int>(reps);
    map['lapses'] = Variable<int>(lapses);
    map['correct'] = Variable<int>(correct);
    map['attempts'] = Variable<int>(attempts);
    return map;
  }

  SkillsCompanion toCompanion(bool nullToAbsent) {
    return SkillsCompanion(
      id: Value(id),
      state: Value(state),
      step: step == null && nullToAbsent ? const Value.absent() : Value(step),
      stability: stability == null && nullToAbsent
          ? const Value.absent()
          : Value(stability),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
      due: Value(due),
      lastReview: lastReview == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReview),
      reps: Value(reps),
      lapses: Value(lapses),
      correct: Value(correct),
      attempts: Value(attempts),
    );
  }

  factory SkillRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SkillRow(
      id: serializer.fromJson<String>(json['id']),
      state: serializer.fromJson<int>(json['state']),
      step: serializer.fromJson<int?>(json['step']),
      stability: serializer.fromJson<double?>(json['stability']),
      difficulty: serializer.fromJson<double?>(json['difficulty']),
      due: serializer.fromJson<DateTime>(json['due']),
      lastReview: serializer.fromJson<DateTime?>(json['lastReview']),
      reps: serializer.fromJson<int>(json['reps']),
      lapses: serializer.fromJson<int>(json['lapses']),
      correct: serializer.fromJson<int>(json['correct']),
      attempts: serializer.fromJson<int>(json['attempts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'state': serializer.toJson<int>(state),
      'step': serializer.toJson<int?>(step),
      'stability': serializer.toJson<double?>(stability),
      'difficulty': serializer.toJson<double?>(difficulty),
      'due': serializer.toJson<DateTime>(due),
      'lastReview': serializer.toJson<DateTime?>(lastReview),
      'reps': serializer.toJson<int>(reps),
      'lapses': serializer.toJson<int>(lapses),
      'correct': serializer.toJson<int>(correct),
      'attempts': serializer.toJson<int>(attempts),
    };
  }

  SkillRow copyWith({
    String? id,
    int? state,
    Value<int?> step = const Value.absent(),
    Value<double?> stability = const Value.absent(),
    Value<double?> difficulty = const Value.absent(),
    DateTime? due,
    Value<DateTime?> lastReview = const Value.absent(),
    int? reps,
    int? lapses,
    int? correct,
    int? attempts,
  }) => SkillRow(
    id: id ?? this.id,
    state: state ?? this.state,
    step: step.present ? step.value : this.step,
    stability: stability.present ? stability.value : this.stability,
    difficulty: difficulty.present ? difficulty.value : this.difficulty,
    due: due ?? this.due,
    lastReview: lastReview.present ? lastReview.value : this.lastReview,
    reps: reps ?? this.reps,
    lapses: lapses ?? this.lapses,
    correct: correct ?? this.correct,
    attempts: attempts ?? this.attempts,
  );
  SkillRow copyWithCompanion(SkillsCompanion data) {
    return SkillRow(
      id: data.id.present ? data.id.value : this.id,
      state: data.state.present ? data.state.value : this.state,
      step: data.step.present ? data.step.value : this.step,
      stability: data.stability.present ? data.stability.value : this.stability,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      due: data.due.present ? data.due.value : this.due,
      lastReview: data.lastReview.present
          ? data.lastReview.value
          : this.lastReview,
      reps: data.reps.present ? data.reps.value : this.reps,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      correct: data.correct.present ? data.correct.value : this.correct,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SkillRow(')
          ..write('id: $id, ')
          ..write('state: $state, ')
          ..write('step: $step, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('due: $due, ')
          ..write('lastReview: $lastReview, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('correct: $correct, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    state,
    step,
    stability,
    difficulty,
    due,
    lastReview,
    reps,
    lapses,
    correct,
    attempts,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SkillRow &&
          other.id == this.id &&
          other.state == this.state &&
          other.step == this.step &&
          other.stability == this.stability &&
          other.difficulty == this.difficulty &&
          other.due == this.due &&
          other.lastReview == this.lastReview &&
          other.reps == this.reps &&
          other.lapses == this.lapses &&
          other.correct == this.correct &&
          other.attempts == this.attempts);
}

class SkillsCompanion extends UpdateCompanion<SkillRow> {
  final Value<String> id;
  final Value<int> state;
  final Value<int?> step;
  final Value<double?> stability;
  final Value<double?> difficulty;
  final Value<DateTime> due;
  final Value<DateTime?> lastReview;
  final Value<int> reps;
  final Value<int> lapses;
  final Value<int> correct;
  final Value<int> attempts;
  final Value<int> rowid;
  const SkillsCompanion({
    this.id = const Value.absent(),
    this.state = const Value.absent(),
    this.step = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.due = const Value.absent(),
    this.lastReview = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.correct = const Value.absent(),
    this.attempts = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SkillsCompanion.insert({
    required String id,
    this.state = const Value.absent(),
    this.step = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.due = const Value.absent(),
    this.lastReview = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.correct = const Value.absent(),
    this.attempts = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<SkillRow> custom({
    Expression<String>? id,
    Expression<int>? state,
    Expression<int>? step,
    Expression<double>? stability,
    Expression<double>? difficulty,
    Expression<DateTime>? due,
    Expression<DateTime>? lastReview,
    Expression<int>? reps,
    Expression<int>? lapses,
    Expression<int>? correct,
    Expression<int>? attempts,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (state != null) 'state': state,
      if (step != null) 'step': step,
      if (stability != null) 'stability': stability,
      if (difficulty != null) 'difficulty': difficulty,
      if (due != null) 'due': due,
      if (lastReview != null) 'last_review': lastReview,
      if (reps != null) 'reps': reps,
      if (lapses != null) 'lapses': lapses,
      if (correct != null) 'correct': correct,
      if (attempts != null) 'attempts': attempts,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SkillsCompanion copyWith({
    Value<String>? id,
    Value<int>? state,
    Value<int?>? step,
    Value<double?>? stability,
    Value<double?>? difficulty,
    Value<DateTime>? due,
    Value<DateTime?>? lastReview,
    Value<int>? reps,
    Value<int>? lapses,
    Value<int>? correct,
    Value<int>? attempts,
    Value<int>? rowid,
  }) {
    return SkillsCompanion(
      id: id ?? this.id,
      state: state ?? this.state,
      step: step ?? this.step,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      due: due ?? this.due,
      lastReview: lastReview ?? this.lastReview,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      correct: correct ?? this.correct,
      attempts: attempts ?? this.attempts,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(state.value);
    }
    if (step.present) {
      map['step'] = Variable<int>(step.value);
    }
    if (stability.present) {
      map['stability'] = Variable<double>(stability.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (due.present) {
      map['due'] = Variable<DateTime>(due.value);
    }
    if (lastReview.present) {
      map['last_review'] = Variable<DateTime>(lastReview.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (correct.present) {
      map['correct'] = Variable<int>(correct.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SkillsCompanion(')
          ..write('id: $id, ')
          ..write('state: $state, ')
          ..write('step: $step, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('due: $due, ')
          ..write('lastReview: $lastReview, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('correct: $correct, ')
          ..write('attempts: $attempts, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MistakesTable extends Mistakes with TableInfo<$MistakesTable, Mistake> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MistakesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _skillIdMeta = const VerificationMeta(
    'skillId',
  );
  @override
  late final GeneratedColumn<String> skillId = GeneratedColumn<String>(
    'skill_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rightStreakMeta = const VerificationMeta(
    'rightStreak',
  );
  @override
  late final GeneratedColumn<int> rightStreak = GeneratedColumn<int>(
    'right_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _resolvedMeta = const VerificationMeta(
    'resolved',
  );
  @override
  late final GeneratedColumn<bool> resolved = GeneratedColumn<bool>(
    'resolved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("resolved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    wordId,
    skillId,
    createdAt,
    rightStreak,
    resolved,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mistakes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Mistake> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    }
    if (data.containsKey('skill_id')) {
      context.handle(
        _skillIdMeta,
        skillId.isAcceptableOrUnknown(data['skill_id']!, _skillIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('right_streak')) {
      context.handle(
        _rightStreakMeta,
        rightStreak.isAcceptableOrUnknown(
          data['right_streak']!,
          _rightStreakMeta,
        ),
      );
    }
    if (data.containsKey('resolved')) {
      context.handle(
        _resolvedMeta,
        resolved.isAcceptableOrUnknown(data['resolved']!, _resolvedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Mistake map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Mistake(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      ),
      skillId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skill_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      rightStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}right_streak'],
      )!,
      resolved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}resolved'],
      )!,
    );
  }

  @override
  $MistakesTable createAlias(String alias) {
    return $MistakesTable(attachedDatabase, alias);
  }
}

class Mistake extends DataClass implements Insertable<Mistake> {
  final int id;
  final int? wordId;
  final String? skillId;
  final DateTime createdAt;
  final int rightStreak;
  final bool resolved;
  const Mistake({
    required this.id,
    this.wordId,
    this.skillId,
    required this.createdAt,
    required this.rightStreak,
    required this.resolved,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || wordId != null) {
      map['word_id'] = Variable<int>(wordId);
    }
    if (!nullToAbsent || skillId != null) {
      map['skill_id'] = Variable<String>(skillId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['right_streak'] = Variable<int>(rightStreak);
    map['resolved'] = Variable<bool>(resolved);
    return map;
  }

  MistakesCompanion toCompanion(bool nullToAbsent) {
    return MistakesCompanion(
      id: Value(id),
      wordId: wordId == null && nullToAbsent
          ? const Value.absent()
          : Value(wordId),
      skillId: skillId == null && nullToAbsent
          ? const Value.absent()
          : Value(skillId),
      createdAt: Value(createdAt),
      rightStreak: Value(rightStreak),
      resolved: Value(resolved),
    );
  }

  factory Mistake.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Mistake(
      id: serializer.fromJson<int>(json['id']),
      wordId: serializer.fromJson<int?>(json['wordId']),
      skillId: serializer.fromJson<String?>(json['skillId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      rightStreak: serializer.fromJson<int>(json['rightStreak']),
      resolved: serializer.fromJson<bool>(json['resolved']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wordId': serializer.toJson<int?>(wordId),
      'skillId': serializer.toJson<String?>(skillId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'rightStreak': serializer.toJson<int>(rightStreak),
      'resolved': serializer.toJson<bool>(resolved),
    };
  }

  Mistake copyWith({
    int? id,
    Value<int?> wordId = const Value.absent(),
    Value<String?> skillId = const Value.absent(),
    DateTime? createdAt,
    int? rightStreak,
    bool? resolved,
  }) => Mistake(
    id: id ?? this.id,
    wordId: wordId.present ? wordId.value : this.wordId,
    skillId: skillId.present ? skillId.value : this.skillId,
    createdAt: createdAt ?? this.createdAt,
    rightStreak: rightStreak ?? this.rightStreak,
    resolved: resolved ?? this.resolved,
  );
  Mistake copyWithCompanion(MistakesCompanion data) {
    return Mistake(
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      skillId: data.skillId.present ? data.skillId.value : this.skillId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      rightStreak: data.rightStreak.present
          ? data.rightStreak.value
          : this.rightStreak,
      resolved: data.resolved.present ? data.resolved.value : this.resolved,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Mistake(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('skillId: $skillId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rightStreak: $rightStreak, ')
          ..write('resolved: $resolved')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, wordId, skillId, createdAt, rightStreak, resolved);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Mistake &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.skillId == this.skillId &&
          other.createdAt == this.createdAt &&
          other.rightStreak == this.rightStreak &&
          other.resolved == this.resolved);
}

class MistakesCompanion extends UpdateCompanion<Mistake> {
  final Value<int> id;
  final Value<int?> wordId;
  final Value<String?> skillId;
  final Value<DateTime> createdAt;
  final Value<int> rightStreak;
  final Value<bool> resolved;
  const MistakesCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.skillId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rightStreak = const Value.absent(),
    this.resolved = const Value.absent(),
  });
  MistakesCompanion.insert({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.skillId = const Value.absent(),
    required DateTime createdAt,
    this.rightStreak = const Value.absent(),
    this.resolved = const Value.absent(),
  }) : createdAt = Value(createdAt);
  static Insertable<Mistake> custom({
    Expression<int>? id,
    Expression<int>? wordId,
    Expression<String>? skillId,
    Expression<DateTime>? createdAt,
    Expression<int>? rightStreak,
    Expression<bool>? resolved,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (skillId != null) 'skill_id': skillId,
      if (createdAt != null) 'created_at': createdAt,
      if (rightStreak != null) 'right_streak': rightStreak,
      if (resolved != null) 'resolved': resolved,
    });
  }

  MistakesCompanion copyWith({
    Value<int>? id,
    Value<int?>? wordId,
    Value<String?>? skillId,
    Value<DateTime>? createdAt,
    Value<int>? rightStreak,
    Value<bool>? resolved,
  }) {
    return MistakesCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      skillId: skillId ?? this.skillId,
      createdAt: createdAt ?? this.createdAt,
      rightStreak: rightStreak ?? this.rightStreak,
      resolved: resolved ?? this.resolved,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (skillId.present) {
      map['skill_id'] = Variable<String>(skillId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rightStreak.present) {
      map['right_streak'] = Variable<int>(rightStreak.value);
    }
    if (resolved.present) {
      map['resolved'] = Variable<bool>(resolved.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MistakesCompanion(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('skillId: $skillId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rightStreak: $rightStreak, ')
          ..write('resolved: $resolved')
          ..write(')'))
        .toString();
  }
}

class $DictionaryTable extends Dictionary
    with TableInfo<$DictionaryTable, DictEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictionaryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _posMeta = const VerificationMeta('pos');
  @override
  late final GeneratedColumn<String> pos = GeneratedColumn<String>(
    'pos',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hanjaMeta = const VerificationMeta('hanja');
  @override
  late final GeneratedColumn<String> hanja = GeneratedColumn<String>(
    'hanja',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pronunciationMeta = const VerificationMeta(
    'pronunciation',
  );
  @override
  late final GeneratedColumn<String> pronunciation = GeneratedColumn<String>(
    'pronunciation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sensesMeta = const VerificationMeta('senses');
  @override
  late final GeneratedColumn<String> senses = GeneratedColumn<String>(
    'senses',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exampleMeta = const VerificationMeta(
    'example',
  );
  @override
  late final GeneratedColumn<String> example = GeneratedColumn<String>(
    'example',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formsMeta = const VerificationMeta('forms');
  @override
  late final GeneratedColumn<String> forms = GeneratedColumn<String>(
    'forms',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    word,
    pos,
    level,
    hanja,
    pronunciation,
    senses,
    example,
    forms,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dictionary';
  @override
  VerificationContext validateIntegrity(
    Insertable<DictEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('pos')) {
      context.handle(
        _posMeta,
        pos.isAcceptableOrUnknown(data['pos']!, _posMeta),
      );
    } else if (isInserting) {
      context.missing(_posMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('hanja')) {
      context.handle(
        _hanjaMeta,
        hanja.isAcceptableOrUnknown(data['hanja']!, _hanjaMeta),
      );
    }
    if (data.containsKey('pronunciation')) {
      context.handle(
        _pronunciationMeta,
        pronunciation.isAcceptableOrUnknown(
          data['pronunciation']!,
          _pronunciationMeta,
        ),
      );
    }
    if (data.containsKey('senses')) {
      context.handle(
        _sensesMeta,
        senses.isAcceptableOrUnknown(data['senses']!, _sensesMeta),
      );
    } else if (isInserting) {
      context.missing(_sensesMeta);
    }
    if (data.containsKey('example')) {
      context.handle(
        _exampleMeta,
        example.isAcceptableOrUnknown(data['example']!, _exampleMeta),
      );
    }
    if (data.containsKey('forms')) {
      context.handle(
        _formsMeta,
        forms.isAcceptableOrUnknown(data['forms']!, _formsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DictEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DictEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      pos: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pos'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      hanja: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hanja'],
      ),
      pronunciation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pronunciation'],
      ),
      senses: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}senses'],
      )!,
      example: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example'],
      ),
      forms: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}forms'],
      ),
    );
  }

  @override
  $DictionaryTable createAlias(String alias) {
    return $DictionaryTable(attachedDatabase, alias);
  }
}

class DictEntry extends DataClass implements Insertable<DictEntry> {
  final int id;
  final String word;
  final String pos;
  final String level;
  final String? hanja;
  final String? pronunciation;

  /// JSON list of {"m": [English words], "d": short definition}.
  final String senses;
  final String? example;

  /// KRDict 활용 forms (JSON) for verbs/adjectives; used to look up conjugated words.
  final String? forms;
  const DictEntry({
    required this.id,
    required this.word,
    required this.pos,
    required this.level,
    this.hanja,
    this.pronunciation,
    required this.senses,
    this.example,
    this.forms,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word'] = Variable<String>(word);
    map['pos'] = Variable<String>(pos);
    map['level'] = Variable<String>(level);
    if (!nullToAbsent || hanja != null) {
      map['hanja'] = Variable<String>(hanja);
    }
    if (!nullToAbsent || pronunciation != null) {
      map['pronunciation'] = Variable<String>(pronunciation);
    }
    map['senses'] = Variable<String>(senses);
    if (!nullToAbsent || example != null) {
      map['example'] = Variable<String>(example);
    }
    if (!nullToAbsent || forms != null) {
      map['forms'] = Variable<String>(forms);
    }
    return map;
  }

  DictionaryCompanion toCompanion(bool nullToAbsent) {
    return DictionaryCompanion(
      id: Value(id),
      word: Value(word),
      pos: Value(pos),
      level: Value(level),
      hanja: hanja == null && nullToAbsent
          ? const Value.absent()
          : Value(hanja),
      pronunciation: pronunciation == null && nullToAbsent
          ? const Value.absent()
          : Value(pronunciation),
      senses: Value(senses),
      example: example == null && nullToAbsent
          ? const Value.absent()
          : Value(example),
      forms: forms == null && nullToAbsent
          ? const Value.absent()
          : Value(forms),
    );
  }

  factory DictEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DictEntry(
      id: serializer.fromJson<int>(json['id']),
      word: serializer.fromJson<String>(json['word']),
      pos: serializer.fromJson<String>(json['pos']),
      level: serializer.fromJson<String>(json['level']),
      hanja: serializer.fromJson<String?>(json['hanja']),
      pronunciation: serializer.fromJson<String?>(json['pronunciation']),
      senses: serializer.fromJson<String>(json['senses']),
      example: serializer.fromJson<String?>(json['example']),
      forms: serializer.fromJson<String?>(json['forms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'word': serializer.toJson<String>(word),
      'pos': serializer.toJson<String>(pos),
      'level': serializer.toJson<String>(level),
      'hanja': serializer.toJson<String?>(hanja),
      'pronunciation': serializer.toJson<String?>(pronunciation),
      'senses': serializer.toJson<String>(senses),
      'example': serializer.toJson<String?>(example),
      'forms': serializer.toJson<String?>(forms),
    };
  }

  DictEntry copyWith({
    int? id,
    String? word,
    String? pos,
    String? level,
    Value<String?> hanja = const Value.absent(),
    Value<String?> pronunciation = const Value.absent(),
    String? senses,
    Value<String?> example = const Value.absent(),
    Value<String?> forms = const Value.absent(),
  }) => DictEntry(
    id: id ?? this.id,
    word: word ?? this.word,
    pos: pos ?? this.pos,
    level: level ?? this.level,
    hanja: hanja.present ? hanja.value : this.hanja,
    pronunciation: pronunciation.present
        ? pronunciation.value
        : this.pronunciation,
    senses: senses ?? this.senses,
    example: example.present ? example.value : this.example,
    forms: forms.present ? forms.value : this.forms,
  );
  DictEntry copyWithCompanion(DictionaryCompanion data) {
    return DictEntry(
      id: data.id.present ? data.id.value : this.id,
      word: data.word.present ? data.word.value : this.word,
      pos: data.pos.present ? data.pos.value : this.pos,
      level: data.level.present ? data.level.value : this.level,
      hanja: data.hanja.present ? data.hanja.value : this.hanja,
      pronunciation: data.pronunciation.present
          ? data.pronunciation.value
          : this.pronunciation,
      senses: data.senses.present ? data.senses.value : this.senses,
      example: data.example.present ? data.example.value : this.example,
      forms: data.forms.present ? data.forms.value : this.forms,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DictEntry(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('pos: $pos, ')
          ..write('level: $level, ')
          ..write('hanja: $hanja, ')
          ..write('pronunciation: $pronunciation, ')
          ..write('senses: $senses, ')
          ..write('example: $example, ')
          ..write('forms: $forms')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    word,
    pos,
    level,
    hanja,
    pronunciation,
    senses,
    example,
    forms,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DictEntry &&
          other.id == this.id &&
          other.word == this.word &&
          other.pos == this.pos &&
          other.level == this.level &&
          other.hanja == this.hanja &&
          other.pronunciation == this.pronunciation &&
          other.senses == this.senses &&
          other.example == this.example &&
          other.forms == this.forms);
}

class DictionaryCompanion extends UpdateCompanion<DictEntry> {
  final Value<int> id;
  final Value<String> word;
  final Value<String> pos;
  final Value<String> level;
  final Value<String?> hanja;
  final Value<String?> pronunciation;
  final Value<String> senses;
  final Value<String?> example;
  final Value<String?> forms;
  const DictionaryCompanion({
    this.id = const Value.absent(),
    this.word = const Value.absent(),
    this.pos = const Value.absent(),
    this.level = const Value.absent(),
    this.hanja = const Value.absent(),
    this.pronunciation = const Value.absent(),
    this.senses = const Value.absent(),
    this.example = const Value.absent(),
    this.forms = const Value.absent(),
  });
  DictionaryCompanion.insert({
    this.id = const Value.absent(),
    required String word,
    required String pos,
    required String level,
    this.hanja = const Value.absent(),
    this.pronunciation = const Value.absent(),
    required String senses,
    this.example = const Value.absent(),
    this.forms = const Value.absent(),
  }) : word = Value(word),
       pos = Value(pos),
       level = Value(level),
       senses = Value(senses);
  static Insertable<DictEntry> custom({
    Expression<int>? id,
    Expression<String>? word,
    Expression<String>? pos,
    Expression<String>? level,
    Expression<String>? hanja,
    Expression<String>? pronunciation,
    Expression<String>? senses,
    Expression<String>? example,
    Expression<String>? forms,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (word != null) 'word': word,
      if (pos != null) 'pos': pos,
      if (level != null) 'level': level,
      if (hanja != null) 'hanja': hanja,
      if (pronunciation != null) 'pronunciation': pronunciation,
      if (senses != null) 'senses': senses,
      if (example != null) 'example': example,
      if (forms != null) 'forms': forms,
    });
  }

  DictionaryCompanion copyWith({
    Value<int>? id,
    Value<String>? word,
    Value<String>? pos,
    Value<String>? level,
    Value<String?>? hanja,
    Value<String?>? pronunciation,
    Value<String>? senses,
    Value<String?>? example,
    Value<String?>? forms,
  }) {
    return DictionaryCompanion(
      id: id ?? this.id,
      word: word ?? this.word,
      pos: pos ?? this.pos,
      level: level ?? this.level,
      hanja: hanja ?? this.hanja,
      pronunciation: pronunciation ?? this.pronunciation,
      senses: senses ?? this.senses,
      example: example ?? this.example,
      forms: forms ?? this.forms,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (pos.present) {
      map['pos'] = Variable<String>(pos.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (hanja.present) {
      map['hanja'] = Variable<String>(hanja.value);
    }
    if (pronunciation.present) {
      map['pronunciation'] = Variable<String>(pronunciation.value);
    }
    if (senses.present) {
      map['senses'] = Variable<String>(senses.value);
    }
    if (example.present) {
      map['example'] = Variable<String>(example.value);
    }
    if (forms.present) {
      map['forms'] = Variable<String>(forms.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryCompanion(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('pos: $pos, ')
          ..write('level: $level, ')
          ..write('hanja: $hanja, ')
          ..write('pronunciation: $pronunciation, ')
          ..write('senses: $senses, ')
          ..write('example: $example, ')
          ..write('forms: $forms')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WordsTable words = $WordsTable(this);
  late final $CardsTable cards = $CardsTable(this);
  late final $ReviewLogsTable reviewLogs = $ReviewLogsTable(this);
  late final $ActivitiesTable activities = $ActivitiesTable(this);
  late final $LessonProgressTable lessonProgress = $LessonProgressTable(this);
  late final $AchievementsTable achievements = $AchievementsTable(this);
  late final $QuestClaimsTable questClaims = $QuestClaimsTable(this);
  late final $SkillsTable skills = $SkillsTable(this);
  late final $MistakesTable mistakes = $MistakesTable(this);
  late final $DictionaryTable dictionary = $DictionaryTable(this);
  late final Index dictionaryWord = Index(
    'dictionary_word',
    'CREATE INDEX dictionary_word ON dictionary (word)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    words,
    cards,
    reviewLogs,
    activities,
    lessonProgress,
    achievements,
    questClaims,
    skills,
    mistakes,
    dictionary,
    dictionaryWord,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'words',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('cards', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'cards',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('review_logs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$WordsTableCreateCompanionBuilder = WordsCompanion Function({
  Value<int> id,
  required String word,
  Value<int> homonym,
  required String pos,
  required String level,
  Value<String?> hanja,
  Value<String?> pronunciation,
  Value<String?> category,
  required String senses,
  required int rank,
  Value<bool> isCustom,
  Value<bool> starred,
  Value<String?> note,
  Value<String?> unit,
  Value<String?> forms,
});
typedef $$WordsTableUpdateCompanionBuilder = WordsCompanion Function({
  Value<int> id,
  Value<String> word,
  Value<int> homonym,
  Value<String> pos,
  Value<String> level,
  Value<String?> hanja,
  Value<String?> pronunciation,
  Value<String?> category,
  Value<String> senses,
  Value<int> rank,
  Value<bool> isCustom,
  Value<bool> starred,
  Value<String?> note,
  Value<String?> unit,
  Value<String?> forms,
});

final class $$WordsTableReferences
    extends BaseReferences<_$AppDatabase, $WordsTable, Word> {
  $$WordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CardsTable, List<StudyCard>> _cardsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.cards,
    aliasName: 'words__id__cards__word_id',
  );

  $$CardsTableProcessedTableManager get cardsRefs {
    final manager = $$CardsTableTableManager(
      $_db,
      $_db.cards,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WordsTableFilterComposer extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get homonym => $composableBuilder(
    column: $table.homonym,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pos => $composableBuilder(
    column: $table.pos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hanja => $composableBuilder(
    column: $table.hanja,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pronunciation => $composableBuilder(
    column: $table.pronunciation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senses => $composableBuilder(
    column: $table.senses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get starred => $composableBuilder(
    column: $table.starred,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get forms => $composableBuilder(
    column: $table.forms,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> cardsRefs(
    Expression<bool> Function($$CardsTableFilterComposer f) f,
  ) {
    final $$CardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableFilterComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WordsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get homonym => $composableBuilder(
    column: $table.homonym,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pos => $composableBuilder(
    column: $table.pos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hanja => $composableBuilder(
    column: $table.hanja,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pronunciation => $composableBuilder(
    column: $table.pronunciation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senses => $composableBuilder(
    column: $table.senses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get starred => $composableBuilder(
    column: $table.starred,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get forms => $composableBuilder(
    column: $table.forms,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<int> get homonym =>
      $composableBuilder(column: $table.homonym, builder: (column) => column);

  GeneratedColumn<String> get pos =>
      $composableBuilder(column: $table.pos, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get hanja =>
      $composableBuilder(column: $table.hanja, builder: (column) => column);

  GeneratedColumn<String> get pronunciation => $composableBuilder(
    column: $table.pronunciation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get senses =>
      $composableBuilder(column: $table.senses, builder: (column) => column);

  GeneratedColumn<int> get rank =>
      $composableBuilder(column: $table.rank, builder: (column) => column);

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);

  GeneratedColumn<bool> get starred =>
      $composableBuilder(column: $table.starred, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get forms =>
      $composableBuilder(column: $table.forms, builder: (column) => column);

  Expression<T> cardsRefs<T extends Object>(
    Expression<T> Function($$CardsTableAnnotationComposer a) f,
  ) {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableAnnotationComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordsTable,
          Word,
          $$WordsTableFilterComposer,
          $$WordsTableOrderingComposer,
          $$WordsTableAnnotationComposer,
          $$WordsTableCreateCompanionBuilder,
          $$WordsTableUpdateCompanionBuilder,
          (Word, $$WordsTableReferences),
          Word,
          PrefetchHooks Function({bool cardsRefs})
        > {
  $$WordsTableTableManager(_$AppDatabase db, $WordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<int> homonym = const Value.absent(),
                Value<String> pos = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<String?> hanja = const Value.absent(),
                Value<String?> pronunciation = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> senses = const Value.absent(),
                Value<int> rank = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<bool> starred = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> forms = const Value.absent(),
              }) => WordsCompanion(
                id: id,
                word: word,
                homonym: homonym,
                pos: pos,
                level: level,
                hanja: hanja,
                pronunciation: pronunciation,
                category: category,
                senses: senses,
                rank: rank,
                isCustom: isCustom,
                starred: starred,
                note: note,
                unit: unit,
                forms: forms,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String word,
                Value<int> homonym = const Value.absent(),
                required String pos,
                required String level,
                Value<String?> hanja = const Value.absent(),
                Value<String?> pronunciation = const Value.absent(),
                Value<String?> category = const Value.absent(),
                required String senses,
                required int rank,
                Value<bool> isCustom = const Value.absent(),
                Value<bool> starred = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> forms = const Value.absent(),
              }) => WordsCompanion.insert(
                id: id,
                word: word,
                homonym: homonym,
                pos: pos,
                level: level,
                hanja: hanja,
                pronunciation: pronunciation,
                category: category,
                senses: senses,
                rank: rank,
                isCustom: isCustom,
                starred: starred,
                note: note,
                unit: unit,
                forms: forms,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WordsTable, Word>(table),
                  $$WordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cardsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (cardsRefs) db.cards],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cardsRefs)
                    await $_getPrefetchedDataByColumns<
                      Word,
                      $WordsTable,
                      StudyCard,
                      $CardsTable
                    >(
                      currentTable: table,
                      referencedTable: $$WordsTableReferences._cardsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$WordsTableReferences(db, table, p0).cardsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'word_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordsTable,
      Word,
      $$WordsTableFilterComposer,
      $$WordsTableOrderingComposer,
      $$WordsTableAnnotationComposer,
      $$WordsTableCreateCompanionBuilder,
      $$WordsTableUpdateCompanionBuilder,
      (Word, $$WordsTableReferences),
      Word,
      PrefetchHooks Function({bool cardsRefs})
    >;
typedef $$CardsTableCreateCompanionBuilder = CardsCompanion Function({
  Value<int> id,
  required int wordId,
  required int direction,
  Value<int> state,
  Value<int?> step,
  Value<double?> stability,
  Value<double?> difficulty,
  Value<DateTime> due,
  Value<DateTime?> lastReview,
  Value<int> reps,
  Value<int> lapses,
  Value<bool> suspended,
});
typedef $$CardsTableUpdateCompanionBuilder = CardsCompanion Function({
  Value<int> id,
  Value<int> wordId,
  Value<int> direction,
  Value<int> state,
  Value<int?> step,
  Value<double?> stability,
  Value<double?> difficulty,
  Value<DateTime> due,
  Value<DateTime?> lastReview,
  Value<int> reps,
  Value<int> lapses,
  Value<bool> suspended,
});

final class $$CardsTableReferences
    extends BaseReferences<_$AppDatabase, $CardsTable, StudyCard> {
  $$CardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('cards__word_id__words__id');

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ReviewLogsTable, List<ReviewLog>>
  _reviewLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reviewLogs,
    aliasName: 'cards__id__review_logs__card_id',
  );

  $$ReviewLogsTableProcessedTableManager get reviewLogsRefs {
    final manager = $$ReviewLogsTableTableManager(
      $_db,
      $_db.reviewLogs,
    ).filter((f) => f.cardId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CardsTableFilterComposer extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get suspended => $composableBuilder(
    column: $table.suspended,
    builder: (column) => ColumnFilters(column),
  );

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> reviewLogsRefs(
    Expression<bool> Function($$ReviewLogsTableFilterComposer f) f,
  ) {
    final $$ReviewLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewLogs,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewLogsTableFilterComposer(
            $db: $db,
            $table: $db.reviewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CardsTableOrderingComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get suspended => $composableBuilder(
    column: $table.suspended,
    builder: (column) => ColumnOrderings(column),
  );

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableOrderingComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get step =>
      $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<double> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get due =>
      $composableBuilder(column: $table.due, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<bool> get suspended =>
      $composableBuilder(column: $table.suspended, builder: (column) => column);

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> reviewLogsRefs<T extends Object>(
    Expression<T> Function($$ReviewLogsTableAnnotationComposer a) f,
  ) {
    final $$ReviewLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewLogs,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.reviewLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CardsTable,
          StudyCard,
          $$CardsTableFilterComposer,
          $$CardsTableOrderingComposer,
          $$CardsTableAnnotationComposer,
          $$CardsTableCreateCompanionBuilder,
          $$CardsTableUpdateCompanionBuilder,
          (StudyCard, $$CardsTableReferences),
          StudyCard,
          PrefetchHooks Function({bool wordId, bool reviewLogsRefs})
        > {
  $$CardsTableTableManager(_$AppDatabase db, $CardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<int> direction = const Value.absent(),
                Value<int> state = const Value.absent(),
                Value<int?> step = const Value.absent(),
                Value<double?> stability = const Value.absent(),
                Value<double?> difficulty = const Value.absent(),
                Value<DateTime> due = const Value.absent(),
                Value<DateTime?> lastReview = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<bool> suspended = const Value.absent(),
              }) => CardsCompanion(
                id: id,
                wordId: wordId,
                direction: direction,
                state: state,
                step: step,
                stability: stability,
                difficulty: difficulty,
                due: due,
                lastReview: lastReview,
                reps: reps,
                lapses: lapses,
                suspended: suspended,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int wordId,
                required int direction,
                Value<int> state = const Value.absent(),
                Value<int?> step = const Value.absent(),
                Value<double?> stability = const Value.absent(),
                Value<double?> difficulty = const Value.absent(),
                Value<DateTime> due = const Value.absent(),
                Value<DateTime?> lastReview = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<bool> suspended = const Value.absent(),
              }) => CardsCompanion.insert(
                id: id,
                wordId: wordId,
                direction: direction,
                state: state,
                step: step,
                stability: stability,
                difficulty: difficulty,
                due: due,
                lastReview: lastReview,
                reps: reps,
                lapses: lapses,
                suspended: suspended,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CardsTable, StudyCard>(table),
                  $$CardsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false, reviewLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (reviewLogsRefs) db.reviewLogs],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (wordId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.wordId,
                        referencedTable: $$CardsTableReferences._wordIdTable(
                          db,
                        ),
                        referencedColumn: $$CardsTableReferences
                            ._wordIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (reviewLogsRefs)
                    await $_getPrefetchedDataByColumns<
                      StudyCard,
                      $CardsTable,
                      ReviewLog,
                      $ReviewLogsTable
                    >(
                      currentTable: table,
                      referencedTable: $$CardsTableReferences
                          ._reviewLogsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CardsTableReferences(db, table, p0).reviewLogsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'card_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CardsTable,
      StudyCard,
      $$CardsTableFilterComposer,
      $$CardsTableOrderingComposer,
      $$CardsTableAnnotationComposer,
      $$CardsTableCreateCompanionBuilder,
      $$CardsTableUpdateCompanionBuilder,
      (StudyCard, $$CardsTableReferences),
      StudyCard,
      PrefetchHooks Function({bool wordId, bool reviewLogsRefs})
    >;
typedef $$ReviewLogsTableCreateCompanionBuilder = ReviewLogsCompanion Function({
  Value<int> id,
  required int cardId,
  required int rating,
  required int stateBefore,
  required DateTime reviewedAt,
  required int elapsedMs,
});
typedef $$ReviewLogsTableUpdateCompanionBuilder = ReviewLogsCompanion Function({
  Value<int> id,
  Value<int> cardId,
  Value<int> rating,
  Value<int> stateBefore,
  Value<DateTime> reviewedAt,
  Value<int> elapsedMs,
});

final class $$ReviewLogsTableReferences
    extends BaseReferences<_$AppDatabase, $ReviewLogsTable, ReviewLog> {
  $$ReviewLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CardsTable _cardIdTable(_$AppDatabase db) =>
      db.cards.createAlias('review_logs__card_id__cards__id');

  $$CardsTableProcessedTableManager get cardId {
    final $_column = $_itemColumn<int>('card_id')!;

    final manager = $$CardsTableTableManager(
      $_db,
      $_db.cards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReviewLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stateBefore => $composableBuilder(
    column: $table.stateBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnFilters(column),
  );

  $$CardsTableFilterComposer get cardId {
    final $$CardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableFilterComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stateBefore => $composableBuilder(
    column: $table.stateBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$CardsTableOrderingComposer get cardId {
    final $$CardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableOrderingComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get stateBefore => $composableBuilder(
    column: $table.stateBefore,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get elapsedMs =>
      $composableBuilder(column: $table.elapsedMs, builder: (column) => column);

  $$CardsTableAnnotationComposer get cardId {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableAnnotationComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewLogsTable,
          ReviewLog,
          $$ReviewLogsTableFilterComposer,
          $$ReviewLogsTableOrderingComposer,
          $$ReviewLogsTableAnnotationComposer,
          $$ReviewLogsTableCreateCompanionBuilder,
          $$ReviewLogsTableUpdateCompanionBuilder,
          (ReviewLog, $$ReviewLogsTableReferences),
          ReviewLog,
          PrefetchHooks Function({bool cardId})
        > {
  $$ReviewLogsTableTableManager(_$AppDatabase db, $ReviewLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> cardId = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<int> stateBefore = const Value.absent(),
                Value<DateTime> reviewedAt = const Value.absent(),
                Value<int> elapsedMs = const Value.absent(),
              }) => ReviewLogsCompanion(
                id: id,
                cardId: cardId,
                rating: rating,
                stateBefore: stateBefore,
                reviewedAt: reviewedAt,
                elapsedMs: elapsedMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int cardId,
                required int rating,
                required int stateBefore,
                required DateTime reviewedAt,
                required int elapsedMs,
              }) => ReviewLogsCompanion.insert(
                id: id,
                cardId: cardId,
                rating: rating,
                stateBefore: stateBefore,
                reviewedAt: reviewedAt,
                elapsedMs: elapsedMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReviewLogsTable, ReviewLog>(table),
                  $$ReviewLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cardId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.cardId,
                        referencedTable: $$ReviewLogsTableReferences
                            ._cardIdTable(db),
                        referencedColumn: $$ReviewLogsTableReferences
                            ._cardIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReviewLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewLogsTable,
      ReviewLog,
      $$ReviewLogsTableFilterComposer,
      $$ReviewLogsTableOrderingComposer,
      $$ReviewLogsTableAnnotationComposer,
      $$ReviewLogsTableCreateCompanionBuilder,
      $$ReviewLogsTableUpdateCompanionBuilder,
      (ReviewLog, $$ReviewLogsTableReferences),
      ReviewLog,
      PrefetchHooks Function({bool cardId})
    >;
typedef $$ActivitiesTableCreateCompanionBuilder = ActivitiesCompanion Function({
  Value<int> id,
  required String kind,
  Value<int> xp,
  Value<int> value,
  Value<String?> ref,
  required DateTime createdAt,
});
typedef $$ActivitiesTableUpdateCompanionBuilder = ActivitiesCompanion Function({
  Value<int> id,
  Value<String> kind,
  Value<int> xp,
  Value<int> value,
  Value<String?> ref,
  Value<DateTime> createdAt,
});

class $$ActivitiesTableFilterComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xp => $composableBuilder(
    column: $table.xp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ref => $composableBuilder(
    column: $table.ref,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActivitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xp => $composableBuilder(
    column: $table.xp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ref => $composableBuilder(
    column: $table.ref,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get xp =>
      $composableBuilder(column: $table.xp, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get ref =>
      $composableBuilder(column: $table.ref, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ActivitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivitiesTable,
          Activity,
          $$ActivitiesTableFilterComposer,
          $$ActivitiesTableOrderingComposer,
          $$ActivitiesTableAnnotationComposer,
          $$ActivitiesTableCreateCompanionBuilder,
          $$ActivitiesTableUpdateCompanionBuilder,
          (Activity, BaseReferences<_$AppDatabase, $ActivitiesTable, Activity>),
          Activity,
          PrefetchHooks Function()
        > {
  $$ActivitiesTableTableManager(_$AppDatabase db, $ActivitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> xp = const Value.absent(),
                Value<int> value = const Value.absent(),
                Value<String?> ref = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ActivitiesCompanion(
                id: id,
                kind: kind,
                xp: xp,
                value: value,
                ref: ref,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                Value<int> xp = const Value.absent(),
                Value<int> value = const Value.absent(),
                Value<String?> ref = const Value.absent(),
                required DateTime createdAt,
              }) => ActivitiesCompanion.insert(
                id: id,
                kind: kind,
                xp: xp,
                value: value,
                ref: ref,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ActivitiesTable, Activity>(table),
                  BaseReferences<_$AppDatabase, $ActivitiesTable, Activity>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActivitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivitiesTable,
      Activity,
      $$ActivitiesTableFilterComposer,
      $$ActivitiesTableOrderingComposer,
      $$ActivitiesTableAnnotationComposer,
      $$ActivitiesTableCreateCompanionBuilder,
      $$ActivitiesTableUpdateCompanionBuilder,
      (Activity, BaseReferences<_$AppDatabase, $ActivitiesTable, Activity>),
      Activity,
      PrefetchHooks Function()
    >;
typedef $$LessonProgressTableCreateCompanionBuilder =
    LessonProgressCompanion Function({
      required String lessonId,
      required int stars,
      required double bestAccuracy,
      Value<int> completions,
      required DateTime firstCompletedAt,
      required DateTime lastCompletedAt,
      Value<int> rowid,
    });
typedef $$LessonProgressTableUpdateCompanionBuilder =
    LessonProgressCompanion Function({
      Value<String> lessonId,
      Value<int> stars,
      Value<double> bestAccuracy,
      Value<int> completions,
      Value<DateTime> firstCompletedAt,
      Value<DateTime> lastCompletedAt,
      Value<int> rowid,
    });

class $$LessonProgressTableFilterComposer
    extends Composer<_$AppDatabase, $LessonProgressTable> {
  $$LessonProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bestAccuracy => $composableBuilder(
    column: $table.bestAccuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completions => $composableBuilder(
    column: $table.completions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstCompletedAt => $composableBuilder(
    column: $table.firstCompletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastCompletedAt => $composableBuilder(
    column: $table.lastCompletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LessonProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonProgressTable> {
  $$LessonProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bestAccuracy => $composableBuilder(
    column: $table.bestAccuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completions => $composableBuilder(
    column: $table.completions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstCompletedAt => $composableBuilder(
    column: $table.firstCompletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastCompletedAt => $composableBuilder(
    column: $table.lastCompletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LessonProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonProgressTable> {
  $$LessonProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<int> get stars =>
      $composableBuilder(column: $table.stars, builder: (column) => column);

  GeneratedColumn<double> get bestAccuracy => $composableBuilder(
    column: $table.bestAccuracy,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completions => $composableBuilder(
    column: $table.completions,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get firstCompletedAt => $composableBuilder(
    column: $table.firstCompletedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastCompletedAt => $composableBuilder(
    column: $table.lastCompletedAt,
    builder: (column) => column,
  );
}

class $$LessonProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LessonProgressTable,
          LessonProgressData,
          $$LessonProgressTableFilterComposer,
          $$LessonProgressTableOrderingComposer,
          $$LessonProgressTableAnnotationComposer,
          $$LessonProgressTableCreateCompanionBuilder,
          $$LessonProgressTableUpdateCompanionBuilder,
          (
            LessonProgressData,
            BaseReferences<
              _$AppDatabase,
              $LessonProgressTable,
              LessonProgressData
            >,
          ),
          LessonProgressData,
          PrefetchHooks Function()
        > {
  $$LessonProgressTableTableManager(
    _$AppDatabase db,
    $LessonProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> lessonId = const Value.absent(),
                Value<int> stars = const Value.absent(),
                Value<double> bestAccuracy = const Value.absent(),
                Value<int> completions = const Value.absent(),
                Value<DateTime> firstCompletedAt = const Value.absent(),
                Value<DateTime> lastCompletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LessonProgressCompanion(
                lessonId: lessonId,
                stars: stars,
                bestAccuracy: bestAccuracy,
                completions: completions,
                firstCompletedAt: firstCompletedAt,
                lastCompletedAt: lastCompletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lessonId,
                required int stars,
                required double bestAccuracy,
                Value<int> completions = const Value.absent(),
                required DateTime firstCompletedAt,
                required DateTime lastCompletedAt,
                Value<int> rowid = const Value.absent(),
              }) => LessonProgressCompanion.insert(
                lessonId: lessonId,
                stars: stars,
                bestAccuracy: bestAccuracy,
                completions: completions,
                firstCompletedAt: firstCompletedAt,
                lastCompletedAt: lastCompletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LessonProgressTable, LessonProgressData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LessonProgressTable,
                    LessonProgressData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LessonProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LessonProgressTable,
      LessonProgressData,
      $$LessonProgressTableFilterComposer,
      $$LessonProgressTableOrderingComposer,
      $$LessonProgressTableAnnotationComposer,
      $$LessonProgressTableCreateCompanionBuilder,
      $$LessonProgressTableUpdateCompanionBuilder,
      (
        LessonProgressData,
        BaseReferences<_$AppDatabase, $LessonProgressTable, LessonProgressData>,
      ),
      LessonProgressData,
      PrefetchHooks Function()
    >;
typedef $$AchievementsTableCreateCompanionBuilder =
    AchievementsCompanion Function({
      required String id,
      required DateTime unlockedAt,
      Value<int> rowid,
    });
typedef $$AchievementsTableUpdateCompanionBuilder =
    AchievementsCompanion Function({
      Value<String> id,
      Value<DateTime> unlockedAt,
      Value<int> rowid,
    });

class $$AchievementsTableFilterComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AchievementsTableOrderingComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AchievementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => column,
  );
}

class $$AchievementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AchievementsTable,
          Achievement,
          $$AchievementsTableFilterComposer,
          $$AchievementsTableOrderingComposer,
          $$AchievementsTableAnnotationComposer,
          $$AchievementsTableCreateCompanionBuilder,
          $$AchievementsTableUpdateCompanionBuilder,
          (
            Achievement,
            BaseReferences<_$AppDatabase, $AchievementsTable, Achievement>,
          ),
          Achievement,
          PrefetchHooks Function()
        > {
  $$AchievementsTableTableManager(_$AppDatabase db, $AchievementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AchievementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AchievementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AchievementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> unlockedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AchievementsCompanion(
                id: id,
                unlockedAt: unlockedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime unlockedAt,
                Value<int> rowid = const Value.absent(),
              }) => AchievementsCompanion.insert(
                id: id,
                unlockedAt: unlockedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AchievementsTable, Achievement>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AchievementsTable,
                    Achievement
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AchievementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AchievementsTable,
      Achievement,
      $$AchievementsTableFilterComposer,
      $$AchievementsTableOrderingComposer,
      $$AchievementsTableAnnotationComposer,
      $$AchievementsTableCreateCompanionBuilder,
      $$AchievementsTableUpdateCompanionBuilder,
      (
        Achievement,
        BaseReferences<_$AppDatabase, $AchievementsTable, Achievement>,
      ),
      Achievement,
      PrefetchHooks Function()
    >;
typedef $$QuestClaimsTableCreateCompanionBuilder =
    QuestClaimsCompanion Function({
      required DateTime day,
      required String questId,
      Value<int> rowid,
    });
typedef $$QuestClaimsTableUpdateCompanionBuilder =
    QuestClaimsCompanion Function({
      Value<DateTime> day,
      Value<String> questId,
      Value<int> rowid,
    });

class $$QuestClaimsTableFilterComposer
    extends Composer<_$AppDatabase, $QuestClaimsTable> {
  $$QuestClaimsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questId => $composableBuilder(
    column: $table.questId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuestClaimsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestClaimsTable> {
  $$QuestClaimsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questId => $composableBuilder(
    column: $table.questId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuestClaimsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestClaimsTable> {
  $$QuestClaimsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get questId =>
      $composableBuilder(column: $table.questId, builder: (column) => column);
}

class $$QuestClaimsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuestClaimsTable,
          QuestClaim,
          $$QuestClaimsTableFilterComposer,
          $$QuestClaimsTableOrderingComposer,
          $$QuestClaimsTableAnnotationComposer,
          $$QuestClaimsTableCreateCompanionBuilder,
          $$QuestClaimsTableUpdateCompanionBuilder,
          (
            QuestClaim,
            BaseReferences<_$AppDatabase, $QuestClaimsTable, QuestClaim>,
          ),
          QuestClaim,
          PrefetchHooks Function()
        > {
  $$QuestClaimsTableTableManager(_$AppDatabase db, $QuestClaimsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestClaimsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestClaimsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestClaimsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<DateTime> day = const Value.absent(),
            Value<String> questId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => QuestClaimsCompanion(day: day, questId: questId, rowid: rowid),
          createCompanionCallback:
              ({
                required DateTime day,
                required String questId,
                Value<int> rowid = const Value.absent(),
              }) => QuestClaimsCompanion.insert(
                day: day,
                questId: questId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuestClaimsTable, QuestClaim>(table),
                  BaseReferences<_$AppDatabase, $QuestClaimsTable, QuestClaim>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuestClaimsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuestClaimsTable,
      QuestClaim,
      $$QuestClaimsTableFilterComposer,
      $$QuestClaimsTableOrderingComposer,
      $$QuestClaimsTableAnnotationComposer,
      $$QuestClaimsTableCreateCompanionBuilder,
      $$QuestClaimsTableUpdateCompanionBuilder,
      (
        QuestClaim,
        BaseReferences<_$AppDatabase, $QuestClaimsTable, QuestClaim>,
      ),
      QuestClaim,
      PrefetchHooks Function()
    >;
typedef $$SkillsTableCreateCompanionBuilder = SkillsCompanion Function({
  required String id,
  Value<int> state,
  Value<int?> step,
  Value<double?> stability,
  Value<double?> difficulty,
  Value<DateTime> due,
  Value<DateTime?> lastReview,
  Value<int> reps,
  Value<int> lapses,
  Value<int> correct,
  Value<int> attempts,
  Value<int> rowid,
});
typedef $$SkillsTableUpdateCompanionBuilder = SkillsCompanion Function({
  Value<String> id,
  Value<int> state,
  Value<int?> step,
  Value<double?> stability,
  Value<double?> difficulty,
  Value<DateTime> due,
  Value<DateTime?> lastReview,
  Value<int> reps,
  Value<int> lapses,
  Value<int> correct,
  Value<int> attempts,
  Value<int> rowid,
});

class $$SkillsTableFilterComposer
    extends Composer<_$AppDatabase, $SkillsTable> {
  $$SkillsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SkillsTableOrderingComposer
    extends Composer<_$AppDatabase, $SkillsTable> {
  $$SkillsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SkillsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SkillsTable> {
  $$SkillsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get step =>
      $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<double> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get due =>
      $composableBuilder(column: $table.due, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<int> get correct =>
      $composableBuilder(column: $table.correct, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);
}

class $$SkillsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SkillsTable,
          SkillRow,
          $$SkillsTableFilterComposer,
          $$SkillsTableOrderingComposer,
          $$SkillsTableAnnotationComposer,
          $$SkillsTableCreateCompanionBuilder,
          $$SkillsTableUpdateCompanionBuilder,
          (SkillRow, BaseReferences<_$AppDatabase, $SkillsTable, SkillRow>),
          SkillRow,
          PrefetchHooks Function()
        > {
  $$SkillsTableTableManager(_$AppDatabase db, $SkillsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SkillsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SkillsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SkillsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> state = const Value.absent(),
                Value<int?> step = const Value.absent(),
                Value<double?> stability = const Value.absent(),
                Value<double?> difficulty = const Value.absent(),
                Value<DateTime> due = const Value.absent(),
                Value<DateTime?> lastReview = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<int> correct = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SkillsCompanion(
                id: id,
                state: state,
                step: step,
                stability: stability,
                difficulty: difficulty,
                due: due,
                lastReview: lastReview,
                reps: reps,
                lapses: lapses,
                correct: correct,
                attempts: attempts,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> state = const Value.absent(),
                Value<int?> step = const Value.absent(),
                Value<double?> stability = const Value.absent(),
                Value<double?> difficulty = const Value.absent(),
                Value<DateTime> due = const Value.absent(),
                Value<DateTime?> lastReview = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<int> correct = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SkillsCompanion.insert(
                id: id,
                state: state,
                step: step,
                stability: stability,
                difficulty: difficulty,
                due: due,
                lastReview: lastReview,
                reps: reps,
                lapses: lapses,
                correct: correct,
                attempts: attempts,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SkillsTable, SkillRow>(table),
                  BaseReferences<_$AppDatabase, $SkillsTable, SkillRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SkillsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SkillsTable,
      SkillRow,
      $$SkillsTableFilterComposer,
      $$SkillsTableOrderingComposer,
      $$SkillsTableAnnotationComposer,
      $$SkillsTableCreateCompanionBuilder,
      $$SkillsTableUpdateCompanionBuilder,
      (SkillRow, BaseReferences<_$AppDatabase, $SkillsTable, SkillRow>),
      SkillRow,
      PrefetchHooks Function()
    >;
typedef $$MistakesTableCreateCompanionBuilder = MistakesCompanion Function({
  Value<int> id,
  Value<int?> wordId,
  Value<String?> skillId,
  required DateTime createdAt,
  Value<int> rightStreak,
  Value<bool> resolved,
});
typedef $$MistakesTableUpdateCompanionBuilder = MistakesCompanion Function({
  Value<int> id,
  Value<int?> wordId,
  Value<String?> skillId,
  Value<DateTime> createdAt,
  Value<int> rightStreak,
  Value<bool> resolved,
});

class $$MistakesTableFilterComposer
    extends Composer<_$AppDatabase, $MistakesTable> {
  $$MistakesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skillId => $composableBuilder(
    column: $table.skillId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rightStreak => $composableBuilder(
    column: $table.rightStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get resolved => $composableBuilder(
    column: $table.resolved,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MistakesTableOrderingComposer
    extends Composer<_$AppDatabase, $MistakesTable> {
  $$MistakesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skillId => $composableBuilder(
    column: $table.skillId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rightStreak => $composableBuilder(
    column: $table.rightStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get resolved => $composableBuilder(
    column: $table.resolved,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MistakesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MistakesTable> {
  $$MistakesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<String> get skillId =>
      $composableBuilder(column: $table.skillId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get rightStreak => $composableBuilder(
    column: $table.rightStreak,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get resolved =>
      $composableBuilder(column: $table.resolved, builder: (column) => column);
}

class $$MistakesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MistakesTable,
          Mistake,
          $$MistakesTableFilterComposer,
          $$MistakesTableOrderingComposer,
          $$MistakesTableAnnotationComposer,
          $$MistakesTableCreateCompanionBuilder,
          $$MistakesTableUpdateCompanionBuilder,
          (Mistake, BaseReferences<_$AppDatabase, $MistakesTable, Mistake>),
          Mistake,
          PrefetchHooks Function()
        > {
  $$MistakesTableTableManager(_$AppDatabase db, $MistakesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MistakesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MistakesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MistakesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> wordId = const Value.absent(),
                Value<String?> skillId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rightStreak = const Value.absent(),
                Value<bool> resolved = const Value.absent(),
              }) => MistakesCompanion(
                id: id,
                wordId: wordId,
                skillId: skillId,
                createdAt: createdAt,
                rightStreak: rightStreak,
                resolved: resolved,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> wordId = const Value.absent(),
                Value<String?> skillId = const Value.absent(),
                required DateTime createdAt,
                Value<int> rightStreak = const Value.absent(),
                Value<bool> resolved = const Value.absent(),
              }) => MistakesCompanion.insert(
                id: id,
                wordId: wordId,
                skillId: skillId,
                createdAt: createdAt,
                rightStreak: rightStreak,
                resolved: resolved,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MistakesTable, Mistake>(table),
                  BaseReferences<_$AppDatabase, $MistakesTable, Mistake>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MistakesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MistakesTable,
      Mistake,
      $$MistakesTableFilterComposer,
      $$MistakesTableOrderingComposer,
      $$MistakesTableAnnotationComposer,
      $$MistakesTableCreateCompanionBuilder,
      $$MistakesTableUpdateCompanionBuilder,
      (Mistake, BaseReferences<_$AppDatabase, $MistakesTable, Mistake>),
      Mistake,
      PrefetchHooks Function()
    >;
typedef $$DictionaryTableCreateCompanionBuilder = DictionaryCompanion Function({
  Value<int> id,
  required String word,
  required String pos,
  required String level,
  Value<String?> hanja,
  Value<String?> pronunciation,
  required String senses,
  Value<String?> example,
  Value<String?> forms,
});
typedef $$DictionaryTableUpdateCompanionBuilder = DictionaryCompanion Function({
  Value<int> id,
  Value<String> word,
  Value<String> pos,
  Value<String> level,
  Value<String?> hanja,
  Value<String?> pronunciation,
  Value<String> senses,
  Value<String?> example,
  Value<String?> forms,
});

class $$DictionaryTableFilterComposer
    extends Composer<_$AppDatabase, $DictionaryTable> {
  $$DictionaryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pos => $composableBuilder(
    column: $table.pos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hanja => $composableBuilder(
    column: $table.hanja,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pronunciation => $composableBuilder(
    column: $table.pronunciation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senses => $composableBuilder(
    column: $table.senses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get forms => $composableBuilder(
    column: $table.forms,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DictionaryTableOrderingComposer
    extends Composer<_$AppDatabase, $DictionaryTable> {
  $$DictionaryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pos => $composableBuilder(
    column: $table.pos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hanja => $composableBuilder(
    column: $table.hanja,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pronunciation => $composableBuilder(
    column: $table.pronunciation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senses => $composableBuilder(
    column: $table.senses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get forms => $composableBuilder(
    column: $table.forms,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DictionaryTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictionaryTable> {
  $$DictionaryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get pos =>
      $composableBuilder(column: $table.pos, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get hanja =>
      $composableBuilder(column: $table.hanja, builder: (column) => column);

  GeneratedColumn<String> get pronunciation => $composableBuilder(
    column: $table.pronunciation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get senses =>
      $composableBuilder(column: $table.senses, builder: (column) => column);

  GeneratedColumn<String> get example =>
      $composableBuilder(column: $table.example, builder: (column) => column);

  GeneratedColumn<String> get forms =>
      $composableBuilder(column: $table.forms, builder: (column) => column);
}

class $$DictionaryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictionaryTable,
          DictEntry,
          $$DictionaryTableFilterComposer,
          $$DictionaryTableOrderingComposer,
          $$DictionaryTableAnnotationComposer,
          $$DictionaryTableCreateCompanionBuilder,
          $$DictionaryTableUpdateCompanionBuilder,
          (
            DictEntry,
            BaseReferences<_$AppDatabase, $DictionaryTable, DictEntry>,
          ),
          DictEntry,
          PrefetchHooks Function()
        > {
  $$DictionaryTableTableManager(_$AppDatabase db, $DictionaryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictionaryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DictionaryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DictionaryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String> pos = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<String?> hanja = const Value.absent(),
                Value<String?> pronunciation = const Value.absent(),
                Value<String> senses = const Value.absent(),
                Value<String?> example = const Value.absent(),
                Value<String?> forms = const Value.absent(),
              }) => DictionaryCompanion(
                id: id,
                word: word,
                pos: pos,
                level: level,
                hanja: hanja,
                pronunciation: pronunciation,
                senses: senses,
                example: example,
                forms: forms,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String word,
                required String pos,
                required String level,
                Value<String?> hanja = const Value.absent(),
                Value<String?> pronunciation = const Value.absent(),
                required String senses,
                Value<String?> example = const Value.absent(),
                Value<String?> forms = const Value.absent(),
              }) => DictionaryCompanion.insert(
                id: id,
                word: word,
                pos: pos,
                level: level,
                hanja: hanja,
                pronunciation: pronunciation,
                senses: senses,
                example: example,
                forms: forms,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DictionaryTable, DictEntry>(table),
                  BaseReferences<_$AppDatabase, $DictionaryTable, DictEntry>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DictionaryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictionaryTable,
      DictEntry,
      $$DictionaryTableFilterComposer,
      $$DictionaryTableOrderingComposer,
      $$DictionaryTableAnnotationComposer,
      $$DictionaryTableCreateCompanionBuilder,
      $$DictionaryTableUpdateCompanionBuilder,
      (DictEntry, BaseReferences<_$AppDatabase, $DictionaryTable, DictEntry>),
      DictEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db, _db.words);
  $$CardsTableTableManager get cards =>
      $$CardsTableTableManager(_db, _db.cards);
  $$ReviewLogsTableTableManager get reviewLogs =>
      $$ReviewLogsTableTableManager(_db, _db.reviewLogs);
  $$ActivitiesTableTableManager get activities =>
      $$ActivitiesTableTableManager(_db, _db.activities);
  $$LessonProgressTableTableManager get lessonProgress =>
      $$LessonProgressTableTableManager(_db, _db.lessonProgress);
  $$AchievementsTableTableManager get achievements =>
      $$AchievementsTableTableManager(_db, _db.achievements);
  $$QuestClaimsTableTableManager get questClaims =>
      $$QuestClaimsTableTableManager(_db, _db.questClaims);
  $$SkillsTableTableManager get skills =>
      $$SkillsTableTableManager(_db, _db.skills);
  $$MistakesTableTableManager get mistakes =>
      $$MistakesTableTableManager(_db, _db.mistakes);
  $$DictionaryTableTableManager get dictionary =>
      $$DictionaryTableTableManager(_db, _db.dictionary);
}
