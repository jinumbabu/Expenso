// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _googleIdMeta =
      const VerificationMeta('googleId');
  @override
  late final GeneratedColumn<String> googleId = GeneratedColumn<String>(
      'google_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('INR'));
  static const VerificationMeta _countryMeta =
      const VerificationMeta('country');
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
      'country', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        googleId,
        email,
        displayName,
        currency,
        country,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('google_id')) {
      context.handle(_googleIdMeta,
          googleId.isAcceptableOrUnknown(data['google_id']!, _googleIdMeta));
    } else if (isInserting) {
      context.missing(_googleIdMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('country')) {
      context.handle(_countryMeta,
          country.isAcceptableOrUnknown(data['country']!, _countryMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      googleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}google_id'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      country: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}country']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String googleId;
  final String email;
  final String displayName;
  final String currency;
  final String? country;
  final DateTime createdAt;
  final DateTime updatedAt;
  const User(
      {required this.id,
      required this.googleId,
      required this.email,
      required this.displayName,
      required this.currency,
      this.country,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['google_id'] = Variable<String>(googleId);
    map['email'] = Variable<String>(email);
    map['display_name'] = Variable<String>(displayName);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || country != null) {
      map['country'] = Variable<String>(country);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      googleId: Value(googleId),
      email: Value(email),
      displayName: Value(displayName),
      currency: Value(currency),
      country: country == null && nullToAbsent
          ? const Value.absent()
          : Value(country),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      googleId: serializer.fromJson<String>(json['googleId']),
      email: serializer.fromJson<String>(json['email']),
      displayName: serializer.fromJson<String>(json['displayName']),
      currency: serializer.fromJson<String>(json['currency']),
      country: serializer.fromJson<String?>(json['country']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'googleId': serializer.toJson<String>(googleId),
      'email': serializer.toJson<String>(email),
      'displayName': serializer.toJson<String>(displayName),
      'currency': serializer.toJson<String>(currency),
      'country': serializer.toJson<String?>(country),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  User copyWith(
          {String? id,
          String? googleId,
          String? email,
          String? displayName,
          String? currency,
          Value<String?> country = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      User(
        id: id ?? this.id,
        googleId: googleId ?? this.googleId,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        currency: currency ?? this.currency,
        country: country.present ? country.value : this.country,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      googleId: data.googleId.present ? data.googleId.value : this.googleId,
      email: data.email.present ? data.email.value : this.email,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      currency: data.currency.present ? data.currency.value : this.currency,
      country: data.country.present ? data.country.value : this.country,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('googleId: $googleId, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('currency: $currency, ')
          ..write('country: $country, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, googleId, email, displayName, currency,
      country, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.googleId == this.googleId &&
          other.email == this.email &&
          other.displayName == this.displayName &&
          other.currency == this.currency &&
          other.country == this.country &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> googleId;
  final Value<String> email;
  final Value<String> displayName;
  final Value<String> currency;
  final Value<String?> country;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.googleId = const Value.absent(),
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.currency = const Value.absent(),
    this.country = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String googleId,
    required String email,
    required String displayName,
    this.currency = const Value.absent(),
    this.country = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        googleId = Value(googleId),
        email = Value(email),
        displayName = Value(displayName),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? googleId,
    Expression<String>? email,
    Expression<String>? displayName,
    Expression<String>? currency,
    Expression<String>? country,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (googleId != null) 'google_id': googleId,
      if (email != null) 'email': email,
      if (displayName != null) 'display_name': displayName,
      if (currency != null) 'currency': currency,
      if (country != null) 'country': country,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith(
      {Value<String>? id,
      Value<String>? googleId,
      Value<String>? email,
      Value<String>? displayName,
      Value<String>? currency,
      Value<String?>? country,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return UsersCompanion(
      id: id ?? this.id,
      googleId: googleId ?? this.googleId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      currency: currency ?? this.currency,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (googleId.present) {
      map['google_id'] = Variable<String>(googleId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('googleId: $googleId, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('currency: $currency, ')
          ..write('country: $country, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _balanceMeta =
      const VerificationMeta('balance');
  @override
  late final GeneratedColumn<int> balance = GeneratedColumn<int>(
      'balance', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isDefaultMeta =
      const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
      'is_default', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_default" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, name, type, balance, isDefault, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<Account> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(_balanceMeta,
          balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta));
    }
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      balance: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}balance'])!,
      isDefault: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_default'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final String id;
  final String userId;
  final String name;
  final String type;
  final int balance;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Account(
      {required this.id,
      required this.userId,
      required this.name,
      required this.type,
      required this.balance,
      required this.isDefault,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['balance'] = Variable<int>(balance);
    map['is_default'] = Variable<bool>(isDefault);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      type: Value(type),
      balance: Value(balance),
      isDefault: Value(isDefault),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Account.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      balance: serializer.fromJson<int>(json['balance']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'balance': serializer.toJson<int>(balance),
      'isDefault': serializer.toJson<bool>(isDefault),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Account copyWith(
          {String? id,
          String? userId,
          String? name,
          String? type,
          int? balance,
          bool? isDefault,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Account(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        type: type ?? this.type,
        balance: balance ?? this.balance,
        isDefault: isDefault ?? this.isDefault,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      balance: data.balance.present ? data.balance.value : this.balance,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('balance: $balance, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, userId, name, type, balance, isDefault, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.type == this.type &&
          other.balance == this.balance &&
          other.isDefault == this.isDefault &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String> type;
  final Value<int> balance;
  final Value<bool> isDefault;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.balance = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String userId,
    required String name,
    required String type,
    this.balance = const Value.absent(),
    this.isDefault = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        name = Value(name),
        type = Value(type),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Account> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? balance,
    Expression<bool>? isDefault,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (balance != null) 'balance': balance,
      if (isDefault != null) 'is_default': isDefault,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? name,
      Value<String>? type,
      Value<int>? balance,
      Value<bool>? isDefault,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AccountsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (balance.present) {
      map['balance'] = Variable<int>(balance.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('balance: $balance, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _usageCountMeta =
      const VerificationMeta('usageCount');
  @override
  late final GeneratedColumn<int> usageCount = GeneratedColumn<int>(
      'usage_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastUsedAtMeta =
      const VerificationMeta('lastUsedAt');
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
      'last_used_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isSystemDefaultMeta =
      const VerificationMeta('isSystemDefault');
  @override
  late final GeneratedColumn<bool> isSystemDefault = GeneratedColumn<bool>(
      'is_system_default', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_system_default" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        name,
        type,
        icon,
        usageCount,
        lastUsedAt,
        isSystemDefault,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('usage_count')) {
      context.handle(
          _usageCountMeta,
          usageCount.isAcceptableOrUnknown(
              data['usage_count']!, _usageCountMeta));
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
          _lastUsedAtMeta,
          lastUsedAt.isAcceptableOrUnknown(
              data['last_used_at']!, _lastUsedAtMeta));
    }
    if (data.containsKey('is_system_default')) {
      context.handle(
          _isSystemDefaultMeta,
          isSystemDefault.isAcceptableOrUnknown(
              data['is_system_default']!, _isSystemDefaultMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon']),
      usageCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}usage_count'])!,
      lastUsedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_used_at']),
      isSystemDefault: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_system_default'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final String userId;
  final String name;
  final String type;
  final String? icon;
  final int usageCount;
  final DateTime? lastUsedAt;
  final bool isSystemDefault;
  final DateTime createdAt;
  const Category(
      {required this.id,
      required this.userId,
      required this.name,
      required this.type,
      this.icon,
      required this.usageCount,
      this.lastUsedAt,
      required this.isSystemDefault,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['usage_count'] = Variable<int>(usageCount);
    if (!nullToAbsent || lastUsedAt != null) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    }
    map['is_system_default'] = Variable<bool>(isSystemDefault);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      type: Value(type),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      usageCount: Value(usageCount),
      lastUsedAt: lastUsedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedAt),
      isSystemDefault: Value(isSystemDefault),
      createdAt: Value(createdAt),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      icon: serializer.fromJson<String?>(json['icon']),
      usageCount: serializer.fromJson<int>(json['usageCount']),
      lastUsedAt: serializer.fromJson<DateTime?>(json['lastUsedAt']),
      isSystemDefault: serializer.fromJson<bool>(json['isSystemDefault']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'icon': serializer.toJson<String?>(icon),
      'usageCount': serializer.toJson<int>(usageCount),
      'lastUsedAt': serializer.toJson<DateTime?>(lastUsedAt),
      'isSystemDefault': serializer.toJson<bool>(isSystemDefault),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Category copyWith(
          {String? id,
          String? userId,
          String? name,
          String? type,
          Value<String?> icon = const Value.absent(),
          int? usageCount,
          Value<DateTime?> lastUsedAt = const Value.absent(),
          bool? isSystemDefault,
          DateTime? createdAt}) =>
      Category(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        type: type ?? this.type,
        icon: icon.present ? icon.value : this.icon,
        usageCount: usageCount ?? this.usageCount,
        lastUsedAt: lastUsedAt.present ? lastUsedAt.value : this.lastUsedAt,
        isSystemDefault: isSystemDefault ?? this.isSystemDefault,
        createdAt: createdAt ?? this.createdAt,
      );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      icon: data.icon.present ? data.icon.value : this.icon,
      usageCount:
          data.usageCount.present ? data.usageCount.value : this.usageCount,
      lastUsedAt:
          data.lastUsedAt.present ? data.lastUsedAt.value : this.lastUsedAt,
      isSystemDefault: data.isSystemDefault.present
          ? data.isSystemDefault.value
          : this.isSystemDefault,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('icon: $icon, ')
          ..write('usageCount: $usageCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('isSystemDefault: $isSystemDefault, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, name, type, icon, usageCount,
      lastUsedAt, isSystemDefault, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.type == this.type &&
          other.icon == this.icon &&
          other.usageCount == this.usageCount &&
          other.lastUsedAt == this.lastUsedAt &&
          other.isSystemDefault == this.isSystemDefault &&
          other.createdAt == this.createdAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> icon;
  final Value<int> usageCount;
  final Value<DateTime?> lastUsedAt;
  final Value<bool> isSystemDefault;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.icon = const Value.absent(),
    this.usageCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.isSystemDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String userId,
    required String name,
    required String type,
    this.icon = const Value.absent(),
    this.usageCount = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.isSystemDefault = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        name = Value(name),
        type = Value(type),
        createdAt = Value(createdAt);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? icon,
    Expression<int>? usageCount,
    Expression<DateTime>? lastUsedAt,
    Expression<bool>? isSystemDefault,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (icon != null) 'icon': icon,
      if (usageCount != null) 'usage_count': usageCount,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (isSystemDefault != null) 'is_system_default': isSystemDefault,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? name,
      Value<String>? type,
      Value<String?>? icon,
      Value<int>? usageCount,
      Value<DateTime?>? lastUsedAt,
      Value<bool>? isSystemDefault,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      usageCount: usageCount ?? this.usageCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isSystemDefault: isSystemDefault ?? this.isSystemDefault,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (usageCount.present) {
      map['usage_count'] = Variable<int>(usageCount.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (isSystemDefault.present) {
      map['is_system_default'] = Variable<bool>(isSystemDefault.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('icon: $icon, ')
          ..write('usageCount: $usageCount, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('isSystemDefault: $isSystemDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentMethodsTable extends PaymentMethods
    with TableInfo<$PaymentMethodsTable, PaymentMethod> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentMethodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _usageCountMeta =
      const VerificationMeta('usageCount');
  @override
  late final GeneratedColumn<int> usageCount = GeneratedColumn<int>(
      'usage_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, accountId, name, type, usageCount, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payment_methods';
  @override
  VerificationContext validateIntegrity(Insertable<PaymentMethod> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('usage_count')) {
      context.handle(
          _usageCountMeta,
          usageCount.isAcceptableOrUnknown(
              data['usage_count']!, _usageCountMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentMethod map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentMethod(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      usageCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}usage_count'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PaymentMethodsTable createAlias(String alias) {
    return $PaymentMethodsTable(attachedDatabase, alias);
  }
}

class PaymentMethod extends DataClass implements Insertable<PaymentMethod> {
  final String id;
  final String userId;
  final String? accountId;
  final String name;
  final String type;
  final int usageCount;
  final DateTime createdAt;
  const PaymentMethod(
      {required this.id,
      required this.userId,
      this.accountId,
      required this.name,
      required this.type,
      required this.usageCount,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['usage_count'] = Variable<int>(usageCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PaymentMethodsCompanion toCompanion(bool nullToAbsent) {
    return PaymentMethodsCompanion(
      id: Value(id),
      userId: Value(userId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      name: Value(name),
      type: Value(type),
      usageCount: Value(usageCount),
      createdAt: Value(createdAt),
    );
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentMethod(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      usageCount: serializer.fromJson<int>(json['usageCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'accountId': serializer.toJson<String?>(accountId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'usageCount': serializer.toJson<int>(usageCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PaymentMethod copyWith(
          {String? id,
          String? userId,
          Value<String?> accountId = const Value.absent(),
          String? name,
          String? type,
          int? usageCount,
          DateTime? createdAt}) =>
      PaymentMethod(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        accountId: accountId.present ? accountId.value : this.accountId,
        name: name ?? this.name,
        type: type ?? this.type,
        usageCount: usageCount ?? this.usageCount,
        createdAt: createdAt ?? this.createdAt,
      );
  PaymentMethod copyWithCompanion(PaymentMethodsCompanion data) {
    return PaymentMethod(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      usageCount:
          data.usageCount.present ? data.usageCount.value : this.usageCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentMethod(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('usageCount: $usageCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, accountId, name, type, usageCount, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentMethod &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.accountId == this.accountId &&
          other.name == this.name &&
          other.type == this.type &&
          other.usageCount == this.usageCount &&
          other.createdAt == this.createdAt);
}

class PaymentMethodsCompanion extends UpdateCompanion<PaymentMethod> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> accountId;
  final Value<String> name;
  final Value<String> type;
  final Value<int> usageCount;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PaymentMethodsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.usageCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentMethodsCompanion.insert({
    required String id,
    required String userId,
    this.accountId = const Value.absent(),
    required String name,
    required String type,
    this.usageCount = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        name = Value(name),
        type = Value(type),
        createdAt = Value(createdAt);
  static Insertable<PaymentMethod> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? accountId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? usageCount,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (accountId != null) 'account_id': accountId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (usageCount != null) 'usage_count': usageCount,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentMethodsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? accountId,
      Value<String>? name,
      Value<String>? type,
      Value<int>? usageCount,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return PaymentMethodsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      type: type ?? this.type,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (usageCount.present) {
      map['usage_count'] = Variable<int>(usageCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentMethodsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('usageCount: $usageCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _paymentMethodIdMeta =
      const VerificationMeta('paymentMethodId');
  @override
  late final GeneratedColumn<String> paymentMethodId = GeneratedColumn<String>(
      'payment_method_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES payment_methods (id)'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _merchantMeta =
      const VerificationMeta('merchant');
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
      'merchant', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _confidenceScoreMeta =
      const VerificationMeta('confidenceScore');
  @override
  late final GeneratedColumn<double> confidenceScore = GeneratedColumn<double>(
      'confidence_score', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _isRecurringMeta =
      const VerificationMeta('isRecurring');
  @override
  late final GeneratedColumn<bool> isRecurring = GeneratedColumn<bool>(
      'is_recurring', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_recurring" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        accountId,
        categoryId,
        paymentMethodId,
        type,
        amount,
        currency,
        description,
        merchant,
        date,
        source,
        confidenceScore,
        isRecurring,
        syncStatus,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<Transaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('payment_method_id')) {
      context.handle(
          _paymentMethodIdMeta,
          paymentMethodId.isAcceptableOrUnknown(
              data['payment_method_id']!, _paymentMethodIdMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('merchant')) {
      context.handle(_merchantMeta,
          merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('confidence_score')) {
      context.handle(
          _confidenceScoreMeta,
          confidenceScore.isAcceptableOrUnknown(
              data['confidence_score']!, _confidenceScoreMeta));
    }
    if (data.containsKey('is_recurring')) {
      context.handle(
          _isRecurringMeta,
          isRecurring.isAcceptableOrUnknown(
              data['is_recurring']!, _isRecurringMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      paymentMethodId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}payment_method_id']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      merchant: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}merchant']),
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      confidenceScore: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}confidence_score']),
      isRecurring: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_recurring'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String id;
  final String userId;
  final String? accountId;
  final String? categoryId;
  final String? paymentMethodId;
  final String type;
  final int amount;
  final String currency;
  final String? description;
  final String? merchant;
  final DateTime date;
  final String source;
  final double? confidenceScore;
  final bool isRecurring;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Transaction(
      {required this.id,
      required this.userId,
      this.accountId,
      this.categoryId,
      this.paymentMethodId,
      required this.type,
      required this.amount,
      required this.currency,
      this.description,
      this.merchant,
      required this.date,
      required this.source,
      this.confidenceScore,
      required this.isRecurring,
      required this.syncStatus,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || paymentMethodId != null) {
      map['payment_method_id'] = Variable<String>(paymentMethodId);
    }
    map['type'] = Variable<String>(type);
    map['amount'] = Variable<int>(amount);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || merchant != null) {
      map['merchant'] = Variable<String>(merchant);
    }
    map['date'] = Variable<DateTime>(date);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || confidenceScore != null) {
      map['confidence_score'] = Variable<double>(confidenceScore);
    }
    map['is_recurring'] = Variable<bool>(isRecurring);
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      userId: Value(userId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      paymentMethodId: paymentMethodId == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethodId),
      type: Value(type),
      amount: Value(amount),
      currency: Value(currency),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      merchant: merchant == null && nullToAbsent
          ? const Value.absent()
          : Value(merchant),
      date: Value(date),
      source: Value(source),
      confidenceScore: confidenceScore == null && nullToAbsent
          ? const Value.absent()
          : Value(confidenceScore),
      isRecurring: Value(isRecurring),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      paymentMethodId: serializer.fromJson<String?>(json['paymentMethodId']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<int>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      description: serializer.fromJson<String?>(json['description']),
      merchant: serializer.fromJson<String?>(json['merchant']),
      date: serializer.fromJson<DateTime>(json['date']),
      source: serializer.fromJson<String>(json['source']),
      confidenceScore: serializer.fromJson<double?>(json['confidenceScore']),
      isRecurring: serializer.fromJson<bool>(json['isRecurring']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'accountId': serializer.toJson<String?>(accountId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'paymentMethodId': serializer.toJson<String?>(paymentMethodId),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<int>(amount),
      'currency': serializer.toJson<String>(currency),
      'description': serializer.toJson<String?>(description),
      'merchant': serializer.toJson<String?>(merchant),
      'date': serializer.toJson<DateTime>(date),
      'source': serializer.toJson<String>(source),
      'confidenceScore': serializer.toJson<double?>(confidenceScore),
      'isRecurring': serializer.toJson<bool>(isRecurring),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Transaction copyWith(
          {String? id,
          String? userId,
          Value<String?> accountId = const Value.absent(),
          Value<String?> categoryId = const Value.absent(),
          Value<String?> paymentMethodId = const Value.absent(),
          String? type,
          int? amount,
          String? currency,
          Value<String?> description = const Value.absent(),
          Value<String?> merchant = const Value.absent(),
          DateTime? date,
          String? source,
          Value<double?> confidenceScore = const Value.absent(),
          bool? isRecurring,
          String? syncStatus,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      Transaction(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        accountId: accountId.present ? accountId.value : this.accountId,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        paymentMethodId: paymentMethodId.present
            ? paymentMethodId.value
            : this.paymentMethodId,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        description: description.present ? description.value : this.description,
        merchant: merchant.present ? merchant.value : this.merchant,
        date: date ?? this.date,
        source: source ?? this.source,
        confidenceScore: confidenceScore.present
            ? confidenceScore.value
            : this.confidenceScore,
        isRecurring: isRecurring ?? this.isRecurring,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      paymentMethodId: data.paymentMethodId.present
          ? data.paymentMethodId.value
          : this.paymentMethodId,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      description:
          data.description.present ? data.description.value : this.description,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      date: data.date.present ? data.date.value : this.date,
      source: data.source.present ? data.source.value : this.source,
      confidenceScore: data.confidenceScore.present
          ? data.confidenceScore.value
          : this.confidenceScore,
      isRecurring:
          data.isRecurring.present ? data.isRecurring.value : this.isRecurring,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('paymentMethodId: $paymentMethodId, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('description: $description, ')
          ..write('merchant: $merchant, ')
          ..write('date: $date, ')
          ..write('source: $source, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      accountId,
      categoryId,
      paymentMethodId,
      type,
      amount,
      currency,
      description,
      merchant,
      date,
      source,
      confidenceScore,
      isRecurring,
      syncStatus,
      createdAt,
      updatedAt,
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.accountId == this.accountId &&
          other.categoryId == this.categoryId &&
          other.paymentMethodId == this.paymentMethodId &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.description == this.description &&
          other.merchant == this.merchant &&
          other.date == this.date &&
          other.source == this.source &&
          other.confidenceScore == this.confidenceScore &&
          other.isRecurring == this.isRecurring &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> accountId;
  final Value<String?> categoryId;
  final Value<String?> paymentMethodId;
  final Value<String> type;
  final Value<int> amount;
  final Value<String> currency;
  final Value<String?> description;
  final Value<String?> merchant;
  final Value<DateTime> date;
  final Value<String> source;
  final Value<double?> confidenceScore;
  final Value<bool> isRecurring;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.paymentMethodId = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.description = const Value.absent(),
    this.merchant = const Value.absent(),
    this.date = const Value.absent(),
    this.source = const Value.absent(),
    this.confidenceScore = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String userId,
    this.accountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.paymentMethodId = const Value.absent(),
    required String type,
    required int amount,
    required String currency,
    this.description = const Value.absent(),
    this.merchant = const Value.absent(),
    required DateTime date,
    required String source,
    this.confidenceScore = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        type = Value(type),
        amount = Value(amount),
        currency = Value(currency),
        date = Value(date),
        source = Value(source),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Transaction> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? accountId,
    Expression<String>? categoryId,
    Expression<String>? paymentMethodId,
    Expression<String>? type,
    Expression<int>? amount,
    Expression<String>? currency,
    Expression<String>? description,
    Expression<String>? merchant,
    Expression<DateTime>? date,
    Expression<String>? source,
    Expression<double>? confidenceScore,
    Expression<bool>? isRecurring,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (accountId != null) 'account_id': accountId,
      if (categoryId != null) 'category_id': categoryId,
      if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (description != null) 'description': description,
      if (merchant != null) 'merchant': merchant,
      if (date != null) 'date': date,
      if (source != null) 'source': source,
      if (confidenceScore != null) 'confidence_score': confidenceScore,
      if (isRecurring != null) 'is_recurring': isRecurring,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? accountId,
      Value<String?>? categoryId,
      Value<String?>? paymentMethodId,
      Value<String>? type,
      Value<int>? amount,
      Value<String>? currency,
      Value<String?>? description,
      Value<String?>? merchant,
      Value<DateTime>? date,
      Value<String>? source,
      Value<double?>? confidenceScore,
      Value<bool>? isRecurring,
      Value<String>? syncStatus,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return TransactionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      source: source ?? this.source,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      isRecurring: isRecurring ?? this.isRecurring,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (paymentMethodId.present) {
      map['payment_method_id'] = Variable<String>(paymentMethodId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (confidenceScore.present) {
      map['confidence_score'] = Variable<double>(confidenceScore.value);
    }
    if (isRecurring.present) {
      map['is_recurring'] = Variable<bool>(isRecurring.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('paymentMethodId: $paymentMethodId, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('description: $description, ')
          ..write('merchant: $merchant, ')
          ..write('date: $date, ')
          ..write('source: $source, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<String> period = GeneratedColumn<String>(
      'period', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        categoryId,
        period,
        amount,
        startDate,
        endDate,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(Insertable<Budget> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('period')) {
      context.handle(_periodMeta,
          period.isAcceptableOrUnknown(data['period']!, _periodMeta));
    } else if (isInserting) {
      context.missing(_periodMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      period: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}period'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class Budget extends DataClass implements Insertable<Budget> {
  final String id;
  final String userId;
  final String? categoryId;
  final String period;
  final int amount;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Budget(
      {required this.id,
      required this.userId,
      this.categoryId,
      required this.period,
      required this.amount,
      required this.startDate,
      this.endDate,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['period'] = Variable<String>(period);
    map['amount'] = Variable<int>(amount);
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      userId: Value(userId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      period: Value(period),
      amount: Value(amount),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Budget.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      period: serializer.fromJson<String>(json['period']),
      amount: serializer.fromJson<int>(json['amount']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'period': serializer.toJson<String>(period),
      'amount': serializer.toJson<int>(amount),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Budget copyWith(
          {String? id,
          String? userId,
          Value<String?> categoryId = const Value.absent(),
          String? period,
          int? amount,
          DateTime? startDate,
          Value<DateTime?> endDate = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Budget(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        period: period ?? this.period,
        amount: amount ?? this.amount,
        startDate: startDate ?? this.startDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      period: data.period.present ? data.period.value : this.period,
      amount: data.amount.present ? data.amount.value : this.amount,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('categoryId: $categoryId, ')
          ..write('period: $period, ')
          ..write('amount: $amount, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, categoryId, period, amount,
      startDate, endDate, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.categoryId == this.categoryId &&
          other.period == this.period &&
          other.amount == this.amount &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> categoryId;
  final Value<String> period;
  final Value<int> amount;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.period = const Value.absent(),
    this.amount = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    required String id,
    required String userId,
    this.categoryId = const Value.absent(),
    required String period,
    required int amount,
    required DateTime startDate,
    this.endDate = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        period = Value(period),
        amount = Value(amount),
        startDate = Value(startDate),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Budget> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? categoryId,
    Expression<String>? period,
    Expression<int>? amount,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (categoryId != null) 'category_id': categoryId,
      if (period != null) 'period': period,
      if (amount != null) 'amount': amount,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? categoryId,
      Value<String>? period,
      Value<int>? amount,
      Value<DateTime>? startDate,
      Value<DateTime?>? endDate,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return BudgetsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      period: period ?? this.period,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (period.present) {
      map['period'] = Variable<String>(period.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('categoryId: $categoryId, ')
          ..write('period: $period, ')
          ..write('amount: $amount, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatHistoryTable extends ChatHistory
    with TableInfo<$ChatHistoryTable, ChatHistoryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _messageMeta =
      const VerificationMeta('message');
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
      'message', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _aiModeMeta = const VerificationMeta('aiMode');
  @override
  late final GeneratedColumn<String> aiMode = GeneratedColumn<String>(
      'ai_mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tokenCountMeta =
      const VerificationMeta('tokenCount');
  @override
  late final GeneratedColumn<int> tokenCount = GeneratedColumn<int>(
      'token_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, role, message, aiMode, tokenCount, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_history';
  @override
  VerificationContext validateIntegrity(Insertable<ChatHistoryItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('message')) {
      context.handle(_messageMeta,
          message.isAcceptableOrUnknown(data['message']!, _messageMeta));
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('ai_mode')) {
      context.handle(_aiModeMeta,
          aiMode.isAcceptableOrUnknown(data['ai_mode']!, _aiModeMeta));
    } else if (isInserting) {
      context.missing(_aiModeMeta);
    }
    if (data.containsKey('token_count')) {
      context.handle(
          _tokenCountMeta,
          tokenCount.isAcceptableOrUnknown(
              data['token_count']!, _tokenCountMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatHistoryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatHistoryItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      message: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message'])!,
      aiMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ai_mode'])!,
      tokenCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}token_count']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ChatHistoryTable createAlias(String alias) {
    return $ChatHistoryTable(attachedDatabase, alias);
  }
}

class ChatHistoryItem extends DataClass implements Insertable<ChatHistoryItem> {
  final String id;
  final String userId;
  final String role;
  final String message;
  final String aiMode;
  final int? tokenCount;
  final DateTime createdAt;
  const ChatHistoryItem(
      {required this.id,
      required this.userId,
      required this.role,
      required this.message,
      required this.aiMode,
      this.tokenCount,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['role'] = Variable<String>(role);
    map['message'] = Variable<String>(message);
    map['ai_mode'] = Variable<String>(aiMode);
    if (!nullToAbsent || tokenCount != null) {
      map['token_count'] = Variable<int>(tokenCount);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ChatHistoryCompanion toCompanion(bool nullToAbsent) {
    return ChatHistoryCompanion(
      id: Value(id),
      userId: Value(userId),
      role: Value(role),
      message: Value(message),
      aiMode: Value(aiMode),
      tokenCount: tokenCount == null && nullToAbsent
          ? const Value.absent()
          : Value(tokenCount),
      createdAt: Value(createdAt),
    );
  }

  factory ChatHistoryItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatHistoryItem(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      role: serializer.fromJson<String>(json['role']),
      message: serializer.fromJson<String>(json['message']),
      aiMode: serializer.fromJson<String>(json['aiMode']),
      tokenCount: serializer.fromJson<int?>(json['tokenCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'role': serializer.toJson<String>(role),
      'message': serializer.toJson<String>(message),
      'aiMode': serializer.toJson<String>(aiMode),
      'tokenCount': serializer.toJson<int?>(tokenCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ChatHistoryItem copyWith(
          {String? id,
          String? userId,
          String? role,
          String? message,
          String? aiMode,
          Value<int?> tokenCount = const Value.absent(),
          DateTime? createdAt}) =>
      ChatHistoryItem(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        role: role ?? this.role,
        message: message ?? this.message,
        aiMode: aiMode ?? this.aiMode,
        tokenCount: tokenCount.present ? tokenCount.value : this.tokenCount,
        createdAt: createdAt ?? this.createdAt,
      );
  ChatHistoryItem copyWithCompanion(ChatHistoryCompanion data) {
    return ChatHistoryItem(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      role: data.role.present ? data.role.value : this.role,
      message: data.message.present ? data.message.value : this.message,
      aiMode: data.aiMode.present ? data.aiMode.value : this.aiMode,
      tokenCount:
          data.tokenCount.present ? data.tokenCount.value : this.tokenCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatHistoryItem(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('message: $message, ')
          ..write('aiMode: $aiMode, ')
          ..write('tokenCount: $tokenCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, role, message, aiMode, tokenCount, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatHistoryItem &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.role == this.role &&
          other.message == this.message &&
          other.aiMode == this.aiMode &&
          other.tokenCount == this.tokenCount &&
          other.createdAt == this.createdAt);
}

class ChatHistoryCompanion extends UpdateCompanion<ChatHistoryItem> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> role;
  final Value<String> message;
  final Value<String> aiMode;
  final Value<int?> tokenCount;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ChatHistoryCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.message = const Value.absent(),
    this.aiMode = const Value.absent(),
    this.tokenCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatHistoryCompanion.insert({
    required String id,
    required String userId,
    required String role,
    required String message,
    required String aiMode,
    this.tokenCount = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        role = Value(role),
        message = Value(message),
        aiMode = Value(aiMode),
        createdAt = Value(createdAt);
  static Insertable<ChatHistoryItem> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? role,
    Expression<String>? message,
    Expression<String>? aiMode,
    Expression<int>? tokenCount,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (message != null) 'message': message,
      if (aiMode != null) 'ai_mode': aiMode,
      if (tokenCount != null) 'token_count': tokenCount,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatHistoryCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? role,
      Value<String>? message,
      Value<String>? aiMode,
      Value<int?>? tokenCount,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ChatHistoryCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      message: message ?? this.message,
      aiMode: aiMode ?? this.aiMode,
      tokenCount: tokenCount ?? this.tokenCount,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (aiMode.present) {
      map['ai_mode'] = Variable<String>(aiMode.value);
    }
    if (tokenCount.present) {
      map['token_count'] = Variable<int>(tokenCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatHistoryCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('message: $message, ')
          ..write('aiMode: $aiMode, ')
          ..write('tokenCount: $tokenCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiMemoriesTable extends AiMemories
    with TableInfo<$AiMemoriesTable, AiMemoryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiMemoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _memoryTypeMeta =
      const VerificationMeta('memoryType');
  @override
  late final GeneratedColumn<String> memoryType = GeneratedColumn<String>(
      'memory_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _memoryKeyMeta =
      const VerificationMeta('memoryKey');
  @override
  late final GeneratedColumn<String> memoryKey = GeneratedColumn<String>(
      'memory_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _memoryValueMeta =
      const VerificationMeta('memoryValue');
  @override
  late final GeneratedColumn<String> memoryValue = GeneratedColumn<String>(
      'memory_value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _confidenceMeta =
      const VerificationMeta('confidence');
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
      'confidence', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
      'expires_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastAccessedAtMeta =
      const VerificationMeta('lastAccessedAt');
  @override
  late final GeneratedColumn<DateTime> lastAccessedAt =
      GeneratedColumn<DateTime>('last_accessed_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        memoryType,
        memoryKey,
        memoryValue,
        confidence,
        expiresAt,
        createdAt,
        lastAccessedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_memories';
  @override
  VerificationContext validateIntegrity(Insertable<AiMemoryItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('memory_type')) {
      context.handle(
          _memoryTypeMeta,
          memoryType.isAcceptableOrUnknown(
              data['memory_type']!, _memoryTypeMeta));
    } else if (isInserting) {
      context.missing(_memoryTypeMeta);
    }
    if (data.containsKey('memory_key')) {
      context.handle(_memoryKeyMeta,
          memoryKey.isAcceptableOrUnknown(data['memory_key']!, _memoryKeyMeta));
    } else if (isInserting) {
      context.missing(_memoryKeyMeta);
    }
    if (data.containsKey('memory_value')) {
      context.handle(
          _memoryValueMeta,
          memoryValue.isAcceptableOrUnknown(
              data['memory_value']!, _memoryValueMeta));
    } else if (isInserting) {
      context.missing(_memoryValueMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
          _confidenceMeta,
          confidence.isAcceptableOrUnknown(
              data['confidence']!, _confidenceMeta));
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
          _lastAccessedAtMeta,
          lastAccessedAt.isAcceptableOrUnknown(
              data['last_accessed_at']!, _lastAccessedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiMemoryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiMemoryItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      memoryType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memory_type'])!,
      memoryKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memory_key'])!,
      memoryValue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memory_value'])!,
      confidence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}confidence']),
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expires_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastAccessedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_accessed_at']),
    );
  }

  @override
  $AiMemoriesTable createAlias(String alias) {
    return $AiMemoriesTable(attachedDatabase, alias);
  }
}

class AiMemoryItem extends DataClass implements Insertable<AiMemoryItem> {
  final String id;
  final String userId;
  final String memoryType;
  final String memoryKey;
  final String memoryValue;
  final double? confidence;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime? lastAccessedAt;
  const AiMemoryItem(
      {required this.id,
      required this.userId,
      required this.memoryType,
      required this.memoryKey,
      required this.memoryValue,
      this.confidence,
      this.expiresAt,
      required this.createdAt,
      this.lastAccessedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['memory_type'] = Variable<String>(memoryType);
    map['memory_key'] = Variable<String>(memoryKey);
    map['memory_value'] = Variable<String>(memoryValue);
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastAccessedAt != null) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt);
    }
    return map;
  }

  AiMemoriesCompanion toCompanion(bool nullToAbsent) {
    return AiMemoriesCompanion(
      id: Value(id),
      userId: Value(userId),
      memoryType: Value(memoryType),
      memoryKey: Value(memoryKey),
      memoryValue: Value(memoryValue),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      createdAt: Value(createdAt),
      lastAccessedAt: lastAccessedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAccessedAt),
    );
  }

  factory AiMemoryItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiMemoryItem(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      memoryType: serializer.fromJson<String>(json['memoryType']),
      memoryKey: serializer.fromJson<String>(json['memoryKey']),
      memoryValue: serializer.fromJson<String>(json['memoryValue']),
      confidence: serializer.fromJson<double?>(json['confidence']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAccessedAt: serializer.fromJson<DateTime?>(json['lastAccessedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'memoryType': serializer.toJson<String>(memoryType),
      'memoryKey': serializer.toJson<String>(memoryKey),
      'memoryValue': serializer.toJson<String>(memoryValue),
      'confidence': serializer.toJson<double?>(confidence),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAccessedAt': serializer.toJson<DateTime?>(lastAccessedAt),
    };
  }

  AiMemoryItem copyWith(
          {String? id,
          String? userId,
          String? memoryType,
          String? memoryKey,
          String? memoryValue,
          Value<double?> confidence = const Value.absent(),
          Value<DateTime?> expiresAt = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> lastAccessedAt = const Value.absent()}) =>
      AiMemoryItem(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        memoryType: memoryType ?? this.memoryType,
        memoryKey: memoryKey ?? this.memoryKey,
        memoryValue: memoryValue ?? this.memoryValue,
        confidence: confidence.present ? confidence.value : this.confidence,
        expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
        createdAt: createdAt ?? this.createdAt,
        lastAccessedAt:
            lastAccessedAt.present ? lastAccessedAt.value : this.lastAccessedAt,
      );
  AiMemoryItem copyWithCompanion(AiMemoriesCompanion data) {
    return AiMemoryItem(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      memoryType:
          data.memoryType.present ? data.memoryType.value : this.memoryType,
      memoryKey: data.memoryKey.present ? data.memoryKey.value : this.memoryKey,
      memoryValue:
          data.memoryValue.present ? data.memoryValue.value : this.memoryValue,
      confidence:
          data.confidence.present ? data.confidence.value : this.confidence,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiMemoryItem(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('memoryType: $memoryType, ')
          ..write('memoryKey: $memoryKey, ')
          ..write('memoryValue: $memoryValue, ')
          ..write('confidence: $confidence, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAccessedAt: $lastAccessedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, memoryType, memoryKey,
      memoryValue, confidence, expiresAt, createdAt, lastAccessedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiMemoryItem &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.memoryType == this.memoryType &&
          other.memoryKey == this.memoryKey &&
          other.memoryValue == this.memoryValue &&
          other.confidence == this.confidence &&
          other.expiresAt == this.expiresAt &&
          other.createdAt == this.createdAt &&
          other.lastAccessedAt == this.lastAccessedAt);
}

class AiMemoriesCompanion extends UpdateCompanion<AiMemoryItem> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> memoryType;
  final Value<String> memoryKey;
  final Value<String> memoryValue;
  final Value<double?> confidence;
  final Value<DateTime?> expiresAt;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastAccessedAt;
  final Value<int> rowid;
  const AiMemoriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.memoryType = const Value.absent(),
    this.memoryKey = const Value.absent(),
    this.memoryValue = const Value.absent(),
    this.confidence = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiMemoriesCompanion.insert({
    required String id,
    required String userId,
    required String memoryType,
    required String memoryKey,
    required String memoryValue,
    this.confidence = const Value.absent(),
    this.expiresAt = const Value.absent(),
    required DateTime createdAt,
    this.lastAccessedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        memoryType = Value(memoryType),
        memoryKey = Value(memoryKey),
        memoryValue = Value(memoryValue),
        createdAt = Value(createdAt);
  static Insertable<AiMemoryItem> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? memoryType,
    Expression<String>? memoryKey,
    Expression<String>? memoryValue,
    Expression<double>? confidence,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAccessedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (memoryType != null) 'memory_type': memoryType,
      if (memoryKey != null) 'memory_key': memoryKey,
      if (memoryValue != null) 'memory_value': memoryValue,
      if (confidence != null) 'confidence': confidence,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiMemoriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? memoryType,
      Value<String>? memoryKey,
      Value<String>? memoryValue,
      Value<double?>? confidence,
      Value<DateTime?>? expiresAt,
      Value<DateTime>? createdAt,
      Value<DateTime?>? lastAccessedAt,
      Value<int>? rowid}) {
    return AiMemoriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      memoryType: memoryType ?? this.memoryType,
      memoryKey: memoryKey ?? this.memoryKey,
      memoryValue: memoryValue ?? this.memoryValue,
      confidence: confidence ?? this.confidence,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (memoryType.present) {
      map['memory_type'] = Variable<String>(memoryType.value);
    }
    if (memoryKey.present) {
      map['memory_key'] = Variable<String>(memoryKey.value);
    }
    if (memoryValue.present) {
      map['memory_value'] = Variable<String>(memoryValue.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiMemoriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('memoryType: $memoryType, ')
          ..write('memoryKey: $memoryKey, ')
          ..write('memoryValue: $memoryValue, ')
          ..write('confidence: $confidence, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditLogsTable extends AuditLogs
    with TableInfo<$AuditLogsTable, AuditLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _eventTypeMeta =
      const VerificationMeta('eventType');
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
      'event_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventCategoryMeta =
      const VerificationMeta('eventCategory');
  @override
  late final GeneratedColumn<String> eventCategory = GeneratedColumn<String>(
      'event_category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, eventType, eventCategory, description, metadata, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_logs';
  @override
  VerificationContext validateIntegrity(Insertable<AuditLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('event_type')) {
      context.handle(_eventTypeMeta,
          eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta));
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('event_category')) {
      context.handle(
          _eventCategoryMeta,
          eventCategory.isAcceptableOrUnknown(
              data['event_category']!, _eventCategoryMeta));
    } else if (isInserting) {
      context.missing(_eventCategoryMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      eventType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_type'])!,
      eventCategory: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_category'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AuditLogsTable createAlias(String alias) {
    return $AuditLogsTable(attachedDatabase, alias);
  }
}

class AuditLog extends DataClass implements Insertable<AuditLog> {
  final String id;
  final String? userId;
  final String eventType;
  final String eventCategory;
  final String description;
  final String? metadata;
  final DateTime createdAt;
  const AuditLog(
      {required this.id,
      this.userId,
      required this.eventType,
      required this.eventCategory,
      required this.description,
      this.metadata,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['event_type'] = Variable<String>(eventType);
    map['event_category'] = Variable<String>(eventCategory);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AuditLogsCompanion toCompanion(bool nullToAbsent) {
    return AuditLogsCompanion(
      id: Value(id),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      eventType: Value(eventType),
      eventCategory: Value(eventCategory),
      description: Value(description),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      createdAt: Value(createdAt),
    );
  }

  factory AuditLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLog(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      eventCategory: serializer.fromJson<String>(json['eventCategory']),
      description: serializer.fromJson<String>(json['description']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String?>(userId),
      'eventType': serializer.toJson<String>(eventType),
      'eventCategory': serializer.toJson<String>(eventCategory),
      'description': serializer.toJson<String>(description),
      'metadata': serializer.toJson<String?>(metadata),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AuditLog copyWith(
          {String? id,
          Value<String?> userId = const Value.absent(),
          String? eventType,
          String? eventCategory,
          String? description,
          Value<String?> metadata = const Value.absent(),
          DateTime? createdAt}) =>
      AuditLog(
        id: id ?? this.id,
        userId: userId.present ? userId.value : this.userId,
        eventType: eventType ?? this.eventType,
        eventCategory: eventCategory ?? this.eventCategory,
        description: description ?? this.description,
        metadata: metadata.present ? metadata.value : this.metadata,
        createdAt: createdAt ?? this.createdAt,
      );
  AuditLog copyWithCompanion(AuditLogsCompanion data) {
    return AuditLog(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      eventCategory: data.eventCategory.present
          ? data.eventCategory.value
          : this.eventCategory,
      description:
          data.description.present ? data.description.value : this.description,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLog(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('eventType: $eventType, ')
          ..write('eventCategory: $eventCategory, ')
          ..write('description: $description, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, userId, eventType, eventCategory, description, metadata, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLog &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.eventType == this.eventType &&
          other.eventCategory == this.eventCategory &&
          other.description == this.description &&
          other.metadata == this.metadata &&
          other.createdAt == this.createdAt);
}

class AuditLogsCompanion extends UpdateCompanion<AuditLog> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String> eventType;
  final Value<String> eventCategory;
  final Value<String> description;
  final Value<String?> metadata;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AuditLogsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.eventCategory = const Value.absent(),
    this.description = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditLogsCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    required String eventType,
    required String eventCategory,
    required String description,
    this.metadata = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        eventType = Value(eventType),
        eventCategory = Value(eventCategory),
        description = Value(description),
        createdAt = Value(createdAt);
  static Insertable<AuditLog> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? eventType,
    Expression<String>? eventCategory,
    Expression<String>? description,
    Expression<String>? metadata,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (eventType != null) 'event_type': eventType,
      if (eventCategory != null) 'event_category': eventCategory,
      if (description != null) 'description': description,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditLogsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? userId,
      Value<String>? eventType,
      Value<String>? eventCategory,
      Value<String>? description,
      Value<String?>? metadata,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return AuditLogsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventType: eventType ?? this.eventType,
      eventCategory: eventCategory ?? this.eventCategory,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (eventCategory.present) {
      map['event_category'] = Variable<String>(eventCategory.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('eventType: $eventType, ')
          ..write('eventCategory: $eventCategory, ')
          ..write('description: $description, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionDraftsTable extends TransactionDrafts
    with TableInfo<$TransactionDraftsTable, TransactionDraft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('INR'));
  static const VerificationMeta _merchantMeta =
      const VerificationMeta('merchant');
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
      'merchant', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _smsSenderMeta =
      const VerificationMeta('smsSender');
  @override
  late final GeneratedColumn<String> smsSender = GeneratedColumn<String>(
      'sms_sender', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cardOrAccountMeta =
      const VerificationMeta('cardOrAccount');
  @override
  late final GeneratedColumn<String> cardOrAccount = GeneratedColumn<String>(
      'card_or_account', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _smsBodyMeta =
      const VerificationMeta('smsBody');
  @override
  late final GeneratedColumn<String> smsBody = GeneratedColumn<String>(
      'sms_body', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _originalSmsIdMeta =
      const VerificationMeta('originalSmsId');
  @override
  late final GeneratedColumn<String> originalSmsId = GeneratedColumn<String>(
      'original_sms_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        amount,
        type,
        currency,
        merchant,
        description,
        date,
        smsSender,
        cardOrAccount,
        smsBody,
        originalSmsId,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_drafts';
  @override
  VerificationContext validateIntegrity(Insertable<TransactionDraft> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('merchant')) {
      context.handle(_merchantMeta,
          merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('sms_sender')) {
      context.handle(_smsSenderMeta,
          smsSender.isAcceptableOrUnknown(data['sms_sender']!, _smsSenderMeta));
    }
    if (data.containsKey('card_or_account')) {
      context.handle(
          _cardOrAccountMeta,
          cardOrAccount.isAcceptableOrUnknown(
              data['card_or_account']!, _cardOrAccountMeta));
    }
    if (data.containsKey('sms_body')) {
      context.handle(_smsBodyMeta,
          smsBody.isAcceptableOrUnknown(data['sms_body']!, _smsBodyMeta));
    }
    if (data.containsKey('original_sms_id')) {
      context.handle(
          _originalSmsIdMeta,
          originalSmsId.isAcceptableOrUnknown(
              data['original_sms_id']!, _originalSmsIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionDraft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionDraft(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      merchant: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}merchant']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      smsSender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sms_sender']),
      cardOrAccount: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}card_or_account']),
      smsBody: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sms_body']),
      originalSmsId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}original_sms_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TransactionDraftsTable createAlias(String alias) {
    return $TransactionDraftsTable(attachedDatabase, alias);
  }
}

class TransactionDraft extends DataClass
    implements Insertable<TransactionDraft> {
  final String id;
  final String userId;
  final int amount;
  final String type;
  final String currency;
  final String? merchant;
  final String? description;
  final DateTime date;
  final String? smsSender;
  final String? cardOrAccount;
  final String? smsBody;
  final String? originalSmsId;
  final DateTime createdAt;
  const TransactionDraft(
      {required this.id,
      required this.userId,
      required this.amount,
      required this.type,
      required this.currency,
      this.merchant,
      this.description,
      required this.date,
      this.smsSender,
      this.cardOrAccount,
      this.smsBody,
      this.originalSmsId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['amount'] = Variable<int>(amount);
    map['type'] = Variable<String>(type);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || merchant != null) {
      map['merchant'] = Variable<String>(merchant);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || smsSender != null) {
      map['sms_sender'] = Variable<String>(smsSender);
    }
    if (!nullToAbsent || cardOrAccount != null) {
      map['card_or_account'] = Variable<String>(cardOrAccount);
    }
    if (!nullToAbsent || smsBody != null) {
      map['sms_body'] = Variable<String>(smsBody);
    }
    if (!nullToAbsent || originalSmsId != null) {
      map['original_sms_id'] = Variable<String>(originalSmsId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TransactionDraftsCompanion toCompanion(bool nullToAbsent) {
    return TransactionDraftsCompanion(
      id: Value(id),
      userId: Value(userId),
      amount: Value(amount),
      type: Value(type),
      currency: Value(currency),
      merchant: merchant == null && nullToAbsent
          ? const Value.absent()
          : Value(merchant),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      date: Value(date),
      smsSender: smsSender == null && nullToAbsent
          ? const Value.absent()
          : Value(smsSender),
      cardOrAccount: cardOrAccount == null && nullToAbsent
          ? const Value.absent()
          : Value(cardOrAccount),
      smsBody: smsBody == null && nullToAbsent
          ? const Value.absent()
          : Value(smsBody),
      originalSmsId: originalSmsId == null && nullToAbsent
          ? const Value.absent()
          : Value(originalSmsId),
      createdAt: Value(createdAt),
    );
  }

  factory TransactionDraft.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionDraft(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      amount: serializer.fromJson<int>(json['amount']),
      type: serializer.fromJson<String>(json['type']),
      currency: serializer.fromJson<String>(json['currency']),
      merchant: serializer.fromJson<String?>(json['merchant']),
      description: serializer.fromJson<String?>(json['description']),
      date: serializer.fromJson<DateTime>(json['date']),
      smsSender: serializer.fromJson<String?>(json['smsSender']),
      cardOrAccount: serializer.fromJson<String?>(json['cardOrAccount']),
      smsBody: serializer.fromJson<String?>(json['smsBody']),
      originalSmsId: serializer.fromJson<String?>(json['originalSmsId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'amount': serializer.toJson<int>(amount),
      'type': serializer.toJson<String>(type),
      'currency': serializer.toJson<String>(currency),
      'merchant': serializer.toJson<String?>(merchant),
      'description': serializer.toJson<String?>(description),
      'date': serializer.toJson<DateTime>(date),
      'smsSender': serializer.toJson<String?>(smsSender),
      'cardOrAccount': serializer.toJson<String?>(cardOrAccount),
      'smsBody': serializer.toJson<String?>(smsBody),
      'originalSmsId': serializer.toJson<String?>(originalSmsId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TransactionDraft copyWith(
          {String? id,
          String? userId,
          int? amount,
          String? type,
          String? currency,
          Value<String?> merchant = const Value.absent(),
          Value<String?> description = const Value.absent(),
          DateTime? date,
          Value<String?> smsSender = const Value.absent(),
          Value<String?> cardOrAccount = const Value.absent(),
          Value<String?> smsBody = const Value.absent(),
          Value<String?> originalSmsId = const Value.absent(),
          DateTime? createdAt}) =>
      TransactionDraft(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        currency: currency ?? this.currency,
        merchant: merchant.present ? merchant.value : this.merchant,
        description: description.present ? description.value : this.description,
        date: date ?? this.date,
        smsSender: smsSender.present ? smsSender.value : this.smsSender,
        cardOrAccount:
            cardOrAccount.present ? cardOrAccount.value : this.cardOrAccount,
        smsBody: smsBody.present ? smsBody.value : this.smsBody,
        originalSmsId:
            originalSmsId.present ? originalSmsId.value : this.originalSmsId,
        createdAt: createdAt ?? this.createdAt,
      );
  TransactionDraft copyWithCompanion(TransactionDraftsCompanion data) {
    return TransactionDraft(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      amount: data.amount.present ? data.amount.value : this.amount,
      type: data.type.present ? data.type.value : this.type,
      currency: data.currency.present ? data.currency.value : this.currency,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      description:
          data.description.present ? data.description.value : this.description,
      date: data.date.present ? data.date.value : this.date,
      smsSender: data.smsSender.present ? data.smsSender.value : this.smsSender,
      cardOrAccount: data.cardOrAccount.present
          ? data.cardOrAccount.value
          : this.cardOrAccount,
      smsBody: data.smsBody.present ? data.smsBody.value : this.smsBody,
      originalSmsId: data.originalSmsId.present
          ? data.originalSmsId.value
          : this.originalSmsId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionDraft(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('currency: $currency, ')
          ..write('merchant: $merchant, ')
          ..write('description: $description, ')
          ..write('date: $date, ')
          ..write('smsSender: $smsSender, ')
          ..write('cardOrAccount: $cardOrAccount, ')
          ..write('smsBody: $smsBody, ')
          ..write('originalSmsId: $originalSmsId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      amount,
      type,
      currency,
      merchant,
      description,
      date,
      smsSender,
      cardOrAccount,
      smsBody,
      originalSmsId,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionDraft &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.amount == this.amount &&
          other.type == this.type &&
          other.currency == this.currency &&
          other.merchant == this.merchant &&
          other.description == this.description &&
          other.date == this.date &&
          other.smsSender == this.smsSender &&
          other.cardOrAccount == this.cardOrAccount &&
          other.smsBody == this.smsBody &&
          other.originalSmsId == this.originalSmsId &&
          other.createdAt == this.createdAt);
}

class TransactionDraftsCompanion extends UpdateCompanion<TransactionDraft> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> amount;
  final Value<String> type;
  final Value<String> currency;
  final Value<String?> merchant;
  final Value<String?> description;
  final Value<DateTime> date;
  final Value<String?> smsSender;
  final Value<String?> cardOrAccount;
  final Value<String?> smsBody;
  final Value<String?> originalSmsId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TransactionDraftsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.amount = const Value.absent(),
    this.type = const Value.absent(),
    this.currency = const Value.absent(),
    this.merchant = const Value.absent(),
    this.description = const Value.absent(),
    this.date = const Value.absent(),
    this.smsSender = const Value.absent(),
    this.cardOrAccount = const Value.absent(),
    this.smsBody = const Value.absent(),
    this.originalSmsId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionDraftsCompanion.insert({
    required String id,
    required String userId,
    required int amount,
    required String type,
    this.currency = const Value.absent(),
    this.merchant = const Value.absent(),
    this.description = const Value.absent(),
    required DateTime date,
    this.smsSender = const Value.absent(),
    this.cardOrAccount = const Value.absent(),
    this.smsBody = const Value.absent(),
    this.originalSmsId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        amount = Value(amount),
        type = Value(type),
        date = Value(date),
        createdAt = Value(createdAt);
  static Insertable<TransactionDraft> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? amount,
    Expression<String>? type,
    Expression<String>? currency,
    Expression<String>? merchant,
    Expression<String>? description,
    Expression<DateTime>? date,
    Expression<String>? smsSender,
    Expression<String>? cardOrAccount,
    Expression<String>? smsBody,
    Expression<String>? originalSmsId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (amount != null) 'amount': amount,
      if (type != null) 'type': type,
      if (currency != null) 'currency': currency,
      if (merchant != null) 'merchant': merchant,
      if (description != null) 'description': description,
      if (date != null) 'date': date,
      if (smsSender != null) 'sms_sender': smsSender,
      if (cardOrAccount != null) 'card_or_account': cardOrAccount,
      if (smsBody != null) 'sms_body': smsBody,
      if (originalSmsId != null) 'original_sms_id': originalSmsId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionDraftsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<int>? amount,
      Value<String>? type,
      Value<String>? currency,
      Value<String?>? merchant,
      Value<String?>? description,
      Value<DateTime>? date,
      Value<String?>? smsSender,
      Value<String?>? cardOrAccount,
      Value<String?>? smsBody,
      Value<String?>? originalSmsId,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return TransactionDraftsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      merchant: merchant ?? this.merchant,
      description: description ?? this.description,
      date: date ?? this.date,
      smsSender: smsSender ?? this.smsSender,
      cardOrAccount: cardOrAccount ?? this.cardOrAccount,
      smsBody: smsBody ?? this.smsBody,
      originalSmsId: originalSmsId ?? this.originalSmsId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (smsSender.present) {
      map['sms_sender'] = Variable<String>(smsSender.value);
    }
    if (cardOrAccount.present) {
      map['card_or_account'] = Variable<String>(cardOrAccount.value);
    }
    if (smsBody.present) {
      map['sms_body'] = Variable<String>(smsBody.value);
    }
    if (originalSmsId.present) {
      map['original_sms_id'] = Variable<String>(originalSmsId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionDraftsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('currency: $currency, ')
          ..write('merchant: $merchant, ')
          ..write('description: $description, ')
          ..write('date: $date, ')
          ..write('smsSender: $smsSender, ')
          ..write('cardOrAccount: $cardOrAccount, ')
          ..write('smsBody: $smsBody, ')
          ..write('originalSmsId: $originalSmsId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $PaymentMethodsTable paymentMethods = $PaymentMethodsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $ChatHistoryTable chatHistory = $ChatHistoryTable(this);
  late final $AiMemoriesTable aiMemories = $AiMemoriesTable(this);
  late final $AuditLogsTable auditLogs = $AuditLogsTable(this);
  late final $TransactionDraftsTable transactionDrafts =
      $TransactionDraftsTable(this);
  late final Index idxCategoriesUsage = Index('idx_categories_usage',
      'CREATE INDEX idx_categories_usage ON categories (user_id, usage_count)');
  late final Index idxTransactionsUserDate = Index('idx_transactions_user_date',
      'CREATE INDEX idx_transactions_user_date ON transactions (user_id, date)');
  late final Index idxTransactionsCategory = Index('idx_transactions_category',
      'CREATE INDEX idx_transactions_category ON transactions (user_id, category_id)');
  late final Index idxTransactionsSync = Index('idx_transactions_sync',
      'CREATE INDEX idx_transactions_sync ON transactions (sync_status)');
  late final UserDao userDao = UserDao(this as AppDatabase);
  late final AccountDao accountDao = AccountDao(this as AppDatabase);
  late final CategoryDao categoryDao = CategoryDao(this as AppDatabase);
  late final PaymentMethodDao paymentMethodDao =
      PaymentMethodDao(this as AppDatabase);
  late final TransactionDao transactionDao =
      TransactionDao(this as AppDatabase);
  late final BudgetDao budgetDao = BudgetDao(this as AppDatabase);
  late final ChatHistoryDao chatHistoryDao =
      ChatHistoryDao(this as AppDatabase);
  late final AiMemoryDao aiMemoryDao = AiMemoryDao(this as AppDatabase);
  late final AuditLogDao auditLogDao = AuditLogDao(this as AppDatabase);
  late final TransactionDraftDao transactionDraftDao =
      TransactionDraftDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        users,
        accounts,
        categories,
        paymentMethods,
        transactions,
        budgets,
        chatHistory,
        aiMemories,
        auditLogs,
        transactionDrafts,
        idxCategoriesUsage,
        idxTransactionsUserDate,
        idxTransactionsCategory,
        idxTransactionsSync
      ];
}

typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  required String id,
  required String googleId,
  required String email,
  required String displayName,
  Value<String> currency,
  Value<String?> country,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<String> id,
  Value<String> googleId,
  Value<String> email,
  Value<String> displayName,
  Value<String> currency,
  Value<String?> country,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$UsersTableReferences
    extends BaseReferences<_$AppDatabase, $UsersTable, User> {
  $$UsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AccountsTable, List<Account>> _accountsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.accounts,
          aliasName: $_aliasNameGenerator(db.users.id, db.accounts.userId));

  $$AccountsTableProcessedTableManager get accountsRefs {
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.userId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_accountsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$CategoriesTable, List<Category>>
      _categoriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.categories,
          aliasName: $_aliasNameGenerator(db.users.id, db.categories.userId));

  $$CategoriesTableProcessedTableManager get categoriesRefs {
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.userId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_categoriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PaymentMethodsTable, List<PaymentMethod>>
      _paymentMethodsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.paymentMethods,
              aliasName:
                  $_aliasNameGenerator(db.users.id, db.paymentMethods.userId));

  $$PaymentMethodsTableProcessedTableManager get paymentMethodsRefs {
    final manager = $$PaymentMethodsTableTableManager($_db, $_db.paymentMethods)
        .filter((f) => f.userId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_paymentMethodsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
      _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.transactions,
          aliasName: $_aliasNameGenerator(db.users.id, db.transactions.userId));

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.userId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BudgetsTable, List<Budget>> _budgetsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.budgets,
          aliasName: $_aliasNameGenerator(db.users.id, db.budgets.userId));

  $$BudgetsTableProcessedTableManager get budgetsRefs {
    final manager = $$BudgetsTableTableManager($_db, $_db.budgets)
        .filter((f) => f.userId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_budgetsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ChatHistoryTable, List<ChatHistoryItem>>
      _chatHistoryRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.chatHistory,
          aliasName: $_aliasNameGenerator(db.users.id, db.chatHistory.userId));

  $$ChatHistoryTableProcessedTableManager get chatHistoryRefs {
    final manager = $$ChatHistoryTableTableManager($_db, $_db.chatHistory)
        .filter((f) => f.userId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_chatHistoryRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AiMemoriesTable, List<AiMemoryItem>>
      _aiMemoriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.aiMemories,
          aliasName: $_aliasNameGenerator(db.users.id, db.aiMemories.userId));

  $$AiMemoriesTableProcessedTableManager get aiMemoriesRefs {
    final manager = $$AiMemoriesTableTableManager($_db, $_db.aiMemories)
        .filter((f) => f.userId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_aiMemoriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AuditLogsTable, List<AuditLog>>
      _auditLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.auditLogs,
          aliasName: $_aliasNameGenerator(db.users.id, db.auditLogs.userId));

  $$AuditLogsTableProcessedTableManager get auditLogsRefs {
    final manager = $$AuditLogsTableTableManager($_db, $_db.auditLogs)
        .filter((f) => f.userId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_auditLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionDraftsTable, List<TransactionDraft>>
      _transactionDraftsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactionDrafts,
              aliasName: $_aliasNameGenerator(
                  db.users.id, db.transactionDrafts.userId));

  $$TransactionDraftsTableProcessedTableManager get transactionDraftsRefs {
    final manager =
        $$TransactionDraftsTableTableManager($_db, $_db.transactionDrafts)
            .filter((f) => f.userId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_transactionDraftsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get googleId => $composableBuilder(
      column: $table.googleId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get country => $composableBuilder(
      column: $table.country, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> accountsRefs(
      Expression<bool> Function($$AccountsTableFilterComposer f) f) {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> categoriesRefs(
      Expression<bool> Function($$CategoriesTableFilterComposer f) f) {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> paymentMethodsRefs(
      Expression<bool> Function($$PaymentMethodsTableFilterComposer f) f) {
    final $$PaymentMethodsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.paymentMethods,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PaymentMethodsTableFilterComposer(
              $db: $db,
              $table: $db.paymentMethods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> budgetsRefs(
      Expression<bool> Function($$BudgetsTableFilterComposer f) f) {
    final $$BudgetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.budgets,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BudgetsTableFilterComposer(
              $db: $db,
              $table: $db.budgets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> chatHistoryRefs(
      Expression<bool> Function($$ChatHistoryTableFilterComposer f) f) {
    final $$ChatHistoryTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chatHistory,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatHistoryTableFilterComposer(
              $db: $db,
              $table: $db.chatHistory,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> aiMemoriesRefs(
      Expression<bool> Function($$AiMemoriesTableFilterComposer f) f) {
    final $$AiMemoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.aiMemories,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AiMemoriesTableFilterComposer(
              $db: $db,
              $table: $db.aiMemories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> auditLogsRefs(
      Expression<bool> Function($$AuditLogsTableFilterComposer f) f) {
    final $$AuditLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.auditLogs,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AuditLogsTableFilterComposer(
              $db: $db,
              $table: $db.auditLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> transactionDraftsRefs(
      Expression<bool> Function($$TransactionDraftsTableFilterComposer f) f) {
    final $$TransactionDraftsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactionDrafts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionDraftsTableFilterComposer(
              $db: $db,
              $table: $db.transactionDrafts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get googleId => $composableBuilder(
      column: $table.googleId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get country => $composableBuilder(
      column: $table.country, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get googleId =>
      $composableBuilder(column: $table.googleId, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> accountsRefs<T extends Object>(
      Expression<T> Function($$AccountsTableAnnotationComposer a) f) {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> categoriesRefs<T extends Object>(
      Expression<T> Function($$CategoriesTableAnnotationComposer a) f) {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> paymentMethodsRefs<T extends Object>(
      Expression<T> Function($$PaymentMethodsTableAnnotationComposer a) f) {
    final $$PaymentMethodsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.paymentMethods,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PaymentMethodsTableAnnotationComposer(
              $db: $db,
              $table: $db.paymentMethods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> budgetsRefs<T extends Object>(
      Expression<T> Function($$BudgetsTableAnnotationComposer a) f) {
    final $$BudgetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.budgets,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BudgetsTableAnnotationComposer(
              $db: $db,
              $table: $db.budgets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> chatHistoryRefs<T extends Object>(
      Expression<T> Function($$ChatHistoryTableAnnotationComposer a) f) {
    final $$ChatHistoryTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chatHistory,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatHistoryTableAnnotationComposer(
              $db: $db,
              $table: $db.chatHistory,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> aiMemoriesRefs<T extends Object>(
      Expression<T> Function($$AiMemoriesTableAnnotationComposer a) f) {
    final $$AiMemoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.aiMemories,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AiMemoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.aiMemories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> auditLogsRefs<T extends Object>(
      Expression<T> Function($$AuditLogsTableAnnotationComposer a) f) {
    final $$AuditLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.auditLogs,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AuditLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.auditLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> transactionDraftsRefs<T extends Object>(
      Expression<T> Function($$TransactionDraftsTableAnnotationComposer a) f) {
    final $$TransactionDraftsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.transactionDrafts,
            getReferencedColumn: (t) => t.userId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$TransactionDraftsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.transactionDrafts,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$UsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, $$UsersTableReferences),
    User,
    PrefetchHooks Function(
        {bool accountsRefs,
        bool categoriesRefs,
        bool paymentMethodsRefs,
        bool transactionsRefs,
        bool budgetsRefs,
        bool chatHistoryRefs,
        bool aiMemoriesRefs,
        bool auditLogsRefs,
        bool transactionDraftsRefs})> {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> googleId = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String?> country = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            googleId: googleId,
            email: email,
            displayName: displayName,
            currency: currency,
            country: country,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String googleId,
            required String email,
            required String displayName,
            Value<String> currency = const Value.absent(),
            Value<String?> country = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            googleId: googleId,
            email: email,
            displayName: displayName,
            currency: currency,
            country: country,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$UsersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {accountsRefs = false,
              categoriesRefs = false,
              paymentMethodsRefs = false,
              transactionsRefs = false,
              budgetsRefs = false,
              chatHistoryRefs = false,
              aiMemoriesRefs = false,
              auditLogsRefs = false,
              transactionDraftsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (accountsRefs) db.accounts,
                if (categoriesRefs) db.categories,
                if (paymentMethodsRefs) db.paymentMethods,
                if (transactionsRefs) db.transactions,
                if (budgetsRefs) db.budgets,
                if (chatHistoryRefs) db.chatHistory,
                if (aiMemoriesRefs) db.aiMemories,
                if (auditLogsRefs) db.auditLogs,
                if (transactionDraftsRefs) db.transactionDrafts
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (accountsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._accountsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0).accountsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (categoriesRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._categoriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .categoriesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (paymentMethodsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._paymentMethodsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .paymentMethodsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (transactionsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (budgetsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._budgetsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0).budgetsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (chatHistoryRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._chatHistoryRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .chatHistoryRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (aiMemoriesRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._aiMemoriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .aiMemoriesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (auditLogsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._auditLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0).auditLogsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (transactionDraftsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$UsersTableReferences
                            ._transactionDraftsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .transactionDraftsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, $$UsersTableReferences),
    User,
    PrefetchHooks Function(
        {bool accountsRefs,
        bool categoriesRefs,
        bool paymentMethodsRefs,
        bool transactionsRefs,
        bool budgetsRefs,
        bool chatHistoryRefs,
        bool aiMemoriesRefs,
        bool auditLogsRefs,
        bool transactionDraftsRefs})>;
typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  required String id,
  required String userId,
  required String name,
  required String type,
  Value<int> balance,
  Value<bool> isDefault,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> name,
  Value<String> type,
  Value<int> balance,
  Value<bool> isDefault,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.accounts.userId, db.users.id));

  $$UsersTableProcessedTableManager? get userId {
    if ($_item.userId == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id($_item.userId!));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$PaymentMethodsTable, List<PaymentMethod>>
      _paymentMethodsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.paymentMethods,
              aliasName: $_aliasNameGenerator(
                  db.accounts.id, db.paymentMethods.accountId));

  $$PaymentMethodsTableProcessedTableManager get paymentMethodsRefs {
    final manager = $$PaymentMethodsTableTableManager($_db, $_db.paymentMethods)
        .filter((f) => f.accountId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_paymentMethodsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
      _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.transactions,
          aliasName:
              $_aliasNameGenerator(db.accounts.id, db.transactions.accountId));

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.accountId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get balance => $composableBuilder(
      column: $table.balance, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> paymentMethodsRefs(
      Expression<bool> Function($$PaymentMethodsTableFilterComposer f) f) {
    final $$PaymentMethodsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.paymentMethods,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PaymentMethodsTableFilterComposer(
              $db: $db,
              $table: $db.paymentMethods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get balance => $composableBuilder(
      column: $table.balance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> paymentMethodsRefs<T extends Object>(
      Expression<T> Function($$PaymentMethodsTableAnnotationComposer a) f) {
    final $$PaymentMethodsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.paymentMethods,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PaymentMethodsTableAnnotationComposer(
              $db: $db,
              $table: $db.paymentMethods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AccountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AccountsTable,
    Account,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (Account, $$AccountsTableReferences),
    Account,
    PrefetchHooks Function(
        {bool userId, bool paymentMethodsRefs, bool transactionsRefs})> {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> balance = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsCompanion(
            id: id,
            userId: userId,
            name: name,
            type: type,
            balance: balance,
            isDefault: isDefault,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String name,
            required String type,
            Value<int> balance = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsCompanion.insert(
            id: id,
            userId: userId,
            name: name,
            type: type,
            balance: balance,
            isDefault: isDefault,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$AccountsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {userId = false,
              paymentMethodsRefs = false,
              transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (paymentMethodsRefs) db.paymentMethods,
                if (transactionsRefs) db.transactions
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable: $$AccountsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$AccountsTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (paymentMethodsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$AccountsTableReferences
                            ._paymentMethodsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .paymentMethodsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.accountId == item.id),
                        typedResults: items),
                  if (transactionsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$AccountsTableReferences
                            ._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.accountId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AccountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AccountsTable,
    Account,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (Account, $$AccountsTableReferences),
    Account,
    PrefetchHooks Function(
        {bool userId, bool paymentMethodsRefs, bool transactionsRefs})>;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String userId,
  required String name,
  required String type,
  Value<String?> icon,
  Value<int> usageCount,
  Value<DateTime?> lastUsedAt,
  Value<bool> isSystemDefault,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> name,
  Value<String> type,
  Value<String?> icon,
  Value<int> usageCount,
  Value<DateTime?> lastUsedAt,
  Value<bool> isSystemDefault,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.categories.userId, db.users.id));

  $$UsersTableProcessedTableManager? get userId {
    if ($_item.userId == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id($_item.userId!));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
      _transactionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactions,
              aliasName: $_aliasNameGenerator(
                  db.categories.id, db.transactions.categoryId));

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.categoryId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BudgetsTable, List<Budget>> _budgetsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.budgets,
          aliasName:
              $_aliasNameGenerator(db.categories.id, db.budgets.categoryId));

  $$BudgetsTableProcessedTableManager get budgetsRefs {
    final manager = $$BudgetsTableTableManager($_db, $_db.budgets)
        .filter((f) => f.categoryId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_budgetsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get usageCount => $composableBuilder(
      column: $table.usageCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSystemDefault => $composableBuilder(
      column: $table.isSystemDefault,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> budgetsRefs(
      Expression<bool> Function($$BudgetsTableFilterComposer f) f) {
    final $$BudgetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.budgets,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BudgetsTableFilterComposer(
              $db: $db,
              $table: $db.budgets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get usageCount => $composableBuilder(
      column: $table.usageCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSystemDefault => $composableBuilder(
      column: $table.isSystemDefault,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get usageCount => $composableBuilder(
      column: $table.usageCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSystemDefault => $composableBuilder(
      column: $table.isSystemDefault, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> budgetsRefs<T extends Object>(
      Expression<T> Function($$BudgetsTableAnnotationComposer a) f) {
    final $$BudgetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.budgets,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BudgetsTableAnnotationComposer(
              $db: $db,
              $table: $db.budgets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, $$CategoriesTableReferences),
    Category,
    PrefetchHooks Function(
        {bool userId, bool transactionsRefs, bool budgetsRefs})> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<int> usageCount = const Value.absent(),
            Value<DateTime?> lastUsedAt = const Value.absent(),
            Value<bool> isSystemDefault = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            userId: userId,
            name: name,
            type: type,
            icon: icon,
            usageCount: usageCount,
            lastUsedAt: lastUsedAt,
            isSystemDefault: isSystemDefault,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String name,
            required String type,
            Value<String?> icon = const Value.absent(),
            Value<int> usageCount = const Value.absent(),
            Value<DateTime?> lastUsedAt = const Value.absent(),
            Value<bool> isSystemDefault = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            userId: userId,
            name: name,
            type: type,
            icon: icon,
            usageCount: usageCount,
            lastUsedAt: lastUsedAt,
            isSystemDefault: isSystemDefault,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CategoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {userId = false, transactionsRefs = false, budgetsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (transactionsRefs) db.transactions,
                if (budgetsRefs) db.budgets
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$CategoriesTableReferences._userIdTable(db),
                    referencedColumn:
                        $$CategoriesTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$CategoriesTableReferences
                            ._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items),
                  if (budgetsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$CategoriesTableReferences._budgetsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .budgetsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, $$CategoriesTableReferences),
    Category,
    PrefetchHooks Function(
        {bool userId, bool transactionsRefs, bool budgetsRefs})>;
typedef $$PaymentMethodsTableCreateCompanionBuilder = PaymentMethodsCompanion
    Function({
  required String id,
  required String userId,
  Value<String?> accountId,
  required String name,
  required String type,
  Value<int> usageCount,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$PaymentMethodsTableUpdateCompanionBuilder = PaymentMethodsCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> accountId,
  Value<String> name,
  Value<String> type,
  Value<int> usageCount,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$PaymentMethodsTableReferences
    extends BaseReferences<_$AppDatabase, $PaymentMethodsTable, PaymentMethod> {
  $$PaymentMethodsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.paymentMethods.userId, db.users.id));

  $$UsersTableProcessedTableManager? get userId {
    if ($_item.userId == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id($_item.userId!));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
          $_aliasNameGenerator(db.paymentMethods.accountId, db.accounts.id));

  $$AccountsTableProcessedTableManager? get accountId {
    if ($_item.accountId == null) return null;
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id($_item.accountId!));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
      _transactionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactions,
              aliasName: $_aliasNameGenerator(
                  db.paymentMethods.id, db.transactions.paymentMethodId));

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.paymentMethodId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PaymentMethodsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentMethodsTable> {
  $$PaymentMethodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get usageCount => $composableBuilder(
      column: $table.usageCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.paymentMethodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PaymentMethodsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentMethodsTable> {
  $$PaymentMethodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get usageCount => $composableBuilder(
      column: $table.usageCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PaymentMethodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentMethodsTable> {
  $$PaymentMethodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get usageCount => $composableBuilder(
      column: $table.usageCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.paymentMethodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PaymentMethodsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PaymentMethodsTable,
    PaymentMethod,
    $$PaymentMethodsTableFilterComposer,
    $$PaymentMethodsTableOrderingComposer,
    $$PaymentMethodsTableAnnotationComposer,
    $$PaymentMethodsTableCreateCompanionBuilder,
    $$PaymentMethodsTableUpdateCompanionBuilder,
    (PaymentMethod, $$PaymentMethodsTableReferences),
    PaymentMethod,
    PrefetchHooks Function(
        {bool userId, bool accountId, bool transactionsRefs})> {
  $$PaymentMethodsTableTableManager(
      _$AppDatabase db, $PaymentMethodsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentMethodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentMethodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentMethodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> accountId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> usageCount = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PaymentMethodsCompanion(
            id: id,
            userId: userId,
            accountId: accountId,
            name: name,
            type: type,
            usageCount: usageCount,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            Value<String?> accountId = const Value.absent(),
            required String name,
            required String type,
            Value<int> usageCount = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PaymentMethodsCompanion.insert(
            id: id,
            userId: userId,
            accountId: accountId,
            name: name,
            type: type,
            usageCount: usageCount,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PaymentMethodsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {userId = false, accountId = false, transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: <
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
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$PaymentMethodsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$PaymentMethodsTableReferences._userIdTable(db).id,
                  ) as T;
                }
                if (accountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.accountId,
                    referencedTable:
                        $$PaymentMethodsTableReferences._accountIdTable(db),
                    referencedColumn:
                        $$PaymentMethodsTableReferences._accountIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$PaymentMethodsTableReferences
                            ._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PaymentMethodsTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.paymentMethodId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PaymentMethodsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PaymentMethodsTable,
    PaymentMethod,
    $$PaymentMethodsTableFilterComposer,
    $$PaymentMethodsTableOrderingComposer,
    $$PaymentMethodsTableAnnotationComposer,
    $$PaymentMethodsTableCreateCompanionBuilder,
    $$PaymentMethodsTableUpdateCompanionBuilder,
    (PaymentMethod, $$PaymentMethodsTableReferences),
    PaymentMethod,
    PrefetchHooks Function(
        {bool userId, bool accountId, bool transactionsRefs})>;
typedef $$TransactionsTableCreateCompanionBuilder = TransactionsCompanion
    Function({
  required String id,
  required String userId,
  Value<String?> accountId,
  Value<String?> categoryId,
  Value<String?> paymentMethodId,
  required String type,
  required int amount,
  required String currency,
  Value<String?> description,
  Value<String?> merchant,
  required DateTime date,
  required String source,
  Value<double?> confidenceScore,
  Value<bool> isRecurring,
  Value<String> syncStatus,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> accountId,
  Value<String?> categoryId,
  Value<String?> paymentMethodId,
  Value<String> type,
  Value<int> amount,
  Value<String> currency,
  Value<String?> description,
  Value<String?> merchant,
  Value<DateTime> date,
  Value<String> source,
  Value<double?> confidenceScore,
  Value<bool> isRecurring,
  Value<String> syncStatus,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, Transaction> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.transactions.userId, db.users.id));

  $$UsersTableProcessedTableManager? get userId {
    if ($_item.userId == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id($_item.userId!));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
          $_aliasNameGenerator(db.transactions.accountId, db.accounts.id));

  $$AccountsTableProcessedTableManager? get accountId {
    if ($_item.accountId == null) return null;
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id($_item.accountId!));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
          $_aliasNameGenerator(db.transactions.categoryId, db.categories.id));

  $$CategoriesTableProcessedTableManager? get categoryId {
    if ($_item.categoryId == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id($_item.categoryId!));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $PaymentMethodsTable _paymentMethodIdTable(_$AppDatabase db) =>
      db.paymentMethods.createAlias($_aliasNameGenerator(
          db.transactions.paymentMethodId, db.paymentMethods.id));

  $$PaymentMethodsTableProcessedTableManager? get paymentMethodId {
    if ($_item.paymentMethodId == null) return null;
    final manager = $$PaymentMethodsTableTableManager($_db, $_db.paymentMethods)
        .filter((f) => f.id($_item.paymentMethodId!));
    final item = $_typedResult.readTableOrNull(_paymentMethodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get merchant => $composableBuilder(
      column: $table.merchant, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get confidenceScore => $composableBuilder(
      column: $table.confidenceScore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRecurring => $composableBuilder(
      column: $table.isRecurring, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PaymentMethodsTableFilterComposer get paymentMethodId {
    final $$PaymentMethodsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.paymentMethodId,
        referencedTable: $db.paymentMethods,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PaymentMethodsTableFilterComposer(
              $db: $db,
              $table: $db.paymentMethods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get merchant => $composableBuilder(
      column: $table.merchant, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get confidenceScore => $composableBuilder(
      column: $table.confidenceScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRecurring => $composableBuilder(
      column: $table.isRecurring, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PaymentMethodsTableOrderingComposer get paymentMethodId {
    final $$PaymentMethodsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.paymentMethodId,
        referencedTable: $db.paymentMethods,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PaymentMethodsTableOrderingComposer(
              $db: $db,
              $table: $db.paymentMethods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<double> get confidenceScore => $composableBuilder(
      column: $table.confidenceScore, builder: (column) => column);

  GeneratedColumn<bool> get isRecurring => $composableBuilder(
      column: $table.isRecurring, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PaymentMethodsTableAnnotationComposer get paymentMethodId {
    final $$PaymentMethodsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.paymentMethodId,
        referencedTable: $db.paymentMethods,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PaymentMethodsTableAnnotationComposer(
              $db: $db,
              $table: $db.paymentMethods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (Transaction, $$TransactionsTableReferences),
    Transaction,
    PrefetchHooks Function(
        {bool userId, bool accountId, bool categoryId, bool paymentMethodId})> {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> accountId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<String?> paymentMethodId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> merchant = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<double?> confidenceScore = const Value.absent(),
            Value<bool> isRecurring = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCompanion(
            id: id,
            userId: userId,
            accountId: accountId,
            categoryId: categoryId,
            paymentMethodId: paymentMethodId,
            type: type,
            amount: amount,
            currency: currency,
            description: description,
            merchant: merchant,
            date: date,
            source: source,
            confidenceScore: confidenceScore,
            isRecurring: isRecurring,
            syncStatus: syncStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            Value<String?> accountId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<String?> paymentMethodId = const Value.absent(),
            required String type,
            required int amount,
            required String currency,
            Value<String?> description = const Value.absent(),
            Value<String?> merchant = const Value.absent(),
            required DateTime date,
            required String source,
            Value<double?> confidenceScore = const Value.absent(),
            Value<bool> isRecurring = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCompanion.insert(
            id: id,
            userId: userId,
            accountId: accountId,
            categoryId: categoryId,
            paymentMethodId: paymentMethodId,
            type: type,
            amount: amount,
            currency: currency,
            description: description,
            merchant: merchant,
            date: date,
            source: source,
            confidenceScore: confidenceScore,
            isRecurring: isRecurring,
            syncStatus: syncStatus,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TransactionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {userId = false,
              accountId = false,
              categoryId = false,
              paymentMethodId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$TransactionsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._userIdTable(db).id,
                  ) as T;
                }
                if (accountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.accountId,
                    referencedTable:
                        $$TransactionsTableReferences._accountIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._accountIdTable(db).id,
                  ) as T;
                }
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$TransactionsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }
                if (paymentMethodId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.paymentMethodId,
                    referencedTable:
                        $$TransactionsTableReferences._paymentMethodIdTable(db),
                    referencedColumn: $$TransactionsTableReferences
                        ._paymentMethodIdTable(db)
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
        ));
}

typedef $$TransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (Transaction, $$TransactionsTableReferences),
    Transaction,
    PrefetchHooks Function(
        {bool userId, bool accountId, bool categoryId, bool paymentMethodId})>;
typedef $$BudgetsTableCreateCompanionBuilder = BudgetsCompanion Function({
  required String id,
  required String userId,
  Value<String?> categoryId,
  required String period,
  required int amount,
  required DateTime startDate,
  Value<DateTime?> endDate,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$BudgetsTableUpdateCompanionBuilder = BudgetsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> categoryId,
  Value<String> period,
  Value<int> amount,
  Value<DateTime> startDate,
  Value<DateTime?> endDate,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$BudgetsTableReferences
    extends BaseReferences<_$AppDatabase, $BudgetsTable, Budget> {
  $$BudgetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.budgets.userId, db.users.id));

  $$UsersTableProcessedTableManager? get userId {
    if ($_item.userId == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id($_item.userId!));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
          $_aliasNameGenerator(db.budgets.categoryId, db.categories.id));

  $$CategoriesTableProcessedTableManager? get categoryId {
    if ($_item.categoryId == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id($_item.categoryId!));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get period => $composableBuilder(
      column: $table.period, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get period => $composableBuilder(
      column: $table.period, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BudgetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BudgetsTable,
    Budget,
    $$BudgetsTableFilterComposer,
    $$BudgetsTableOrderingComposer,
    $$BudgetsTableAnnotationComposer,
    $$BudgetsTableCreateCompanionBuilder,
    $$BudgetsTableUpdateCompanionBuilder,
    (Budget, $$BudgetsTableReferences),
    Budget,
    PrefetchHooks Function({bool userId, bool categoryId})> {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<String> period = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetsCompanion(
            id: id,
            userId: userId,
            categoryId: categoryId,
            period: period,
            amount: amount,
            startDate: startDate,
            endDate: endDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            Value<String?> categoryId = const Value.absent(),
            required String period,
            required int amount,
            required DateTime startDate,
            Value<DateTime?> endDate = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetsCompanion.insert(
            id: id,
            userId: userId,
            categoryId: categoryId,
            period: period,
            amount: amount,
            startDate: startDate,
            endDate: endDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$BudgetsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({userId = false, categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable: $$BudgetsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$BudgetsTableReferences._userIdTable(db).id,
                  ) as T;
                }
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$BudgetsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$BudgetsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$BudgetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BudgetsTable,
    Budget,
    $$BudgetsTableFilterComposer,
    $$BudgetsTableOrderingComposer,
    $$BudgetsTableAnnotationComposer,
    $$BudgetsTableCreateCompanionBuilder,
    $$BudgetsTableUpdateCompanionBuilder,
    (Budget, $$BudgetsTableReferences),
    Budget,
    PrefetchHooks Function({bool userId, bool categoryId})>;
typedef $$ChatHistoryTableCreateCompanionBuilder = ChatHistoryCompanion
    Function({
  required String id,
  required String userId,
  required String role,
  required String message,
  required String aiMode,
  Value<int?> tokenCount,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$ChatHistoryTableUpdateCompanionBuilder = ChatHistoryCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> role,
  Value<String> message,
  Value<String> aiMode,
  Value<int?> tokenCount,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$ChatHistoryTableReferences
    extends BaseReferences<_$AppDatabase, $ChatHistoryTable, ChatHistoryItem> {
  $$ChatHistoryTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.chatHistory.userId, db.users.id));

  $$UsersTableProcessedTableManager? get userId {
    if ($_item.userId == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id($_item.userId!));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ChatHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $ChatHistoryTable> {
  $$ChatHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get aiMode => $composableBuilder(
      column: $table.aiMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tokenCount => $composableBuilder(
      column: $table.tokenCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChatHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatHistoryTable> {
  $$ChatHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get aiMode => $composableBuilder(
      column: $table.aiMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tokenCount => $composableBuilder(
      column: $table.tokenCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChatHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatHistoryTable> {
  $$ChatHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get aiMode =>
      $composableBuilder(column: $table.aiMode, builder: (column) => column);

  GeneratedColumn<int> get tokenCount => $composableBuilder(
      column: $table.tokenCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChatHistoryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChatHistoryTable,
    ChatHistoryItem,
    $$ChatHistoryTableFilterComposer,
    $$ChatHistoryTableOrderingComposer,
    $$ChatHistoryTableAnnotationComposer,
    $$ChatHistoryTableCreateCompanionBuilder,
    $$ChatHistoryTableUpdateCompanionBuilder,
    (ChatHistoryItem, $$ChatHistoryTableReferences),
    ChatHistoryItem,
    PrefetchHooks Function({bool userId})> {
  $$ChatHistoryTableTableManager(_$AppDatabase db, $ChatHistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> message = const Value.absent(),
            Value<String> aiMode = const Value.absent(),
            Value<int?> tokenCount = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatHistoryCompanion(
            id: id,
            userId: userId,
            role: role,
            message: message,
            aiMode: aiMode,
            tokenCount: tokenCount,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String role,
            required String message,
            required String aiMode,
            Value<int?> tokenCount = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatHistoryCompanion.insert(
            id: id,
            userId: userId,
            role: role,
            message: message,
            aiMode: aiMode,
            tokenCount: tokenCount,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ChatHistoryTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$ChatHistoryTableReferences._userIdTable(db),
                    referencedColumn:
                        $$ChatHistoryTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ChatHistoryTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChatHistoryTable,
    ChatHistoryItem,
    $$ChatHistoryTableFilterComposer,
    $$ChatHistoryTableOrderingComposer,
    $$ChatHistoryTableAnnotationComposer,
    $$ChatHistoryTableCreateCompanionBuilder,
    $$ChatHistoryTableUpdateCompanionBuilder,
    (ChatHistoryItem, $$ChatHistoryTableReferences),
    ChatHistoryItem,
    PrefetchHooks Function({bool userId})>;
typedef $$AiMemoriesTableCreateCompanionBuilder = AiMemoriesCompanion Function({
  required String id,
  required String userId,
  required String memoryType,
  required String memoryKey,
  required String memoryValue,
  Value<double?> confidence,
  Value<DateTime?> expiresAt,
  required DateTime createdAt,
  Value<DateTime?> lastAccessedAt,
  Value<int> rowid,
});
typedef $$AiMemoriesTableUpdateCompanionBuilder = AiMemoriesCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> memoryType,
  Value<String> memoryKey,
  Value<String> memoryValue,
  Value<double?> confidence,
  Value<DateTime?> expiresAt,
  Value<DateTime> createdAt,
  Value<DateTime?> lastAccessedAt,
  Value<int> rowid,
});

final class $$AiMemoriesTableReferences
    extends BaseReferences<_$AppDatabase, $AiMemoriesTable, AiMemoryItem> {
  $$AiMemoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.aiMemories.userId, db.users.id));

  $$UsersTableProcessedTableManager? get userId {
    if ($_item.userId == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id($_item.userId!));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AiMemoriesTableFilterComposer
    extends Composer<_$AppDatabase, $AiMemoriesTable> {
  $$AiMemoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memoryType => $composableBuilder(
      column: $table.memoryType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memoryKey => $composableBuilder(
      column: $table.memoryKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memoryValue => $composableBuilder(
      column: $table.memoryValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAccessedAt => $composableBuilder(
      column: $table.lastAccessedAt,
      builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AiMemoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $AiMemoriesTable> {
  $$AiMemoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memoryType => $composableBuilder(
      column: $table.memoryType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memoryKey => $composableBuilder(
      column: $table.memoryKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memoryValue => $composableBuilder(
      column: $table.memoryValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAccessedAt => $composableBuilder(
      column: $table.lastAccessedAt,
      builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AiMemoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiMemoriesTable> {
  $$AiMemoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get memoryType => $composableBuilder(
      column: $table.memoryType, builder: (column) => column);

  GeneratedColumn<String> get memoryKey =>
      $composableBuilder(column: $table.memoryKey, builder: (column) => column);

  GeneratedColumn<String> get memoryValue => $composableBuilder(
      column: $table.memoryValue, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAccessedAt => $composableBuilder(
      column: $table.lastAccessedAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AiMemoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AiMemoriesTable,
    AiMemoryItem,
    $$AiMemoriesTableFilterComposer,
    $$AiMemoriesTableOrderingComposer,
    $$AiMemoriesTableAnnotationComposer,
    $$AiMemoriesTableCreateCompanionBuilder,
    $$AiMemoriesTableUpdateCompanionBuilder,
    (AiMemoryItem, $$AiMemoriesTableReferences),
    AiMemoryItem,
    PrefetchHooks Function({bool userId})> {
  $$AiMemoriesTableTableManager(_$AppDatabase db, $AiMemoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiMemoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiMemoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiMemoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> memoryType = const Value.absent(),
            Value<String> memoryKey = const Value.absent(),
            Value<String> memoryValue = const Value.absent(),
            Value<double?> confidence = const Value.absent(),
            Value<DateTime?> expiresAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> lastAccessedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AiMemoriesCompanion(
            id: id,
            userId: userId,
            memoryType: memoryType,
            memoryKey: memoryKey,
            memoryValue: memoryValue,
            confidence: confidence,
            expiresAt: expiresAt,
            createdAt: createdAt,
            lastAccessedAt: lastAccessedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String memoryType,
            required String memoryKey,
            required String memoryValue,
            Value<double?> confidence = const Value.absent(),
            Value<DateTime?> expiresAt = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> lastAccessedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AiMemoriesCompanion.insert(
            id: id,
            userId: userId,
            memoryType: memoryType,
            memoryKey: memoryKey,
            memoryValue: memoryValue,
            confidence: confidence,
            expiresAt: expiresAt,
            createdAt: createdAt,
            lastAccessedAt: lastAccessedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AiMemoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$AiMemoriesTableReferences._userIdTable(db),
                    referencedColumn:
                        $$AiMemoriesTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AiMemoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AiMemoriesTable,
    AiMemoryItem,
    $$AiMemoriesTableFilterComposer,
    $$AiMemoriesTableOrderingComposer,
    $$AiMemoriesTableAnnotationComposer,
    $$AiMemoriesTableCreateCompanionBuilder,
    $$AiMemoriesTableUpdateCompanionBuilder,
    (AiMemoryItem, $$AiMemoriesTableReferences),
    AiMemoryItem,
    PrefetchHooks Function({bool userId})>;
typedef $$AuditLogsTableCreateCompanionBuilder = AuditLogsCompanion Function({
  required String id,
  Value<String?> userId,
  required String eventType,
  required String eventCategory,
  required String description,
  Value<String?> metadata,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$AuditLogsTableUpdateCompanionBuilder = AuditLogsCompanion Function({
  Value<String> id,
  Value<String?> userId,
  Value<String> eventType,
  Value<String> eventCategory,
  Value<String> description,
  Value<String?> metadata,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$AuditLogsTableReferences
    extends BaseReferences<_$AppDatabase, $AuditLogsTable, AuditLog> {
  $$AuditLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.auditLogs.userId, db.users.id));

  $$UsersTableProcessedTableManager? get userId {
    if ($_item.userId == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id($_item.userId!));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AuditLogsTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventCategory => $composableBuilder(
      column: $table.eventCategory, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AuditLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventCategory => $composableBuilder(
      column: $table.eventCategory,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AuditLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get eventCategory => $composableBuilder(
      column: $table.eventCategory, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AuditLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AuditLogsTable,
    AuditLog,
    $$AuditLogsTableFilterComposer,
    $$AuditLogsTableOrderingComposer,
    $$AuditLogsTableAnnotationComposer,
    $$AuditLogsTableCreateCompanionBuilder,
    $$AuditLogsTableUpdateCompanionBuilder,
    (AuditLog, $$AuditLogsTableReferences),
    AuditLog,
    PrefetchHooks Function({bool userId})> {
  $$AuditLogsTableTableManager(_$AppDatabase db, $AuditLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String> eventType = const Value.absent(),
            Value<String> eventCategory = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AuditLogsCompanion(
            id: id,
            userId: userId,
            eventType: eventType,
            eventCategory: eventCategory,
            description: description,
            metadata: metadata,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> userId = const Value.absent(),
            required String eventType,
            required String eventCategory,
            required String description,
            Value<String?> metadata = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AuditLogsCompanion.insert(
            id: id,
            userId: userId,
            eventType: eventType,
            eventCategory: eventCategory,
            description: description,
            metadata: metadata,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AuditLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$AuditLogsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$AuditLogsTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AuditLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AuditLogsTable,
    AuditLog,
    $$AuditLogsTableFilterComposer,
    $$AuditLogsTableOrderingComposer,
    $$AuditLogsTableAnnotationComposer,
    $$AuditLogsTableCreateCompanionBuilder,
    $$AuditLogsTableUpdateCompanionBuilder,
    (AuditLog, $$AuditLogsTableReferences),
    AuditLog,
    PrefetchHooks Function({bool userId})>;
typedef $$TransactionDraftsTableCreateCompanionBuilder
    = TransactionDraftsCompanion Function({
  required String id,
  required String userId,
  required int amount,
  required String type,
  Value<String> currency,
  Value<String?> merchant,
  Value<String?> description,
  required DateTime date,
  Value<String?> smsSender,
  Value<String?> cardOrAccount,
  Value<String?> smsBody,
  Value<String?> originalSmsId,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$TransactionDraftsTableUpdateCompanionBuilder
    = TransactionDraftsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<int> amount,
  Value<String> type,
  Value<String> currency,
  Value<String?> merchant,
  Value<String?> description,
  Value<DateTime> date,
  Value<String?> smsSender,
  Value<String?> cardOrAccount,
  Value<String?> smsBody,
  Value<String?> originalSmsId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$TransactionDraftsTableReferences extends BaseReferences<
    _$AppDatabase, $TransactionDraftsTable, TransactionDraft> {
  $$TransactionDraftsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users.createAlias(
      $_aliasNameGenerator(db.transactionDrafts.userId, db.users.id));

  $$UsersTableProcessedTableManager? get userId {
    if ($_item.userId == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id($_item.userId!));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TransactionDraftsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionDraftsTable> {
  $$TransactionDraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get merchant => $composableBuilder(
      column: $table.merchant, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get smsSender => $composableBuilder(
      column: $table.smsSender, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cardOrAccount => $composableBuilder(
      column: $table.cardOrAccount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get smsBody => $composableBuilder(
      column: $table.smsBody, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originalSmsId => $composableBuilder(
      column: $table.originalSmsId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionDraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionDraftsTable> {
  $$TransactionDraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get merchant => $composableBuilder(
      column: $table.merchant, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get smsSender => $composableBuilder(
      column: $table.smsSender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cardOrAccount => $composableBuilder(
      column: $table.cardOrAccount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get smsBody => $composableBuilder(
      column: $table.smsBody, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originalSmsId => $composableBuilder(
      column: $table.originalSmsId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionDraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionDraftsTable> {
  $$TransactionDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get smsSender =>
      $composableBuilder(column: $table.smsSender, builder: (column) => column);

  GeneratedColumn<String> get cardOrAccount => $composableBuilder(
      column: $table.cardOrAccount, builder: (column) => column);

  GeneratedColumn<String> get smsBody =>
      $composableBuilder(column: $table.smsBody, builder: (column) => column);

  GeneratedColumn<String> get originalSmsId => $composableBuilder(
      column: $table.originalSmsId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionDraftsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionDraftsTable,
    TransactionDraft,
    $$TransactionDraftsTableFilterComposer,
    $$TransactionDraftsTableOrderingComposer,
    $$TransactionDraftsTableAnnotationComposer,
    $$TransactionDraftsTableCreateCompanionBuilder,
    $$TransactionDraftsTableUpdateCompanionBuilder,
    (TransactionDraft, $$TransactionDraftsTableReferences),
    TransactionDraft,
    PrefetchHooks Function({bool userId})> {
  $$TransactionDraftsTableTableManager(
      _$AppDatabase db, $TransactionDraftsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionDraftsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<String?> merchant = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String?> smsSender = const Value.absent(),
            Value<String?> cardOrAccount = const Value.absent(),
            Value<String?> smsBody = const Value.absent(),
            Value<String?> originalSmsId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionDraftsCompanion(
            id: id,
            userId: userId,
            amount: amount,
            type: type,
            currency: currency,
            merchant: merchant,
            description: description,
            date: date,
            smsSender: smsSender,
            cardOrAccount: cardOrAccount,
            smsBody: smsBody,
            originalSmsId: originalSmsId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required int amount,
            required String type,
            Value<String> currency = const Value.absent(),
            Value<String?> merchant = const Value.absent(),
            Value<String?> description = const Value.absent(),
            required DateTime date,
            Value<String?> smsSender = const Value.absent(),
            Value<String?> cardOrAccount = const Value.absent(),
            Value<String?> smsBody = const Value.absent(),
            Value<String?> originalSmsId = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionDraftsCompanion.insert(
            id: id,
            userId: userId,
            amount: amount,
            type: type,
            currency: currency,
            merchant: merchant,
            description: description,
            date: date,
            smsSender: smsSender,
            cardOrAccount: cardOrAccount,
            smsBody: smsBody,
            originalSmsId: originalSmsId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TransactionDraftsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$TransactionDraftsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$TransactionDraftsTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TransactionDraftsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionDraftsTable,
    TransactionDraft,
    $$TransactionDraftsTableFilterComposer,
    $$TransactionDraftsTableOrderingComposer,
    $$TransactionDraftsTableAnnotationComposer,
    $$TransactionDraftsTableCreateCompanionBuilder,
    $$TransactionDraftsTableUpdateCompanionBuilder,
    (TransactionDraft, $$TransactionDraftsTableReferences),
    TransactionDraft,
    PrefetchHooks Function({bool userId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$PaymentMethodsTableTableManager get paymentMethods =>
      $$PaymentMethodsTableTableManager(_db, _db.paymentMethods);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$ChatHistoryTableTableManager get chatHistory =>
      $$ChatHistoryTableTableManager(_db, _db.chatHistory);
  $$AiMemoriesTableTableManager get aiMemories =>
      $$AiMemoriesTableTableManager(_db, _db.aiMemories);
  $$AuditLogsTableTableManager get auditLogs =>
      $$AuditLogsTableTableManager(_db, _db.auditLogs);
  $$TransactionDraftsTableTableManager get transactionDrafts =>
      $$TransactionDraftsTableTableManager(_db, _db.transactionDrafts);
}
