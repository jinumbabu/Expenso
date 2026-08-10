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
  static const VerificationMeta _photoUrlMeta =
      const VerificationMeta('photoUrl');
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
      'photo_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastLoginMeta =
      const VerificationMeta('lastLogin');
  @override
  late final GeneratedColumn<DateTime> lastLogin = GeneratedColumn<DateTime>(
      'last_login', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        googleId,
        email,
        displayName,
        currency,
        country,
        createdAt,
        updatedAt,
        photoUrl,
        lastLogin
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
    if (data.containsKey('photo_url')) {
      context.handle(_photoUrlMeta,
          photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta));
    }
    if (data.containsKey('last_login')) {
      context.handle(_lastLoginMeta,
          lastLogin.isAcceptableOrUnknown(data['last_login']!, _lastLoginMeta));
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
      photoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_url']),
      lastLogin: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_login']),
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
  final String? photoUrl;
  final DateTime? lastLogin;
  const User(
      {required this.id,
      required this.googleId,
      required this.email,
      required this.displayName,
      required this.currency,
      this.country,
      required this.createdAt,
      required this.updatedAt,
      this.photoUrl,
      this.lastLogin});
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
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    if (!nullToAbsent || lastLogin != null) {
      map['last_login'] = Variable<DateTime>(lastLogin);
    }
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
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      lastLogin: lastLogin == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLogin),
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
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      lastLogin: serializer.fromJson<DateTime?>(json['lastLogin']),
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
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'lastLogin': serializer.toJson<DateTime?>(lastLogin),
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
          DateTime? updatedAt,
          Value<String?> photoUrl = const Value.absent(),
          Value<DateTime?> lastLogin = const Value.absent()}) =>
      User(
        id: id ?? this.id,
        googleId: googleId ?? this.googleId,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        currency: currency ?? this.currency,
        country: country.present ? country.value : this.country,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
        lastLogin: lastLogin.present ? lastLogin.value : this.lastLogin,
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
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      lastLogin: data.lastLogin.present ? data.lastLogin.value : this.lastLogin,
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
          ..write('updatedAt: $updatedAt, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('lastLogin: $lastLogin')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, googleId, email, displayName, currency,
      country, createdAt, updatedAt, photoUrl, lastLogin);
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
          other.updatedAt == this.updatedAt &&
          other.photoUrl == this.photoUrl &&
          other.lastLogin == this.lastLogin);
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
  final Value<String?> photoUrl;
  final Value<DateTime?> lastLogin;
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
    this.photoUrl = const Value.absent(),
    this.lastLogin = const Value.absent(),
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
    this.photoUrl = const Value.absent(),
    this.lastLogin = const Value.absent(),
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
    Expression<String>? photoUrl,
    Expression<DateTime>? lastLogin,
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
      if (photoUrl != null) 'photo_url': photoUrl,
      if (lastLogin != null) 'last_login': lastLogin,
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
      Value<String?>? photoUrl,
      Value<DateTime?>? lastLogin,
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
      photoUrl: photoUrl ?? this.photoUrl,
      lastLogin: lastLogin ?? this.lastLogin,
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
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (lastLogin.present) {
      map['last_login'] = Variable<DateTime>(lastLogin.value);
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
          ..write('photoUrl: $photoUrl, ')
          ..write('lastLogin: $lastLogin, ')
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
  static const VerificationMeta _bankNameMeta =
      const VerificationMeta('bankName');
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
      'bank_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _openingBalanceMeta =
      const VerificationMeta('openingBalance');
  @override
  late final GeneratedColumn<int> openingBalance = GeneratedColumn<int>(
      'opening_balance', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _colorThemeMeta =
      const VerificationMeta('colorTheme');
  @override
  late final GeneratedColumn<String> colorTheme = GeneratedColumn<String>(
      'color_theme', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'));
  static const VerificationMeta _creditLimitMeta =
      const VerificationMeta('creditLimit');
  @override
  late final GeneratedColumn<int> creditLimit = GeneratedColumn<int>(
      'credit_limit', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _availableCreditMeta =
      const VerificationMeta('availableCredit');
  @override
  late final GeneratedColumn<int> availableCredit = GeneratedColumn<int>(
      'available_credit', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _outstandingBalanceMeta =
      const VerificationMeta('outstandingBalance');
  @override
  late final GeneratedColumn<int> outstandingBalance = GeneratedColumn<int>(
      'outstanding_balance', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _statementDateMeta =
      const VerificationMeta('statementDate');
  @override
  late final GeneratedColumn<int> statementDate = GeneratedColumn<int>(
      'statement_date', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _paymentDueDateMeta =
      const VerificationMeta('paymentDueDate');
  @override
  late final GeneratedColumn<int> paymentDueDate = GeneratedColumn<int>(
      'payment_due_date', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _minAmountDueMeta =
      const VerificationMeta('minAmountDue');
  @override
  late final GeneratedColumn<int> minAmountDue = GeneratedColumn<int>(
      'min_amount_due', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _totalAmountDueMeta =
      const VerificationMeta('totalAmountDue');
  @override
  late final GeneratedColumn<int> totalAmountDue = GeneratedColumn<int>(
      'total_amount_due', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastPaymentMeta =
      const VerificationMeta('lastPayment');
  @override
  late final GeneratedColumn<int> lastPayment = GeneratedColumn<int>(
      'last_payment', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nextDueDateMeta =
      const VerificationMeta('nextDueDate');
  @override
  late final GeneratedColumn<DateTime> nextDueDate = GeneratedColumn<DateTime>(
      'next_due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _paymentStatusMeta =
      const VerificationMeta('paymentStatus');
  @override
  late final GeneratedColumn<String> paymentStatus = GeneratedColumn<String>(
      'payment_status', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _autoPayMeta =
      const VerificationMeta('autoPay');
  @override
  late final GeneratedColumn<bool> autoPay = GeneratedColumn<bool>(
      'auto_pay', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("auto_pay" IN (0, 1))'));
  static const VerificationMeta _isEstimatedMeta =
      const VerificationMeta('isEstimated');
  @override
  late final GeneratedColumn<bool> isEstimated = GeneratedColumn<bool>(
      'is_estimated', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_estimated" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _last4DigitsMeta =
      const VerificationMeta('last4Digits');
  @override
  late final GeneratedColumn<String> last4Digits = GeneratedColumn<String>(
      'last_4_digits', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statementCycleMeta =
      const VerificationMeta('statementCycle');
  @override
  late final GeneratedColumn<String> statementCycle = GeneratedColumn<String>(
      'statement_cycle', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _enableBillReminderMeta =
      const VerificationMeta('enableBillReminder');
  @override
  late final GeneratedColumn<bool> enableBillReminder = GeneratedColumn<bool>(
      'enable_bill_reminder', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("enable_bill_reminder" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _enableSmsTrackingMeta =
      const VerificationMeta('enableSmsTracking');
  @override
  late final GeneratedColumn<bool> enableSmsTracking = GeneratedColumn<bool>(
      'enable_sms_tracking', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("enable_sms_tracking" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _verifiedBalanceMeta =
      const VerificationMeta('verifiedBalance');
  @override
  late final GeneratedColumn<int> verifiedBalance = GeneratedColumn<int>(
      'verified_balance', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _calculatedBalanceMeta =
      const VerificationMeta('calculatedBalance');
  @override
  late final GeneratedColumn<int> calculatedBalance = GeneratedColumn<int>(
      'calculated_balance', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _importedBalanceMeta =
      const VerificationMeta('importedBalance');
  @override
  late final GeneratedColumn<int> importedBalance = GeneratedColumn<int>(
      'imported_balance', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastSyncedBalanceMeta =
      const VerificationMeta('lastSyncedBalance');
  @override
  late final GeneratedColumn<int> lastSyncedBalance = GeneratedColumn<int>(
      'last_synced_balance', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _verifiedAtMeta =
      const VerificationMeta('verifiedAt');
  @override
  late final GeneratedColumn<DateTime> verifiedAt = GeneratedColumn<DateTime>(
      'verified_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _hasMismatchMeta =
      const VerificationMeta('hasMismatch');
  @override
  late final GeneratedColumn<bool> hasMismatch = GeneratedColumn<bool>(
      'has_mismatch', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_mismatch" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _mismatchExpectedMeta =
      const VerificationMeta('mismatchExpected');
  @override
  late final GeneratedColumn<int> mismatchExpected = GeneratedColumn<int>(
      'mismatch_expected', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _mismatchImportedMeta =
      const VerificationMeta('mismatchImported');
  @override
  late final GeneratedColumn<int> mismatchImported = GeneratedColumn<int>(
      'mismatch_imported', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        name,
        type,
        balance,
        isDefault,
        createdAt,
        updatedAt,
        bankName,
        openingBalance,
        currency,
        colorTheme,
        icon,
        notes,
        isActive,
        creditLimit,
        availableCredit,
        outstandingBalance,
        statementDate,
        paymentDueDate,
        minAmountDue,
        totalAmountDue,
        lastPayment,
        nextDueDate,
        paymentStatus,
        autoPay,
        isEstimated,
        last4Digits,
        statementCycle,
        enableBillReminder,
        enableSmsTracking,
        verifiedBalance,
        calculatedBalance,
        importedBalance,
        lastSyncedBalance,
        verifiedAt,
        hasMismatch,
        mismatchExpected,
        mismatchImported,
        sortOrder
      ];
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
    if (data.containsKey('bank_name')) {
      context.handle(_bankNameMeta,
          bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta));
    }
    if (data.containsKey('opening_balance')) {
      context.handle(
          _openingBalanceMeta,
          openingBalance.isAcceptableOrUnknown(
              data['opening_balance']!, _openingBalanceMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('color_theme')) {
      context.handle(
          _colorThemeMeta,
          colorTheme.isAcceptableOrUnknown(
              data['color_theme']!, _colorThemeMeta));
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('credit_limit')) {
      context.handle(
          _creditLimitMeta,
          creditLimit.isAcceptableOrUnknown(
              data['credit_limit']!, _creditLimitMeta));
    }
    if (data.containsKey('available_credit')) {
      context.handle(
          _availableCreditMeta,
          availableCredit.isAcceptableOrUnknown(
              data['available_credit']!, _availableCreditMeta));
    }
    if (data.containsKey('outstanding_balance')) {
      context.handle(
          _outstandingBalanceMeta,
          outstandingBalance.isAcceptableOrUnknown(
              data['outstanding_balance']!, _outstandingBalanceMeta));
    }
    if (data.containsKey('statement_date')) {
      context.handle(
          _statementDateMeta,
          statementDate.isAcceptableOrUnknown(
              data['statement_date']!, _statementDateMeta));
    }
    if (data.containsKey('payment_due_date')) {
      context.handle(
          _paymentDueDateMeta,
          paymentDueDate.isAcceptableOrUnknown(
              data['payment_due_date']!, _paymentDueDateMeta));
    }
    if (data.containsKey('min_amount_due')) {
      context.handle(
          _minAmountDueMeta,
          minAmountDue.isAcceptableOrUnknown(
              data['min_amount_due']!, _minAmountDueMeta));
    }
    if (data.containsKey('total_amount_due')) {
      context.handle(
          _totalAmountDueMeta,
          totalAmountDue.isAcceptableOrUnknown(
              data['total_amount_due']!, _totalAmountDueMeta));
    }
    if (data.containsKey('last_payment')) {
      context.handle(
          _lastPaymentMeta,
          lastPayment.isAcceptableOrUnknown(
              data['last_payment']!, _lastPaymentMeta));
    }
    if (data.containsKey('next_due_date')) {
      context.handle(
          _nextDueDateMeta,
          nextDueDate.isAcceptableOrUnknown(
              data['next_due_date']!, _nextDueDateMeta));
    }
    if (data.containsKey('payment_status')) {
      context.handle(
          _paymentStatusMeta,
          paymentStatus.isAcceptableOrUnknown(
              data['payment_status']!, _paymentStatusMeta));
    }
    if (data.containsKey('auto_pay')) {
      context.handle(_autoPayMeta,
          autoPay.isAcceptableOrUnknown(data['auto_pay']!, _autoPayMeta));
    }
    if (data.containsKey('is_estimated')) {
      context.handle(
          _isEstimatedMeta,
          isEstimated.isAcceptableOrUnknown(
              data['is_estimated']!, _isEstimatedMeta));
    }
    if (data.containsKey('last_4_digits')) {
      context.handle(
          _last4DigitsMeta,
          last4Digits.isAcceptableOrUnknown(
              data['last_4_digits']!, _last4DigitsMeta));
    }
    if (data.containsKey('statement_cycle')) {
      context.handle(
          _statementCycleMeta,
          statementCycle.isAcceptableOrUnknown(
              data['statement_cycle']!, _statementCycleMeta));
    }
    if (data.containsKey('enable_bill_reminder')) {
      context.handle(
          _enableBillReminderMeta,
          enableBillReminder.isAcceptableOrUnknown(
              data['enable_bill_reminder']!, _enableBillReminderMeta));
    }
    if (data.containsKey('enable_sms_tracking')) {
      context.handle(
          _enableSmsTrackingMeta,
          enableSmsTracking.isAcceptableOrUnknown(
              data['enable_sms_tracking']!, _enableSmsTrackingMeta));
    }
    if (data.containsKey('verified_balance')) {
      context.handle(
          _verifiedBalanceMeta,
          verifiedBalance.isAcceptableOrUnknown(
              data['verified_balance']!, _verifiedBalanceMeta));
    }
    if (data.containsKey('calculated_balance')) {
      context.handle(
          _calculatedBalanceMeta,
          calculatedBalance.isAcceptableOrUnknown(
              data['calculated_balance']!, _calculatedBalanceMeta));
    }
    if (data.containsKey('imported_balance')) {
      context.handle(
          _importedBalanceMeta,
          importedBalance.isAcceptableOrUnknown(
              data['imported_balance']!, _importedBalanceMeta));
    }
    if (data.containsKey('last_synced_balance')) {
      context.handle(
          _lastSyncedBalanceMeta,
          lastSyncedBalance.isAcceptableOrUnknown(
              data['last_synced_balance']!, _lastSyncedBalanceMeta));
    }
    if (data.containsKey('verified_at')) {
      context.handle(
          _verifiedAtMeta,
          verifiedAt.isAcceptableOrUnknown(
              data['verified_at']!, _verifiedAtMeta));
    }
    if (data.containsKey('has_mismatch')) {
      context.handle(
          _hasMismatchMeta,
          hasMismatch.isAcceptableOrUnknown(
              data['has_mismatch']!, _hasMismatchMeta));
    }
    if (data.containsKey('mismatch_expected')) {
      context.handle(
          _mismatchExpectedMeta,
          mismatchExpected.isAcceptableOrUnknown(
              data['mismatch_expected']!, _mismatchExpectedMeta));
    }
    if (data.containsKey('mismatch_imported')) {
      context.handle(
          _mismatchImportedMeta,
          mismatchImported.isAcceptableOrUnknown(
              data['mismatch_imported']!, _mismatchImportedMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
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
      bankName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bank_name']),
      openingBalance: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}opening_balance']),
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency']),
      colorTheme: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_theme']),
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active']),
      creditLimit: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}credit_limit']),
      availableCredit: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}available_credit']),
      outstandingBalance: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}outstanding_balance']),
      statementDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}statement_date']),
      paymentDueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}payment_due_date']),
      minAmountDue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min_amount_due']),
      totalAmountDue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_amount_due']),
      lastPayment: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_payment']),
      nextDueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}next_due_date']),
      paymentStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_status']),
      autoPay: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}auto_pay']),
      isEstimated: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_estimated'])!,
      last4Digits: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_4_digits']),
      statementCycle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}statement_cycle']),
      enableBillReminder: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}enable_bill_reminder']),
      enableSmsTracking: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}enable_sms_tracking']),
      verifiedBalance: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}verified_balance']),
      calculatedBalance: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}calculated_balance']),
      importedBalance: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}imported_balance']),
      lastSyncedBalance: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}last_synced_balance']),
      verifiedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}verified_at']),
      hasMismatch: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}has_mismatch']),
      mismatchExpected: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mismatch_expected']),
      mismatchImported: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mismatch_imported']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order']),
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
  final String? bankName;
  final int? openingBalance;
  final String? currency;
  final String? colorTheme;
  final String? icon;
  final String? notes;
  final bool? isActive;
  final int? creditLimit;
  final int? availableCredit;
  final int? outstandingBalance;
  final int? statementDate;
  final int? paymentDueDate;
  final int? minAmountDue;
  final int? totalAmountDue;
  final int? lastPayment;
  final DateTime? nextDueDate;
  final String? paymentStatus;
  final bool? autoPay;
  final bool isEstimated;
  final String? last4Digits;
  final String? statementCycle;
  final bool? enableBillReminder;
  final bool? enableSmsTracking;
  final int? verifiedBalance;
  final int? calculatedBalance;
  final int? importedBalance;
  final int? lastSyncedBalance;
  final DateTime? verifiedAt;
  final bool? hasMismatch;
  final int? mismatchExpected;
  final int? mismatchImported;
  final int? sortOrder;
  const Account(
      {required this.id,
      required this.userId,
      required this.name,
      required this.type,
      required this.balance,
      required this.isDefault,
      required this.createdAt,
      required this.updatedAt,
      this.bankName,
      this.openingBalance,
      this.currency,
      this.colorTheme,
      this.icon,
      this.notes,
      this.isActive,
      this.creditLimit,
      this.availableCredit,
      this.outstandingBalance,
      this.statementDate,
      this.paymentDueDate,
      this.minAmountDue,
      this.totalAmountDue,
      this.lastPayment,
      this.nextDueDate,
      this.paymentStatus,
      this.autoPay,
      required this.isEstimated,
      this.last4Digits,
      this.statementCycle,
      this.enableBillReminder,
      this.enableSmsTracking,
      this.verifiedBalance,
      this.calculatedBalance,
      this.importedBalance,
      this.lastSyncedBalance,
      this.verifiedAt,
      this.hasMismatch,
      this.mismatchExpected,
      this.mismatchImported,
      this.sortOrder});
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
    if (!nullToAbsent || bankName != null) {
      map['bank_name'] = Variable<String>(bankName);
    }
    if (!nullToAbsent || openingBalance != null) {
      map['opening_balance'] = Variable<int>(openingBalance);
    }
    if (!nullToAbsent || currency != null) {
      map['currency'] = Variable<String>(currency);
    }
    if (!nullToAbsent || colorTheme != null) {
      map['color_theme'] = Variable<String>(colorTheme);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || isActive != null) {
      map['is_active'] = Variable<bool>(isActive);
    }
    if (!nullToAbsent || creditLimit != null) {
      map['credit_limit'] = Variable<int>(creditLimit);
    }
    if (!nullToAbsent || availableCredit != null) {
      map['available_credit'] = Variable<int>(availableCredit);
    }
    if (!nullToAbsent || outstandingBalance != null) {
      map['outstanding_balance'] = Variable<int>(outstandingBalance);
    }
    if (!nullToAbsent || statementDate != null) {
      map['statement_date'] = Variable<int>(statementDate);
    }
    if (!nullToAbsent || paymentDueDate != null) {
      map['payment_due_date'] = Variable<int>(paymentDueDate);
    }
    if (!nullToAbsent || minAmountDue != null) {
      map['min_amount_due'] = Variable<int>(minAmountDue);
    }
    if (!nullToAbsent || totalAmountDue != null) {
      map['total_amount_due'] = Variable<int>(totalAmountDue);
    }
    if (!nullToAbsent || lastPayment != null) {
      map['last_payment'] = Variable<int>(lastPayment);
    }
    if (!nullToAbsent || nextDueDate != null) {
      map['next_due_date'] = Variable<DateTime>(nextDueDate);
    }
    if (!nullToAbsent || paymentStatus != null) {
      map['payment_status'] = Variable<String>(paymentStatus);
    }
    if (!nullToAbsent || autoPay != null) {
      map['auto_pay'] = Variable<bool>(autoPay);
    }
    map['is_estimated'] = Variable<bool>(isEstimated);
    if (!nullToAbsent || last4Digits != null) {
      map['last_4_digits'] = Variable<String>(last4Digits);
    }
    if (!nullToAbsent || statementCycle != null) {
      map['statement_cycle'] = Variable<String>(statementCycle);
    }
    if (!nullToAbsent || enableBillReminder != null) {
      map['enable_bill_reminder'] = Variable<bool>(enableBillReminder);
    }
    if (!nullToAbsent || enableSmsTracking != null) {
      map['enable_sms_tracking'] = Variable<bool>(enableSmsTracking);
    }
    if (!nullToAbsent || verifiedBalance != null) {
      map['verified_balance'] = Variable<int>(verifiedBalance);
    }
    if (!nullToAbsent || calculatedBalance != null) {
      map['calculated_balance'] = Variable<int>(calculatedBalance);
    }
    if (!nullToAbsent || importedBalance != null) {
      map['imported_balance'] = Variable<int>(importedBalance);
    }
    if (!nullToAbsent || lastSyncedBalance != null) {
      map['last_synced_balance'] = Variable<int>(lastSyncedBalance);
    }
    if (!nullToAbsent || verifiedAt != null) {
      map['verified_at'] = Variable<DateTime>(verifiedAt);
    }
    if (!nullToAbsent || hasMismatch != null) {
      map['has_mismatch'] = Variable<bool>(hasMismatch);
    }
    if (!nullToAbsent || mismatchExpected != null) {
      map['mismatch_expected'] = Variable<int>(mismatchExpected);
    }
    if (!nullToAbsent || mismatchImported != null) {
      map['mismatch_imported'] = Variable<int>(mismatchImported);
    }
    if (!nullToAbsent || sortOrder != null) {
      map['sort_order'] = Variable<int>(sortOrder);
    }
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
      bankName: bankName == null && nullToAbsent
          ? const Value.absent()
          : Value(bankName),
      openingBalance: openingBalance == null && nullToAbsent
          ? const Value.absent()
          : Value(openingBalance),
      currency: currency == null && nullToAbsent
          ? const Value.absent()
          : Value(currency),
      colorTheme: colorTheme == null && nullToAbsent
          ? const Value.absent()
          : Value(colorTheme),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      isActive: isActive == null && nullToAbsent
          ? const Value.absent()
          : Value(isActive),
      creditLimit: creditLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(creditLimit),
      availableCredit: availableCredit == null && nullToAbsent
          ? const Value.absent()
          : Value(availableCredit),
      outstandingBalance: outstandingBalance == null && nullToAbsent
          ? const Value.absent()
          : Value(outstandingBalance),
      statementDate: statementDate == null && nullToAbsent
          ? const Value.absent()
          : Value(statementDate),
      paymentDueDate: paymentDueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentDueDate),
      minAmountDue: minAmountDue == null && nullToAbsent
          ? const Value.absent()
          : Value(minAmountDue),
      totalAmountDue: totalAmountDue == null && nullToAbsent
          ? const Value.absent()
          : Value(totalAmountDue),
      lastPayment: lastPayment == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPayment),
      nextDueDate: nextDueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(nextDueDate),
      paymentStatus: paymentStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentStatus),
      autoPay: autoPay == null && nullToAbsent
          ? const Value.absent()
          : Value(autoPay),
      isEstimated: Value(isEstimated),
      last4Digits: last4Digits == null && nullToAbsent
          ? const Value.absent()
          : Value(last4Digits),
      statementCycle: statementCycle == null && nullToAbsent
          ? const Value.absent()
          : Value(statementCycle),
      enableBillReminder: enableBillReminder == null && nullToAbsent
          ? const Value.absent()
          : Value(enableBillReminder),
      enableSmsTracking: enableSmsTracking == null && nullToAbsent
          ? const Value.absent()
          : Value(enableSmsTracking),
      verifiedBalance: verifiedBalance == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedBalance),
      calculatedBalance: calculatedBalance == null && nullToAbsent
          ? const Value.absent()
          : Value(calculatedBalance),
      importedBalance: importedBalance == null && nullToAbsent
          ? const Value.absent()
          : Value(importedBalance),
      lastSyncedBalance: lastSyncedBalance == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedBalance),
      verifiedAt: verifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedAt),
      hasMismatch: hasMismatch == null && nullToAbsent
          ? const Value.absent()
          : Value(hasMismatch),
      mismatchExpected: mismatchExpected == null && nullToAbsent
          ? const Value.absent()
          : Value(mismatchExpected),
      mismatchImported: mismatchImported == null && nullToAbsent
          ? const Value.absent()
          : Value(mismatchImported),
      sortOrder: sortOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(sortOrder),
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
      bankName: serializer.fromJson<String?>(json['bankName']),
      openingBalance: serializer.fromJson<int?>(json['openingBalance']),
      currency: serializer.fromJson<String?>(json['currency']),
      colorTheme: serializer.fromJson<String?>(json['colorTheme']),
      icon: serializer.fromJson<String?>(json['icon']),
      notes: serializer.fromJson<String?>(json['notes']),
      isActive: serializer.fromJson<bool?>(json['isActive']),
      creditLimit: serializer.fromJson<int?>(json['creditLimit']),
      availableCredit: serializer.fromJson<int?>(json['availableCredit']),
      outstandingBalance: serializer.fromJson<int?>(json['outstandingBalance']),
      statementDate: serializer.fromJson<int?>(json['statementDate']),
      paymentDueDate: serializer.fromJson<int?>(json['paymentDueDate']),
      minAmountDue: serializer.fromJson<int?>(json['minAmountDue']),
      totalAmountDue: serializer.fromJson<int?>(json['totalAmountDue']),
      lastPayment: serializer.fromJson<int?>(json['lastPayment']),
      nextDueDate: serializer.fromJson<DateTime?>(json['nextDueDate']),
      paymentStatus: serializer.fromJson<String?>(json['paymentStatus']),
      autoPay: serializer.fromJson<bool?>(json['autoPay']),
      isEstimated: serializer.fromJson<bool>(json['isEstimated']),
      last4Digits: serializer.fromJson<String?>(json['last4Digits']),
      statementCycle: serializer.fromJson<String?>(json['statementCycle']),
      enableBillReminder:
          serializer.fromJson<bool?>(json['enableBillReminder']),
      enableSmsTracking: serializer.fromJson<bool?>(json['enableSmsTracking']),
      verifiedBalance: serializer.fromJson<int?>(json['verifiedBalance']),
      calculatedBalance: serializer.fromJson<int?>(json['calculatedBalance']),
      importedBalance: serializer.fromJson<int?>(json['importedBalance']),
      lastSyncedBalance: serializer.fromJson<int?>(json['lastSyncedBalance']),
      verifiedAt: serializer.fromJson<DateTime?>(json['verifiedAt']),
      hasMismatch: serializer.fromJson<bool?>(json['hasMismatch']),
      mismatchExpected: serializer.fromJson<int?>(json['mismatchExpected']),
      mismatchImported: serializer.fromJson<int?>(json['mismatchImported']),
      sortOrder: serializer.fromJson<int?>(json['sortOrder']),
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
      'bankName': serializer.toJson<String?>(bankName),
      'openingBalance': serializer.toJson<int?>(openingBalance),
      'currency': serializer.toJson<String?>(currency),
      'colorTheme': serializer.toJson<String?>(colorTheme),
      'icon': serializer.toJson<String?>(icon),
      'notes': serializer.toJson<String?>(notes),
      'isActive': serializer.toJson<bool?>(isActive),
      'creditLimit': serializer.toJson<int?>(creditLimit),
      'availableCredit': serializer.toJson<int?>(availableCredit),
      'outstandingBalance': serializer.toJson<int?>(outstandingBalance),
      'statementDate': serializer.toJson<int?>(statementDate),
      'paymentDueDate': serializer.toJson<int?>(paymentDueDate),
      'minAmountDue': serializer.toJson<int?>(minAmountDue),
      'totalAmountDue': serializer.toJson<int?>(totalAmountDue),
      'lastPayment': serializer.toJson<int?>(lastPayment),
      'nextDueDate': serializer.toJson<DateTime?>(nextDueDate),
      'paymentStatus': serializer.toJson<String?>(paymentStatus),
      'autoPay': serializer.toJson<bool?>(autoPay),
      'isEstimated': serializer.toJson<bool>(isEstimated),
      'last4Digits': serializer.toJson<String?>(last4Digits),
      'statementCycle': serializer.toJson<String?>(statementCycle),
      'enableBillReminder': serializer.toJson<bool?>(enableBillReminder),
      'enableSmsTracking': serializer.toJson<bool?>(enableSmsTracking),
      'verifiedBalance': serializer.toJson<int?>(verifiedBalance),
      'calculatedBalance': serializer.toJson<int?>(calculatedBalance),
      'importedBalance': serializer.toJson<int?>(importedBalance),
      'lastSyncedBalance': serializer.toJson<int?>(lastSyncedBalance),
      'verifiedAt': serializer.toJson<DateTime?>(verifiedAt),
      'hasMismatch': serializer.toJson<bool?>(hasMismatch),
      'mismatchExpected': serializer.toJson<int?>(mismatchExpected),
      'mismatchImported': serializer.toJson<int?>(mismatchImported),
      'sortOrder': serializer.toJson<int?>(sortOrder),
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
          DateTime? updatedAt,
          Value<String?> bankName = const Value.absent(),
          Value<int?> openingBalance = const Value.absent(),
          Value<String?> currency = const Value.absent(),
          Value<String?> colorTheme = const Value.absent(),
          Value<String?> icon = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          Value<bool?> isActive = const Value.absent(),
          Value<int?> creditLimit = const Value.absent(),
          Value<int?> availableCredit = const Value.absent(),
          Value<int?> outstandingBalance = const Value.absent(),
          Value<int?> statementDate = const Value.absent(),
          Value<int?> paymentDueDate = const Value.absent(),
          Value<int?> minAmountDue = const Value.absent(),
          Value<int?> totalAmountDue = const Value.absent(),
          Value<int?> lastPayment = const Value.absent(),
          Value<DateTime?> nextDueDate = const Value.absent(),
          Value<String?> paymentStatus = const Value.absent(),
          Value<bool?> autoPay = const Value.absent(),
          bool? isEstimated,
          Value<String?> last4Digits = const Value.absent(),
          Value<String?> statementCycle = const Value.absent(),
          Value<bool?> enableBillReminder = const Value.absent(),
          Value<bool?> enableSmsTracking = const Value.absent(),
          Value<int?> verifiedBalance = const Value.absent(),
          Value<int?> calculatedBalance = const Value.absent(),
          Value<int?> importedBalance = const Value.absent(),
          Value<int?> lastSyncedBalance = const Value.absent(),
          Value<DateTime?> verifiedAt = const Value.absent(),
          Value<bool?> hasMismatch = const Value.absent(),
          Value<int?> mismatchExpected = const Value.absent(),
          Value<int?> mismatchImported = const Value.absent(),
          Value<int?> sortOrder = const Value.absent()}) =>
      Account(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        type: type ?? this.type,
        balance: balance ?? this.balance,
        isDefault: isDefault ?? this.isDefault,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        bankName: bankName.present ? bankName.value : this.bankName,
        openingBalance:
            openingBalance.present ? openingBalance.value : this.openingBalance,
        currency: currency.present ? currency.value : this.currency,
        colorTheme: colorTheme.present ? colorTheme.value : this.colorTheme,
        icon: icon.present ? icon.value : this.icon,
        notes: notes.present ? notes.value : this.notes,
        isActive: isActive.present ? isActive.value : this.isActive,
        creditLimit: creditLimit.present ? creditLimit.value : this.creditLimit,
        availableCredit: availableCredit.present
            ? availableCredit.value
            : this.availableCredit,
        outstandingBalance: outstandingBalance.present
            ? outstandingBalance.value
            : this.outstandingBalance,
        statementDate:
            statementDate.present ? statementDate.value : this.statementDate,
        paymentDueDate:
            paymentDueDate.present ? paymentDueDate.value : this.paymentDueDate,
        minAmountDue:
            minAmountDue.present ? minAmountDue.value : this.minAmountDue,
        totalAmountDue:
            totalAmountDue.present ? totalAmountDue.value : this.totalAmountDue,
        lastPayment: lastPayment.present ? lastPayment.value : this.lastPayment,
        nextDueDate: nextDueDate.present ? nextDueDate.value : this.nextDueDate,
        paymentStatus:
            paymentStatus.present ? paymentStatus.value : this.paymentStatus,
        autoPay: autoPay.present ? autoPay.value : this.autoPay,
        isEstimated: isEstimated ?? this.isEstimated,
        last4Digits: last4Digits.present ? last4Digits.value : this.last4Digits,
        statementCycle:
            statementCycle.present ? statementCycle.value : this.statementCycle,
        enableBillReminder: enableBillReminder.present
            ? enableBillReminder.value
            : this.enableBillReminder,
        enableSmsTracking: enableSmsTracking.present
            ? enableSmsTracking.value
            : this.enableSmsTracking,
        verifiedBalance: verifiedBalance.present
            ? verifiedBalance.value
            : this.verifiedBalance,
        calculatedBalance: calculatedBalance.present
            ? calculatedBalance.value
            : this.calculatedBalance,
        importedBalance: importedBalance.present
            ? importedBalance.value
            : this.importedBalance,
        lastSyncedBalance: lastSyncedBalance.present
            ? lastSyncedBalance.value
            : this.lastSyncedBalance,
        verifiedAt: verifiedAt.present ? verifiedAt.value : this.verifiedAt,
        hasMismatch: hasMismatch.present ? hasMismatch.value : this.hasMismatch,
        mismatchExpected: mismatchExpected.present
            ? mismatchExpected.value
            : this.mismatchExpected,
        mismatchImported: mismatchImported.present
            ? mismatchImported.value
            : this.mismatchImported,
        sortOrder: sortOrder.present ? sortOrder.value : this.sortOrder,
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
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      openingBalance: data.openingBalance.present
          ? data.openingBalance.value
          : this.openingBalance,
      currency: data.currency.present ? data.currency.value : this.currency,
      colorTheme:
          data.colorTheme.present ? data.colorTheme.value : this.colorTheme,
      icon: data.icon.present ? data.icon.value : this.icon,
      notes: data.notes.present ? data.notes.value : this.notes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      creditLimit:
          data.creditLimit.present ? data.creditLimit.value : this.creditLimit,
      availableCredit: data.availableCredit.present
          ? data.availableCredit.value
          : this.availableCredit,
      outstandingBalance: data.outstandingBalance.present
          ? data.outstandingBalance.value
          : this.outstandingBalance,
      statementDate: data.statementDate.present
          ? data.statementDate.value
          : this.statementDate,
      paymentDueDate: data.paymentDueDate.present
          ? data.paymentDueDate.value
          : this.paymentDueDate,
      minAmountDue: data.minAmountDue.present
          ? data.minAmountDue.value
          : this.minAmountDue,
      totalAmountDue: data.totalAmountDue.present
          ? data.totalAmountDue.value
          : this.totalAmountDue,
      lastPayment:
          data.lastPayment.present ? data.lastPayment.value : this.lastPayment,
      nextDueDate:
          data.nextDueDate.present ? data.nextDueDate.value : this.nextDueDate,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      autoPay: data.autoPay.present ? data.autoPay.value : this.autoPay,
      isEstimated:
          data.isEstimated.present ? data.isEstimated.value : this.isEstimated,
      last4Digits:
          data.last4Digits.present ? data.last4Digits.value : this.last4Digits,
      statementCycle: data.statementCycle.present
          ? data.statementCycle.value
          : this.statementCycle,
      enableBillReminder: data.enableBillReminder.present
          ? data.enableBillReminder.value
          : this.enableBillReminder,
      enableSmsTracking: data.enableSmsTracking.present
          ? data.enableSmsTracking.value
          : this.enableSmsTracking,
      verifiedBalance: data.verifiedBalance.present
          ? data.verifiedBalance.value
          : this.verifiedBalance,
      calculatedBalance: data.calculatedBalance.present
          ? data.calculatedBalance.value
          : this.calculatedBalance,
      importedBalance: data.importedBalance.present
          ? data.importedBalance.value
          : this.importedBalance,
      lastSyncedBalance: data.lastSyncedBalance.present
          ? data.lastSyncedBalance.value
          : this.lastSyncedBalance,
      verifiedAt:
          data.verifiedAt.present ? data.verifiedAt.value : this.verifiedAt,
      hasMismatch:
          data.hasMismatch.present ? data.hasMismatch.value : this.hasMismatch,
      mismatchExpected: data.mismatchExpected.present
          ? data.mismatchExpected.value
          : this.mismatchExpected,
      mismatchImported: data.mismatchImported.present
          ? data.mismatchImported.value
          : this.mismatchImported,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
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
          ..write('updatedAt: $updatedAt, ')
          ..write('bankName: $bankName, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('currency: $currency, ')
          ..write('colorTheme: $colorTheme, ')
          ..write('icon: $icon, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('availableCredit: $availableCredit, ')
          ..write('outstandingBalance: $outstandingBalance, ')
          ..write('statementDate: $statementDate, ')
          ..write('paymentDueDate: $paymentDueDate, ')
          ..write('minAmountDue: $minAmountDue, ')
          ..write('totalAmountDue: $totalAmountDue, ')
          ..write('lastPayment: $lastPayment, ')
          ..write('nextDueDate: $nextDueDate, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('autoPay: $autoPay, ')
          ..write('isEstimated: $isEstimated, ')
          ..write('last4Digits: $last4Digits, ')
          ..write('statementCycle: $statementCycle, ')
          ..write('enableBillReminder: $enableBillReminder, ')
          ..write('enableSmsTracking: $enableSmsTracking, ')
          ..write('verifiedBalance: $verifiedBalance, ')
          ..write('calculatedBalance: $calculatedBalance, ')
          ..write('importedBalance: $importedBalance, ')
          ..write('lastSyncedBalance: $lastSyncedBalance, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('hasMismatch: $hasMismatch, ')
          ..write('mismatchExpected: $mismatchExpected, ')
          ..write('mismatchImported: $mismatchImported, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        userId,
        name,
        type,
        balance,
        isDefault,
        createdAt,
        updatedAt,
        bankName,
        openingBalance,
        currency,
        colorTheme,
        icon,
        notes,
        isActive,
        creditLimit,
        availableCredit,
        outstandingBalance,
        statementDate,
        paymentDueDate,
        minAmountDue,
        totalAmountDue,
        lastPayment,
        nextDueDate,
        paymentStatus,
        autoPay,
        isEstimated,
        last4Digits,
        statementCycle,
        enableBillReminder,
        enableSmsTracking,
        verifiedBalance,
        calculatedBalance,
        importedBalance,
        lastSyncedBalance,
        verifiedAt,
        hasMismatch,
        mismatchExpected,
        mismatchImported,
        sortOrder
      ]);
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
          other.updatedAt == this.updatedAt &&
          other.bankName == this.bankName &&
          other.openingBalance == this.openingBalance &&
          other.currency == this.currency &&
          other.colorTheme == this.colorTheme &&
          other.icon == this.icon &&
          other.notes == this.notes &&
          other.isActive == this.isActive &&
          other.creditLimit == this.creditLimit &&
          other.availableCredit == this.availableCredit &&
          other.outstandingBalance == this.outstandingBalance &&
          other.statementDate == this.statementDate &&
          other.paymentDueDate == this.paymentDueDate &&
          other.minAmountDue == this.minAmountDue &&
          other.totalAmountDue == this.totalAmountDue &&
          other.lastPayment == this.lastPayment &&
          other.nextDueDate == this.nextDueDate &&
          other.paymentStatus == this.paymentStatus &&
          other.autoPay == this.autoPay &&
          other.isEstimated == this.isEstimated &&
          other.last4Digits == this.last4Digits &&
          other.statementCycle == this.statementCycle &&
          other.enableBillReminder == this.enableBillReminder &&
          other.enableSmsTracking == this.enableSmsTracking &&
          other.verifiedBalance == this.verifiedBalance &&
          other.calculatedBalance == this.calculatedBalance &&
          other.importedBalance == this.importedBalance &&
          other.lastSyncedBalance == this.lastSyncedBalance &&
          other.verifiedAt == this.verifiedAt &&
          other.hasMismatch == this.hasMismatch &&
          other.mismatchExpected == this.mismatchExpected &&
          other.mismatchImported == this.mismatchImported &&
          other.sortOrder == this.sortOrder);
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
  final Value<String?> bankName;
  final Value<int?> openingBalance;
  final Value<String?> currency;
  final Value<String?> colorTheme;
  final Value<String?> icon;
  final Value<String?> notes;
  final Value<bool?> isActive;
  final Value<int?> creditLimit;
  final Value<int?> availableCredit;
  final Value<int?> outstandingBalance;
  final Value<int?> statementDate;
  final Value<int?> paymentDueDate;
  final Value<int?> minAmountDue;
  final Value<int?> totalAmountDue;
  final Value<int?> lastPayment;
  final Value<DateTime?> nextDueDate;
  final Value<String?> paymentStatus;
  final Value<bool?> autoPay;
  final Value<bool> isEstimated;
  final Value<String?> last4Digits;
  final Value<String?> statementCycle;
  final Value<bool?> enableBillReminder;
  final Value<bool?> enableSmsTracking;
  final Value<int?> verifiedBalance;
  final Value<int?> calculatedBalance;
  final Value<int?> importedBalance;
  final Value<int?> lastSyncedBalance;
  final Value<DateTime?> verifiedAt;
  final Value<bool?> hasMismatch;
  final Value<int?> mismatchExpected;
  final Value<int?> mismatchImported;
  final Value<int?> sortOrder;
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
    this.bankName = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.currency = const Value.absent(),
    this.colorTheme = const Value.absent(),
    this.icon = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.availableCredit = const Value.absent(),
    this.outstandingBalance = const Value.absent(),
    this.statementDate = const Value.absent(),
    this.paymentDueDate = const Value.absent(),
    this.minAmountDue = const Value.absent(),
    this.totalAmountDue = const Value.absent(),
    this.lastPayment = const Value.absent(),
    this.nextDueDate = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.autoPay = const Value.absent(),
    this.isEstimated = const Value.absent(),
    this.last4Digits = const Value.absent(),
    this.statementCycle = const Value.absent(),
    this.enableBillReminder = const Value.absent(),
    this.enableSmsTracking = const Value.absent(),
    this.verifiedBalance = const Value.absent(),
    this.calculatedBalance = const Value.absent(),
    this.importedBalance = const Value.absent(),
    this.lastSyncedBalance = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.hasMismatch = const Value.absent(),
    this.mismatchExpected = const Value.absent(),
    this.mismatchImported = const Value.absent(),
    this.sortOrder = const Value.absent(),
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
    this.bankName = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.currency = const Value.absent(),
    this.colorTheme = const Value.absent(),
    this.icon = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.availableCredit = const Value.absent(),
    this.outstandingBalance = const Value.absent(),
    this.statementDate = const Value.absent(),
    this.paymentDueDate = const Value.absent(),
    this.minAmountDue = const Value.absent(),
    this.totalAmountDue = const Value.absent(),
    this.lastPayment = const Value.absent(),
    this.nextDueDate = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.autoPay = const Value.absent(),
    this.isEstimated = const Value.absent(),
    this.last4Digits = const Value.absent(),
    this.statementCycle = const Value.absent(),
    this.enableBillReminder = const Value.absent(),
    this.enableSmsTracking = const Value.absent(),
    this.verifiedBalance = const Value.absent(),
    this.calculatedBalance = const Value.absent(),
    this.importedBalance = const Value.absent(),
    this.lastSyncedBalance = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.hasMismatch = const Value.absent(),
    this.mismatchExpected = const Value.absent(),
    this.mismatchImported = const Value.absent(),
    this.sortOrder = const Value.absent(),
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
    Expression<String>? bankName,
    Expression<int>? openingBalance,
    Expression<String>? currency,
    Expression<String>? colorTheme,
    Expression<String>? icon,
    Expression<String>? notes,
    Expression<bool>? isActive,
    Expression<int>? creditLimit,
    Expression<int>? availableCredit,
    Expression<int>? outstandingBalance,
    Expression<int>? statementDate,
    Expression<int>? paymentDueDate,
    Expression<int>? minAmountDue,
    Expression<int>? totalAmountDue,
    Expression<int>? lastPayment,
    Expression<DateTime>? nextDueDate,
    Expression<String>? paymentStatus,
    Expression<bool>? autoPay,
    Expression<bool>? isEstimated,
    Expression<String>? last4Digits,
    Expression<String>? statementCycle,
    Expression<bool>? enableBillReminder,
    Expression<bool>? enableSmsTracking,
    Expression<int>? verifiedBalance,
    Expression<int>? calculatedBalance,
    Expression<int>? importedBalance,
    Expression<int>? lastSyncedBalance,
    Expression<DateTime>? verifiedAt,
    Expression<bool>? hasMismatch,
    Expression<int>? mismatchExpected,
    Expression<int>? mismatchImported,
    Expression<int>? sortOrder,
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
      if (bankName != null) 'bank_name': bankName,
      if (openingBalance != null) 'opening_balance': openingBalance,
      if (currency != null) 'currency': currency,
      if (colorTheme != null) 'color_theme': colorTheme,
      if (icon != null) 'icon': icon,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
      if (creditLimit != null) 'credit_limit': creditLimit,
      if (availableCredit != null) 'available_credit': availableCredit,
      if (outstandingBalance != null) 'outstanding_balance': outstandingBalance,
      if (statementDate != null) 'statement_date': statementDate,
      if (paymentDueDate != null) 'payment_due_date': paymentDueDate,
      if (minAmountDue != null) 'min_amount_due': minAmountDue,
      if (totalAmountDue != null) 'total_amount_due': totalAmountDue,
      if (lastPayment != null) 'last_payment': lastPayment,
      if (nextDueDate != null) 'next_due_date': nextDueDate,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (autoPay != null) 'auto_pay': autoPay,
      if (isEstimated != null) 'is_estimated': isEstimated,
      if (last4Digits != null) 'last_4_digits': last4Digits,
      if (statementCycle != null) 'statement_cycle': statementCycle,
      if (enableBillReminder != null)
        'enable_bill_reminder': enableBillReminder,
      if (enableSmsTracking != null) 'enable_sms_tracking': enableSmsTracking,
      if (verifiedBalance != null) 'verified_balance': verifiedBalance,
      if (calculatedBalance != null) 'calculated_balance': calculatedBalance,
      if (importedBalance != null) 'imported_balance': importedBalance,
      if (lastSyncedBalance != null) 'last_synced_balance': lastSyncedBalance,
      if (verifiedAt != null) 'verified_at': verifiedAt,
      if (hasMismatch != null) 'has_mismatch': hasMismatch,
      if (mismatchExpected != null) 'mismatch_expected': mismatchExpected,
      if (mismatchImported != null) 'mismatch_imported': mismatchImported,
      if (sortOrder != null) 'sort_order': sortOrder,
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
      Value<String?>? bankName,
      Value<int?>? openingBalance,
      Value<String?>? currency,
      Value<String?>? colorTheme,
      Value<String?>? icon,
      Value<String?>? notes,
      Value<bool?>? isActive,
      Value<int?>? creditLimit,
      Value<int?>? availableCredit,
      Value<int?>? outstandingBalance,
      Value<int?>? statementDate,
      Value<int?>? paymentDueDate,
      Value<int?>? minAmountDue,
      Value<int?>? totalAmountDue,
      Value<int?>? lastPayment,
      Value<DateTime?>? nextDueDate,
      Value<String?>? paymentStatus,
      Value<bool?>? autoPay,
      Value<bool>? isEstimated,
      Value<String?>? last4Digits,
      Value<String?>? statementCycle,
      Value<bool?>? enableBillReminder,
      Value<bool?>? enableSmsTracking,
      Value<int?>? verifiedBalance,
      Value<int?>? calculatedBalance,
      Value<int?>? importedBalance,
      Value<int?>? lastSyncedBalance,
      Value<DateTime?>? verifiedAt,
      Value<bool?>? hasMismatch,
      Value<int?>? mismatchExpected,
      Value<int?>? mismatchImported,
      Value<int?>? sortOrder,
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
      bankName: bankName ?? this.bankName,
      openingBalance: openingBalance ?? this.openingBalance,
      currency: currency ?? this.currency,
      colorTheme: colorTheme ?? this.colorTheme,
      icon: icon ?? this.icon,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      creditLimit: creditLimit ?? this.creditLimit,
      availableCredit: availableCredit ?? this.availableCredit,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      statementDate: statementDate ?? this.statementDate,
      paymentDueDate: paymentDueDate ?? this.paymentDueDate,
      minAmountDue: minAmountDue ?? this.minAmountDue,
      totalAmountDue: totalAmountDue ?? this.totalAmountDue,
      lastPayment: lastPayment ?? this.lastPayment,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      autoPay: autoPay ?? this.autoPay,
      isEstimated: isEstimated ?? this.isEstimated,
      last4Digits: last4Digits ?? this.last4Digits,
      statementCycle: statementCycle ?? this.statementCycle,
      enableBillReminder: enableBillReminder ?? this.enableBillReminder,
      enableSmsTracking: enableSmsTracking ?? this.enableSmsTracking,
      verifiedBalance: verifiedBalance ?? this.verifiedBalance,
      calculatedBalance: calculatedBalance ?? this.calculatedBalance,
      importedBalance: importedBalance ?? this.importedBalance,
      lastSyncedBalance: lastSyncedBalance ?? this.lastSyncedBalance,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      hasMismatch: hasMismatch ?? this.hasMismatch,
      mismatchExpected: mismatchExpected ?? this.mismatchExpected,
      mismatchImported: mismatchImported ?? this.mismatchImported,
      sortOrder: sortOrder ?? this.sortOrder,
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
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (openingBalance.present) {
      map['opening_balance'] = Variable<int>(openingBalance.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (colorTheme.present) {
      map['color_theme'] = Variable<String>(colorTheme.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<int>(creditLimit.value);
    }
    if (availableCredit.present) {
      map['available_credit'] = Variable<int>(availableCredit.value);
    }
    if (outstandingBalance.present) {
      map['outstanding_balance'] = Variable<int>(outstandingBalance.value);
    }
    if (statementDate.present) {
      map['statement_date'] = Variable<int>(statementDate.value);
    }
    if (paymentDueDate.present) {
      map['payment_due_date'] = Variable<int>(paymentDueDate.value);
    }
    if (minAmountDue.present) {
      map['min_amount_due'] = Variable<int>(minAmountDue.value);
    }
    if (totalAmountDue.present) {
      map['total_amount_due'] = Variable<int>(totalAmountDue.value);
    }
    if (lastPayment.present) {
      map['last_payment'] = Variable<int>(lastPayment.value);
    }
    if (nextDueDate.present) {
      map['next_due_date'] = Variable<DateTime>(nextDueDate.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (autoPay.present) {
      map['auto_pay'] = Variable<bool>(autoPay.value);
    }
    if (isEstimated.present) {
      map['is_estimated'] = Variable<bool>(isEstimated.value);
    }
    if (last4Digits.present) {
      map['last_4_digits'] = Variable<String>(last4Digits.value);
    }
    if (statementCycle.present) {
      map['statement_cycle'] = Variable<String>(statementCycle.value);
    }
    if (enableBillReminder.present) {
      map['enable_bill_reminder'] = Variable<bool>(enableBillReminder.value);
    }
    if (enableSmsTracking.present) {
      map['enable_sms_tracking'] = Variable<bool>(enableSmsTracking.value);
    }
    if (verifiedBalance.present) {
      map['verified_balance'] = Variable<int>(verifiedBalance.value);
    }
    if (calculatedBalance.present) {
      map['calculated_balance'] = Variable<int>(calculatedBalance.value);
    }
    if (importedBalance.present) {
      map['imported_balance'] = Variable<int>(importedBalance.value);
    }
    if (lastSyncedBalance.present) {
      map['last_synced_balance'] = Variable<int>(lastSyncedBalance.value);
    }
    if (verifiedAt.present) {
      map['verified_at'] = Variable<DateTime>(verifiedAt.value);
    }
    if (hasMismatch.present) {
      map['has_mismatch'] = Variable<bool>(hasMismatch.value);
    }
    if (mismatchExpected.present) {
      map['mismatch_expected'] = Variable<int>(mismatchExpected.value);
    }
    if (mismatchImported.present) {
      map['mismatch_imported'] = Variable<int>(mismatchImported.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
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
          ..write('bankName: $bankName, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('currency: $currency, ')
          ..write('colorTheme: $colorTheme, ')
          ..write('icon: $icon, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('availableCredit: $availableCredit, ')
          ..write('outstandingBalance: $outstandingBalance, ')
          ..write('statementDate: $statementDate, ')
          ..write('paymentDueDate: $paymentDueDate, ')
          ..write('minAmountDue: $minAmountDue, ')
          ..write('totalAmountDue: $totalAmountDue, ')
          ..write('lastPayment: $lastPayment, ')
          ..write('nextDueDate: $nextDueDate, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('autoPay: $autoPay, ')
          ..write('isEstimated: $isEstimated, ')
          ..write('last4Digits: $last4Digits, ')
          ..write('statementCycle: $statementCycle, ')
          ..write('enableBillReminder: $enableBillReminder, ')
          ..write('enableSmsTracking: $enableSmsTracking, ')
          ..write('verifiedBalance: $verifiedBalance, ')
          ..write('calculatedBalance: $calculatedBalance, ')
          ..write('importedBalance: $importedBalance, ')
          ..write('lastSyncedBalance: $lastSyncedBalance, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('hasMismatch: $hasMismatch, ')
          ..write('mismatchExpected: $mismatchExpected, ')
          ..write('mismatchImported: $mismatchImported, ')
          ..write('sortOrder: $sortOrder, ')
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
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
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
        name,
        type,
        icon,
        usageCount,
        lastUsedAt,
        isSystemDefault,
        parentId,
        color,
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
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
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
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
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
  final String? parentId;
  final String? color;
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
      this.parentId,
      this.color,
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
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
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
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
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
      parentId: serializer.fromJson<String?>(json['parentId']),
      color: serializer.fromJson<String?>(json['color']),
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
      'parentId': serializer.toJson<String?>(parentId),
      'color': serializer.toJson<String?>(color),
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
          Value<String?> parentId = const Value.absent(),
          Value<String?> color = const Value.absent(),
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
        parentId: parentId.present ? parentId.value : this.parentId,
        color: color.present ? color.value : this.color,
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
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      color: data.color.present ? data.color.value : this.color,
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
          ..write('parentId: $parentId, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, name, type, icon, usageCount,
      lastUsedAt, isSystemDefault, parentId, color, createdAt);
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
          other.parentId == this.parentId &&
          other.color == this.color &&
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
  final Value<String?> parentId;
  final Value<String?> color;
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
    this.parentId = const Value.absent(),
    this.color = const Value.absent(),
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
    this.parentId = const Value.absent(),
    this.color = const Value.absent(),
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
    Expression<String>? parentId,
    Expression<String>? color,
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
      if (parentId != null) 'parent_id': parentId,
      if (color != null) 'color': color,
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
      Value<String?>? parentId,
      Value<String?>? color,
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
      parentId: parentId ?? this.parentId,
      color: color ?? this.color,
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
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
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
          ..write('parentId: $parentId, ')
          ..write('color: $color, ')
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
  static const VerificationMeta _subcategoryIdMeta =
      const VerificationMeta('subcategoryId');
  @override
  late final GeneratedColumn<String> subcategoryId = GeneratedColumn<String>(
      'subcategory_id', aliasedName, true,
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
  static const VerificationMeta _transactionTypeMeta =
      const VerificationMeta('transactionType');
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
      'transaction_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _accountTypeMeta =
      const VerificationMeta('accountType');
  @override
  late final GeneratedColumn<String> accountType = GeneratedColumn<String>(
      'account_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _billStatusMeta =
      const VerificationMeta('billStatus');
  @override
  late final GeneratedColumn<String> billStatus = GeneratedColumn<String>(
      'bill_status', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _referenceNumberMeta =
      const VerificationMeta('referenceNumber');
  @override
  late final GeneratedColumn<String> referenceNumber = GeneratedColumn<String>(
      'reference_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _aiClassificationMeta =
      const VerificationMeta('aiClassification');
  @override
  late final GeneratedColumn<String> aiClassification = GeneratedColumn<String>(
      'ai_classification', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _receiptUrlMeta =
      const VerificationMeta('receiptUrl');
  @override
  late final GeneratedColumn<String> receiptUrl = GeneratedColumn<String>(
      'receipt_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _billLinkMeta =
      const VerificationMeta('billLink');
  @override
  late final GeneratedColumn<String> billLink = GeneratedColumn<String>(
      'bill_link', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fingerprintMeta =
      const VerificationMeta('fingerprint');
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
      'fingerprint', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _supportingSmsMeta =
      const VerificationMeta('supportingSms');
  @override
  late final GeneratedColumn<String> supportingSms = GeneratedColumn<String>(
      'supporting_sms', aliasedName, true,
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
        subcategoryId,
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
        transactionType,
        accountType,
        billStatus,
        dueDate,
        referenceNumber,
        aiClassification,
        receiptUrl,
        billLink,
        tags,
        fingerprint,
        supportingSms,
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
    if (data.containsKey('subcategory_id')) {
      context.handle(
          _subcategoryIdMeta,
          subcategoryId.isAcceptableOrUnknown(
              data['subcategory_id']!, _subcategoryIdMeta));
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
    if (data.containsKey('transaction_type')) {
      context.handle(
          _transactionTypeMeta,
          transactionType.isAcceptableOrUnknown(
              data['transaction_type']!, _transactionTypeMeta));
    }
    if (data.containsKey('account_type')) {
      context.handle(
          _accountTypeMeta,
          accountType.isAcceptableOrUnknown(
              data['account_type']!, _accountTypeMeta));
    }
    if (data.containsKey('bill_status')) {
      context.handle(
          _billStatusMeta,
          billStatus.isAcceptableOrUnknown(
              data['bill_status']!, _billStatusMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('reference_number')) {
      context.handle(
          _referenceNumberMeta,
          referenceNumber.isAcceptableOrUnknown(
              data['reference_number']!, _referenceNumberMeta));
    }
    if (data.containsKey('ai_classification')) {
      context.handle(
          _aiClassificationMeta,
          aiClassification.isAcceptableOrUnknown(
              data['ai_classification']!, _aiClassificationMeta));
    }
    if (data.containsKey('receipt_url')) {
      context.handle(
          _receiptUrlMeta,
          receiptUrl.isAcceptableOrUnknown(
              data['receipt_url']!, _receiptUrlMeta));
    }
    if (data.containsKey('bill_link')) {
      context.handle(_billLinkMeta,
          billLink.isAcceptableOrUnknown(data['bill_link']!, _billLinkMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
          _fingerprintMeta,
          fingerprint.isAcceptableOrUnknown(
              data['fingerprint']!, _fingerprintMeta));
    }
    if (data.containsKey('supporting_sms')) {
      context.handle(
          _supportingSmsMeta,
          supportingSms.isAcceptableOrUnknown(
              data['supporting_sms']!, _supportingSmsMeta));
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
      subcategoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subcategory_id']),
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
      transactionType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}transaction_type']),
      accountType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_type']),
      billStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bill_status']),
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      referenceNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}reference_number']),
      aiClassification: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}ai_classification']),
      receiptUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}receipt_url']),
      billLink: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bill_link']),
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags']),
      fingerprint: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fingerprint']),
      supportingSms: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}supporting_sms']),
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
  final String? subcategoryId;
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
  final String? transactionType;
  final String? accountType;
  final String? billStatus;
  final DateTime? dueDate;
  final String? referenceNumber;
  final String? aiClassification;
  final String? receiptUrl;
  final String? billLink;
  final String? tags;
  final String? fingerprint;
  final String? supportingSms;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Transaction(
      {required this.id,
      required this.userId,
      this.accountId,
      this.categoryId,
      this.subcategoryId,
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
      this.transactionType,
      this.accountType,
      this.billStatus,
      this.dueDate,
      this.referenceNumber,
      this.aiClassification,
      this.receiptUrl,
      this.billLink,
      this.tags,
      this.fingerprint,
      this.supportingSms,
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
    if (!nullToAbsent || subcategoryId != null) {
      map['subcategory_id'] = Variable<String>(subcategoryId);
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
    if (!nullToAbsent || transactionType != null) {
      map['transaction_type'] = Variable<String>(transactionType);
    }
    if (!nullToAbsent || accountType != null) {
      map['account_type'] = Variable<String>(accountType);
    }
    if (!nullToAbsent || billStatus != null) {
      map['bill_status'] = Variable<String>(billStatus);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || referenceNumber != null) {
      map['reference_number'] = Variable<String>(referenceNumber);
    }
    if (!nullToAbsent || aiClassification != null) {
      map['ai_classification'] = Variable<String>(aiClassification);
    }
    if (!nullToAbsent || receiptUrl != null) {
      map['receipt_url'] = Variable<String>(receiptUrl);
    }
    if (!nullToAbsent || billLink != null) {
      map['bill_link'] = Variable<String>(billLink);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || fingerprint != null) {
      map['fingerprint'] = Variable<String>(fingerprint);
    }
    if (!nullToAbsent || supportingSms != null) {
      map['supporting_sms'] = Variable<String>(supportingSms);
    }
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
      subcategoryId: subcategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(subcategoryId),
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
      transactionType: transactionType == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionType),
      accountType: accountType == null && nullToAbsent
          ? const Value.absent()
          : Value(accountType),
      billStatus: billStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(billStatus),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      referenceNumber: referenceNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceNumber),
      aiClassification: aiClassification == null && nullToAbsent
          ? const Value.absent()
          : Value(aiClassification),
      receiptUrl: receiptUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptUrl),
      billLink: billLink == null && nullToAbsent
          ? const Value.absent()
          : Value(billLink),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      fingerprint: fingerprint == null && nullToAbsent
          ? const Value.absent()
          : Value(fingerprint),
      supportingSms: supportingSms == null && nullToAbsent
          ? const Value.absent()
          : Value(supportingSms),
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
      subcategoryId: serializer.fromJson<String?>(json['subcategoryId']),
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
      transactionType: serializer.fromJson<String?>(json['transactionType']),
      accountType: serializer.fromJson<String?>(json['accountType']),
      billStatus: serializer.fromJson<String?>(json['billStatus']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      referenceNumber: serializer.fromJson<String?>(json['referenceNumber']),
      aiClassification: serializer.fromJson<String?>(json['aiClassification']),
      receiptUrl: serializer.fromJson<String?>(json['receiptUrl']),
      billLink: serializer.fromJson<String?>(json['billLink']),
      tags: serializer.fromJson<String?>(json['tags']),
      fingerprint: serializer.fromJson<String?>(json['fingerprint']),
      supportingSms: serializer.fromJson<String?>(json['supportingSms']),
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
      'subcategoryId': serializer.toJson<String?>(subcategoryId),
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
      'transactionType': serializer.toJson<String?>(transactionType),
      'accountType': serializer.toJson<String?>(accountType),
      'billStatus': serializer.toJson<String?>(billStatus),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'referenceNumber': serializer.toJson<String?>(referenceNumber),
      'aiClassification': serializer.toJson<String?>(aiClassification),
      'receiptUrl': serializer.toJson<String?>(receiptUrl),
      'billLink': serializer.toJson<String?>(billLink),
      'tags': serializer.toJson<String?>(tags),
      'fingerprint': serializer.toJson<String?>(fingerprint),
      'supportingSms': serializer.toJson<String?>(supportingSms),
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
          Value<String?> subcategoryId = const Value.absent(),
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
          Value<String?> transactionType = const Value.absent(),
          Value<String?> accountType = const Value.absent(),
          Value<String?> billStatus = const Value.absent(),
          Value<DateTime?> dueDate = const Value.absent(),
          Value<String?> referenceNumber = const Value.absent(),
          Value<String?> aiClassification = const Value.absent(),
          Value<String?> receiptUrl = const Value.absent(),
          Value<String?> billLink = const Value.absent(),
          Value<String?> tags = const Value.absent(),
          Value<String?> fingerprint = const Value.absent(),
          Value<String?> supportingSms = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      Transaction(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        accountId: accountId.present ? accountId.value : this.accountId,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        subcategoryId:
            subcategoryId.present ? subcategoryId.value : this.subcategoryId,
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
        transactionType: transactionType.present
            ? transactionType.value
            : this.transactionType,
        accountType: accountType.present ? accountType.value : this.accountType,
        billStatus: billStatus.present ? billStatus.value : this.billStatus,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        referenceNumber: referenceNumber.present
            ? referenceNumber.value
            : this.referenceNumber,
        aiClassification: aiClassification.present
            ? aiClassification.value
            : this.aiClassification,
        receiptUrl: receiptUrl.present ? receiptUrl.value : this.receiptUrl,
        billLink: billLink.present ? billLink.value : this.billLink,
        tags: tags.present ? tags.value : this.tags,
        fingerprint: fingerprint.present ? fingerprint.value : this.fingerprint,
        supportingSms:
            supportingSms.present ? supportingSms.value : this.supportingSms,
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
      subcategoryId: data.subcategoryId.present
          ? data.subcategoryId.value
          : this.subcategoryId,
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
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      accountType:
          data.accountType.present ? data.accountType.value : this.accountType,
      billStatus:
          data.billStatus.present ? data.billStatus.value : this.billStatus,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      referenceNumber: data.referenceNumber.present
          ? data.referenceNumber.value
          : this.referenceNumber,
      aiClassification: data.aiClassification.present
          ? data.aiClassification.value
          : this.aiClassification,
      receiptUrl:
          data.receiptUrl.present ? data.receiptUrl.value : this.receiptUrl,
      billLink: data.billLink.present ? data.billLink.value : this.billLink,
      tags: data.tags.present ? data.tags.value : this.tags,
      fingerprint:
          data.fingerprint.present ? data.fingerprint.value : this.fingerprint,
      supportingSms: data.supportingSms.present
          ? data.supportingSms.value
          : this.supportingSms,
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
          ..write('subcategoryId: $subcategoryId, ')
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
          ..write('transactionType: $transactionType, ')
          ..write('accountType: $accountType, ')
          ..write('billStatus: $billStatus, ')
          ..write('dueDate: $dueDate, ')
          ..write('referenceNumber: $referenceNumber, ')
          ..write('aiClassification: $aiClassification, ')
          ..write('receiptUrl: $receiptUrl, ')
          ..write('billLink: $billLink, ')
          ..write('tags: $tags, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('supportingSms: $supportingSms, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        userId,
        accountId,
        categoryId,
        subcategoryId,
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
        transactionType,
        accountType,
        billStatus,
        dueDate,
        referenceNumber,
        aiClassification,
        receiptUrl,
        billLink,
        tags,
        fingerprint,
        supportingSms,
        createdAt,
        updatedAt,
        deletedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.accountId == this.accountId &&
          other.categoryId == this.categoryId &&
          other.subcategoryId == this.subcategoryId &&
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
          other.transactionType == this.transactionType &&
          other.accountType == this.accountType &&
          other.billStatus == this.billStatus &&
          other.dueDate == this.dueDate &&
          other.referenceNumber == this.referenceNumber &&
          other.aiClassification == this.aiClassification &&
          other.receiptUrl == this.receiptUrl &&
          other.billLink == this.billLink &&
          other.tags == this.tags &&
          other.fingerprint == this.fingerprint &&
          other.supportingSms == this.supportingSms &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> accountId;
  final Value<String?> categoryId;
  final Value<String?> subcategoryId;
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
  final Value<String?> transactionType;
  final Value<String?> accountType;
  final Value<String?> billStatus;
  final Value<DateTime?> dueDate;
  final Value<String?> referenceNumber;
  final Value<String?> aiClassification;
  final Value<String?> receiptUrl;
  final Value<String?> billLink;
  final Value<String?> tags;
  final Value<String?> fingerprint;
  final Value<String?> supportingSms;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.subcategoryId = const Value.absent(),
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
    this.transactionType = const Value.absent(),
    this.accountType = const Value.absent(),
    this.billStatus = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.referenceNumber = const Value.absent(),
    this.aiClassification = const Value.absent(),
    this.receiptUrl = const Value.absent(),
    this.billLink = const Value.absent(),
    this.tags = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.supportingSms = const Value.absent(),
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
    this.subcategoryId = const Value.absent(),
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
    this.transactionType = const Value.absent(),
    this.accountType = const Value.absent(),
    this.billStatus = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.referenceNumber = const Value.absent(),
    this.aiClassification = const Value.absent(),
    this.receiptUrl = const Value.absent(),
    this.billLink = const Value.absent(),
    this.tags = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.supportingSms = const Value.absent(),
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
    Expression<String>? subcategoryId,
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
    Expression<String>? transactionType,
    Expression<String>? accountType,
    Expression<String>? billStatus,
    Expression<DateTime>? dueDate,
    Expression<String>? referenceNumber,
    Expression<String>? aiClassification,
    Expression<String>? receiptUrl,
    Expression<String>? billLink,
    Expression<String>? tags,
    Expression<String>? fingerprint,
    Expression<String>? supportingSms,
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
      if (subcategoryId != null) 'subcategory_id': subcategoryId,
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
      if (transactionType != null) 'transaction_type': transactionType,
      if (accountType != null) 'account_type': accountType,
      if (billStatus != null) 'bill_status': billStatus,
      if (dueDate != null) 'due_date': dueDate,
      if (referenceNumber != null) 'reference_number': referenceNumber,
      if (aiClassification != null) 'ai_classification': aiClassification,
      if (receiptUrl != null) 'receipt_url': receiptUrl,
      if (billLink != null) 'bill_link': billLink,
      if (tags != null) 'tags': tags,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (supportingSms != null) 'supporting_sms': supportingSms,
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
      Value<String?>? subcategoryId,
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
      Value<String?>? transactionType,
      Value<String?>? accountType,
      Value<String?>? billStatus,
      Value<DateTime?>? dueDate,
      Value<String?>? referenceNumber,
      Value<String?>? aiClassification,
      Value<String?>? receiptUrl,
      Value<String?>? billLink,
      Value<String?>? tags,
      Value<String?>? fingerprint,
      Value<String?>? supportingSms,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<int>? rowid}) {
    return TransactionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
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
      transactionType: transactionType ?? this.transactionType,
      accountType: accountType ?? this.accountType,
      billStatus: billStatus ?? this.billStatus,
      dueDate: dueDate ?? this.dueDate,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      aiClassification: aiClassification ?? this.aiClassification,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      billLink: billLink ?? this.billLink,
      tags: tags ?? this.tags,
      fingerprint: fingerprint ?? this.fingerprint,
      supportingSms: supportingSms ?? this.supportingSms,
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
    if (subcategoryId.present) {
      map['subcategory_id'] = Variable<String>(subcategoryId.value);
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
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (accountType.present) {
      map['account_type'] = Variable<String>(accountType.value);
    }
    if (billStatus.present) {
      map['bill_status'] = Variable<String>(billStatus.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (referenceNumber.present) {
      map['reference_number'] = Variable<String>(referenceNumber.value);
    }
    if (aiClassification.present) {
      map['ai_classification'] = Variable<String>(aiClassification.value);
    }
    if (receiptUrl.present) {
      map['receipt_url'] = Variable<String>(receiptUrl.value);
    }
    if (billLink.present) {
      map['bill_link'] = Variable<String>(billLink.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (supportingSms.present) {
      map['supporting_sms'] = Variable<String>(supportingSms.value);
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
          ..write('subcategoryId: $subcategoryId, ')
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
          ..write('transactionType: $transactionType, ')
          ..write('accountType: $accountType, ')
          ..write('billStatus: $billStatus, ')
          ..write('dueDate: $dueDate, ')
          ..write('referenceNumber: $referenceNumber, ')
          ..write('aiClassification: $aiClassification, ')
          ..write('receiptUrl: $receiptUrl, ')
          ..write('billLink: $billLink, ')
          ..write('tags: $tags, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('supportingSms: $supportingSms, ')
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
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _confidenceScoreMeta =
      const VerificationMeta('confidenceScore');
  @override
  late final GeneratedColumn<double> confidenceScore = GeneratedColumn<double>(
      'confidence_score', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _matchingTransactionIdMeta =
      const VerificationMeta('matchingTransactionId');
  @override
  late final GeneratedColumn<String> matchingTransactionId =
      GeneratedColumn<String>('matching_transaction_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _supportingSmsMeta =
      const VerificationMeta('supportingSms');
  @override
  late final GeneratedColumn<String> supportingSms = GeneratedColumn<String>(
      'supporting_sms', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
        createdAt,
        categoryId,
        category,
        confidenceScore,
        matchingTransactionId,
        supportingSms
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
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('confidence_score')) {
      context.handle(
          _confidenceScoreMeta,
          confidenceScore.isAcceptableOrUnknown(
              data['confidence_score']!, _confidenceScoreMeta));
    }
    if (data.containsKey('matching_transaction_id')) {
      context.handle(
          _matchingTransactionIdMeta,
          matchingTransactionId.isAcceptableOrUnknown(
              data['matching_transaction_id']!, _matchingTransactionIdMeta));
    }
    if (data.containsKey('supporting_sms')) {
      context.handle(
          _supportingSmsMeta,
          supportingSms.isAcceptableOrUnknown(
              data['supporting_sms']!, _supportingSmsMeta));
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
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      confidenceScore: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}confidence_score']),
      matchingTransactionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}matching_transaction_id']),
      supportingSms: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}supporting_sms']),
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
  final String? categoryId;
  final String? category;
  final double? confidenceScore;
  final String? matchingTransactionId;
  final String? supportingSms;
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
      required this.createdAt,
      this.categoryId,
      this.category,
      this.confidenceScore,
      this.matchingTransactionId,
      this.supportingSms});
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
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || confidenceScore != null) {
      map['confidence_score'] = Variable<double>(confidenceScore);
    }
    if (!nullToAbsent || matchingTransactionId != null) {
      map['matching_transaction_id'] = Variable<String>(matchingTransactionId);
    }
    if (!nullToAbsent || supportingSms != null) {
      map['supporting_sms'] = Variable<String>(supportingSms);
    }
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
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      confidenceScore: confidenceScore == null && nullToAbsent
          ? const Value.absent()
          : Value(confidenceScore),
      matchingTransactionId: matchingTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(matchingTransactionId),
      supportingSms: supportingSms == null && nullToAbsent
          ? const Value.absent()
          : Value(supportingSms),
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
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      category: serializer.fromJson<String?>(json['category']),
      confidenceScore: serializer.fromJson<double?>(json['confidenceScore']),
      matchingTransactionId:
          serializer.fromJson<String?>(json['matchingTransactionId']),
      supportingSms: serializer.fromJson<String?>(json['supportingSms']),
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
      'categoryId': serializer.toJson<String?>(categoryId),
      'category': serializer.toJson<String?>(category),
      'confidenceScore': serializer.toJson<double?>(confidenceScore),
      'matchingTransactionId':
          serializer.toJson<String?>(matchingTransactionId),
      'supportingSms': serializer.toJson<String?>(supportingSms),
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
          DateTime? createdAt,
          Value<String?> categoryId = const Value.absent(),
          Value<String?> category = const Value.absent(),
          Value<double?> confidenceScore = const Value.absent(),
          Value<String?> matchingTransactionId = const Value.absent(),
          Value<String?> supportingSms = const Value.absent()}) =>
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
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        category: category.present ? category.value : this.category,
        confidenceScore: confidenceScore.present
            ? confidenceScore.value
            : this.confidenceScore,
        matchingTransactionId: matchingTransactionId.present
            ? matchingTransactionId.value
            : this.matchingTransactionId,
        supportingSms:
            supportingSms.present ? supportingSms.value : this.supportingSms,
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
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      category: data.category.present ? data.category.value : this.category,
      confidenceScore: data.confidenceScore.present
          ? data.confidenceScore.value
          : this.confidenceScore,
      matchingTransactionId: data.matchingTransactionId.present
          ? data.matchingTransactionId.value
          : this.matchingTransactionId,
      supportingSms: data.supportingSms.present
          ? data.supportingSms.value
          : this.supportingSms,
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
          ..write('createdAt: $createdAt, ')
          ..write('categoryId: $categoryId, ')
          ..write('category: $category, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('matchingTransactionId: $matchingTransactionId, ')
          ..write('supportingSms: $supportingSms')
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
      createdAt,
      categoryId,
      category,
      confidenceScore,
      matchingTransactionId,
      supportingSms);
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
          other.createdAt == this.createdAt &&
          other.categoryId == this.categoryId &&
          other.category == this.category &&
          other.confidenceScore == this.confidenceScore &&
          other.matchingTransactionId == this.matchingTransactionId &&
          other.supportingSms == this.supportingSms);
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
  final Value<String?> categoryId;
  final Value<String?> category;
  final Value<double?> confidenceScore;
  final Value<String?> matchingTransactionId;
  final Value<String?> supportingSms;
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
    this.categoryId = const Value.absent(),
    this.category = const Value.absent(),
    this.confidenceScore = const Value.absent(),
    this.matchingTransactionId = const Value.absent(),
    this.supportingSms = const Value.absent(),
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
    this.categoryId = const Value.absent(),
    this.category = const Value.absent(),
    this.confidenceScore = const Value.absent(),
    this.matchingTransactionId = const Value.absent(),
    this.supportingSms = const Value.absent(),
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
    Expression<String>? categoryId,
    Expression<String>? category,
    Expression<double>? confidenceScore,
    Expression<String>? matchingTransactionId,
    Expression<String>? supportingSms,
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
      if (categoryId != null) 'category_id': categoryId,
      if (category != null) 'category': category,
      if (confidenceScore != null) 'confidence_score': confidenceScore,
      if (matchingTransactionId != null)
        'matching_transaction_id': matchingTransactionId,
      if (supportingSms != null) 'supporting_sms': supportingSms,
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
      Value<String?>? categoryId,
      Value<String?>? category,
      Value<double?>? confidenceScore,
      Value<String?>? matchingTransactionId,
      Value<String?>? supportingSms,
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
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      matchingTransactionId:
          matchingTransactionId ?? this.matchingTransactionId,
      supportingSms: supportingSms ?? this.supportingSms,
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
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (confidenceScore.present) {
      map['confidence_score'] = Variable<double>(confidenceScore.value);
    }
    if (matchingTransactionId.present) {
      map['matching_transaction_id'] =
          Variable<String>(matchingTransactionId.value);
    }
    if (supportingSms.present) {
      map['supporting_sms'] = Variable<String>(supportingSms.value);
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
          ..write('categoryId: $categoryId, ')
          ..write('category: $category, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('matchingTransactionId: $matchingTransactionId, ')
          ..write('supportingSms: $supportingSms, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetAmountMeta =
      const VerificationMeta('targetAmount');
  @override
  late final GeneratedColumn<int> targetAmount = GeneratedColumn<int>(
      'target_amount', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _currentAmountMeta =
      const VerificationMeta('currentAmount');
  @override
  late final GeneratedColumn<int> currentAmount = GeneratedColumn<int>(
      'current_amount', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _targetDateMeta =
      const VerificationMeta('targetDate');
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
      'target_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
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
        title,
        targetAmount,
        currentAmount,
        targetDate,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(Insertable<Goal> instance,
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
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('target_amount')) {
      context.handle(
          _targetAmountMeta,
          targetAmount.isAcceptableOrUnknown(
              data['target_amount']!, _targetAmountMeta));
    } else if (isInserting) {
      context.missing(_targetAmountMeta);
    }
    if (data.containsKey('current_amount')) {
      context.handle(
          _currentAmountMeta,
          currentAmount.isAcceptableOrUnknown(
              data['current_amount']!, _currentAmountMeta));
    } else if (isInserting) {
      context.missing(_currentAmountMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
          _targetDateMeta,
          targetDate.isAcceptableOrUnknown(
              data['target_date']!, _targetDateMeta));
    } else if (isInserting) {
      context.missing(_targetDateMeta);
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
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      targetAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_amount'])!,
      currentAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_amount'])!,
      targetDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}target_date'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class Goal extends DataClass implements Insertable<Goal> {
  final String id;
  final String userId;
  final String title;
  final int targetAmount;
  final int currentAmount;
  final DateTime targetDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Goal(
      {required this.id,
      required this.userId,
      required this.title,
      required this.targetAmount,
      required this.currentAmount,
      required this.targetDate,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['title'] = Variable<String>(title);
    map['target_amount'] = Variable<int>(targetAmount);
    map['current_amount'] = Variable<int>(currentAmount);
    map['target_date'] = Variable<DateTime>(targetDate);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      targetAmount: Value(targetAmount),
      currentAmount: Value(currentAmount),
      targetDate: Value(targetDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Goal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      targetAmount: serializer.fromJson<int>(json['targetAmount']),
      currentAmount: serializer.fromJson<int>(json['currentAmount']),
      targetDate: serializer.fromJson<DateTime>(json['targetDate']),
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
      'title': serializer.toJson<String>(title),
      'targetAmount': serializer.toJson<int>(targetAmount),
      'currentAmount': serializer.toJson<int>(currentAmount),
      'targetDate': serializer.toJson<DateTime>(targetDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Goal copyWith(
          {String? id,
          String? userId,
          String? title,
          int? targetAmount,
          int? currentAmount,
          DateTime? targetDate,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Goal(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        targetAmount: targetAmount ?? this.targetAmount,
        currentAmount: currentAmount ?? this.currentAmount,
        targetDate: targetDate ?? this.targetDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      targetAmount: data.targetAmount.present
          ? data.targetAmount.value
          : this.targetAmount,
      currentAmount: data.currentAmount.present
          ? data.currentAmount.value
          : this.currentAmount,
      targetDate:
          data.targetDate.present ? data.targetDate.value : this.targetDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('currentAmount: $currentAmount, ')
          ..write('targetDate: $targetDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, title, targetAmount,
      currentAmount, targetDate, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.targetAmount == this.targetAmount &&
          other.currentAmount == this.currentAmount &&
          other.targetDate == this.targetDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> title;
  final Value<int> targetAmount;
  final Value<int> currentAmount;
  final Value<DateTime> targetDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.currentAmount = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    required String userId,
    required String title,
    required int targetAmount,
    required int currentAmount,
    required DateTime targetDate,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        title = Value(title),
        targetAmount = Value(targetAmount),
        currentAmount = Value(currentAmount),
        targetDate = Value(targetDate),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Goal> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<int>? targetAmount,
    Expression<int>? currentAmount,
    Expression<DateTime>? targetDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (currentAmount != null) 'current_amount': currentAmount,
      if (targetDate != null) 'target_date': targetDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? title,
      Value<int>? targetAmount,
      Value<int>? currentAmount,
      Value<DateTime>? targetDate,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return GoalsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (targetAmount.present) {
      map['target_amount'] = Variable<int>(targetAmount.value);
    }
    if (currentAmount.present) {
      map['current_amount'] = Variable<int>(currentAmount.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
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
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('currentAmount: $currentAmount, ')
          ..write('targetDate: $targetDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SubscriptionsTable extends Subscriptions
    with TableInfo<$SubscriptionsTable, Subscription> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubscriptionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _monthlyCostMeta =
      const VerificationMeta('monthlyCost');
  @override
  late final GeneratedColumn<int> monthlyCost = GeneratedColumn<int>(
      'monthly_cost', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _annualCostMeta =
      const VerificationMeta('annualCost');
  @override
  late final GeneratedColumn<int> annualCost = GeneratedColumn<int>(
      'annual_cost', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _billingCycleMeta =
      const VerificationMeta('billingCycle');
  @override
  late final GeneratedColumn<String> billingCycle = GeneratedColumn<String>(
      'billing_cycle', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _renewalDateMeta =
      const VerificationMeta('renewalDate');
  @override
  late final GeneratedColumn<DateTime> renewalDate = GeneratedColumn<DateTime>(
      'renewal_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _providerNameMeta =
      const VerificationMeta('providerName');
  @override
  late final GeneratedColumn<String> providerName = GeneratedColumn<String>(
      'provider_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _confidenceMeta =
      const VerificationMeta('confidence');
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
      'confidence', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
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
        title,
        monthlyCost,
        annualCost,
        billingCycle,
        renewalDate,
        providerName,
        confidence,
        status,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subscriptions';
  @override
  VerificationContext validateIntegrity(Insertable<Subscription> instance,
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
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('monthly_cost')) {
      context.handle(
          _monthlyCostMeta,
          monthlyCost.isAcceptableOrUnknown(
              data['monthly_cost']!, _monthlyCostMeta));
    } else if (isInserting) {
      context.missing(_monthlyCostMeta);
    }
    if (data.containsKey('annual_cost')) {
      context.handle(
          _annualCostMeta,
          annualCost.isAcceptableOrUnknown(
              data['annual_cost']!, _annualCostMeta));
    } else if (isInserting) {
      context.missing(_annualCostMeta);
    }
    if (data.containsKey('billing_cycle')) {
      context.handle(
          _billingCycleMeta,
          billingCycle.isAcceptableOrUnknown(
              data['billing_cycle']!, _billingCycleMeta));
    } else if (isInserting) {
      context.missing(_billingCycleMeta);
    }
    if (data.containsKey('renewal_date')) {
      context.handle(
          _renewalDateMeta,
          renewalDate.isAcceptableOrUnknown(
              data['renewal_date']!, _renewalDateMeta));
    } else if (isInserting) {
      context.missing(_renewalDateMeta);
    }
    if (data.containsKey('provider_name')) {
      context.handle(
          _providerNameMeta,
          providerName.isAcceptableOrUnknown(
              data['provider_name']!, _providerNameMeta));
    } else if (isInserting) {
      context.missing(_providerNameMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
          _confidenceMeta,
          confidence.isAcceptableOrUnknown(
              data['confidence']!, _confidenceMeta));
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
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
  Subscription map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subscription(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      monthlyCost: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}monthly_cost'])!,
      annualCost: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}annual_cost'])!,
      billingCycle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}billing_cycle'])!,
      renewalDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}renewal_date'])!,
      providerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_name'])!,
      confidence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}confidence'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SubscriptionsTable createAlias(String alias) {
    return $SubscriptionsTable(attachedDatabase, alias);
  }
}

class Subscription extends DataClass implements Insertable<Subscription> {
  final String id;
  final String userId;
  final String title;
  final int monthlyCost;
  final int annualCost;
  final String billingCycle;
  final DateTime renewalDate;
  final String providerName;
  final double confidence;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Subscription(
      {required this.id,
      required this.userId,
      required this.title,
      required this.monthlyCost,
      required this.annualCost,
      required this.billingCycle,
      required this.renewalDate,
      required this.providerName,
      required this.confidence,
      required this.status,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['title'] = Variable<String>(title);
    map['monthly_cost'] = Variable<int>(monthlyCost);
    map['annual_cost'] = Variable<int>(annualCost);
    map['billing_cycle'] = Variable<String>(billingCycle);
    map['renewal_date'] = Variable<DateTime>(renewalDate);
    map['provider_name'] = Variable<String>(providerName);
    map['confidence'] = Variable<double>(confidence);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SubscriptionsCompanion toCompanion(bool nullToAbsent) {
    return SubscriptionsCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      monthlyCost: Value(monthlyCost),
      annualCost: Value(annualCost),
      billingCycle: Value(billingCycle),
      renewalDate: Value(renewalDate),
      providerName: Value(providerName),
      confidence: Value(confidence),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Subscription.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subscription(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      monthlyCost: serializer.fromJson<int>(json['monthlyCost']),
      annualCost: serializer.fromJson<int>(json['annualCost']),
      billingCycle: serializer.fromJson<String>(json['billingCycle']),
      renewalDate: serializer.fromJson<DateTime>(json['renewalDate']),
      providerName: serializer.fromJson<String>(json['providerName']),
      confidence: serializer.fromJson<double>(json['confidence']),
      status: serializer.fromJson<String>(json['status']),
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
      'title': serializer.toJson<String>(title),
      'monthlyCost': serializer.toJson<int>(monthlyCost),
      'annualCost': serializer.toJson<int>(annualCost),
      'billingCycle': serializer.toJson<String>(billingCycle),
      'renewalDate': serializer.toJson<DateTime>(renewalDate),
      'providerName': serializer.toJson<String>(providerName),
      'confidence': serializer.toJson<double>(confidence),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Subscription copyWith(
          {String? id,
          String? userId,
          String? title,
          int? monthlyCost,
          int? annualCost,
          String? billingCycle,
          DateTime? renewalDate,
          String? providerName,
          double? confidence,
          String? status,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Subscription(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        monthlyCost: monthlyCost ?? this.monthlyCost,
        annualCost: annualCost ?? this.annualCost,
        billingCycle: billingCycle ?? this.billingCycle,
        renewalDate: renewalDate ?? this.renewalDate,
        providerName: providerName ?? this.providerName,
        confidence: confidence ?? this.confidence,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Subscription copyWithCompanion(SubscriptionsCompanion data) {
    return Subscription(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      monthlyCost:
          data.monthlyCost.present ? data.monthlyCost.value : this.monthlyCost,
      annualCost:
          data.annualCost.present ? data.annualCost.value : this.annualCost,
      billingCycle: data.billingCycle.present
          ? data.billingCycle.value
          : this.billingCycle,
      renewalDate:
          data.renewalDate.present ? data.renewalDate.value : this.renewalDate,
      providerName: data.providerName.present
          ? data.providerName.value
          : this.providerName,
      confidence:
          data.confidence.present ? data.confidence.value : this.confidence,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subscription(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('monthlyCost: $monthlyCost, ')
          ..write('annualCost: $annualCost, ')
          ..write('billingCycle: $billingCycle, ')
          ..write('renewalDate: $renewalDate, ')
          ..write('providerName: $providerName, ')
          ..write('confidence: $confidence, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      title,
      monthlyCost,
      annualCost,
      billingCycle,
      renewalDate,
      providerName,
      confidence,
      status,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subscription &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.monthlyCost == this.monthlyCost &&
          other.annualCost == this.annualCost &&
          other.billingCycle == this.billingCycle &&
          other.renewalDate == this.renewalDate &&
          other.providerName == this.providerName &&
          other.confidence == this.confidence &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SubscriptionsCompanion extends UpdateCompanion<Subscription> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> title;
  final Value<int> monthlyCost;
  final Value<int> annualCost;
  final Value<String> billingCycle;
  final Value<DateTime> renewalDate;
  final Value<String> providerName;
  final Value<double> confidence;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SubscriptionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.monthlyCost = const Value.absent(),
    this.annualCost = const Value.absent(),
    this.billingCycle = const Value.absent(),
    this.renewalDate = const Value.absent(),
    this.providerName = const Value.absent(),
    this.confidence = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubscriptionsCompanion.insert({
    required String id,
    required String userId,
    required String title,
    required int monthlyCost,
    required int annualCost,
    required String billingCycle,
    required DateTime renewalDate,
    required String providerName,
    required double confidence,
    required String status,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        title = Value(title),
        monthlyCost = Value(monthlyCost),
        annualCost = Value(annualCost),
        billingCycle = Value(billingCycle),
        renewalDate = Value(renewalDate),
        providerName = Value(providerName),
        confidence = Value(confidence),
        status = Value(status),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Subscription> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<int>? monthlyCost,
    Expression<int>? annualCost,
    Expression<String>? billingCycle,
    Expression<DateTime>? renewalDate,
    Expression<String>? providerName,
    Expression<double>? confidence,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (monthlyCost != null) 'monthly_cost': monthlyCost,
      if (annualCost != null) 'annual_cost': annualCost,
      if (billingCycle != null) 'billing_cycle': billingCycle,
      if (renewalDate != null) 'renewal_date': renewalDate,
      if (providerName != null) 'provider_name': providerName,
      if (confidence != null) 'confidence': confidence,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubscriptionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? title,
      Value<int>? monthlyCost,
      Value<int>? annualCost,
      Value<String>? billingCycle,
      Value<DateTime>? renewalDate,
      Value<String>? providerName,
      Value<double>? confidence,
      Value<String>? status,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SubscriptionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      monthlyCost: monthlyCost ?? this.monthlyCost,
      annualCost: annualCost ?? this.annualCost,
      billingCycle: billingCycle ?? this.billingCycle,
      renewalDate: renewalDate ?? this.renewalDate,
      providerName: providerName ?? this.providerName,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (monthlyCost.present) {
      map['monthly_cost'] = Variable<int>(monthlyCost.value);
    }
    if (annualCost.present) {
      map['annual_cost'] = Variable<int>(annualCost.value);
    }
    if (billingCycle.present) {
      map['billing_cycle'] = Variable<String>(billingCycle.value);
    }
    if (renewalDate.present) {
      map['renewal_date'] = Variable<DateTime>(renewalDate.value);
    }
    if (providerName.present) {
      map['provider_name'] = Variable<String>(providerName.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
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
    return (StringBuffer('SubscriptionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('monthlyCost: $monthlyCost, ')
          ..write('annualCost: $annualCost, ')
          ..write('billingCycle: $billingCycle, ')
          ..write('renewalDate: $renewalDate, ')
          ..write('providerName: $providerName, ')
          ..write('confidence: $confidence, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FinancialReportsTable extends FinancialReports
    with TableInfo<$FinancialReportsTable, FinancialReport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinancialReportsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _summaryTextMeta =
      const VerificationMeta('summaryText');
  @override
  late final GeneratedColumn<String> summaryText = GeneratedColumn<String>(
      'summary_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jsonPayloadMeta =
      const VerificationMeta('jsonPayload');
  @override
  late final GeneratedColumn<String> jsonPayload = GeneratedColumn<String>(
      'json_payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _exportedFilePathMeta =
      const VerificationMeta('exportedFilePath');
  @override
  late final GeneratedColumn<String> exportedFilePath = GeneratedColumn<String>(
      'exported_file_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, type, summaryText, jsonPayload, exportedFilePath, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'financial_reports';
  @override
  VerificationContext validateIntegrity(Insertable<FinancialReport> instance,
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
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('summary_text')) {
      context.handle(
          _summaryTextMeta,
          summaryText.isAcceptableOrUnknown(
              data['summary_text']!, _summaryTextMeta));
    } else if (isInserting) {
      context.missing(_summaryTextMeta);
    }
    if (data.containsKey('json_payload')) {
      context.handle(
          _jsonPayloadMeta,
          jsonPayload.isAcceptableOrUnknown(
              data['json_payload']!, _jsonPayloadMeta));
    } else if (isInserting) {
      context.missing(_jsonPayloadMeta);
    }
    if (data.containsKey('exported_file_path')) {
      context.handle(
          _exportedFilePathMeta,
          exportedFilePath.isAcceptableOrUnknown(
              data['exported_file_path']!, _exportedFilePathMeta));
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
  FinancialReport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinancialReport(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      summaryText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}summary_text'])!,
      jsonPayload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}json_payload'])!,
      exportedFilePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}exported_file_path']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $FinancialReportsTable createAlias(String alias) {
    return $FinancialReportsTable(attachedDatabase, alias);
  }
}

class FinancialReport extends DataClass implements Insertable<FinancialReport> {
  final String id;
  final String userId;
  final String type;
  final String summaryText;
  final String jsonPayload;
  final String? exportedFilePath;
  final DateTime createdAt;
  const FinancialReport(
      {required this.id,
      required this.userId,
      required this.type,
      required this.summaryText,
      required this.jsonPayload,
      this.exportedFilePath,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['type'] = Variable<String>(type);
    map['summary_text'] = Variable<String>(summaryText);
    map['json_payload'] = Variable<String>(jsonPayload);
    if (!nullToAbsent || exportedFilePath != null) {
      map['exported_file_path'] = Variable<String>(exportedFilePath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FinancialReportsCompanion toCompanion(bool nullToAbsent) {
    return FinancialReportsCompanion(
      id: Value(id),
      userId: Value(userId),
      type: Value(type),
      summaryText: Value(summaryText),
      jsonPayload: Value(jsonPayload),
      exportedFilePath: exportedFilePath == null && nullToAbsent
          ? const Value.absent()
          : Value(exportedFilePath),
      createdAt: Value(createdAt),
    );
  }

  factory FinancialReport.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinancialReport(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      type: serializer.fromJson<String>(json['type']),
      summaryText: serializer.fromJson<String>(json['summaryText']),
      jsonPayload: serializer.fromJson<String>(json['jsonPayload']),
      exportedFilePath: serializer.fromJson<String?>(json['exportedFilePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'type': serializer.toJson<String>(type),
      'summaryText': serializer.toJson<String>(summaryText),
      'jsonPayload': serializer.toJson<String>(jsonPayload),
      'exportedFilePath': serializer.toJson<String?>(exportedFilePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FinancialReport copyWith(
          {String? id,
          String? userId,
          String? type,
          String? summaryText,
          String? jsonPayload,
          Value<String?> exportedFilePath = const Value.absent(),
          DateTime? createdAt}) =>
      FinancialReport(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        type: type ?? this.type,
        summaryText: summaryText ?? this.summaryText,
        jsonPayload: jsonPayload ?? this.jsonPayload,
        exportedFilePath: exportedFilePath.present
            ? exportedFilePath.value
            : this.exportedFilePath,
        createdAt: createdAt ?? this.createdAt,
      );
  FinancialReport copyWithCompanion(FinancialReportsCompanion data) {
    return FinancialReport(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      type: data.type.present ? data.type.value : this.type,
      summaryText:
          data.summaryText.present ? data.summaryText.value : this.summaryText,
      jsonPayload:
          data.jsonPayload.present ? data.jsonPayload.value : this.jsonPayload,
      exportedFilePath: data.exportedFilePath.present
          ? data.exportedFilePath.value
          : this.exportedFilePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinancialReport(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('summaryText: $summaryText, ')
          ..write('jsonPayload: $jsonPayload, ')
          ..write('exportedFilePath: $exportedFilePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, userId, type, summaryText, jsonPayload, exportedFilePath, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinancialReport &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.type == this.type &&
          other.summaryText == this.summaryText &&
          other.jsonPayload == this.jsonPayload &&
          other.exportedFilePath == this.exportedFilePath &&
          other.createdAt == this.createdAt);
}

class FinancialReportsCompanion extends UpdateCompanion<FinancialReport> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> type;
  final Value<String> summaryText;
  final Value<String> jsonPayload;
  final Value<String?> exportedFilePath;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FinancialReportsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.type = const Value.absent(),
    this.summaryText = const Value.absent(),
    this.jsonPayload = const Value.absent(),
    this.exportedFilePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FinancialReportsCompanion.insert({
    required String id,
    required String userId,
    required String type,
    required String summaryText,
    required String jsonPayload,
    this.exportedFilePath = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        type = Value(type),
        summaryText = Value(summaryText),
        jsonPayload = Value(jsonPayload),
        createdAt = Value(createdAt);
  static Insertable<FinancialReport> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? type,
    Expression<String>? summaryText,
    Expression<String>? jsonPayload,
    Expression<String>? exportedFilePath,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (type != null) 'type': type,
      if (summaryText != null) 'summary_text': summaryText,
      if (jsonPayload != null) 'json_payload': jsonPayload,
      if (exportedFilePath != null) 'exported_file_path': exportedFilePath,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FinancialReportsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? type,
      Value<String>? summaryText,
      Value<String>? jsonPayload,
      Value<String?>? exportedFilePath,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return FinancialReportsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      summaryText: summaryText ?? this.summaryText,
      jsonPayload: jsonPayload ?? this.jsonPayload,
      exportedFilePath: exportedFilePath ?? this.exportedFilePath,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (summaryText.present) {
      map['summary_text'] = Variable<String>(summaryText.value);
    }
    if (jsonPayload.present) {
      map['json_payload'] = Variable<String>(jsonPayload.value);
    }
    if (exportedFilePath.present) {
      map['exported_file_path'] = Variable<String>(exportedFilePath.value);
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
    return (StringBuffer('FinancialReportsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('summaryText: $summaryText, ')
          ..write('jsonPayload: $jsonPayload, ')
          ..write('exportedFilePath: $exportedFilePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AgentLogsTable extends AgentLogs
    with TableInfo<$AgentLogsTable, AgentLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgentLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _agentNameMeta =
      const VerificationMeta('agentName');
  @override
  late final GeneratedColumn<String> agentName = GeneratedColumn<String>(
      'agent_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _actionTypeMeta =
      const VerificationMeta('actionType');
  @override
  late final GeneratedColumn<String> actionType = GeneratedColumn<String>(
      'action_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _decisionDescriptionMeta =
      const VerificationMeta('decisionDescription');
  @override
  late final GeneratedColumn<String> decisionDescription =
      GeneratedColumn<String>('decision_description', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _confidenceScoreMeta =
      const VerificationMeta('confidenceScore');
  @override
  late final GeneratedColumn<double> confidenceScore = GeneratedColumn<double>(
      'confidence_score', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        agentName,
        actionType,
        decisionDescription,
        confidenceScore,
        timestamp
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agent_logs';
  @override
  VerificationContext validateIntegrity(Insertable<AgentLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('agent_name')) {
      context.handle(_agentNameMeta,
          agentName.isAcceptableOrUnknown(data['agent_name']!, _agentNameMeta));
    } else if (isInserting) {
      context.missing(_agentNameMeta);
    }
    if (data.containsKey('action_type')) {
      context.handle(
          _actionTypeMeta,
          actionType.isAcceptableOrUnknown(
              data['action_type']!, _actionTypeMeta));
    } else if (isInserting) {
      context.missing(_actionTypeMeta);
    }
    if (data.containsKey('decision_description')) {
      context.handle(
          _decisionDescriptionMeta,
          decisionDescription.isAcceptableOrUnknown(
              data['decision_description']!, _decisionDescriptionMeta));
    } else if (isInserting) {
      context.missing(_decisionDescriptionMeta);
    }
    if (data.containsKey('confidence_score')) {
      context.handle(
          _confidenceScoreMeta,
          confidenceScore.isAcceptableOrUnknown(
              data['confidence_score']!, _confidenceScoreMeta));
    } else if (isInserting) {
      context.missing(_confidenceScoreMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AgentLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      agentName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}agent_name'])!,
      actionType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action_type'])!,
      decisionDescription: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}decision_description'])!,
      confidenceScore: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}confidence_score'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  $AgentLogsTable createAlias(String alias) {
    return $AgentLogsTable(attachedDatabase, alias);
  }
}

class AgentLog extends DataClass implements Insertable<AgentLog> {
  final String id;
  final String agentName;
  final String actionType;
  final String decisionDescription;
  final double confidenceScore;
  final DateTime timestamp;
  const AgentLog(
      {required this.id,
      required this.agentName,
      required this.actionType,
      required this.decisionDescription,
      required this.confidenceScore,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['agent_name'] = Variable<String>(agentName);
    map['action_type'] = Variable<String>(actionType);
    map['decision_description'] = Variable<String>(decisionDescription);
    map['confidence_score'] = Variable<double>(confidenceScore);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  AgentLogsCompanion toCompanion(bool nullToAbsent) {
    return AgentLogsCompanion(
      id: Value(id),
      agentName: Value(agentName),
      actionType: Value(actionType),
      decisionDescription: Value(decisionDescription),
      confidenceScore: Value(confidenceScore),
      timestamp: Value(timestamp),
    );
  }

  factory AgentLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentLog(
      id: serializer.fromJson<String>(json['id']),
      agentName: serializer.fromJson<String>(json['agentName']),
      actionType: serializer.fromJson<String>(json['actionType']),
      decisionDescription:
          serializer.fromJson<String>(json['decisionDescription']),
      confidenceScore: serializer.fromJson<double>(json['confidenceScore']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'agentName': serializer.toJson<String>(agentName),
      'actionType': serializer.toJson<String>(actionType),
      'decisionDescription': serializer.toJson<String>(decisionDescription),
      'confidenceScore': serializer.toJson<double>(confidenceScore),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  AgentLog copyWith(
          {String? id,
          String? agentName,
          String? actionType,
          String? decisionDescription,
          double? confidenceScore,
          DateTime? timestamp}) =>
      AgentLog(
        id: id ?? this.id,
        agentName: agentName ?? this.agentName,
        actionType: actionType ?? this.actionType,
        decisionDescription: decisionDescription ?? this.decisionDescription,
        confidenceScore: confidenceScore ?? this.confidenceScore,
        timestamp: timestamp ?? this.timestamp,
      );
  AgentLog copyWithCompanion(AgentLogsCompanion data) {
    return AgentLog(
      id: data.id.present ? data.id.value : this.id,
      agentName: data.agentName.present ? data.agentName.value : this.agentName,
      actionType:
          data.actionType.present ? data.actionType.value : this.actionType,
      decisionDescription: data.decisionDescription.present
          ? data.decisionDescription.value
          : this.decisionDescription,
      confidenceScore: data.confidenceScore.present
          ? data.confidenceScore.value
          : this.confidenceScore,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentLog(')
          ..write('id: $id, ')
          ..write('agentName: $agentName, ')
          ..write('actionType: $actionType, ')
          ..write('decisionDescription: $decisionDescription, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, agentName, actionType,
      decisionDescription, confidenceScore, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentLog &&
          other.id == this.id &&
          other.agentName == this.agentName &&
          other.actionType == this.actionType &&
          other.decisionDescription == this.decisionDescription &&
          other.confidenceScore == this.confidenceScore &&
          other.timestamp == this.timestamp);
}

class AgentLogsCompanion extends UpdateCompanion<AgentLog> {
  final Value<String> id;
  final Value<String> agentName;
  final Value<String> actionType;
  final Value<String> decisionDescription;
  final Value<double> confidenceScore;
  final Value<DateTime> timestamp;
  final Value<int> rowid;
  const AgentLogsCompanion({
    this.id = const Value.absent(),
    this.agentName = const Value.absent(),
    this.actionType = const Value.absent(),
    this.decisionDescription = const Value.absent(),
    this.confidenceScore = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgentLogsCompanion.insert({
    required String id,
    required String agentName,
    required String actionType,
    required String decisionDescription,
    required double confidenceScore,
    required DateTime timestamp,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        agentName = Value(agentName),
        actionType = Value(actionType),
        decisionDescription = Value(decisionDescription),
        confidenceScore = Value(confidenceScore),
        timestamp = Value(timestamp);
  static Insertable<AgentLog> custom({
    Expression<String>? id,
    Expression<String>? agentName,
    Expression<String>? actionType,
    Expression<String>? decisionDescription,
    Expression<double>? confidenceScore,
    Expression<DateTime>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (agentName != null) 'agent_name': agentName,
      if (actionType != null) 'action_type': actionType,
      if (decisionDescription != null)
        'decision_description': decisionDescription,
      if (confidenceScore != null) 'confidence_score': confidenceScore,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgentLogsCompanion copyWith(
      {Value<String>? id,
      Value<String>? agentName,
      Value<String>? actionType,
      Value<String>? decisionDescription,
      Value<double>? confidenceScore,
      Value<DateTime>? timestamp,
      Value<int>? rowid}) {
    return AgentLogsCompanion(
      id: id ?? this.id,
      agentName: agentName ?? this.agentName,
      actionType: actionType ?? this.actionType,
      decisionDescription: decisionDescription ?? this.decisionDescription,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (agentName.present) {
      map['agent_name'] = Variable<String>(agentName.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(actionType.value);
    }
    if (decisionDescription.present) {
      map['decision_description'] = Variable<String>(decisionDescription.value);
    }
    if (confidenceScore.present) {
      map['confidence_score'] = Variable<double>(confidenceScore.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgentLogsCompanion(')
          ..write('id: $id, ')
          ..write('agentName: $agentName, ')
          ..write('actionType: $actionType, ')
          ..write('decisionDescription: $decisionDescription, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FinancialPredictionsTable extends FinancialPredictions
    with TableInfo<$FinancialPredictionsTable, FinancialPrediction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinancialPredictionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _targetDateMeta =
      const VerificationMeta('targetDate');
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
      'target_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _predictedBalanceMeta =
      const VerificationMeta('predictedBalance');
  @override
  late final GeneratedColumn<int> predictedBalance = GeneratedColumn<int>(
      'predicted_balance', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _predictedExpensesMeta =
      const VerificationMeta('predictedExpenses');
  @override
  late final GeneratedColumn<int> predictedExpenses = GeneratedColumn<int>(
      'predicted_expenses', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _confidenceMeta =
      const VerificationMeta('confidence');
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
      'confidence', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _metricPayloadMeta =
      const VerificationMeta('metricPayload');
  @override
  late final GeneratedColumn<String> metricPayload = GeneratedColumn<String>(
      'metric_payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
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
        targetDate,
        predictedBalance,
        predictedExpenses,
        confidence,
        metricPayload,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'financial_predictions';
  @override
  VerificationContext validateIntegrity(
      Insertable<FinancialPrediction> instance,
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
    if (data.containsKey('target_date')) {
      context.handle(
          _targetDateMeta,
          targetDate.isAcceptableOrUnknown(
              data['target_date']!, _targetDateMeta));
    } else if (isInserting) {
      context.missing(_targetDateMeta);
    }
    if (data.containsKey('predicted_balance')) {
      context.handle(
          _predictedBalanceMeta,
          predictedBalance.isAcceptableOrUnknown(
              data['predicted_balance']!, _predictedBalanceMeta));
    } else if (isInserting) {
      context.missing(_predictedBalanceMeta);
    }
    if (data.containsKey('predicted_expenses')) {
      context.handle(
          _predictedExpensesMeta,
          predictedExpenses.isAcceptableOrUnknown(
              data['predicted_expenses']!, _predictedExpensesMeta));
    } else if (isInserting) {
      context.missing(_predictedExpensesMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
          _confidenceMeta,
          confidence.isAcceptableOrUnknown(
              data['confidence']!, _confidenceMeta));
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('metric_payload')) {
      context.handle(
          _metricPayloadMeta,
          metricPayload.isAcceptableOrUnknown(
              data['metric_payload']!, _metricPayloadMeta));
    } else if (isInserting) {
      context.missing(_metricPayloadMeta);
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
  FinancialPrediction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinancialPrediction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      targetDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}target_date'])!,
      predictedBalance: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}predicted_balance'])!,
      predictedExpenses: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}predicted_expenses'])!,
      confidence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}confidence'])!,
      metricPayload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metric_payload'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $FinancialPredictionsTable createAlias(String alias) {
    return $FinancialPredictionsTable(attachedDatabase, alias);
  }
}

class FinancialPrediction extends DataClass
    implements Insertable<FinancialPrediction> {
  final String id;
  final String userId;
  final DateTime targetDate;
  final int predictedBalance;
  final int predictedExpenses;
  final double confidence;
  final String metricPayload;
  final DateTime createdAt;
  const FinancialPrediction(
      {required this.id,
      required this.userId,
      required this.targetDate,
      required this.predictedBalance,
      required this.predictedExpenses,
      required this.confidence,
      required this.metricPayload,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['target_date'] = Variable<DateTime>(targetDate);
    map['predicted_balance'] = Variable<int>(predictedBalance);
    map['predicted_expenses'] = Variable<int>(predictedExpenses);
    map['confidence'] = Variable<double>(confidence);
    map['metric_payload'] = Variable<String>(metricPayload);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FinancialPredictionsCompanion toCompanion(bool nullToAbsent) {
    return FinancialPredictionsCompanion(
      id: Value(id),
      userId: Value(userId),
      targetDate: Value(targetDate),
      predictedBalance: Value(predictedBalance),
      predictedExpenses: Value(predictedExpenses),
      confidence: Value(confidence),
      metricPayload: Value(metricPayload),
      createdAt: Value(createdAt),
    );
  }

  factory FinancialPrediction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinancialPrediction(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      targetDate: serializer.fromJson<DateTime>(json['targetDate']),
      predictedBalance: serializer.fromJson<int>(json['predictedBalance']),
      predictedExpenses: serializer.fromJson<int>(json['predictedExpenses']),
      confidence: serializer.fromJson<double>(json['confidence']),
      metricPayload: serializer.fromJson<String>(json['metricPayload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'targetDate': serializer.toJson<DateTime>(targetDate),
      'predictedBalance': serializer.toJson<int>(predictedBalance),
      'predictedExpenses': serializer.toJson<int>(predictedExpenses),
      'confidence': serializer.toJson<double>(confidence),
      'metricPayload': serializer.toJson<String>(metricPayload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FinancialPrediction copyWith(
          {String? id,
          String? userId,
          DateTime? targetDate,
          int? predictedBalance,
          int? predictedExpenses,
          double? confidence,
          String? metricPayload,
          DateTime? createdAt}) =>
      FinancialPrediction(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        targetDate: targetDate ?? this.targetDate,
        predictedBalance: predictedBalance ?? this.predictedBalance,
        predictedExpenses: predictedExpenses ?? this.predictedExpenses,
        confidence: confidence ?? this.confidence,
        metricPayload: metricPayload ?? this.metricPayload,
        createdAt: createdAt ?? this.createdAt,
      );
  FinancialPrediction copyWithCompanion(FinancialPredictionsCompanion data) {
    return FinancialPrediction(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      targetDate:
          data.targetDate.present ? data.targetDate.value : this.targetDate,
      predictedBalance: data.predictedBalance.present
          ? data.predictedBalance.value
          : this.predictedBalance,
      predictedExpenses: data.predictedExpenses.present
          ? data.predictedExpenses.value
          : this.predictedExpenses,
      confidence:
          data.confidence.present ? data.confidence.value : this.confidence,
      metricPayload: data.metricPayload.present
          ? data.metricPayload.value
          : this.metricPayload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinancialPrediction(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('targetDate: $targetDate, ')
          ..write('predictedBalance: $predictedBalance, ')
          ..write('predictedExpenses: $predictedExpenses, ')
          ..write('confidence: $confidence, ')
          ..write('metricPayload: $metricPayload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, targetDate, predictedBalance,
      predictedExpenses, confidence, metricPayload, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinancialPrediction &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.targetDate == this.targetDate &&
          other.predictedBalance == this.predictedBalance &&
          other.predictedExpenses == this.predictedExpenses &&
          other.confidence == this.confidence &&
          other.metricPayload == this.metricPayload &&
          other.createdAt == this.createdAt);
}

class FinancialPredictionsCompanion
    extends UpdateCompanion<FinancialPrediction> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> targetDate;
  final Value<int> predictedBalance;
  final Value<int> predictedExpenses;
  final Value<double> confidence;
  final Value<String> metricPayload;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FinancialPredictionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.predictedBalance = const Value.absent(),
    this.predictedExpenses = const Value.absent(),
    this.confidence = const Value.absent(),
    this.metricPayload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FinancialPredictionsCompanion.insert({
    required String id,
    required String userId,
    required DateTime targetDate,
    required int predictedBalance,
    required int predictedExpenses,
    required double confidence,
    required String metricPayload,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        targetDate = Value(targetDate),
        predictedBalance = Value(predictedBalance),
        predictedExpenses = Value(predictedExpenses),
        confidence = Value(confidence),
        metricPayload = Value(metricPayload),
        createdAt = Value(createdAt);
  static Insertable<FinancialPrediction> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<DateTime>? targetDate,
    Expression<int>? predictedBalance,
    Expression<int>? predictedExpenses,
    Expression<double>? confidence,
    Expression<String>? metricPayload,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (targetDate != null) 'target_date': targetDate,
      if (predictedBalance != null) 'predicted_balance': predictedBalance,
      if (predictedExpenses != null) 'predicted_expenses': predictedExpenses,
      if (confidence != null) 'confidence': confidence,
      if (metricPayload != null) 'metric_payload': metricPayload,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FinancialPredictionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<DateTime>? targetDate,
      Value<int>? predictedBalance,
      Value<int>? predictedExpenses,
      Value<double>? confidence,
      Value<String>? metricPayload,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return FinancialPredictionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetDate: targetDate ?? this.targetDate,
      predictedBalance: predictedBalance ?? this.predictedBalance,
      predictedExpenses: predictedExpenses ?? this.predictedExpenses,
      confidence: confidence ?? this.confidence,
      metricPayload: metricPayload ?? this.metricPayload,
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
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (predictedBalance.present) {
      map['predicted_balance'] = Variable<int>(predictedBalance.value);
    }
    if (predictedExpenses.present) {
      map['predicted_expenses'] = Variable<int>(predictedExpenses.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (metricPayload.present) {
      map['metric_payload'] = Variable<String>(metricPayload.value);
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
    return (StringBuffer('FinancialPredictionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('targetDate: $targetDate, ')
          ..write('predictedBalance: $predictedBalance, ')
          ..write('predictedExpenses: $predictedExpenses, ')
          ..write('confidence: $confidence, ')
          ..write('metricPayload: $metricPayload, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppNotificationsTable extends AppNotifications
    with TableInfo<$AppNotificationsTable, AppNotification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppNotificationsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
      'priority', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
      'is_read', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_read" IN (0, 1))'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, title, body, priority, isRead, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_notifications';
  @override
  VerificationContext validateIntegrity(Insertable<AppNotification> instance,
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
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(_isReadMeta,
          isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta));
    } else if (isInserting) {
      context.missing(_isReadMeta);
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
  AppNotification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppNotification(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}priority'])!,
      isRead: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_read'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AppNotificationsTable createAlias(String alias) {
    return $AppNotificationsTable(attachedDatabase, alias);
  }
}

class AppNotification extends DataClass implements Insertable<AppNotification> {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String priority;
  final bool isRead;
  final DateTime createdAt;
  const AppNotification(
      {required this.id,
      required this.userId,
      required this.title,
      required this.body,
      required this.priority,
      required this.isRead,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['priority'] = Variable<String>(priority);
    map['is_read'] = Variable<bool>(isRead);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AppNotificationsCompanion toCompanion(bool nullToAbsent) {
    return AppNotificationsCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      body: Value(body),
      priority: Value(priority),
      isRead: Value(isRead),
      createdAt: Value(createdAt),
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppNotification(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      priority: serializer.fromJson<String>(json['priority']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'priority': serializer.toJson<String>(priority),
      'isRead': serializer.toJson<bool>(isRead),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AppNotification copyWith(
          {String? id,
          String? userId,
          String? title,
          String? body,
          String? priority,
          bool? isRead,
          DateTime? createdAt}) =>
      AppNotification(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        body: body ?? this.body,
        priority: priority ?? this.priority,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt ?? this.createdAt,
      );
  AppNotification copyWithCompanion(AppNotificationsCompanion data) {
    return AppNotification(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      priority: data.priority.present ? data.priority.value : this.priority,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppNotification(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('priority: $priority, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, title, body, priority, isRead, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppNotification &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.body == this.body &&
          other.priority == this.priority &&
          other.isRead == this.isRead &&
          other.createdAt == this.createdAt);
}

class AppNotificationsCompanion extends UpdateCompanion<AppNotification> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> title;
  final Value<String> body;
  final Value<String> priority;
  final Value<bool> isRead;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AppNotificationsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.priority = const Value.absent(),
    this.isRead = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppNotificationsCompanion.insert({
    required String id,
    required String userId,
    required String title,
    required String body,
    required String priority,
    required bool isRead,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        title = Value(title),
        body = Value(body),
        priority = Value(priority),
        isRead = Value(isRead),
        createdAt = Value(createdAt);
  static Insertable<AppNotification> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? priority,
    Expression<bool>? isRead,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (priority != null) 'priority': priority,
      if (isRead != null) 'is_read': isRead,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppNotificationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? title,
      Value<String>? body,
      Value<String>? priority,
      Value<bool>? isRead,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return AppNotificationsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
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
    return (StringBuffer('AppNotificationsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('priority: $priority, ')
          ..write('isRead: $isRead, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnrecognizedMessagesTable extends UnrecognizedMessages
    with TableInfo<$UnrecognizedMessagesTable, UnrecognizedMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnrecognizedMessagesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
      'sender', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _failureReasonMeta =
      const VerificationMeta('failureReason');
  @override
  late final GeneratedColumn<String> failureReason = GeneratedColumn<String>(
      'failure_reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, sender, body, date, failureReason, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unrecognized_messages';
  @override
  VerificationContext validateIntegrity(
      Insertable<UnrecognizedMessage> instance,
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
    if (data.containsKey('sender')) {
      context.handle(_senderMeta,
          sender.isAcceptableOrUnknown(data['sender']!, _senderMeta));
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('failure_reason')) {
      context.handle(
          _failureReasonMeta,
          failureReason.isAcceptableOrUnknown(
              data['failure_reason']!, _failureReasonMeta));
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
  UnrecognizedMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnrecognizedMessage(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      sender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender']),
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      failureReason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}failure_reason']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $UnrecognizedMessagesTable createAlias(String alias) {
    return $UnrecognizedMessagesTable(attachedDatabase, alias);
  }
}

class UnrecognizedMessage extends DataClass
    implements Insertable<UnrecognizedMessage> {
  final String id;
  final String userId;
  final String? sender;
  final String body;
  final DateTime date;
  final String? failureReason;
  final DateTime createdAt;
  const UnrecognizedMessage(
      {required this.id,
      required this.userId,
      this.sender,
      required this.body,
      required this.date,
      this.failureReason,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || sender != null) {
      map['sender'] = Variable<String>(sender);
    }
    map['body'] = Variable<String>(body);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || failureReason != null) {
      map['failure_reason'] = Variable<String>(failureReason);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UnrecognizedMessagesCompanion toCompanion(bool nullToAbsent) {
    return UnrecognizedMessagesCompanion(
      id: Value(id),
      userId: Value(userId),
      sender:
          sender == null && nullToAbsent ? const Value.absent() : Value(sender),
      body: Value(body),
      date: Value(date),
      failureReason: failureReason == null && nullToAbsent
          ? const Value.absent()
          : Value(failureReason),
      createdAt: Value(createdAt),
    );
  }

  factory UnrecognizedMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnrecognizedMessage(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      sender: serializer.fromJson<String?>(json['sender']),
      body: serializer.fromJson<String>(json['body']),
      date: serializer.fromJson<DateTime>(json['date']),
      failureReason: serializer.fromJson<String?>(json['failureReason']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'sender': serializer.toJson<String?>(sender),
      'body': serializer.toJson<String>(body),
      'date': serializer.toJson<DateTime>(date),
      'failureReason': serializer.toJson<String?>(failureReason),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UnrecognizedMessage copyWith(
          {String? id,
          String? userId,
          Value<String?> sender = const Value.absent(),
          String? body,
          DateTime? date,
          Value<String?> failureReason = const Value.absent(),
          DateTime? createdAt}) =>
      UnrecognizedMessage(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        sender: sender.present ? sender.value : this.sender,
        body: body ?? this.body,
        date: date ?? this.date,
        failureReason:
            failureReason.present ? failureReason.value : this.failureReason,
        createdAt: createdAt ?? this.createdAt,
      );
  UnrecognizedMessage copyWithCompanion(UnrecognizedMessagesCompanion data) {
    return UnrecognizedMessage(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      sender: data.sender.present ? data.sender.value : this.sender,
      body: data.body.present ? data.body.value : this.body,
      date: data.date.present ? data.date.value : this.date,
      failureReason: data.failureReason.present
          ? data.failureReason.value
          : this.failureReason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnrecognizedMessage(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('sender: $sender, ')
          ..write('body: $body, ')
          ..write('date: $date, ')
          ..write('failureReason: $failureReason, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, sender, body, date, failureReason, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnrecognizedMessage &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.sender == this.sender &&
          other.body == this.body &&
          other.date == this.date &&
          other.failureReason == this.failureReason &&
          other.createdAt == this.createdAt);
}

class UnrecognizedMessagesCompanion
    extends UpdateCompanion<UnrecognizedMessage> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> sender;
  final Value<String> body;
  final Value<DateTime> date;
  final Value<String?> failureReason;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const UnrecognizedMessagesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.sender = const Value.absent(),
    this.body = const Value.absent(),
    this.date = const Value.absent(),
    this.failureReason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnrecognizedMessagesCompanion.insert({
    required String id,
    required String userId,
    this.sender = const Value.absent(),
    required String body,
    required DateTime date,
    this.failureReason = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        body = Value(body),
        date = Value(date),
        createdAt = Value(createdAt);
  static Insertable<UnrecognizedMessage> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? sender,
    Expression<String>? body,
    Expression<DateTime>? date,
    Expression<String>? failureReason,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (sender != null) 'sender': sender,
      if (body != null) 'body': body,
      if (date != null) 'date': date,
      if (failureReason != null) 'failure_reason': failureReason,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnrecognizedMessagesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? sender,
      Value<String>? body,
      Value<DateTime>? date,
      Value<String?>? failureReason,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return UnrecognizedMessagesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sender: sender ?? this.sender,
      body: body ?? this.body,
      date: date ?? this.date,
      failureReason: failureReason ?? this.failureReason,
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
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (failureReason.present) {
      map['failure_reason'] = Variable<String>(failureReason.value);
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
    return (StringBuffer('UnrecognizedMessagesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('sender: $sender, ')
          ..write('body: $body, ')
          ..write('date: $date, ')
          ..write('failureReason: $failureReason, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RawSmsTable extends RawSms with TableInfo<$RawSmsTable, RawSmsEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RawSmsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
      'sender', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _receivedAtMeta =
      const VerificationMeta('receivedAt');
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
      'received_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, body, sender, receivedAt, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'raw_sms';
  @override
  VerificationContext validateIntegrity(Insertable<RawSmsEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('sender')) {
      context.handle(_senderMeta,
          sender.isAcceptableOrUnknown(data['sender']!, _senderMeta));
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
          _receivedAtMeta,
          receivedAt.isAcceptableOrUnknown(
              data['received_at']!, _receivedAtMeta));
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
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
  RawSmsEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RawSmsEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      sender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender'])!,
      receivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}received_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $RawSmsTable createAlias(String alias) {
    return $RawSmsTable(attachedDatabase, alias);
  }
}

class RawSmsEntry extends DataClass implements Insertable<RawSmsEntry> {
  final String id;
  final String body;
  final String sender;
  final DateTime receivedAt;
  final DateTime createdAt;
  const RawSmsEntry(
      {required this.id,
      required this.body,
      required this.sender,
      required this.receivedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['body'] = Variable<String>(body);
    map['sender'] = Variable<String>(sender);
    map['received_at'] = Variable<DateTime>(receivedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RawSmsCompanion toCompanion(bool nullToAbsent) {
    return RawSmsCompanion(
      id: Value(id),
      body: Value(body),
      sender: Value(sender),
      receivedAt: Value(receivedAt),
      createdAt: Value(createdAt),
    );
  }

  factory RawSmsEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RawSmsEntry(
      id: serializer.fromJson<String>(json['id']),
      body: serializer.fromJson<String>(json['body']),
      sender: serializer.fromJson<String>(json['sender']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'body': serializer.toJson<String>(body),
      'sender': serializer.toJson<String>(sender),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RawSmsEntry copyWith(
          {String? id,
          String? body,
          String? sender,
          DateTime? receivedAt,
          DateTime? createdAt}) =>
      RawSmsEntry(
        id: id ?? this.id,
        body: body ?? this.body,
        sender: sender ?? this.sender,
        receivedAt: receivedAt ?? this.receivedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  RawSmsEntry copyWithCompanion(RawSmsCompanion data) {
    return RawSmsEntry(
      id: data.id.present ? data.id.value : this.id,
      body: data.body.present ? data.body.value : this.body,
      sender: data.sender.present ? data.sender.value : this.sender,
      receivedAt:
          data.receivedAt.present ? data.receivedAt.value : this.receivedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RawSmsEntry(')
          ..write('id: $id, ')
          ..write('body: $body, ')
          ..write('sender: $sender, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, body, sender, receivedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RawSmsEntry &&
          other.id == this.id &&
          other.body == this.body &&
          other.sender == this.sender &&
          other.receivedAt == this.receivedAt &&
          other.createdAt == this.createdAt);
}

class RawSmsCompanion extends UpdateCompanion<RawSmsEntry> {
  final Value<String> id;
  final Value<String> body;
  final Value<String> sender;
  final Value<DateTime> receivedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const RawSmsCompanion({
    this.id = const Value.absent(),
    this.body = const Value.absent(),
    this.sender = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RawSmsCompanion.insert({
    required String id,
    required String body,
    required String sender,
    required DateTime receivedAt,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        body = Value(body),
        sender = Value(sender),
        receivedAt = Value(receivedAt),
        createdAt = Value(createdAt);
  static Insertable<RawSmsEntry> custom({
    Expression<String>? id,
    Expression<String>? body,
    Expression<String>? sender,
    Expression<DateTime>? receivedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (body != null) 'body': body,
      if (sender != null) 'sender': sender,
      if (receivedAt != null) 'received_at': receivedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RawSmsCompanion copyWith(
      {Value<String>? id,
      Value<String>? body,
      Value<String>? sender,
      Value<DateTime>? receivedAt,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return RawSmsCompanion(
      id: id ?? this.id,
      body: body ?? this.body,
      sender: sender ?? this.sender,
      receivedAt: receivedAt ?? this.receivedAt,
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
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
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
    return (StringBuffer('RawSmsCompanion(')
          ..write('id: $id, ')
          ..write('body: $body, ')
          ..write('sender: $sender, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ParsedSmsTable extends ParsedSms
    with TableInfo<$ParsedSmsTable, ParsedSmsEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ParsedSmsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _smsIdMeta = const VerificationMeta('smsId');
  @override
  late final GeneratedColumn<String> smsId = GeneratedColumn<String>(
      'sms_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES raw_sms (id)'));
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
      'sender', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _receivedAtMeta =
      const VerificationMeta('receivedAt');
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
      'received_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _bankNameMeta =
      const VerificationMeta('bankName');
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
      'bank_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _accountTypeMeta =
      const VerificationMeta('accountType');
  @override
  late final GeneratedColumn<String> accountType = GeneratedColumn<String>(
      'account_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _accountLast4Meta =
      const VerificationMeta('accountLast4');
  @override
  late final GeneratedColumn<String> accountLast4 = GeneratedColumn<String>(
      'account_last_4', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cardTypeMeta =
      const VerificationMeta('cardType');
  @override
  late final GeneratedColumn<String> cardType = GeneratedColumn<String>(
      'card_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _merchantMeta =
      const VerificationMeta('merchant');
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
      'merchant', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isDebitMeta =
      const VerificationMeta('isDebit');
  @override
  late final GeneratedColumn<bool> isDebit = GeneratedColumn<bool>(
      'is_debit', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_debit" IN (0, 1))'));
  static const VerificationMeta _availableBalanceMeta =
      const VerificationMeta('availableBalance');
  @override
  late final GeneratedColumn<int> availableBalance = GeneratedColumn<int>(
      'available_balance', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _referenceNumberMeta =
      const VerificationMeta('referenceNumber');
  @override
  late final GeneratedColumn<String> referenceNumber = GeneratedColumn<String>(
      'reference_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _upiIdMeta = const VerificationMeta('upiId');
  @override
  late final GeneratedColumn<String> upiId = GeneratedColumn<String>(
      'upi_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _paymentMethodMeta =
      const VerificationMeta('paymentMethod');
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
      'payment_method', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _purposeMeta =
      const VerificationMeta('purpose');
  @override
  late final GeneratedColumn<String> purpose = GeneratedColumn<String>(
      'purpose', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _billAmountMeta =
      const VerificationMeta('billAmount');
  @override
  late final GeneratedColumn<int> billAmount = GeneratedColumn<int>(
      'bill_amount', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _minDueMeta = const VerificationMeta('minDue');
  @override
  late final GeneratedColumn<int> minDue = GeneratedColumn<int>(
      'min_due', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _outstandingAmountMeta =
      const VerificationMeta('outstandingAmount');
  @override
  late final GeneratedColumn<int> outstandingAmount = GeneratedColumn<int>(
      'outstanding_amount', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _statementDateMeta =
      const VerificationMeta('statementDate');
  @override
  late final GeneratedColumn<DateTime> statementDate =
      GeneratedColumn<DateTime>('statement_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _paymentDateMeta =
      const VerificationMeta('paymentDate');
  @override
  late final GeneratedColumn<DateTime> paymentDate = GeneratedColumn<DateTime>(
      'payment_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _subcategoryMeta =
      const VerificationMeta('subcategory');
  @override
  late final GeneratedColumn<String> subcategory = GeneratedColumn<String>(
      'subcategory', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _transactionTypeMeta =
      const VerificationMeta('transactionType');
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
      'transaction_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _confidenceScoreMeta =
      const VerificationMeta('confidenceScore');
  @override
  late final GeneratedColumn<double> confidenceScore = GeneratedColumn<double>(
      'confidence_score', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _duplicateHashMeta =
      const VerificationMeta('duplicateHash');
  @override
  late final GeneratedColumn<String> duplicateHash = GeneratedColumn<String>(
      'duplicate_hash', aliasedName, true,
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
        smsId,
        sender,
        receivedAt,
        bankName,
        accountType,
        accountLast4,
        cardType,
        merchant,
        amount,
        isDebit,
        availableBalance,
        referenceNumber,
        upiId,
        paymentMethod,
        purpose,
        billAmount,
        minDue,
        outstandingAmount,
        dueDate,
        statementDate,
        paymentDate,
        category,
        subcategory,
        transactionType,
        confidenceScore,
        duplicateHash,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'parsed_sms';
  @override
  VerificationContext validateIntegrity(Insertable<ParsedSmsEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sms_id')) {
      context.handle(
          _smsIdMeta, smsId.isAcceptableOrUnknown(data['sms_id']!, _smsIdMeta));
    }
    if (data.containsKey('sender')) {
      context.handle(_senderMeta,
          sender.isAcceptableOrUnknown(data['sender']!, _senderMeta));
    }
    if (data.containsKey('received_at')) {
      context.handle(
          _receivedAtMeta,
          receivedAt.isAcceptableOrUnknown(
              data['received_at']!, _receivedAtMeta));
    }
    if (data.containsKey('bank_name')) {
      context.handle(_bankNameMeta,
          bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta));
    }
    if (data.containsKey('account_type')) {
      context.handle(
          _accountTypeMeta,
          accountType.isAcceptableOrUnknown(
              data['account_type']!, _accountTypeMeta));
    }
    if (data.containsKey('account_last_4')) {
      context.handle(
          _accountLast4Meta,
          accountLast4.isAcceptableOrUnknown(
              data['account_last_4']!, _accountLast4Meta));
    }
    if (data.containsKey('card_type')) {
      context.handle(_cardTypeMeta,
          cardType.isAcceptableOrUnknown(data['card_type']!, _cardTypeMeta));
    }
    if (data.containsKey('merchant')) {
      context.handle(_merchantMeta,
          merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    }
    if (data.containsKey('is_debit')) {
      context.handle(_isDebitMeta,
          isDebit.isAcceptableOrUnknown(data['is_debit']!, _isDebitMeta));
    }
    if (data.containsKey('available_balance')) {
      context.handle(
          _availableBalanceMeta,
          availableBalance.isAcceptableOrUnknown(
              data['available_balance']!, _availableBalanceMeta));
    }
    if (data.containsKey('reference_number')) {
      context.handle(
          _referenceNumberMeta,
          referenceNumber.isAcceptableOrUnknown(
              data['reference_number']!, _referenceNumberMeta));
    }
    if (data.containsKey('upi_id')) {
      context.handle(
          _upiIdMeta, upiId.isAcceptableOrUnknown(data['upi_id']!, _upiIdMeta));
    }
    if (data.containsKey('payment_method')) {
      context.handle(
          _paymentMethodMeta,
          paymentMethod.isAcceptableOrUnknown(
              data['payment_method']!, _paymentMethodMeta));
    }
    if (data.containsKey('purpose')) {
      context.handle(_purposeMeta,
          purpose.isAcceptableOrUnknown(data['purpose']!, _purposeMeta));
    }
    if (data.containsKey('bill_amount')) {
      context.handle(
          _billAmountMeta,
          billAmount.isAcceptableOrUnknown(
              data['bill_amount']!, _billAmountMeta));
    }
    if (data.containsKey('min_due')) {
      context.handle(_minDueMeta,
          minDue.isAcceptableOrUnknown(data['min_due']!, _minDueMeta));
    }
    if (data.containsKey('outstanding_amount')) {
      context.handle(
          _outstandingAmountMeta,
          outstandingAmount.isAcceptableOrUnknown(
              data['outstanding_amount']!, _outstandingAmountMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('statement_date')) {
      context.handle(
          _statementDateMeta,
          statementDate.isAcceptableOrUnknown(
              data['statement_date']!, _statementDateMeta));
    }
    if (data.containsKey('payment_date')) {
      context.handle(
          _paymentDateMeta,
          paymentDate.isAcceptableOrUnknown(
              data['payment_date']!, _paymentDateMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('subcategory')) {
      context.handle(
          _subcategoryMeta,
          subcategory.isAcceptableOrUnknown(
              data['subcategory']!, _subcategoryMeta));
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
          _transactionTypeMeta,
          transactionType.isAcceptableOrUnknown(
              data['transaction_type']!, _transactionTypeMeta));
    }
    if (data.containsKey('confidence_score')) {
      context.handle(
          _confidenceScoreMeta,
          confidenceScore.isAcceptableOrUnknown(
              data['confidence_score']!, _confidenceScoreMeta));
    }
    if (data.containsKey('duplicate_hash')) {
      context.handle(
          _duplicateHashMeta,
          duplicateHash.isAcceptableOrUnknown(
              data['duplicate_hash']!, _duplicateHashMeta));
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
  ParsedSmsEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ParsedSmsEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      smsId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sms_id']),
      sender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender']),
      receivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}received_at']),
      bankName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bank_name']),
      accountType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_type']),
      accountLast4: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_last_4']),
      cardType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}card_type']),
      merchant: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}merchant']),
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount']),
      isDebit: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_debit']),
      availableBalance: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}available_balance']),
      referenceNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}reference_number']),
      upiId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}upi_id']),
      paymentMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_method']),
      purpose: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}purpose']),
      billAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bill_amount']),
      minDue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min_due']),
      outstandingAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}outstanding_amount']),
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      statementDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}statement_date']),
      paymentDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}payment_date']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      subcategory: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subcategory']),
      transactionType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}transaction_type']),
      confidenceScore: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}confidence_score']),
      duplicateHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}duplicate_hash']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ParsedSmsTable createAlias(String alias) {
    return $ParsedSmsTable(attachedDatabase, alias);
  }
}

class ParsedSmsEntry extends DataClass implements Insertable<ParsedSmsEntry> {
  final String id;
  final String? smsId;
  final String? sender;
  final DateTime? receivedAt;
  final String? bankName;
  final String? accountType;
  final String? accountLast4;
  final String? cardType;
  final String? merchant;
  final int? amount;
  final bool? isDebit;
  final int? availableBalance;
  final String? referenceNumber;
  final String? upiId;
  final String? paymentMethod;
  final String? purpose;
  final int? billAmount;
  final int? minDue;
  final int? outstandingAmount;
  final DateTime? dueDate;
  final DateTime? statementDate;
  final DateTime? paymentDate;
  final String? category;
  final String? subcategory;
  final String? transactionType;
  final double? confidenceScore;
  final String? duplicateHash;
  final DateTime createdAt;
  const ParsedSmsEntry(
      {required this.id,
      this.smsId,
      this.sender,
      this.receivedAt,
      this.bankName,
      this.accountType,
      this.accountLast4,
      this.cardType,
      this.merchant,
      this.amount,
      this.isDebit,
      this.availableBalance,
      this.referenceNumber,
      this.upiId,
      this.paymentMethod,
      this.purpose,
      this.billAmount,
      this.minDue,
      this.outstandingAmount,
      this.dueDate,
      this.statementDate,
      this.paymentDate,
      this.category,
      this.subcategory,
      this.transactionType,
      this.confidenceScore,
      this.duplicateHash,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || smsId != null) {
      map['sms_id'] = Variable<String>(smsId);
    }
    if (!nullToAbsent || sender != null) {
      map['sender'] = Variable<String>(sender);
    }
    if (!nullToAbsent || receivedAt != null) {
      map['received_at'] = Variable<DateTime>(receivedAt);
    }
    if (!nullToAbsent || bankName != null) {
      map['bank_name'] = Variable<String>(bankName);
    }
    if (!nullToAbsent || accountType != null) {
      map['account_type'] = Variable<String>(accountType);
    }
    if (!nullToAbsent || accountLast4 != null) {
      map['account_last_4'] = Variable<String>(accountLast4);
    }
    if (!nullToAbsent || cardType != null) {
      map['card_type'] = Variable<String>(cardType);
    }
    if (!nullToAbsent || merchant != null) {
      map['merchant'] = Variable<String>(merchant);
    }
    if (!nullToAbsent || amount != null) {
      map['amount'] = Variable<int>(amount);
    }
    if (!nullToAbsent || isDebit != null) {
      map['is_debit'] = Variable<bool>(isDebit);
    }
    if (!nullToAbsent || availableBalance != null) {
      map['available_balance'] = Variable<int>(availableBalance);
    }
    if (!nullToAbsent || referenceNumber != null) {
      map['reference_number'] = Variable<String>(referenceNumber);
    }
    if (!nullToAbsent || upiId != null) {
      map['upi_id'] = Variable<String>(upiId);
    }
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    if (!nullToAbsent || purpose != null) {
      map['purpose'] = Variable<String>(purpose);
    }
    if (!nullToAbsent || billAmount != null) {
      map['bill_amount'] = Variable<int>(billAmount);
    }
    if (!nullToAbsent || minDue != null) {
      map['min_due'] = Variable<int>(minDue);
    }
    if (!nullToAbsent || outstandingAmount != null) {
      map['outstanding_amount'] = Variable<int>(outstandingAmount);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || statementDate != null) {
      map['statement_date'] = Variable<DateTime>(statementDate);
    }
    if (!nullToAbsent || paymentDate != null) {
      map['payment_date'] = Variable<DateTime>(paymentDate);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || subcategory != null) {
      map['subcategory'] = Variable<String>(subcategory);
    }
    if (!nullToAbsent || transactionType != null) {
      map['transaction_type'] = Variable<String>(transactionType);
    }
    if (!nullToAbsent || confidenceScore != null) {
      map['confidence_score'] = Variable<double>(confidenceScore);
    }
    if (!nullToAbsent || duplicateHash != null) {
      map['duplicate_hash'] = Variable<String>(duplicateHash);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ParsedSmsCompanion toCompanion(bool nullToAbsent) {
    return ParsedSmsCompanion(
      id: Value(id),
      smsId:
          smsId == null && nullToAbsent ? const Value.absent() : Value(smsId),
      sender:
          sender == null && nullToAbsent ? const Value.absent() : Value(sender),
      receivedAt: receivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(receivedAt),
      bankName: bankName == null && nullToAbsent
          ? const Value.absent()
          : Value(bankName),
      accountType: accountType == null && nullToAbsent
          ? const Value.absent()
          : Value(accountType),
      accountLast4: accountLast4 == null && nullToAbsent
          ? const Value.absent()
          : Value(accountLast4),
      cardType: cardType == null && nullToAbsent
          ? const Value.absent()
          : Value(cardType),
      merchant: merchant == null && nullToAbsent
          ? const Value.absent()
          : Value(merchant),
      amount:
          amount == null && nullToAbsent ? const Value.absent() : Value(amount),
      isDebit: isDebit == null && nullToAbsent
          ? const Value.absent()
          : Value(isDebit),
      availableBalance: availableBalance == null && nullToAbsent
          ? const Value.absent()
          : Value(availableBalance),
      referenceNumber: referenceNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceNumber),
      upiId:
          upiId == null && nullToAbsent ? const Value.absent() : Value(upiId),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      purpose: purpose == null && nullToAbsent
          ? const Value.absent()
          : Value(purpose),
      billAmount: billAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(billAmount),
      minDue:
          minDue == null && nullToAbsent ? const Value.absent() : Value(minDue),
      outstandingAmount: outstandingAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(outstandingAmount),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      statementDate: statementDate == null && nullToAbsent
          ? const Value.absent()
          : Value(statementDate),
      paymentDate: paymentDate == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentDate),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      subcategory: subcategory == null && nullToAbsent
          ? const Value.absent()
          : Value(subcategory),
      transactionType: transactionType == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionType),
      confidenceScore: confidenceScore == null && nullToAbsent
          ? const Value.absent()
          : Value(confidenceScore),
      duplicateHash: duplicateHash == null && nullToAbsent
          ? const Value.absent()
          : Value(duplicateHash),
      createdAt: Value(createdAt),
    );
  }

  factory ParsedSmsEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ParsedSmsEntry(
      id: serializer.fromJson<String>(json['id']),
      smsId: serializer.fromJson<String?>(json['smsId']),
      sender: serializer.fromJson<String?>(json['sender']),
      receivedAt: serializer.fromJson<DateTime?>(json['receivedAt']),
      bankName: serializer.fromJson<String?>(json['bankName']),
      accountType: serializer.fromJson<String?>(json['accountType']),
      accountLast4: serializer.fromJson<String?>(json['accountLast4']),
      cardType: serializer.fromJson<String?>(json['cardType']),
      merchant: serializer.fromJson<String?>(json['merchant']),
      amount: serializer.fromJson<int?>(json['amount']),
      isDebit: serializer.fromJson<bool?>(json['isDebit']),
      availableBalance: serializer.fromJson<int?>(json['availableBalance']),
      referenceNumber: serializer.fromJson<String?>(json['referenceNumber']),
      upiId: serializer.fromJson<String?>(json['upiId']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      purpose: serializer.fromJson<String?>(json['purpose']),
      billAmount: serializer.fromJson<int?>(json['billAmount']),
      minDue: serializer.fromJson<int?>(json['minDue']),
      outstandingAmount: serializer.fromJson<int?>(json['outstandingAmount']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      statementDate: serializer.fromJson<DateTime?>(json['statementDate']),
      paymentDate: serializer.fromJson<DateTime?>(json['paymentDate']),
      category: serializer.fromJson<String?>(json['category']),
      subcategory: serializer.fromJson<String?>(json['subcategory']),
      transactionType: serializer.fromJson<String?>(json['transactionType']),
      confidenceScore: serializer.fromJson<double?>(json['confidenceScore']),
      duplicateHash: serializer.fromJson<String?>(json['duplicateHash']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'smsId': serializer.toJson<String?>(smsId),
      'sender': serializer.toJson<String?>(sender),
      'receivedAt': serializer.toJson<DateTime?>(receivedAt),
      'bankName': serializer.toJson<String?>(bankName),
      'accountType': serializer.toJson<String?>(accountType),
      'accountLast4': serializer.toJson<String?>(accountLast4),
      'cardType': serializer.toJson<String?>(cardType),
      'merchant': serializer.toJson<String?>(merchant),
      'amount': serializer.toJson<int?>(amount),
      'isDebit': serializer.toJson<bool?>(isDebit),
      'availableBalance': serializer.toJson<int?>(availableBalance),
      'referenceNumber': serializer.toJson<String?>(referenceNumber),
      'upiId': serializer.toJson<String?>(upiId),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'purpose': serializer.toJson<String?>(purpose),
      'billAmount': serializer.toJson<int?>(billAmount),
      'minDue': serializer.toJson<int?>(minDue),
      'outstandingAmount': serializer.toJson<int?>(outstandingAmount),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'statementDate': serializer.toJson<DateTime?>(statementDate),
      'paymentDate': serializer.toJson<DateTime?>(paymentDate),
      'category': serializer.toJson<String?>(category),
      'subcategory': serializer.toJson<String?>(subcategory),
      'transactionType': serializer.toJson<String?>(transactionType),
      'confidenceScore': serializer.toJson<double?>(confidenceScore),
      'duplicateHash': serializer.toJson<String?>(duplicateHash),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ParsedSmsEntry copyWith(
          {String? id,
          Value<String?> smsId = const Value.absent(),
          Value<String?> sender = const Value.absent(),
          Value<DateTime?> receivedAt = const Value.absent(),
          Value<String?> bankName = const Value.absent(),
          Value<String?> accountType = const Value.absent(),
          Value<String?> accountLast4 = const Value.absent(),
          Value<String?> cardType = const Value.absent(),
          Value<String?> merchant = const Value.absent(),
          Value<int?> amount = const Value.absent(),
          Value<bool?> isDebit = const Value.absent(),
          Value<int?> availableBalance = const Value.absent(),
          Value<String?> referenceNumber = const Value.absent(),
          Value<String?> upiId = const Value.absent(),
          Value<String?> paymentMethod = const Value.absent(),
          Value<String?> purpose = const Value.absent(),
          Value<int?> billAmount = const Value.absent(),
          Value<int?> minDue = const Value.absent(),
          Value<int?> outstandingAmount = const Value.absent(),
          Value<DateTime?> dueDate = const Value.absent(),
          Value<DateTime?> statementDate = const Value.absent(),
          Value<DateTime?> paymentDate = const Value.absent(),
          Value<String?> category = const Value.absent(),
          Value<String?> subcategory = const Value.absent(),
          Value<String?> transactionType = const Value.absent(),
          Value<double?> confidenceScore = const Value.absent(),
          Value<String?> duplicateHash = const Value.absent(),
          DateTime? createdAt}) =>
      ParsedSmsEntry(
        id: id ?? this.id,
        smsId: smsId.present ? smsId.value : this.smsId,
        sender: sender.present ? sender.value : this.sender,
        receivedAt: receivedAt.present ? receivedAt.value : this.receivedAt,
        bankName: bankName.present ? bankName.value : this.bankName,
        accountType: accountType.present ? accountType.value : this.accountType,
        accountLast4:
            accountLast4.present ? accountLast4.value : this.accountLast4,
        cardType: cardType.present ? cardType.value : this.cardType,
        merchant: merchant.present ? merchant.value : this.merchant,
        amount: amount.present ? amount.value : this.amount,
        isDebit: isDebit.present ? isDebit.value : this.isDebit,
        availableBalance: availableBalance.present
            ? availableBalance.value
            : this.availableBalance,
        referenceNumber: referenceNumber.present
            ? referenceNumber.value
            : this.referenceNumber,
        upiId: upiId.present ? upiId.value : this.upiId,
        paymentMethod:
            paymentMethod.present ? paymentMethod.value : this.paymentMethod,
        purpose: purpose.present ? purpose.value : this.purpose,
        billAmount: billAmount.present ? billAmount.value : this.billAmount,
        minDue: minDue.present ? minDue.value : this.minDue,
        outstandingAmount: outstandingAmount.present
            ? outstandingAmount.value
            : this.outstandingAmount,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        statementDate:
            statementDate.present ? statementDate.value : this.statementDate,
        paymentDate: paymentDate.present ? paymentDate.value : this.paymentDate,
        category: category.present ? category.value : this.category,
        subcategory: subcategory.present ? subcategory.value : this.subcategory,
        transactionType: transactionType.present
            ? transactionType.value
            : this.transactionType,
        confidenceScore: confidenceScore.present
            ? confidenceScore.value
            : this.confidenceScore,
        duplicateHash:
            duplicateHash.present ? duplicateHash.value : this.duplicateHash,
        createdAt: createdAt ?? this.createdAt,
      );
  ParsedSmsEntry copyWithCompanion(ParsedSmsCompanion data) {
    return ParsedSmsEntry(
      id: data.id.present ? data.id.value : this.id,
      smsId: data.smsId.present ? data.smsId.value : this.smsId,
      sender: data.sender.present ? data.sender.value : this.sender,
      receivedAt:
          data.receivedAt.present ? data.receivedAt.value : this.receivedAt,
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      accountType:
          data.accountType.present ? data.accountType.value : this.accountType,
      accountLast4: data.accountLast4.present
          ? data.accountLast4.value
          : this.accountLast4,
      cardType: data.cardType.present ? data.cardType.value : this.cardType,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      amount: data.amount.present ? data.amount.value : this.amount,
      isDebit: data.isDebit.present ? data.isDebit.value : this.isDebit,
      availableBalance: data.availableBalance.present
          ? data.availableBalance.value
          : this.availableBalance,
      referenceNumber: data.referenceNumber.present
          ? data.referenceNumber.value
          : this.referenceNumber,
      upiId: data.upiId.present ? data.upiId.value : this.upiId,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      purpose: data.purpose.present ? data.purpose.value : this.purpose,
      billAmount:
          data.billAmount.present ? data.billAmount.value : this.billAmount,
      minDue: data.minDue.present ? data.minDue.value : this.minDue,
      outstandingAmount: data.outstandingAmount.present
          ? data.outstandingAmount.value
          : this.outstandingAmount,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      statementDate: data.statementDate.present
          ? data.statementDate.value
          : this.statementDate,
      paymentDate:
          data.paymentDate.present ? data.paymentDate.value : this.paymentDate,
      category: data.category.present ? data.category.value : this.category,
      subcategory:
          data.subcategory.present ? data.subcategory.value : this.subcategory,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      confidenceScore: data.confidenceScore.present
          ? data.confidenceScore.value
          : this.confidenceScore,
      duplicateHash: data.duplicateHash.present
          ? data.duplicateHash.value
          : this.duplicateHash,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ParsedSmsEntry(')
          ..write('id: $id, ')
          ..write('smsId: $smsId, ')
          ..write('sender: $sender, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('bankName: $bankName, ')
          ..write('accountType: $accountType, ')
          ..write('accountLast4: $accountLast4, ')
          ..write('cardType: $cardType, ')
          ..write('merchant: $merchant, ')
          ..write('amount: $amount, ')
          ..write('isDebit: $isDebit, ')
          ..write('availableBalance: $availableBalance, ')
          ..write('referenceNumber: $referenceNumber, ')
          ..write('upiId: $upiId, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('purpose: $purpose, ')
          ..write('billAmount: $billAmount, ')
          ..write('minDue: $minDue, ')
          ..write('outstandingAmount: $outstandingAmount, ')
          ..write('dueDate: $dueDate, ')
          ..write('statementDate: $statementDate, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('category: $category, ')
          ..write('subcategory: $subcategory, ')
          ..write('transactionType: $transactionType, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('duplicateHash: $duplicateHash, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        smsId,
        sender,
        receivedAt,
        bankName,
        accountType,
        accountLast4,
        cardType,
        merchant,
        amount,
        isDebit,
        availableBalance,
        referenceNumber,
        upiId,
        paymentMethod,
        purpose,
        billAmount,
        minDue,
        outstandingAmount,
        dueDate,
        statementDate,
        paymentDate,
        category,
        subcategory,
        transactionType,
        confidenceScore,
        duplicateHash,
        createdAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ParsedSmsEntry &&
          other.id == this.id &&
          other.smsId == this.smsId &&
          other.sender == this.sender &&
          other.receivedAt == this.receivedAt &&
          other.bankName == this.bankName &&
          other.accountType == this.accountType &&
          other.accountLast4 == this.accountLast4 &&
          other.cardType == this.cardType &&
          other.merchant == this.merchant &&
          other.amount == this.amount &&
          other.isDebit == this.isDebit &&
          other.availableBalance == this.availableBalance &&
          other.referenceNumber == this.referenceNumber &&
          other.upiId == this.upiId &&
          other.paymentMethod == this.paymentMethod &&
          other.purpose == this.purpose &&
          other.billAmount == this.billAmount &&
          other.minDue == this.minDue &&
          other.outstandingAmount == this.outstandingAmount &&
          other.dueDate == this.dueDate &&
          other.statementDate == this.statementDate &&
          other.paymentDate == this.paymentDate &&
          other.category == this.category &&
          other.subcategory == this.subcategory &&
          other.transactionType == this.transactionType &&
          other.confidenceScore == this.confidenceScore &&
          other.duplicateHash == this.duplicateHash &&
          other.createdAt == this.createdAt);
}

class ParsedSmsCompanion extends UpdateCompanion<ParsedSmsEntry> {
  final Value<String> id;
  final Value<String?> smsId;
  final Value<String?> sender;
  final Value<DateTime?> receivedAt;
  final Value<String?> bankName;
  final Value<String?> accountType;
  final Value<String?> accountLast4;
  final Value<String?> cardType;
  final Value<String?> merchant;
  final Value<int?> amount;
  final Value<bool?> isDebit;
  final Value<int?> availableBalance;
  final Value<String?> referenceNumber;
  final Value<String?> upiId;
  final Value<String?> paymentMethod;
  final Value<String?> purpose;
  final Value<int?> billAmount;
  final Value<int?> minDue;
  final Value<int?> outstandingAmount;
  final Value<DateTime?> dueDate;
  final Value<DateTime?> statementDate;
  final Value<DateTime?> paymentDate;
  final Value<String?> category;
  final Value<String?> subcategory;
  final Value<String?> transactionType;
  final Value<double?> confidenceScore;
  final Value<String?> duplicateHash;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ParsedSmsCompanion({
    this.id = const Value.absent(),
    this.smsId = const Value.absent(),
    this.sender = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.bankName = const Value.absent(),
    this.accountType = const Value.absent(),
    this.accountLast4 = const Value.absent(),
    this.cardType = const Value.absent(),
    this.merchant = const Value.absent(),
    this.amount = const Value.absent(),
    this.isDebit = const Value.absent(),
    this.availableBalance = const Value.absent(),
    this.referenceNumber = const Value.absent(),
    this.upiId = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.purpose = const Value.absent(),
    this.billAmount = const Value.absent(),
    this.minDue = const Value.absent(),
    this.outstandingAmount = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.statementDate = const Value.absent(),
    this.paymentDate = const Value.absent(),
    this.category = const Value.absent(),
    this.subcategory = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.confidenceScore = const Value.absent(),
    this.duplicateHash = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ParsedSmsCompanion.insert({
    required String id,
    this.smsId = const Value.absent(),
    this.sender = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.bankName = const Value.absent(),
    this.accountType = const Value.absent(),
    this.accountLast4 = const Value.absent(),
    this.cardType = const Value.absent(),
    this.merchant = const Value.absent(),
    this.amount = const Value.absent(),
    this.isDebit = const Value.absent(),
    this.availableBalance = const Value.absent(),
    this.referenceNumber = const Value.absent(),
    this.upiId = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.purpose = const Value.absent(),
    this.billAmount = const Value.absent(),
    this.minDue = const Value.absent(),
    this.outstandingAmount = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.statementDate = const Value.absent(),
    this.paymentDate = const Value.absent(),
    this.category = const Value.absent(),
    this.subcategory = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.confidenceScore = const Value.absent(),
    this.duplicateHash = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt);
  static Insertable<ParsedSmsEntry> custom({
    Expression<String>? id,
    Expression<String>? smsId,
    Expression<String>? sender,
    Expression<DateTime>? receivedAt,
    Expression<String>? bankName,
    Expression<String>? accountType,
    Expression<String>? accountLast4,
    Expression<String>? cardType,
    Expression<String>? merchant,
    Expression<int>? amount,
    Expression<bool>? isDebit,
    Expression<int>? availableBalance,
    Expression<String>? referenceNumber,
    Expression<String>? upiId,
    Expression<String>? paymentMethod,
    Expression<String>? purpose,
    Expression<int>? billAmount,
    Expression<int>? minDue,
    Expression<int>? outstandingAmount,
    Expression<DateTime>? dueDate,
    Expression<DateTime>? statementDate,
    Expression<DateTime>? paymentDate,
    Expression<String>? category,
    Expression<String>? subcategory,
    Expression<String>? transactionType,
    Expression<double>? confidenceScore,
    Expression<String>? duplicateHash,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (smsId != null) 'sms_id': smsId,
      if (sender != null) 'sender': sender,
      if (receivedAt != null) 'received_at': receivedAt,
      if (bankName != null) 'bank_name': bankName,
      if (accountType != null) 'account_type': accountType,
      if (accountLast4 != null) 'account_last_4': accountLast4,
      if (cardType != null) 'card_type': cardType,
      if (merchant != null) 'merchant': merchant,
      if (amount != null) 'amount': amount,
      if (isDebit != null) 'is_debit': isDebit,
      if (availableBalance != null) 'available_balance': availableBalance,
      if (referenceNumber != null) 'reference_number': referenceNumber,
      if (upiId != null) 'upi_id': upiId,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (purpose != null) 'purpose': purpose,
      if (billAmount != null) 'bill_amount': billAmount,
      if (minDue != null) 'min_due': minDue,
      if (outstandingAmount != null) 'outstanding_amount': outstandingAmount,
      if (dueDate != null) 'due_date': dueDate,
      if (statementDate != null) 'statement_date': statementDate,
      if (paymentDate != null) 'payment_date': paymentDate,
      if (category != null) 'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      if (transactionType != null) 'transaction_type': transactionType,
      if (confidenceScore != null) 'confidence_score': confidenceScore,
      if (duplicateHash != null) 'duplicate_hash': duplicateHash,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ParsedSmsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? smsId,
      Value<String?>? sender,
      Value<DateTime?>? receivedAt,
      Value<String?>? bankName,
      Value<String?>? accountType,
      Value<String?>? accountLast4,
      Value<String?>? cardType,
      Value<String?>? merchant,
      Value<int?>? amount,
      Value<bool?>? isDebit,
      Value<int?>? availableBalance,
      Value<String?>? referenceNumber,
      Value<String?>? upiId,
      Value<String?>? paymentMethod,
      Value<String?>? purpose,
      Value<int?>? billAmount,
      Value<int?>? minDue,
      Value<int?>? outstandingAmount,
      Value<DateTime?>? dueDate,
      Value<DateTime?>? statementDate,
      Value<DateTime?>? paymentDate,
      Value<String?>? category,
      Value<String?>? subcategory,
      Value<String?>? transactionType,
      Value<double?>? confidenceScore,
      Value<String?>? duplicateHash,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ParsedSmsCompanion(
      id: id ?? this.id,
      smsId: smsId ?? this.smsId,
      sender: sender ?? this.sender,
      receivedAt: receivedAt ?? this.receivedAt,
      bankName: bankName ?? this.bankName,
      accountType: accountType ?? this.accountType,
      accountLast4: accountLast4 ?? this.accountLast4,
      cardType: cardType ?? this.cardType,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      isDebit: isDebit ?? this.isDebit,
      availableBalance: availableBalance ?? this.availableBalance,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      upiId: upiId ?? this.upiId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      purpose: purpose ?? this.purpose,
      billAmount: billAmount ?? this.billAmount,
      minDue: minDue ?? this.minDue,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      dueDate: dueDate ?? this.dueDate,
      statementDate: statementDate ?? this.statementDate,
      paymentDate: paymentDate ?? this.paymentDate,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      transactionType: transactionType ?? this.transactionType,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      duplicateHash: duplicateHash ?? this.duplicateHash,
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
    if (smsId.present) {
      map['sms_id'] = Variable<String>(smsId.value);
    }
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (accountType.present) {
      map['account_type'] = Variable<String>(accountType.value);
    }
    if (accountLast4.present) {
      map['account_last_4'] = Variable<String>(accountLast4.value);
    }
    if (cardType.present) {
      map['card_type'] = Variable<String>(cardType.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (isDebit.present) {
      map['is_debit'] = Variable<bool>(isDebit.value);
    }
    if (availableBalance.present) {
      map['available_balance'] = Variable<int>(availableBalance.value);
    }
    if (referenceNumber.present) {
      map['reference_number'] = Variable<String>(referenceNumber.value);
    }
    if (upiId.present) {
      map['upi_id'] = Variable<String>(upiId.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (purpose.present) {
      map['purpose'] = Variable<String>(purpose.value);
    }
    if (billAmount.present) {
      map['bill_amount'] = Variable<int>(billAmount.value);
    }
    if (minDue.present) {
      map['min_due'] = Variable<int>(minDue.value);
    }
    if (outstandingAmount.present) {
      map['outstanding_amount'] = Variable<int>(outstandingAmount.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (statementDate.present) {
      map['statement_date'] = Variable<DateTime>(statementDate.value);
    }
    if (paymentDate.present) {
      map['payment_date'] = Variable<DateTime>(paymentDate.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (subcategory.present) {
      map['subcategory'] = Variable<String>(subcategory.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (confidenceScore.present) {
      map['confidence_score'] = Variable<double>(confidenceScore.value);
    }
    if (duplicateHash.present) {
      map['duplicate_hash'] = Variable<String>(duplicateHash.value);
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
    return (StringBuffer('ParsedSmsCompanion(')
          ..write('id: $id, ')
          ..write('smsId: $smsId, ')
          ..write('sender: $sender, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('bankName: $bankName, ')
          ..write('accountType: $accountType, ')
          ..write('accountLast4: $accountLast4, ')
          ..write('cardType: $cardType, ')
          ..write('merchant: $merchant, ')
          ..write('amount: $amount, ')
          ..write('isDebit: $isDebit, ')
          ..write('availableBalance: $availableBalance, ')
          ..write('referenceNumber: $referenceNumber, ')
          ..write('upiId: $upiId, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('purpose: $purpose, ')
          ..write('billAmount: $billAmount, ')
          ..write('minDue: $minDue, ')
          ..write('outstandingAmount: $outstandingAmount, ')
          ..write('dueDate: $dueDate, ')
          ..write('statementDate: $statementDate, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('category: $category, ')
          ..write('subcategory: $subcategory, ')
          ..write('transactionType: $transactionType, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('duplicateHash: $duplicateHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BillsTable extends Bills with TableInfo<$BillsTable, Bill> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _minDueMeta = const VerificationMeta('minDue');
  @override
  late final GeneratedColumn<int> minDue = GeneratedColumn<int>(
      'min_due', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _statementDateMeta =
      const VerificationMeta('statementDate');
  @override
  late final GeneratedColumn<DateTime> statementDate =
      GeneratedColumn<DateTime>('statement_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _billingCycleMeta =
      const VerificationMeta('billingCycle');
  @override
  late final GeneratedColumn<String> billingCycle = GeneratedColumn<String>(
      'billing_cycle', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _paymentTransactionIdMeta =
      const VerificationMeta('paymentTransactionId');
  @override
  late final GeneratedColumn<String> paymentTransactionId = GeneratedColumn<
          String>('payment_transaction_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES transactions (id)'));
  static const VerificationMeta _paymentSourceAccountIdMeta =
      const VerificationMeta('paymentSourceAccountId');
  @override
  late final GeneratedColumn<String> paymentSourceAccountId =
      GeneratedColumn<String>('payment_source_account_id', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultConstraints:
              GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
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
        accountId,
        title,
        amount,
        minDue,
        dueDate,
        statementDate,
        status,
        billingCycle,
        paymentTransactionId,
        paymentSourceAccountId,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bills';
  @override
  VerificationContext validateIntegrity(Insertable<Bill> instance,
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
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('min_due')) {
      context.handle(_minDueMeta,
          minDue.isAcceptableOrUnknown(data['min_due']!, _minDueMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('statement_date')) {
      context.handle(
          _statementDateMeta,
          statementDate.isAcceptableOrUnknown(
              data['statement_date']!, _statementDateMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('billing_cycle')) {
      context.handle(
          _billingCycleMeta,
          billingCycle.isAcceptableOrUnknown(
              data['billing_cycle']!, _billingCycleMeta));
    }
    if (data.containsKey('payment_transaction_id')) {
      context.handle(
          _paymentTransactionIdMeta,
          paymentTransactionId.isAcceptableOrUnknown(
              data['payment_transaction_id']!, _paymentTransactionIdMeta));
    }
    if (data.containsKey('payment_source_account_id')) {
      context.handle(
          _paymentSourceAccountIdMeta,
          paymentSourceAccountId.isAcceptableOrUnknown(
              data['payment_source_account_id']!, _paymentSourceAccountIdMeta));
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
  Bill map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bill(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      minDue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min_due']),
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      statementDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}statement_date']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      billingCycle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}billing_cycle']),
      paymentTransactionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}payment_transaction_id']),
      paymentSourceAccountId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}payment_source_account_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BillsTable createAlias(String alias) {
    return $BillsTable(attachedDatabase, alias);
  }
}

class Bill extends DataClass implements Insertable<Bill> {
  final String id;
  final String userId;
  final String? accountId;
  final String title;
  final int amount;
  final int? minDue;
  final DateTime? dueDate;
  final DateTime? statementDate;
  final String status;
  final String? billingCycle;
  final String? paymentTransactionId;
  final String? paymentSourceAccountId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Bill(
      {required this.id,
      required this.userId,
      this.accountId,
      required this.title,
      required this.amount,
      this.minDue,
      this.dueDate,
      this.statementDate,
      required this.status,
      this.billingCycle,
      this.paymentTransactionId,
      this.paymentSourceAccountId,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['title'] = Variable<String>(title);
    map['amount'] = Variable<int>(amount);
    if (!nullToAbsent || minDue != null) {
      map['min_due'] = Variable<int>(minDue);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || statementDate != null) {
      map['statement_date'] = Variable<DateTime>(statementDate);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || billingCycle != null) {
      map['billing_cycle'] = Variable<String>(billingCycle);
    }
    if (!nullToAbsent || paymentTransactionId != null) {
      map['payment_transaction_id'] = Variable<String>(paymentTransactionId);
    }
    if (!nullToAbsent || paymentSourceAccountId != null) {
      map['payment_source_account_id'] =
          Variable<String>(paymentSourceAccountId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BillsCompanion toCompanion(bool nullToAbsent) {
    return BillsCompanion(
      id: Value(id),
      userId: Value(userId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      title: Value(title),
      amount: Value(amount),
      minDue:
          minDue == null && nullToAbsent ? const Value.absent() : Value(minDue),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      statementDate: statementDate == null && nullToAbsent
          ? const Value.absent()
          : Value(statementDate),
      status: Value(status),
      billingCycle: billingCycle == null && nullToAbsent
          ? const Value.absent()
          : Value(billingCycle),
      paymentTransactionId: paymentTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentTransactionId),
      paymentSourceAccountId: paymentSourceAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentSourceAccountId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Bill.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bill(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      title: serializer.fromJson<String>(json['title']),
      amount: serializer.fromJson<int>(json['amount']),
      minDue: serializer.fromJson<int?>(json['minDue']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      statementDate: serializer.fromJson<DateTime?>(json['statementDate']),
      status: serializer.fromJson<String>(json['status']),
      billingCycle: serializer.fromJson<String?>(json['billingCycle']),
      paymentTransactionId:
          serializer.fromJson<String?>(json['paymentTransactionId']),
      paymentSourceAccountId:
          serializer.fromJson<String?>(json['paymentSourceAccountId']),
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
      'accountId': serializer.toJson<String?>(accountId),
      'title': serializer.toJson<String>(title),
      'amount': serializer.toJson<int>(amount),
      'minDue': serializer.toJson<int?>(minDue),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'statementDate': serializer.toJson<DateTime?>(statementDate),
      'status': serializer.toJson<String>(status),
      'billingCycle': serializer.toJson<String?>(billingCycle),
      'paymentTransactionId': serializer.toJson<String?>(paymentTransactionId),
      'paymentSourceAccountId':
          serializer.toJson<String?>(paymentSourceAccountId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Bill copyWith(
          {String? id,
          String? userId,
          Value<String?> accountId = const Value.absent(),
          String? title,
          int? amount,
          Value<int?> minDue = const Value.absent(),
          Value<DateTime?> dueDate = const Value.absent(),
          Value<DateTime?> statementDate = const Value.absent(),
          String? status,
          Value<String?> billingCycle = const Value.absent(),
          Value<String?> paymentTransactionId = const Value.absent(),
          Value<String?> paymentSourceAccountId = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Bill(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        accountId: accountId.present ? accountId.value : this.accountId,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        minDue: minDue.present ? minDue.value : this.minDue,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        statementDate:
            statementDate.present ? statementDate.value : this.statementDate,
        status: status ?? this.status,
        billingCycle:
            billingCycle.present ? billingCycle.value : this.billingCycle,
        paymentTransactionId: paymentTransactionId.present
            ? paymentTransactionId.value
            : this.paymentTransactionId,
        paymentSourceAccountId: paymentSourceAccountId.present
            ? paymentSourceAccountId.value
            : this.paymentSourceAccountId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Bill copyWithCompanion(BillsCompanion data) {
    return Bill(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      title: data.title.present ? data.title.value : this.title,
      amount: data.amount.present ? data.amount.value : this.amount,
      minDue: data.minDue.present ? data.minDue.value : this.minDue,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      statementDate: data.statementDate.present
          ? data.statementDate.value
          : this.statementDate,
      status: data.status.present ? data.status.value : this.status,
      billingCycle: data.billingCycle.present
          ? data.billingCycle.value
          : this.billingCycle,
      paymentTransactionId: data.paymentTransactionId.present
          ? data.paymentTransactionId.value
          : this.paymentTransactionId,
      paymentSourceAccountId: data.paymentSourceAccountId.present
          ? data.paymentSourceAccountId.value
          : this.paymentSourceAccountId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bill(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('title: $title, ')
          ..write('amount: $amount, ')
          ..write('minDue: $minDue, ')
          ..write('dueDate: $dueDate, ')
          ..write('statementDate: $statementDate, ')
          ..write('status: $status, ')
          ..write('billingCycle: $billingCycle, ')
          ..write('paymentTransactionId: $paymentTransactionId, ')
          ..write('paymentSourceAccountId: $paymentSourceAccountId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      accountId,
      title,
      amount,
      minDue,
      dueDate,
      statementDate,
      status,
      billingCycle,
      paymentTransactionId,
      paymentSourceAccountId,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bill &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.accountId == this.accountId &&
          other.title == this.title &&
          other.amount == this.amount &&
          other.minDue == this.minDue &&
          other.dueDate == this.dueDate &&
          other.statementDate == this.statementDate &&
          other.status == this.status &&
          other.billingCycle == this.billingCycle &&
          other.paymentTransactionId == this.paymentTransactionId &&
          other.paymentSourceAccountId == this.paymentSourceAccountId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BillsCompanion extends UpdateCompanion<Bill> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> accountId;
  final Value<String> title;
  final Value<int> amount;
  final Value<int?> minDue;
  final Value<DateTime?> dueDate;
  final Value<DateTime?> statementDate;
  final Value<String> status;
  final Value<String?> billingCycle;
  final Value<String?> paymentTransactionId;
  final Value<String?> paymentSourceAccountId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BillsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.title = const Value.absent(),
    this.amount = const Value.absent(),
    this.minDue = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.statementDate = const Value.absent(),
    this.status = const Value.absent(),
    this.billingCycle = const Value.absent(),
    this.paymentTransactionId = const Value.absent(),
    this.paymentSourceAccountId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BillsCompanion.insert({
    required String id,
    required String userId,
    this.accountId = const Value.absent(),
    required String title,
    required int amount,
    this.minDue = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.statementDate = const Value.absent(),
    required String status,
    this.billingCycle = const Value.absent(),
    this.paymentTransactionId = const Value.absent(),
    this.paymentSourceAccountId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        title = Value(title),
        amount = Value(amount),
        status = Value(status),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Bill> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? accountId,
    Expression<String>? title,
    Expression<int>? amount,
    Expression<int>? minDue,
    Expression<DateTime>? dueDate,
    Expression<DateTime>? statementDate,
    Expression<String>? status,
    Expression<String>? billingCycle,
    Expression<String>? paymentTransactionId,
    Expression<String>? paymentSourceAccountId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (accountId != null) 'account_id': accountId,
      if (title != null) 'title': title,
      if (amount != null) 'amount': amount,
      if (minDue != null) 'min_due': minDue,
      if (dueDate != null) 'due_date': dueDate,
      if (statementDate != null) 'statement_date': statementDate,
      if (status != null) 'status': status,
      if (billingCycle != null) 'billing_cycle': billingCycle,
      if (paymentTransactionId != null)
        'payment_transaction_id': paymentTransactionId,
      if (paymentSourceAccountId != null)
        'payment_source_account_id': paymentSourceAccountId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BillsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? accountId,
      Value<String>? title,
      Value<int>? amount,
      Value<int?>? minDue,
      Value<DateTime?>? dueDate,
      Value<DateTime?>? statementDate,
      Value<String>? status,
      Value<String?>? billingCycle,
      Value<String?>? paymentTransactionId,
      Value<String?>? paymentSourceAccountId,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return BillsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      minDue: minDue ?? this.minDue,
      dueDate: dueDate ?? this.dueDate,
      statementDate: statementDate ?? this.statementDate,
      status: status ?? this.status,
      billingCycle: billingCycle ?? this.billingCycle,
      paymentTransactionId: paymentTransactionId ?? this.paymentTransactionId,
      paymentSourceAccountId:
          paymentSourceAccountId ?? this.paymentSourceAccountId,
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
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (minDue.present) {
      map['min_due'] = Variable<int>(minDue.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (statementDate.present) {
      map['statement_date'] = Variable<DateTime>(statementDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (billingCycle.present) {
      map['billing_cycle'] = Variable<String>(billingCycle.value);
    }
    if (paymentTransactionId.present) {
      map['payment_transaction_id'] =
          Variable<String>(paymentTransactionId.value);
    }
    if (paymentSourceAccountId.present) {
      map['payment_source_account_id'] =
          Variable<String>(paymentSourceAccountId.value);
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
    return (StringBuffer('BillsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('title: $title, ')
          ..write('amount: $amount, ')
          ..write('minDue: $minDue, ')
          ..write('dueDate: $dueDate, ')
          ..write('statementDate: $statementDate, ')
          ..write('status: $status, ')
          ..write('billingCycle: $billingCycle, ')
          ..write('paymentTransactionId: $paymentTransactionId, ')
          ..write('paymentSourceAccountId: $paymentSourceAccountId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MerchantsTable extends Merchants
    with TableInfo<$MerchantsTable, MerchantEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MerchantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rawNameMeta =
      const VerificationMeta('rawName');
  @override
  late final GeneratedColumn<String> rawName = GeneratedColumn<String>(
      'raw_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _cleanNameMeta =
      const VerificationMeta('cleanName');
  @override
  late final GeneratedColumn<String> cleanName = GeneratedColumn<String>(
      'clean_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
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
  List<GeneratedColumn> get $columns =>
      [id, rawName, cleanName, category, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'merchants';
  @override
  VerificationContext validateIntegrity(Insertable<MerchantEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('raw_name')) {
      context.handle(_rawNameMeta,
          rawName.isAcceptableOrUnknown(data['raw_name']!, _rawNameMeta));
    } else if (isInserting) {
      context.missing(_rawNameMeta);
    }
    if (data.containsKey('clean_name')) {
      context.handle(_cleanNameMeta,
          cleanName.isAcceptableOrUnknown(data['clean_name']!, _cleanNameMeta));
    } else if (isInserting) {
      context.missing(_cleanNameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
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
  MerchantEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MerchantEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      rawName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}raw_name'])!,
      cleanName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}clean_name'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $MerchantsTable createAlias(String alias) {
    return $MerchantsTable(attachedDatabase, alias);
  }
}

class MerchantEntity extends DataClass implements Insertable<MerchantEntity> {
  final String id;
  final String rawName;
  final String cleanName;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MerchantEntity(
      {required this.id,
      required this.rawName,
      required this.cleanName,
      this.category,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['raw_name'] = Variable<String>(rawName);
    map['clean_name'] = Variable<String>(cleanName);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MerchantsCompanion toCompanion(bool nullToAbsent) {
    return MerchantsCompanion(
      id: Value(id),
      rawName: Value(rawName),
      cleanName: Value(cleanName),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MerchantEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MerchantEntity(
      id: serializer.fromJson<String>(json['id']),
      rawName: serializer.fromJson<String>(json['rawName']),
      cleanName: serializer.fromJson<String>(json['cleanName']),
      category: serializer.fromJson<String?>(json['category']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'rawName': serializer.toJson<String>(rawName),
      'cleanName': serializer.toJson<String>(cleanName),
      'category': serializer.toJson<String?>(category),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MerchantEntity copyWith(
          {String? id,
          String? rawName,
          String? cleanName,
          Value<String?> category = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      MerchantEntity(
        id: id ?? this.id,
        rawName: rawName ?? this.rawName,
        cleanName: cleanName ?? this.cleanName,
        category: category.present ? category.value : this.category,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  MerchantEntity copyWithCompanion(MerchantsCompanion data) {
    return MerchantEntity(
      id: data.id.present ? data.id.value : this.id,
      rawName: data.rawName.present ? data.rawName.value : this.rawName,
      cleanName: data.cleanName.present ? data.cleanName.value : this.cleanName,
      category: data.category.present ? data.category.value : this.category,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MerchantEntity(')
          ..write('id: $id, ')
          ..write('rawName: $rawName, ')
          ..write('cleanName: $cleanName, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, rawName, cleanName, category, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MerchantEntity &&
          other.id == this.id &&
          other.rawName == this.rawName &&
          other.cleanName == this.cleanName &&
          other.category == this.category &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MerchantsCompanion extends UpdateCompanion<MerchantEntity> {
  final Value<String> id;
  final Value<String> rawName;
  final Value<String> cleanName;
  final Value<String?> category;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MerchantsCompanion({
    this.id = const Value.absent(),
    this.rawName = const Value.absent(),
    this.cleanName = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MerchantsCompanion.insert({
    required String id,
    required String rawName,
    required String cleanName,
    this.category = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        rawName = Value(rawName),
        cleanName = Value(cleanName),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<MerchantEntity> custom({
    Expression<String>? id,
    Expression<String>? rawName,
    Expression<String>? cleanName,
    Expression<String>? category,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rawName != null) 'raw_name': rawName,
      if (cleanName != null) 'clean_name': cleanName,
      if (category != null) 'category': category,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MerchantsCompanion copyWith(
      {Value<String>? id,
      Value<String>? rawName,
      Value<String>? cleanName,
      Value<String?>? category,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return MerchantsCompanion(
      id: id ?? this.id,
      rawName: rawName ?? this.rawName,
      cleanName: cleanName ?? this.cleanName,
      category: category ?? this.category,
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
    if (rawName.present) {
      map['raw_name'] = Variable<String>(rawName.value);
    }
    if (cleanName.present) {
      map['clean_name'] = Variable<String>(cleanName.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
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
    return (StringBuffer('MerchantsCompanion(')
          ..write('id: $id, ')
          ..write('rawName: $rawName, ')
          ..write('cleanName: $cleanName, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiLearningsTable extends AiLearnings
    with TableInfo<$AiLearningsTable, AiLearning> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiLearningsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _patternKeyMeta =
      const VerificationMeta('patternKey');
  @override
  late final GeneratedColumn<String> patternKey = GeneratedColumn<String>(
      'pattern_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userValueMeta =
      const VerificationMeta('userValue');
  @override
  late final GeneratedColumn<String> userValue = GeneratedColumn<String>(
      'user_value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
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
      [id, userId, patternKey, userValue, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_learnings';
  @override
  VerificationContext validateIntegrity(Insertable<AiLearning> instance,
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
    if (data.containsKey('pattern_key')) {
      context.handle(
          _patternKeyMeta,
          patternKey.isAcceptableOrUnknown(
              data['pattern_key']!, _patternKeyMeta));
    } else if (isInserting) {
      context.missing(_patternKeyMeta);
    }
    if (data.containsKey('user_value')) {
      context.handle(_userValueMeta,
          userValue.isAcceptableOrUnknown(data['user_value']!, _userValueMeta));
    } else if (isInserting) {
      context.missing(_userValueMeta);
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
  AiLearning map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiLearning(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      patternKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pattern_key'])!,
      userValue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_value'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AiLearningsTable createAlias(String alias) {
    return $AiLearningsTable(attachedDatabase, alias);
  }
}

class AiLearning extends DataClass implements Insertable<AiLearning> {
  final String id;
  final String userId;
  final String patternKey;
  final String userValue;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AiLearning(
      {required this.id,
      required this.userId,
      required this.patternKey,
      required this.userValue,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['pattern_key'] = Variable<String>(patternKey);
    map['user_value'] = Variable<String>(userValue);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AiLearningsCompanion toCompanion(bool nullToAbsent) {
    return AiLearningsCompanion(
      id: Value(id),
      userId: Value(userId),
      patternKey: Value(patternKey),
      userValue: Value(userValue),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AiLearning.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiLearning(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      patternKey: serializer.fromJson<String>(json['patternKey']),
      userValue: serializer.fromJson<String>(json['userValue']),
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
      'patternKey': serializer.toJson<String>(patternKey),
      'userValue': serializer.toJson<String>(userValue),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AiLearning copyWith(
          {String? id,
          String? userId,
          String? patternKey,
          String? userValue,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      AiLearning(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        patternKey: patternKey ?? this.patternKey,
        userValue: userValue ?? this.userValue,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AiLearning copyWithCompanion(AiLearningsCompanion data) {
    return AiLearning(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      patternKey:
          data.patternKey.present ? data.patternKey.value : this.patternKey,
      userValue: data.userValue.present ? data.userValue.value : this.userValue,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiLearning(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('patternKey: $patternKey, ')
          ..write('userValue: $userValue, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, patternKey, userValue, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiLearning &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.patternKey == this.patternKey &&
          other.userValue == this.userValue &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AiLearningsCompanion extends UpdateCompanion<AiLearning> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> patternKey;
  final Value<String> userValue;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AiLearningsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.patternKey = const Value.absent(),
    this.userValue = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiLearningsCompanion.insert({
    required String id,
    required String userId,
    required String patternKey,
    required String userValue,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        patternKey = Value(patternKey),
        userValue = Value(userValue),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<AiLearning> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? patternKey,
    Expression<String>? userValue,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (patternKey != null) 'pattern_key': patternKey,
      if (userValue != null) 'user_value': userValue,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiLearningsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? patternKey,
      Value<String>? userValue,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AiLearningsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      patternKey: patternKey ?? this.patternKey,
      userValue: userValue ?? this.userValue,
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
    if (patternKey.present) {
      map['pattern_key'] = Variable<String>(patternKey.value);
    }
    if (userValue.present) {
      map['user_value'] = Variable<String>(userValue.value);
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
    return (StringBuffer('AiLearningsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('patternKey: $patternKey, ')
          ..write('userValue: $userValue, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DuplicateHashesTable extends DuplicateHashes
    with TableInfo<$DuplicateHashesTable, DuplicateHash> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DuplicateHashesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
      'hash', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _transactionIdMeta =
      const VerificationMeta('transactionId');
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
      'transaction_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _billIdMeta = const VerificationMeta('billId');
  @override
  late final GeneratedColumn<String> billId = GeneratedColumn<String>(
      'bill_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, hash, transactionId, billId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'duplicate_hashes';
  @override
  VerificationContext validateIntegrity(Insertable<DuplicateHash> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hash')) {
      context.handle(
          _hashMeta, hash.isAcceptableOrUnknown(data['hash']!, _hashMeta));
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
          _transactionIdMeta,
          transactionId.isAcceptableOrUnknown(
              data['transaction_id']!, _transactionIdMeta));
    }
    if (data.containsKey('bill_id')) {
      context.handle(_billIdMeta,
          billId.isAcceptableOrUnknown(data['bill_id']!, _billIdMeta));
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
  DuplicateHash map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DuplicateHash(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      hash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hash'])!,
      transactionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transaction_id']),
      billId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bill_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DuplicateHashesTable createAlias(String alias) {
    return $DuplicateHashesTable(attachedDatabase, alias);
  }
}

class DuplicateHash extends DataClass implements Insertable<DuplicateHash> {
  final String id;
  final String hash;
  final String? transactionId;
  final String? billId;
  final DateTime createdAt;
  const DuplicateHash(
      {required this.id,
      required this.hash,
      this.transactionId,
      this.billId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hash'] = Variable<String>(hash);
    if (!nullToAbsent || transactionId != null) {
      map['transaction_id'] = Variable<String>(transactionId);
    }
    if (!nullToAbsent || billId != null) {
      map['bill_id'] = Variable<String>(billId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DuplicateHashesCompanion toCompanion(bool nullToAbsent) {
    return DuplicateHashesCompanion(
      id: Value(id),
      hash: Value(hash),
      transactionId: transactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionId),
      billId:
          billId == null && nullToAbsent ? const Value.absent() : Value(billId),
      createdAt: Value(createdAt),
    );
  }

  factory DuplicateHash.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DuplicateHash(
      id: serializer.fromJson<String>(json['id']),
      hash: serializer.fromJson<String>(json['hash']),
      transactionId: serializer.fromJson<String?>(json['transactionId']),
      billId: serializer.fromJson<String?>(json['billId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hash': serializer.toJson<String>(hash),
      'transactionId': serializer.toJson<String?>(transactionId),
      'billId': serializer.toJson<String?>(billId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DuplicateHash copyWith(
          {String? id,
          String? hash,
          Value<String?> transactionId = const Value.absent(),
          Value<String?> billId = const Value.absent(),
          DateTime? createdAt}) =>
      DuplicateHash(
        id: id ?? this.id,
        hash: hash ?? this.hash,
        transactionId:
            transactionId.present ? transactionId.value : this.transactionId,
        billId: billId.present ? billId.value : this.billId,
        createdAt: createdAt ?? this.createdAt,
      );
  DuplicateHash copyWithCompanion(DuplicateHashesCompanion data) {
    return DuplicateHash(
      id: data.id.present ? data.id.value : this.id,
      hash: data.hash.present ? data.hash.value : this.hash,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      billId: data.billId.present ? data.billId.value : this.billId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DuplicateHash(')
          ..write('id: $id, ')
          ..write('hash: $hash, ')
          ..write('transactionId: $transactionId, ')
          ..write('billId: $billId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, hash, transactionId, billId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DuplicateHash &&
          other.id == this.id &&
          other.hash == this.hash &&
          other.transactionId == this.transactionId &&
          other.billId == this.billId &&
          other.createdAt == this.createdAt);
}

class DuplicateHashesCompanion extends UpdateCompanion<DuplicateHash> {
  final Value<String> id;
  final Value<String> hash;
  final Value<String?> transactionId;
  final Value<String?> billId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DuplicateHashesCompanion({
    this.id = const Value.absent(),
    this.hash = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.billId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DuplicateHashesCompanion.insert({
    required String id,
    required String hash,
    this.transactionId = const Value.absent(),
    this.billId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        hash = Value(hash),
        createdAt = Value(createdAt);
  static Insertable<DuplicateHash> custom({
    Expression<String>? id,
    Expression<String>? hash,
    Expression<String>? transactionId,
    Expression<String>? billId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hash != null) 'hash': hash,
      if (transactionId != null) 'transaction_id': transactionId,
      if (billId != null) 'bill_id': billId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DuplicateHashesCompanion copyWith(
      {Value<String>? id,
      Value<String>? hash,
      Value<String?>? transactionId,
      Value<String?>? billId,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return DuplicateHashesCompanion(
      id: id ?? this.id,
      hash: hash ?? this.hash,
      transactionId: transactionId ?? this.transactionId,
      billId: billId ?? this.billId,
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
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (billId.present) {
      map['bill_id'] = Variable<String>(billId.value);
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
    return (StringBuffer('DuplicateHashesCompanion(')
          ..write('id: $id, ')
          ..write('hash: $hash, ')
          ..write('transactionId: $transactionId, ')
          ..write('billId: $billId, ')
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
  late final $GoalsTable goals = $GoalsTable(this);
  late final $SubscriptionsTable subscriptions = $SubscriptionsTable(this);
  late final $FinancialReportsTable financialReports =
      $FinancialReportsTable(this);
  late final $AgentLogsTable agentLogs = $AgentLogsTable(this);
  late final $FinancialPredictionsTable financialPredictions =
      $FinancialPredictionsTable(this);
  late final $AppNotificationsTable appNotifications =
      $AppNotificationsTable(this);
  late final $UnrecognizedMessagesTable unrecognizedMessages =
      $UnrecognizedMessagesTable(this);
  late final $RawSmsTable rawSms = $RawSmsTable(this);
  late final $ParsedSmsTable parsedSms = $ParsedSmsTable(this);
  late final $BillsTable bills = $BillsTable(this);
  late final $MerchantsTable merchants = $MerchantsTable(this);
  late final $AiLearningsTable aiLearnings = $AiLearningsTable(this);
  late final $DuplicateHashesTable duplicateHashes =
      $DuplicateHashesTable(this);
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
  late final GoalDao goalDao = GoalDao(this as AppDatabase);
  late final SubscriptionDao subscriptionDao =
      SubscriptionDao(this as AppDatabase);
  late final ReportDao reportDao = ReportDao(this as AppDatabase);
  late final AgentLogDao agentLogDao = AgentLogDao(this as AppDatabase);
  late final PredictionDao predictionDao = PredictionDao(this as AppDatabase);
  late final NotificationDao notificationDao =
      NotificationDao(this as AppDatabase);
  late final UnrecognizedMessageDao unrecognizedMessageDao =
      UnrecognizedMessageDao(this as AppDatabase);
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
        goals,
        subscriptions,
        financialReports,
        agentLogs,
        financialPredictions,
        appNotifications,
        unrecognizedMessages,
        rawSms,
        parsedSms,
        bills,
        merchants,
        aiLearnings,
        duplicateHashes,
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
  Value<String?> photoUrl,
  Value<DateTime?> lastLogin,
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
  Value<String?> photoUrl,
  Value<DateTime?> lastLogin,
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

  static MultiTypedResultKey<$GoalsTable, List<Goal>> _goalsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.goals,
          aliasName: $_aliasNameGenerator(db.users.id, db.goals.userId));

  $$GoalsTableProcessedTableManager get goalsRefs {
    final manager = $$GoalsTableTableManager($_db, $_db.goals)
        .filter((f) => f.userId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_goalsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SubscriptionsTable, List<Subscription>>
      _subscriptionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.subscriptions,
              aliasName:
                  $_aliasNameGenerator(db.users.id, db.subscriptions.userId));

  $$SubscriptionsTableProcessedTableManager get subscriptionsRefs {
    final manager = $$SubscriptionsTableTableManager($_db, $_db.subscriptions)
        .filter((f) => f.userId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_subscriptionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$FinancialReportsTable, List<FinancialReport>>
      _financialReportsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.financialReports,
              aliasName: $_aliasNameGenerator(
                  db.users.id, db.financialReports.userId));

  $$FinancialReportsTableProcessedTableManager get financialReportsRefs {
    final manager =
        $$FinancialReportsTableTableManager($_db, $_db.financialReports)
            .filter((f) => f.userId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_financialReportsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$FinancialPredictionsTable,
      List<FinancialPrediction>> _financialPredictionsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.financialPredictions,
          aliasName: $_aliasNameGenerator(
              db.users.id, db.financialPredictions.userId));

  $$FinancialPredictionsTableProcessedTableManager
      get financialPredictionsRefs {
    final manager =
        $$FinancialPredictionsTableTableManager($_db, $_db.financialPredictions)
            .filter((f) => f.userId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_financialPredictionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AppNotificationsTable, List<AppNotification>>
      _appNotificationsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.appNotifications,
              aliasName: $_aliasNameGenerator(
                  db.users.id, db.appNotifications.userId));

  $$AppNotificationsTableProcessedTableManager get appNotificationsRefs {
    final manager =
        $$AppNotificationsTableTableManager($_db, $_db.appNotifications)
            .filter((f) => f.userId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_appNotificationsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$UnrecognizedMessagesTable,
      List<UnrecognizedMessage>> _unrecognizedMessagesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.unrecognizedMessages,
          aliasName: $_aliasNameGenerator(
              db.users.id, db.unrecognizedMessages.userId));

  $$UnrecognizedMessagesTableProcessedTableManager
      get unrecognizedMessagesRefs {
    final manager =
        $$UnrecognizedMessagesTableTableManager($_db, $_db.unrecognizedMessages)
            .filter((f) => f.userId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_unrecognizedMessagesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BillsTable, List<Bill>> _billsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.bills,
          aliasName: $_aliasNameGenerator(db.users.id, db.bills.userId));

  $$BillsTableProcessedTableManager get billsRefs {
    final manager = $$BillsTableTableManager($_db, $_db.bills)
        .filter((f) => f.userId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_billsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AiLearningsTable, List<AiLearning>>
      _aiLearningsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.aiLearnings,
          aliasName: $_aliasNameGenerator(db.users.id, db.aiLearnings.userId));

  $$AiLearningsTableProcessedTableManager get aiLearningsRefs {
    final manager = $$AiLearningsTableTableManager($_db, $_db.aiLearnings)
        .filter((f) => f.userId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_aiLearningsRefsTable($_db));
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

  ColumnFilters<String> get photoUrl => $composableBuilder(
      column: $table.photoUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastLogin => $composableBuilder(
      column: $table.lastLogin, builder: (column) => ColumnFilters(column));

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

  Expression<bool> goalsRefs(
      Expression<bool> Function($$GoalsTableFilterComposer f) f) {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableFilterComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> subscriptionsRefs(
      Expression<bool> Function($$SubscriptionsTableFilterComposer f) f) {
    final $$SubscriptionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.subscriptions,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubscriptionsTableFilterComposer(
              $db: $db,
              $table: $db.subscriptions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> financialReportsRefs(
      Expression<bool> Function($$FinancialReportsTableFilterComposer f) f) {
    final $$FinancialReportsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.financialReports,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FinancialReportsTableFilterComposer(
              $db: $db,
              $table: $db.financialReports,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> financialPredictionsRefs(
      Expression<bool> Function($$FinancialPredictionsTableFilterComposer f)
          f) {
    final $$FinancialPredictionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.financialPredictions,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FinancialPredictionsTableFilterComposer(
              $db: $db,
              $table: $db.financialPredictions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> appNotificationsRefs(
      Expression<bool> Function($$AppNotificationsTableFilterComposer f) f) {
    final $$AppNotificationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.appNotifications,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AppNotificationsTableFilterComposer(
              $db: $db,
              $table: $db.appNotifications,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> unrecognizedMessagesRefs(
      Expression<bool> Function($$UnrecognizedMessagesTableFilterComposer f)
          f) {
    final $$UnrecognizedMessagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.unrecognizedMessages,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnrecognizedMessagesTableFilterComposer(
              $db: $db,
              $table: $db.unrecognizedMessages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> billsRefs(
      Expression<bool> Function($$BillsTableFilterComposer f) f) {
    final $$BillsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bills,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BillsTableFilterComposer(
              $db: $db,
              $table: $db.bills,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> aiLearningsRefs(
      Expression<bool> Function($$AiLearningsTableFilterComposer f) f) {
    final $$AiLearningsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.aiLearnings,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AiLearningsTableFilterComposer(
              $db: $db,
              $table: $db.aiLearnings,
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

  ColumnOrderings<String> get photoUrl => $composableBuilder(
      column: $table.photoUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastLogin => $composableBuilder(
      column: $table.lastLogin, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get lastLogin =>
      $composableBuilder(column: $table.lastLogin, builder: (column) => column);

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

  Expression<T> goalsRefs<T extends Object>(
      Expression<T> Function($$GoalsTableAnnotationComposer a) f) {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableAnnotationComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> subscriptionsRefs<T extends Object>(
      Expression<T> Function($$SubscriptionsTableAnnotationComposer a) f) {
    final $$SubscriptionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.subscriptions,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubscriptionsTableAnnotationComposer(
              $db: $db,
              $table: $db.subscriptions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> financialReportsRefs<T extends Object>(
      Expression<T> Function($$FinancialReportsTableAnnotationComposer a) f) {
    final $$FinancialReportsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.financialReports,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FinancialReportsTableAnnotationComposer(
              $db: $db,
              $table: $db.financialReports,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> financialPredictionsRefs<T extends Object>(
      Expression<T> Function($$FinancialPredictionsTableAnnotationComposer a)
          f) {
    final $$FinancialPredictionsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.financialPredictions,
            getReferencedColumn: (t) => t.userId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$FinancialPredictionsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.financialPredictions,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> appNotificationsRefs<T extends Object>(
      Expression<T> Function($$AppNotificationsTableAnnotationComposer a) f) {
    final $$AppNotificationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.appNotifications,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AppNotificationsTableAnnotationComposer(
              $db: $db,
              $table: $db.appNotifications,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> unrecognizedMessagesRefs<T extends Object>(
      Expression<T> Function($$UnrecognizedMessagesTableAnnotationComposer a)
          f) {
    final $$UnrecognizedMessagesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.unrecognizedMessages,
            getReferencedColumn: (t) => t.userId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$UnrecognizedMessagesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.unrecognizedMessages,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> billsRefs<T extends Object>(
      Expression<T> Function($$BillsTableAnnotationComposer a) f) {
    final $$BillsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bills,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BillsTableAnnotationComposer(
              $db: $db,
              $table: $db.bills,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> aiLearningsRefs<T extends Object>(
      Expression<T> Function($$AiLearningsTableAnnotationComposer a) f) {
    final $$AiLearningsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.aiLearnings,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AiLearningsTableAnnotationComposer(
              $db: $db,
              $table: $db.aiLearnings,
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
        bool transactionDraftsRefs,
        bool goalsRefs,
        bool subscriptionsRefs,
        bool financialReportsRefs,
        bool financialPredictionsRefs,
        bool appNotificationsRefs,
        bool unrecognizedMessagesRefs,
        bool billsRefs,
        bool aiLearningsRefs})> {
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
            Value<String?> photoUrl = const Value.absent(),
            Value<DateTime?> lastLogin = const Value.absent(),
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
            photoUrl: photoUrl,
            lastLogin: lastLogin,
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
            Value<String?> photoUrl = const Value.absent(),
            Value<DateTime?> lastLogin = const Value.absent(),
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
            photoUrl: photoUrl,
            lastLogin: lastLogin,
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
              transactionDraftsRefs = false,
              goalsRefs = false,
              subscriptionsRefs = false,
              financialReportsRefs = false,
              financialPredictionsRefs = false,
              appNotificationsRefs = false,
              unrecognizedMessagesRefs = false,
              billsRefs = false,
              aiLearningsRefs = false}) {
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
                if (transactionDraftsRefs) db.transactionDrafts,
                if (goalsRefs) db.goals,
                if (subscriptionsRefs) db.subscriptions,
                if (financialReportsRefs) db.financialReports,
                if (financialPredictionsRefs) db.financialPredictions,
                if (appNotificationsRefs) db.appNotifications,
                if (unrecognizedMessagesRefs) db.unrecognizedMessages,
                if (billsRefs) db.bills,
                if (aiLearningsRefs) db.aiLearnings
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
                        typedResults: items),
                  if (goalsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._goalsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0).goalsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (subscriptionsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._subscriptionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .subscriptionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (financialReportsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$UsersTableReferences
                            ._financialReportsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .financialReportsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (financialPredictionsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$UsersTableReferences
                            ._financialPredictionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .financialPredictionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (appNotificationsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$UsersTableReferences
                            ._appNotificationsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .appNotificationsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (unrecognizedMessagesRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$UsersTableReferences
                            ._unrecognizedMessagesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .unrecognizedMessagesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (billsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._billsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0).billsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (aiLearningsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._aiLearningsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .aiLearningsRefs,
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
        bool transactionDraftsRefs,
        bool goalsRefs,
        bool subscriptionsRefs,
        bool financialReportsRefs,
        bool financialPredictionsRefs,
        bool appNotificationsRefs,
        bool unrecognizedMessagesRefs,
        bool billsRefs,
        bool aiLearningsRefs})>;
typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  required String id,
  required String userId,
  required String name,
  required String type,
  Value<int> balance,
  Value<bool> isDefault,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String?> bankName,
  Value<int?> openingBalance,
  Value<String?> currency,
  Value<String?> colorTheme,
  Value<String?> icon,
  Value<String?> notes,
  Value<bool?> isActive,
  Value<int?> creditLimit,
  Value<int?> availableCredit,
  Value<int?> outstandingBalance,
  Value<int?> statementDate,
  Value<int?> paymentDueDate,
  Value<int?> minAmountDue,
  Value<int?> totalAmountDue,
  Value<int?> lastPayment,
  Value<DateTime?> nextDueDate,
  Value<String?> paymentStatus,
  Value<bool?> autoPay,
  Value<bool> isEstimated,
  Value<String?> last4Digits,
  Value<String?> statementCycle,
  Value<bool?> enableBillReminder,
  Value<bool?> enableSmsTracking,
  Value<int?> verifiedBalance,
  Value<int?> calculatedBalance,
  Value<int?> importedBalance,
  Value<int?> lastSyncedBalance,
  Value<DateTime?> verifiedAt,
  Value<bool?> hasMismatch,
  Value<int?> mismatchExpected,
  Value<int?> mismatchImported,
  Value<int?> sortOrder,
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
  Value<String?> bankName,
  Value<int?> openingBalance,
  Value<String?> currency,
  Value<String?> colorTheme,
  Value<String?> icon,
  Value<String?> notes,
  Value<bool?> isActive,
  Value<int?> creditLimit,
  Value<int?> availableCredit,
  Value<int?> outstandingBalance,
  Value<int?> statementDate,
  Value<int?> paymentDueDate,
  Value<int?> minAmountDue,
  Value<int?> totalAmountDue,
  Value<int?> lastPayment,
  Value<DateTime?> nextDueDate,
  Value<String?> paymentStatus,
  Value<bool?> autoPay,
  Value<bool> isEstimated,
  Value<String?> last4Digits,
  Value<String?> statementCycle,
  Value<bool?> enableBillReminder,
  Value<bool?> enableSmsTracking,
  Value<int?> verifiedBalance,
  Value<int?> calculatedBalance,
  Value<int?> importedBalance,
  Value<int?> lastSyncedBalance,
  Value<DateTime?> verifiedAt,
  Value<bool?> hasMismatch,
  Value<int?> mismatchExpected,
  Value<int?> mismatchImported,
  Value<int?> sortOrder,
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

  ColumnFilters<String> get bankName => $composableBuilder(
      column: $table.bankName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get openingBalance => $composableBuilder(
      column: $table.openingBalance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorTheme => $composableBuilder(
      column: $table.colorTheme, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get creditLimit => $composableBuilder(
      column: $table.creditLimit, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get availableCredit => $composableBuilder(
      column: $table.availableCredit,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get outstandingBalance => $composableBuilder(
      column: $table.outstandingBalance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get statementDate => $composableBuilder(
      column: $table.statementDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get paymentDueDate => $composableBuilder(
      column: $table.paymentDueDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minAmountDue => $composableBuilder(
      column: $table.minAmountDue, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalAmountDue => $composableBuilder(
      column: $table.totalAmountDue,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastPayment => $composableBuilder(
      column: $table.lastPayment, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextDueDate => $composableBuilder(
      column: $table.nextDueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get autoPay => $composableBuilder(
      column: $table.autoPay, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isEstimated => $composableBuilder(
      column: $table.isEstimated, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get last4Digits => $composableBuilder(
      column: $table.last4Digits, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get statementCycle => $composableBuilder(
      column: $table.statementCycle,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enableBillReminder => $composableBuilder(
      column: $table.enableBillReminder,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enableSmsTracking => $composableBuilder(
      column: $table.enableSmsTracking,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get verifiedBalance => $composableBuilder(
      column: $table.verifiedBalance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get calculatedBalance => $composableBuilder(
      column: $table.calculatedBalance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get importedBalance => $composableBuilder(
      column: $table.importedBalance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastSyncedBalance => $composableBuilder(
      column: $table.lastSyncedBalance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get verifiedAt => $composableBuilder(
      column: $table.verifiedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hasMismatch => $composableBuilder(
      column: $table.hasMismatch, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mismatchExpected => $composableBuilder(
      column: $table.mismatchExpected,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mismatchImported => $composableBuilder(
      column: $table.mismatchImported,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<String> get bankName => $composableBuilder(
      column: $table.bankName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get openingBalance => $composableBuilder(
      column: $table.openingBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorTheme => $composableBuilder(
      column: $table.colorTheme, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get creditLimit => $composableBuilder(
      column: $table.creditLimit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get availableCredit => $composableBuilder(
      column: $table.availableCredit,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get outstandingBalance => $composableBuilder(
      column: $table.outstandingBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get statementDate => $composableBuilder(
      column: $table.statementDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get paymentDueDate => $composableBuilder(
      column: $table.paymentDueDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minAmountDue => $composableBuilder(
      column: $table.minAmountDue,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalAmountDue => $composableBuilder(
      column: $table.totalAmountDue,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastPayment => $composableBuilder(
      column: $table.lastPayment, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextDueDate => $composableBuilder(
      column: $table.nextDueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get autoPay => $composableBuilder(
      column: $table.autoPay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isEstimated => $composableBuilder(
      column: $table.isEstimated, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get last4Digits => $composableBuilder(
      column: $table.last4Digits, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get statementCycle => $composableBuilder(
      column: $table.statementCycle,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enableBillReminder => $composableBuilder(
      column: $table.enableBillReminder,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enableSmsTracking => $composableBuilder(
      column: $table.enableSmsTracking,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get verifiedBalance => $composableBuilder(
      column: $table.verifiedBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get calculatedBalance => $composableBuilder(
      column: $table.calculatedBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get importedBalance => $composableBuilder(
      column: $table.importedBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastSyncedBalance => $composableBuilder(
      column: $table.lastSyncedBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get verifiedAt => $composableBuilder(
      column: $table.verifiedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasMismatch => $composableBuilder(
      column: $table.hasMismatch, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mismatchExpected => $composableBuilder(
      column: $table.mismatchExpected,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mismatchImported => $composableBuilder(
      column: $table.mismatchImported,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<int> get openingBalance => $composableBuilder(
      column: $table.openingBalance, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get colorTheme => $composableBuilder(
      column: $table.colorTheme, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get creditLimit => $composableBuilder(
      column: $table.creditLimit, builder: (column) => column);

  GeneratedColumn<int> get availableCredit => $composableBuilder(
      column: $table.availableCredit, builder: (column) => column);

  GeneratedColumn<int> get outstandingBalance => $composableBuilder(
      column: $table.outstandingBalance, builder: (column) => column);

  GeneratedColumn<int> get statementDate => $composableBuilder(
      column: $table.statementDate, builder: (column) => column);

  GeneratedColumn<int> get paymentDueDate => $composableBuilder(
      column: $table.paymentDueDate, builder: (column) => column);

  GeneratedColumn<int> get minAmountDue => $composableBuilder(
      column: $table.minAmountDue, builder: (column) => column);

  GeneratedColumn<int> get totalAmountDue => $composableBuilder(
      column: $table.totalAmountDue, builder: (column) => column);

  GeneratedColumn<int> get lastPayment => $composableBuilder(
      column: $table.lastPayment, builder: (column) => column);

  GeneratedColumn<DateTime> get nextDueDate => $composableBuilder(
      column: $table.nextDueDate, builder: (column) => column);

  GeneratedColumn<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus, builder: (column) => column);

  GeneratedColumn<bool> get autoPay =>
      $composableBuilder(column: $table.autoPay, builder: (column) => column);

  GeneratedColumn<bool> get isEstimated => $composableBuilder(
      column: $table.isEstimated, builder: (column) => column);

  GeneratedColumn<String> get last4Digits => $composableBuilder(
      column: $table.last4Digits, builder: (column) => column);

  GeneratedColumn<String> get statementCycle => $composableBuilder(
      column: $table.statementCycle, builder: (column) => column);

  GeneratedColumn<bool> get enableBillReminder => $composableBuilder(
      column: $table.enableBillReminder, builder: (column) => column);

  GeneratedColumn<bool> get enableSmsTracking => $composableBuilder(
      column: $table.enableSmsTracking, builder: (column) => column);

  GeneratedColumn<int> get verifiedBalance => $composableBuilder(
      column: $table.verifiedBalance, builder: (column) => column);

  GeneratedColumn<int> get calculatedBalance => $composableBuilder(
      column: $table.calculatedBalance, builder: (column) => column);

  GeneratedColumn<int> get importedBalance => $composableBuilder(
      column: $table.importedBalance, builder: (column) => column);

  GeneratedColumn<int> get lastSyncedBalance => $composableBuilder(
      column: $table.lastSyncedBalance, builder: (column) => column);

  GeneratedColumn<DateTime> get verifiedAt => $composableBuilder(
      column: $table.verifiedAt, builder: (column) => column);

  GeneratedColumn<bool> get hasMismatch => $composableBuilder(
      column: $table.hasMismatch, builder: (column) => column);

  GeneratedColumn<int> get mismatchExpected => $composableBuilder(
      column: $table.mismatchExpected, builder: (column) => column);

  GeneratedColumn<int> get mismatchImported => $composableBuilder(
      column: $table.mismatchImported, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

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
            Value<String?> bankName = const Value.absent(),
            Value<int?> openingBalance = const Value.absent(),
            Value<String?> currency = const Value.absent(),
            Value<String?> colorTheme = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool?> isActive = const Value.absent(),
            Value<int?> creditLimit = const Value.absent(),
            Value<int?> availableCredit = const Value.absent(),
            Value<int?> outstandingBalance = const Value.absent(),
            Value<int?> statementDate = const Value.absent(),
            Value<int?> paymentDueDate = const Value.absent(),
            Value<int?> minAmountDue = const Value.absent(),
            Value<int?> totalAmountDue = const Value.absent(),
            Value<int?> lastPayment = const Value.absent(),
            Value<DateTime?> nextDueDate = const Value.absent(),
            Value<String?> paymentStatus = const Value.absent(),
            Value<bool?> autoPay = const Value.absent(),
            Value<bool> isEstimated = const Value.absent(),
            Value<String?> last4Digits = const Value.absent(),
            Value<String?> statementCycle = const Value.absent(),
            Value<bool?> enableBillReminder = const Value.absent(),
            Value<bool?> enableSmsTracking = const Value.absent(),
            Value<int?> verifiedBalance = const Value.absent(),
            Value<int?> calculatedBalance = const Value.absent(),
            Value<int?> importedBalance = const Value.absent(),
            Value<int?> lastSyncedBalance = const Value.absent(),
            Value<DateTime?> verifiedAt = const Value.absent(),
            Value<bool?> hasMismatch = const Value.absent(),
            Value<int?> mismatchExpected = const Value.absent(),
            Value<int?> mismatchImported = const Value.absent(),
            Value<int?> sortOrder = const Value.absent(),
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
            bankName: bankName,
            openingBalance: openingBalance,
            currency: currency,
            colorTheme: colorTheme,
            icon: icon,
            notes: notes,
            isActive: isActive,
            creditLimit: creditLimit,
            availableCredit: availableCredit,
            outstandingBalance: outstandingBalance,
            statementDate: statementDate,
            paymentDueDate: paymentDueDate,
            minAmountDue: minAmountDue,
            totalAmountDue: totalAmountDue,
            lastPayment: lastPayment,
            nextDueDate: nextDueDate,
            paymentStatus: paymentStatus,
            autoPay: autoPay,
            isEstimated: isEstimated,
            last4Digits: last4Digits,
            statementCycle: statementCycle,
            enableBillReminder: enableBillReminder,
            enableSmsTracking: enableSmsTracking,
            verifiedBalance: verifiedBalance,
            calculatedBalance: calculatedBalance,
            importedBalance: importedBalance,
            lastSyncedBalance: lastSyncedBalance,
            verifiedAt: verifiedAt,
            hasMismatch: hasMismatch,
            mismatchExpected: mismatchExpected,
            mismatchImported: mismatchImported,
            sortOrder: sortOrder,
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
            Value<String?> bankName = const Value.absent(),
            Value<int?> openingBalance = const Value.absent(),
            Value<String?> currency = const Value.absent(),
            Value<String?> colorTheme = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool?> isActive = const Value.absent(),
            Value<int?> creditLimit = const Value.absent(),
            Value<int?> availableCredit = const Value.absent(),
            Value<int?> outstandingBalance = const Value.absent(),
            Value<int?> statementDate = const Value.absent(),
            Value<int?> paymentDueDate = const Value.absent(),
            Value<int?> minAmountDue = const Value.absent(),
            Value<int?> totalAmountDue = const Value.absent(),
            Value<int?> lastPayment = const Value.absent(),
            Value<DateTime?> nextDueDate = const Value.absent(),
            Value<String?> paymentStatus = const Value.absent(),
            Value<bool?> autoPay = const Value.absent(),
            Value<bool> isEstimated = const Value.absent(),
            Value<String?> last4Digits = const Value.absent(),
            Value<String?> statementCycle = const Value.absent(),
            Value<bool?> enableBillReminder = const Value.absent(),
            Value<bool?> enableSmsTracking = const Value.absent(),
            Value<int?> verifiedBalance = const Value.absent(),
            Value<int?> calculatedBalance = const Value.absent(),
            Value<int?> importedBalance = const Value.absent(),
            Value<int?> lastSyncedBalance = const Value.absent(),
            Value<DateTime?> verifiedAt = const Value.absent(),
            Value<bool?> hasMismatch = const Value.absent(),
            Value<int?> mismatchExpected = const Value.absent(),
            Value<int?> mismatchImported = const Value.absent(),
            Value<int?> sortOrder = const Value.absent(),
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
            bankName: bankName,
            openingBalance: openingBalance,
            currency: currency,
            colorTheme: colorTheme,
            icon: icon,
            notes: notes,
            isActive: isActive,
            creditLimit: creditLimit,
            availableCredit: availableCredit,
            outstandingBalance: outstandingBalance,
            statementDate: statementDate,
            paymentDueDate: paymentDueDate,
            minAmountDue: minAmountDue,
            totalAmountDue: totalAmountDue,
            lastPayment: lastPayment,
            nextDueDate: nextDueDate,
            paymentStatus: paymentStatus,
            autoPay: autoPay,
            isEstimated: isEstimated,
            last4Digits: last4Digits,
            statementCycle: statementCycle,
            enableBillReminder: enableBillReminder,
            enableSmsTracking: enableSmsTracking,
            verifiedBalance: verifiedBalance,
            calculatedBalance: calculatedBalance,
            importedBalance: importedBalance,
            lastSyncedBalance: lastSyncedBalance,
            verifiedAt: verifiedAt,
            hasMismatch: hasMismatch,
            mismatchExpected: mismatchExpected,
            mismatchImported: mismatchImported,
            sortOrder: sortOrder,
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
  Value<String?> parentId,
  Value<String?> color,
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
  Value<String?> parentId,
  Value<String?> color,
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

  static $CategoriesTable _parentIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
          $_aliasNameGenerator(db.categories.parentId, db.categories.id));

  $$CategoriesTableProcessedTableManager? get parentId {
    if ($_item.parentId == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id($_item.parentId!));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
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

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

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

  $$CategoriesTableFilterComposer get parentId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentId,
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

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

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

  $$CategoriesTableOrderingComposer get parentId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentId,
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

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

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

  $$CategoriesTableAnnotationComposer get parentId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentId,
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
    PrefetchHooks Function({bool userId, bool parentId, bool budgetsRefs})> {
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
            Value<String?> parentId = const Value.absent(),
            Value<String?> color = const Value.absent(),
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
            parentId: parentId,
            color: color,
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
            Value<String?> parentId = const Value.absent(),
            Value<String?> color = const Value.absent(),
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
            parentId: parentId,
            color: color,
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
              {userId = false, parentId = false, budgetsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (budgetsRefs) db.budgets],
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
                if (parentId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.parentId,
                    referencedTable:
                        $$CategoriesTableReferences._parentIdTable(db),
                    referencedColumn:
                        $$CategoriesTableReferences._parentIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
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
    PrefetchHooks Function({bool userId, bool parentId, bool budgetsRefs})>;
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
  Value<String?> subcategoryId,
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
  Value<String?> transactionType,
  Value<String?> accountType,
  Value<String?> billStatus,
  Value<DateTime?> dueDate,
  Value<String?> referenceNumber,
  Value<String?> aiClassification,
  Value<String?> receiptUrl,
  Value<String?> billLink,
  Value<String?> tags,
  Value<String?> fingerprint,
  Value<String?> supportingSms,
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
  Value<String?> subcategoryId,
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
  Value<String?> transactionType,
  Value<String?> accountType,
  Value<String?> billStatus,
  Value<DateTime?> dueDate,
  Value<String?> referenceNumber,
  Value<String?> aiClassification,
  Value<String?> receiptUrl,
  Value<String?> billLink,
  Value<String?> tags,
  Value<String?> fingerprint,
  Value<String?> supportingSms,
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

  static $CategoriesTable _subcategoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias($_aliasNameGenerator(
          db.transactions.subcategoryId, db.categories.id));

  $$CategoriesTableProcessedTableManager? get subcategoryId {
    if ($_item.subcategoryId == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id($_item.subcategoryId!));
    final item = $_typedResult.readTableOrNull(_subcategoryIdTable($_db));
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

  static MultiTypedResultKey<$BillsTable, List<Bill>> _billsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.bills,
          aliasName: $_aliasNameGenerator(
              db.transactions.id, db.bills.paymentTransactionId));

  $$BillsTableProcessedTableManager get billsRefs {
    final manager = $$BillsTableTableManager($_db, $_db.bills)
        .filter((f) => f.paymentTransactionId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_billsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
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

  ColumnFilters<String> get transactionType => $composableBuilder(
      column: $table.transactionType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountType => $composableBuilder(
      column: $table.accountType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get billStatus => $composableBuilder(
      column: $table.billStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get referenceNumber => $composableBuilder(
      column: $table.referenceNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get aiClassification => $composableBuilder(
      column: $table.aiClassification,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get receiptUrl => $composableBuilder(
      column: $table.receiptUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get billLink => $composableBuilder(
      column: $table.billLink, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fingerprint => $composableBuilder(
      column: $table.fingerprint, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supportingSms => $composableBuilder(
      column: $table.supportingSms, builder: (column) => ColumnFilters(column));

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

  $$CategoriesTableFilterComposer get subcategoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subcategoryId,
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

  Expression<bool> billsRefs(
      Expression<bool> Function($$BillsTableFilterComposer f) f) {
    final $$BillsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bills,
        getReferencedColumn: (t) => t.paymentTransactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BillsTableFilterComposer(
              $db: $db,
              $table: $db.bills,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
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

  ColumnOrderings<String> get transactionType => $composableBuilder(
      column: $table.transactionType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountType => $composableBuilder(
      column: $table.accountType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get billStatus => $composableBuilder(
      column: $table.billStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get referenceNumber => $composableBuilder(
      column: $table.referenceNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get aiClassification => $composableBuilder(
      column: $table.aiClassification,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get receiptUrl => $composableBuilder(
      column: $table.receiptUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get billLink => $composableBuilder(
      column: $table.billLink, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fingerprint => $composableBuilder(
      column: $table.fingerprint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supportingSms => $composableBuilder(
      column: $table.supportingSms,
      builder: (column) => ColumnOrderings(column));

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

  $$CategoriesTableOrderingComposer get subcategoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subcategoryId,
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

  GeneratedColumn<String> get transactionType => $composableBuilder(
      column: $table.transactionType, builder: (column) => column);

  GeneratedColumn<String> get accountType => $composableBuilder(
      column: $table.accountType, builder: (column) => column);

  GeneratedColumn<String> get billStatus => $composableBuilder(
      column: $table.billStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get referenceNumber => $composableBuilder(
      column: $table.referenceNumber, builder: (column) => column);

  GeneratedColumn<String> get aiClassification => $composableBuilder(
      column: $table.aiClassification, builder: (column) => column);

  GeneratedColumn<String> get receiptUrl => $composableBuilder(
      column: $table.receiptUrl, builder: (column) => column);

  GeneratedColumn<String> get billLink =>
      $composableBuilder(column: $table.billLink, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get fingerprint => $composableBuilder(
      column: $table.fingerprint, builder: (column) => column);

  GeneratedColumn<String> get supportingSms => $composableBuilder(
      column: $table.supportingSms, builder: (column) => column);

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

  $$CategoriesTableAnnotationComposer get subcategoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subcategoryId,
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

  Expression<T> billsRefs<T extends Object>(
      Expression<T> Function($$BillsTableAnnotationComposer a) f) {
    final $$BillsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bills,
        getReferencedColumn: (t) => t.paymentTransactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BillsTableAnnotationComposer(
              $db: $db,
              $table: $db.bills,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
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
        {bool userId,
        bool accountId,
        bool categoryId,
        bool subcategoryId,
        bool paymentMethodId,
        bool billsRefs})> {
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
            Value<String?> subcategoryId = const Value.absent(),
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
            Value<String?> transactionType = const Value.absent(),
            Value<String?> accountType = const Value.absent(),
            Value<String?> billStatus = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<String?> referenceNumber = const Value.absent(),
            Value<String?> aiClassification = const Value.absent(),
            Value<String?> receiptUrl = const Value.absent(),
            Value<String?> billLink = const Value.absent(),
            Value<String?> tags = const Value.absent(),
            Value<String?> fingerprint = const Value.absent(),
            Value<String?> supportingSms = const Value.absent(),
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
            subcategoryId: subcategoryId,
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
            transactionType: transactionType,
            accountType: accountType,
            billStatus: billStatus,
            dueDate: dueDate,
            referenceNumber: referenceNumber,
            aiClassification: aiClassification,
            receiptUrl: receiptUrl,
            billLink: billLink,
            tags: tags,
            fingerprint: fingerprint,
            supportingSms: supportingSms,
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
            Value<String?> subcategoryId = const Value.absent(),
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
            Value<String?> transactionType = const Value.absent(),
            Value<String?> accountType = const Value.absent(),
            Value<String?> billStatus = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<String?> referenceNumber = const Value.absent(),
            Value<String?> aiClassification = const Value.absent(),
            Value<String?> receiptUrl = const Value.absent(),
            Value<String?> billLink = const Value.absent(),
            Value<String?> tags = const Value.absent(),
            Value<String?> fingerprint = const Value.absent(),
            Value<String?> supportingSms = const Value.absent(),
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
            subcategoryId: subcategoryId,
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
            transactionType: transactionType,
            accountType: accountType,
            billStatus: billStatus,
            dueDate: dueDate,
            referenceNumber: referenceNumber,
            aiClassification: aiClassification,
            receiptUrl: receiptUrl,
            billLink: billLink,
            tags: tags,
            fingerprint: fingerprint,
            supportingSms: supportingSms,
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
              subcategoryId = false,
              paymentMethodId = false,
              billsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (billsRefs) db.bills],
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
                if (subcategoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.subcategoryId,
                    referencedTable:
                        $$TransactionsTableReferences._subcategoryIdTable(db),
                    referencedColumn: $$TransactionsTableReferences
                        ._subcategoryIdTable(db)
                        .id,
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
                return [
                  if (billsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$TransactionsTableReferences._billsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TransactionsTableReferences(db, table, p0)
                                .billsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems.where(
                                (e) => e.paymentTransactionId == item.id),
                        typedResults: items)
                ];
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
        {bool userId,
        bool accountId,
        bool categoryId,
        bool subcategoryId,
        bool paymentMethodId,
        bool billsRefs})>;
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
  Value<String?> categoryId,
  Value<String?> category,
  Value<double?> confidenceScore,
  Value<String?> matchingTransactionId,
  Value<String?> supportingSms,
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
  Value<String?> categoryId,
  Value<String?> category,
  Value<double?> confidenceScore,
  Value<String?> matchingTransactionId,
  Value<String?> supportingSms,
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

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get confidenceScore => $composableBuilder(
      column: $table.confidenceScore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get matchingTransactionId => $composableBuilder(
      column: $table.matchingTransactionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supportingSms => $composableBuilder(
      column: $table.supportingSms, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get confidenceScore => $composableBuilder(
      column: $table.confidenceScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get matchingTransactionId => $composableBuilder(
      column: $table.matchingTransactionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supportingSms => $composableBuilder(
      column: $table.supportingSms,
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

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get confidenceScore => $composableBuilder(
      column: $table.confidenceScore, builder: (column) => column);

  GeneratedColumn<String> get matchingTransactionId => $composableBuilder(
      column: $table.matchingTransactionId, builder: (column) => column);

  GeneratedColumn<String> get supportingSms => $composableBuilder(
      column: $table.supportingSms, builder: (column) => column);

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
            Value<String?> categoryId = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<double?> confidenceScore = const Value.absent(),
            Value<String?> matchingTransactionId = const Value.absent(),
            Value<String?> supportingSms = const Value.absent(),
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
            categoryId: categoryId,
            category: category,
            confidenceScore: confidenceScore,
            matchingTransactionId: matchingTransactionId,
            supportingSms: supportingSms,
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
            Value<String?> categoryId = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<double?> confidenceScore = const Value.absent(),
            Value<String?> matchingTransactionId = const Value.absent(),
            Value<String?> supportingSms = const Value.absent(),
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
            categoryId: categoryId,
            category: category,
            confidenceScore: confidenceScore,
            matchingTransactionId: matchingTransactionId,
            supportingSms: supportingSms,
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
typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  required String id,
  required String userId,
  required String title,
  required int targetAmount,
  required int currentAmount,
  required DateTime targetDate,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> title,
  Value<int> targetAmount,
  Value<int> currentAmount,
  Value<DateTime> targetDate,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$GoalsTableReferences
    extends BaseReferences<_$AppDatabase, $GoalsTable, Goal> {
  $$GoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) =>
      db.users.createAlias($_aliasNameGenerator(db.goals.userId, db.users.id));

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

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetAmount => $composableBuilder(
      column: $table.targetAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentAmount => $composableBuilder(
      column: $table.currentAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => ColumnFilters(column));

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
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetAmount => $composableBuilder(
      column: $table.targetAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentAmount => $composableBuilder(
      column: $table.currentAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => ColumnOrderings(column));

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

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get targetAmount => $composableBuilder(
      column: $table.targetAmount, builder: (column) => column);

  GeneratedColumn<int> get currentAmount => $composableBuilder(
      column: $table.currentAmount, builder: (column) => column);

  GeneratedColumn<DateTime> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => column);

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
}

class $$GoalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GoalsTable,
    Goal,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableAnnotationComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder,
    (Goal, $$GoalsTableReferences),
    Goal,
    PrefetchHooks Function({bool userId})> {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<int> targetAmount = const Value.absent(),
            Value<int> currentAmount = const Value.absent(),
            Value<DateTime> targetDate = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GoalsCompanion(
            id: id,
            userId: userId,
            title: title,
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            targetDate: targetDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String title,
            required int targetAmount,
            required int currentAmount,
            required DateTime targetDate,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              GoalsCompanion.insert(
            id: id,
            userId: userId,
            title: title,
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            targetDate: targetDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$GoalsTableReferences(db, table, e)))
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
                    referencedTable: $$GoalsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$GoalsTableReferences._userIdTable(db).id,
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

typedef $$GoalsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GoalsTable,
    Goal,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableAnnotationComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder,
    (Goal, $$GoalsTableReferences),
    Goal,
    PrefetchHooks Function({bool userId})>;
typedef $$SubscriptionsTableCreateCompanionBuilder = SubscriptionsCompanion
    Function({
  required String id,
  required String userId,
  required String title,
  required int monthlyCost,
  required int annualCost,
  required String billingCycle,
  required DateTime renewalDate,
  required String providerName,
  required double confidence,
  required String status,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SubscriptionsTableUpdateCompanionBuilder = SubscriptionsCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> title,
  Value<int> monthlyCost,
  Value<int> annualCost,
  Value<String> billingCycle,
  Value<DateTime> renewalDate,
  Value<String> providerName,
  Value<double> confidence,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$SubscriptionsTableReferences
    extends BaseReferences<_$AppDatabase, $SubscriptionsTable, Subscription> {
  $$SubscriptionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.subscriptions.userId, db.users.id));

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

class $$SubscriptionsTableFilterComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get monthlyCost => $composableBuilder(
      column: $table.monthlyCost, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get annualCost => $composableBuilder(
      column: $table.annualCost, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get billingCycle => $composableBuilder(
      column: $table.billingCycle, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get renewalDate => $composableBuilder(
      column: $table.renewalDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerName => $composableBuilder(
      column: $table.providerName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

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
}

class $$SubscriptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get monthlyCost => $composableBuilder(
      column: $table.monthlyCost, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get annualCost => $composableBuilder(
      column: $table.annualCost, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get billingCycle => $composableBuilder(
      column: $table.billingCycle,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get renewalDate => $composableBuilder(
      column: $table.renewalDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerName => $composableBuilder(
      column: $table.providerName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

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

class $$SubscriptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get monthlyCost => $composableBuilder(
      column: $table.monthlyCost, builder: (column) => column);

  GeneratedColumn<int> get annualCost => $composableBuilder(
      column: $table.annualCost, builder: (column) => column);

  GeneratedColumn<String> get billingCycle => $composableBuilder(
      column: $table.billingCycle, builder: (column) => column);

  GeneratedColumn<DateTime> get renewalDate => $composableBuilder(
      column: $table.renewalDate, builder: (column) => column);

  GeneratedColumn<String> get providerName => $composableBuilder(
      column: $table.providerName, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

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
}

class $$SubscriptionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SubscriptionsTable,
    Subscription,
    $$SubscriptionsTableFilterComposer,
    $$SubscriptionsTableOrderingComposer,
    $$SubscriptionsTableAnnotationComposer,
    $$SubscriptionsTableCreateCompanionBuilder,
    $$SubscriptionsTableUpdateCompanionBuilder,
    (Subscription, $$SubscriptionsTableReferences),
    Subscription,
    PrefetchHooks Function({bool userId})> {
  $$SubscriptionsTableTableManager(_$AppDatabase db, $SubscriptionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubscriptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubscriptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubscriptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<int> monthlyCost = const Value.absent(),
            Value<int> annualCost = const Value.absent(),
            Value<String> billingCycle = const Value.absent(),
            Value<DateTime> renewalDate = const Value.absent(),
            Value<String> providerName = const Value.absent(),
            Value<double> confidence = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SubscriptionsCompanion(
            id: id,
            userId: userId,
            title: title,
            monthlyCost: monthlyCost,
            annualCost: annualCost,
            billingCycle: billingCycle,
            renewalDate: renewalDate,
            providerName: providerName,
            confidence: confidence,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String title,
            required int monthlyCost,
            required int annualCost,
            required String billingCycle,
            required DateTime renewalDate,
            required String providerName,
            required double confidence,
            required String status,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SubscriptionsCompanion.insert(
            id: id,
            userId: userId,
            title: title,
            monthlyCost: monthlyCost,
            annualCost: annualCost,
            billingCycle: billingCycle,
            renewalDate: renewalDate,
            providerName: providerName,
            confidence: confidence,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SubscriptionsTableReferences(db, table, e)
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
                        $$SubscriptionsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$SubscriptionsTableReferences._userIdTable(db).id,
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

typedef $$SubscriptionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SubscriptionsTable,
    Subscription,
    $$SubscriptionsTableFilterComposer,
    $$SubscriptionsTableOrderingComposer,
    $$SubscriptionsTableAnnotationComposer,
    $$SubscriptionsTableCreateCompanionBuilder,
    $$SubscriptionsTableUpdateCompanionBuilder,
    (Subscription, $$SubscriptionsTableReferences),
    Subscription,
    PrefetchHooks Function({bool userId})>;
typedef $$FinancialReportsTableCreateCompanionBuilder
    = FinancialReportsCompanion Function({
  required String id,
  required String userId,
  required String type,
  required String summaryText,
  required String jsonPayload,
  Value<String?> exportedFilePath,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$FinancialReportsTableUpdateCompanionBuilder
    = FinancialReportsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> type,
  Value<String> summaryText,
  Value<String> jsonPayload,
  Value<String?> exportedFilePath,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$FinancialReportsTableReferences extends BaseReferences<
    _$AppDatabase, $FinancialReportsTable, FinancialReport> {
  $$FinancialReportsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users.createAlias(
      $_aliasNameGenerator(db.financialReports.userId, db.users.id));

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

class $$FinancialReportsTableFilterComposer
    extends Composer<_$AppDatabase, $FinancialReportsTable> {
  $$FinancialReportsTableFilterComposer({
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

  ColumnFilters<String> get summaryText => $composableBuilder(
      column: $table.summaryText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jsonPayload => $composableBuilder(
      column: $table.jsonPayload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exportedFilePath => $composableBuilder(
      column: $table.exportedFilePath,
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
}

class $$FinancialReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $FinancialReportsTable> {
  $$FinancialReportsTableOrderingComposer({
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

  ColumnOrderings<String> get summaryText => $composableBuilder(
      column: $table.summaryText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jsonPayload => $composableBuilder(
      column: $table.jsonPayload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exportedFilePath => $composableBuilder(
      column: $table.exportedFilePath,
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

class $$FinancialReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinancialReportsTable> {
  $$FinancialReportsTableAnnotationComposer({
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

  GeneratedColumn<String> get summaryText => $composableBuilder(
      column: $table.summaryText, builder: (column) => column);

  GeneratedColumn<String> get jsonPayload => $composableBuilder(
      column: $table.jsonPayload, builder: (column) => column);

  GeneratedColumn<String> get exportedFilePath => $composableBuilder(
      column: $table.exportedFilePath, builder: (column) => column);

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

class $$FinancialReportsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FinancialReportsTable,
    FinancialReport,
    $$FinancialReportsTableFilterComposer,
    $$FinancialReportsTableOrderingComposer,
    $$FinancialReportsTableAnnotationComposer,
    $$FinancialReportsTableCreateCompanionBuilder,
    $$FinancialReportsTableUpdateCompanionBuilder,
    (FinancialReport, $$FinancialReportsTableReferences),
    FinancialReport,
    PrefetchHooks Function({bool userId})> {
  $$FinancialReportsTableTableManager(
      _$AppDatabase db, $FinancialReportsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinancialReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinancialReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FinancialReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> summaryText = const Value.absent(),
            Value<String> jsonPayload = const Value.absent(),
            Value<String?> exportedFilePath = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FinancialReportsCompanion(
            id: id,
            userId: userId,
            type: type,
            summaryText: summaryText,
            jsonPayload: jsonPayload,
            exportedFilePath: exportedFilePath,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String type,
            required String summaryText,
            required String jsonPayload,
            Value<String?> exportedFilePath = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              FinancialReportsCompanion.insert(
            id: id,
            userId: userId,
            type: type,
            summaryText: summaryText,
            jsonPayload: jsonPayload,
            exportedFilePath: exportedFilePath,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$FinancialReportsTableReferences(db, table, e)
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
                        $$FinancialReportsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$FinancialReportsTableReferences._userIdTable(db).id,
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

typedef $$FinancialReportsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FinancialReportsTable,
    FinancialReport,
    $$FinancialReportsTableFilterComposer,
    $$FinancialReportsTableOrderingComposer,
    $$FinancialReportsTableAnnotationComposer,
    $$FinancialReportsTableCreateCompanionBuilder,
    $$FinancialReportsTableUpdateCompanionBuilder,
    (FinancialReport, $$FinancialReportsTableReferences),
    FinancialReport,
    PrefetchHooks Function({bool userId})>;
typedef $$AgentLogsTableCreateCompanionBuilder = AgentLogsCompanion Function({
  required String id,
  required String agentName,
  required String actionType,
  required String decisionDescription,
  required double confidenceScore,
  required DateTime timestamp,
  Value<int> rowid,
});
typedef $$AgentLogsTableUpdateCompanionBuilder = AgentLogsCompanion Function({
  Value<String> id,
  Value<String> agentName,
  Value<String> actionType,
  Value<String> decisionDescription,
  Value<double> confidenceScore,
  Value<DateTime> timestamp,
  Value<int> rowid,
});

class $$AgentLogsTableFilterComposer
    extends Composer<_$AppDatabase, $AgentLogsTable> {
  $$AgentLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get agentName => $composableBuilder(
      column: $table.agentName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get actionType => $composableBuilder(
      column: $table.actionType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get decisionDescription => $composableBuilder(
      column: $table.decisionDescription,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get confidenceScore => $composableBuilder(
      column: $table.confidenceScore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));
}

class $$AgentLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $AgentLogsTable> {
  $$AgentLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get agentName => $composableBuilder(
      column: $table.agentName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get actionType => $composableBuilder(
      column: $table.actionType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get decisionDescription => $composableBuilder(
      column: $table.decisionDescription,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get confidenceScore => $composableBuilder(
      column: $table.confidenceScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));
}

class $$AgentLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AgentLogsTable> {
  $$AgentLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get agentName =>
      $composableBuilder(column: $table.agentName, builder: (column) => column);

  GeneratedColumn<String> get actionType => $composableBuilder(
      column: $table.actionType, builder: (column) => column);

  GeneratedColumn<String> get decisionDescription => $composableBuilder(
      column: $table.decisionDescription, builder: (column) => column);

  GeneratedColumn<double> get confidenceScore => $composableBuilder(
      column: $table.confidenceScore, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$AgentLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AgentLogsTable,
    AgentLog,
    $$AgentLogsTableFilterComposer,
    $$AgentLogsTableOrderingComposer,
    $$AgentLogsTableAnnotationComposer,
    $$AgentLogsTableCreateCompanionBuilder,
    $$AgentLogsTableUpdateCompanionBuilder,
    (AgentLog, BaseReferences<_$AppDatabase, $AgentLogsTable, AgentLog>),
    AgentLog,
    PrefetchHooks Function()> {
  $$AgentLogsTableTableManager(_$AppDatabase db, $AgentLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgentLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgentLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgentLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> agentName = const Value.absent(),
            Value<String> actionType = const Value.absent(),
            Value<String> decisionDescription = const Value.absent(),
            Value<double> confidenceScore = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AgentLogsCompanion(
            id: id,
            agentName: agentName,
            actionType: actionType,
            decisionDescription: decisionDescription,
            confidenceScore: confidenceScore,
            timestamp: timestamp,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String agentName,
            required String actionType,
            required String decisionDescription,
            required double confidenceScore,
            required DateTime timestamp,
            Value<int> rowid = const Value.absent(),
          }) =>
              AgentLogsCompanion.insert(
            id: id,
            agentName: agentName,
            actionType: actionType,
            decisionDescription: decisionDescription,
            confidenceScore: confidenceScore,
            timestamp: timestamp,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AgentLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AgentLogsTable,
    AgentLog,
    $$AgentLogsTableFilterComposer,
    $$AgentLogsTableOrderingComposer,
    $$AgentLogsTableAnnotationComposer,
    $$AgentLogsTableCreateCompanionBuilder,
    $$AgentLogsTableUpdateCompanionBuilder,
    (AgentLog, BaseReferences<_$AppDatabase, $AgentLogsTable, AgentLog>),
    AgentLog,
    PrefetchHooks Function()>;
typedef $$FinancialPredictionsTableCreateCompanionBuilder
    = FinancialPredictionsCompanion Function({
  required String id,
  required String userId,
  required DateTime targetDate,
  required int predictedBalance,
  required int predictedExpenses,
  required double confidence,
  required String metricPayload,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$FinancialPredictionsTableUpdateCompanionBuilder
    = FinancialPredictionsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<DateTime> targetDate,
  Value<int> predictedBalance,
  Value<int> predictedExpenses,
  Value<double> confidence,
  Value<String> metricPayload,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$FinancialPredictionsTableReferences extends BaseReferences<
    _$AppDatabase, $FinancialPredictionsTable, FinancialPrediction> {
  $$FinancialPredictionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users.createAlias(
      $_aliasNameGenerator(db.financialPredictions.userId, db.users.id));

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

class $$FinancialPredictionsTableFilterComposer
    extends Composer<_$AppDatabase, $FinancialPredictionsTable> {
  $$FinancialPredictionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get predictedBalance => $composableBuilder(
      column: $table.predictedBalance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get predictedExpenses => $composableBuilder(
      column: $table.predictedExpenses,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metricPayload => $composableBuilder(
      column: $table.metricPayload, builder: (column) => ColumnFilters(column));

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

class $$FinancialPredictionsTableOrderingComposer
    extends Composer<_$AppDatabase, $FinancialPredictionsTable> {
  $$FinancialPredictionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get predictedBalance => $composableBuilder(
      column: $table.predictedBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get predictedExpenses => $composableBuilder(
      column: $table.predictedExpenses,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metricPayload => $composableBuilder(
      column: $table.metricPayload,
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

class $$FinancialPredictionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinancialPredictionsTable> {
  $$FinancialPredictionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => column);

  GeneratedColumn<int> get predictedBalance => $composableBuilder(
      column: $table.predictedBalance, builder: (column) => column);

  GeneratedColumn<int> get predictedExpenses => $composableBuilder(
      column: $table.predictedExpenses, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => column);

  GeneratedColumn<String> get metricPayload => $composableBuilder(
      column: $table.metricPayload, builder: (column) => column);

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

class $$FinancialPredictionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FinancialPredictionsTable,
    FinancialPrediction,
    $$FinancialPredictionsTableFilterComposer,
    $$FinancialPredictionsTableOrderingComposer,
    $$FinancialPredictionsTableAnnotationComposer,
    $$FinancialPredictionsTableCreateCompanionBuilder,
    $$FinancialPredictionsTableUpdateCompanionBuilder,
    (FinancialPrediction, $$FinancialPredictionsTableReferences),
    FinancialPrediction,
    PrefetchHooks Function({bool userId})> {
  $$FinancialPredictionsTableTableManager(
      _$AppDatabase db, $FinancialPredictionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinancialPredictionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinancialPredictionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FinancialPredictionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<DateTime> targetDate = const Value.absent(),
            Value<int> predictedBalance = const Value.absent(),
            Value<int> predictedExpenses = const Value.absent(),
            Value<double> confidence = const Value.absent(),
            Value<String> metricPayload = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FinancialPredictionsCompanion(
            id: id,
            userId: userId,
            targetDate: targetDate,
            predictedBalance: predictedBalance,
            predictedExpenses: predictedExpenses,
            confidence: confidence,
            metricPayload: metricPayload,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required DateTime targetDate,
            required int predictedBalance,
            required int predictedExpenses,
            required double confidence,
            required String metricPayload,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              FinancialPredictionsCompanion.insert(
            id: id,
            userId: userId,
            targetDate: targetDate,
            predictedBalance: predictedBalance,
            predictedExpenses: predictedExpenses,
            confidence: confidence,
            metricPayload: metricPayload,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$FinancialPredictionsTableReferences(db, table, e)
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
                        $$FinancialPredictionsTableReferences._userIdTable(db),
                    referencedColumn: $$FinancialPredictionsTableReferences
                        ._userIdTable(db)
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

typedef $$FinancialPredictionsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $FinancialPredictionsTable,
        FinancialPrediction,
        $$FinancialPredictionsTableFilterComposer,
        $$FinancialPredictionsTableOrderingComposer,
        $$FinancialPredictionsTableAnnotationComposer,
        $$FinancialPredictionsTableCreateCompanionBuilder,
        $$FinancialPredictionsTableUpdateCompanionBuilder,
        (FinancialPrediction, $$FinancialPredictionsTableReferences),
        FinancialPrediction,
        PrefetchHooks Function({bool userId})>;
typedef $$AppNotificationsTableCreateCompanionBuilder
    = AppNotificationsCompanion Function({
  required String id,
  required String userId,
  required String title,
  required String body,
  required String priority,
  required bool isRead,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$AppNotificationsTableUpdateCompanionBuilder
    = AppNotificationsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> title,
  Value<String> body,
  Value<String> priority,
  Value<bool> isRead,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$AppNotificationsTableReferences extends BaseReferences<
    _$AppDatabase, $AppNotificationsTable, AppNotification> {
  $$AppNotificationsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users.createAlias(
      $_aliasNameGenerator(db.appNotifications.userId, db.users.id));

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

class $$AppNotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $AppNotificationsTable> {
  $$AppNotificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnFilters(column));

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

class $$AppNotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppNotificationsTable> {
  $$AppNotificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRead => $composableBuilder(
      column: $table.isRead, builder: (column) => ColumnOrderings(column));

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

class $$AppNotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppNotificationsTable> {
  $$AppNotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

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

class $$AppNotificationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppNotificationsTable,
    AppNotification,
    $$AppNotificationsTableFilterComposer,
    $$AppNotificationsTableOrderingComposer,
    $$AppNotificationsTableAnnotationComposer,
    $$AppNotificationsTableCreateCompanionBuilder,
    $$AppNotificationsTableUpdateCompanionBuilder,
    (AppNotification, $$AppNotificationsTableReferences),
    AppNotification,
    PrefetchHooks Function({bool userId})> {
  $$AppNotificationsTableTableManager(
      _$AppDatabase db, $AppNotificationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppNotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppNotificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppNotificationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<String> priority = const Value.absent(),
            Value<bool> isRead = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppNotificationsCompanion(
            id: id,
            userId: userId,
            title: title,
            body: body,
            priority: priority,
            isRead: isRead,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String title,
            required String body,
            required String priority,
            required bool isRead,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AppNotificationsCompanion.insert(
            id: id,
            userId: userId,
            title: title,
            body: body,
            priority: priority,
            isRead: isRead,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AppNotificationsTableReferences(db, table, e)
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
                        $$AppNotificationsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$AppNotificationsTableReferences._userIdTable(db).id,
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

typedef $$AppNotificationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppNotificationsTable,
    AppNotification,
    $$AppNotificationsTableFilterComposer,
    $$AppNotificationsTableOrderingComposer,
    $$AppNotificationsTableAnnotationComposer,
    $$AppNotificationsTableCreateCompanionBuilder,
    $$AppNotificationsTableUpdateCompanionBuilder,
    (AppNotification, $$AppNotificationsTableReferences),
    AppNotification,
    PrefetchHooks Function({bool userId})>;
typedef $$UnrecognizedMessagesTableCreateCompanionBuilder
    = UnrecognizedMessagesCompanion Function({
  required String id,
  required String userId,
  Value<String?> sender,
  required String body,
  required DateTime date,
  Value<String?> failureReason,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$UnrecognizedMessagesTableUpdateCompanionBuilder
    = UnrecognizedMessagesCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> sender,
  Value<String> body,
  Value<DateTime> date,
  Value<String?> failureReason,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$UnrecognizedMessagesTableReferences extends BaseReferences<
    _$AppDatabase, $UnrecognizedMessagesTable, UnrecognizedMessage> {
  $$UnrecognizedMessagesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users.createAlias(
      $_aliasNameGenerator(db.unrecognizedMessages.userId, db.users.id));

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

class $$UnrecognizedMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $UnrecognizedMessagesTable> {
  $$UnrecognizedMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sender => $composableBuilder(
      column: $table.sender, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get failureReason => $composableBuilder(
      column: $table.failureReason, builder: (column) => ColumnFilters(column));

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

class $$UnrecognizedMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $UnrecognizedMessagesTable> {
  $$UnrecognizedMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sender => $composableBuilder(
      column: $table.sender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get failureReason => $composableBuilder(
      column: $table.failureReason,
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

class $$UnrecognizedMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnrecognizedMessagesTable> {
  $$UnrecognizedMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get failureReason => $composableBuilder(
      column: $table.failureReason, builder: (column) => column);

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

class $$UnrecognizedMessagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UnrecognizedMessagesTable,
    UnrecognizedMessage,
    $$UnrecognizedMessagesTableFilterComposer,
    $$UnrecognizedMessagesTableOrderingComposer,
    $$UnrecognizedMessagesTableAnnotationComposer,
    $$UnrecognizedMessagesTableCreateCompanionBuilder,
    $$UnrecognizedMessagesTableUpdateCompanionBuilder,
    (UnrecognizedMessage, $$UnrecognizedMessagesTableReferences),
    UnrecognizedMessage,
    PrefetchHooks Function({bool userId})> {
  $$UnrecognizedMessagesTableTableManager(
      _$AppDatabase db, $UnrecognizedMessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnrecognizedMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnrecognizedMessagesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnrecognizedMessagesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> sender = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String?> failureReason = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UnrecognizedMessagesCompanion(
            id: id,
            userId: userId,
            sender: sender,
            body: body,
            date: date,
            failureReason: failureReason,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            Value<String?> sender = const Value.absent(),
            required String body,
            required DateTime date,
            Value<String?> failureReason = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              UnrecognizedMessagesCompanion.insert(
            id: id,
            userId: userId,
            sender: sender,
            body: body,
            date: date,
            failureReason: failureReason,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$UnrecognizedMessagesTableReferences(db, table, e)
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
                        $$UnrecognizedMessagesTableReferences._userIdTable(db),
                    referencedColumn: $$UnrecognizedMessagesTableReferences
                        ._userIdTable(db)
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

typedef $$UnrecognizedMessagesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $UnrecognizedMessagesTable,
        UnrecognizedMessage,
        $$UnrecognizedMessagesTableFilterComposer,
        $$UnrecognizedMessagesTableOrderingComposer,
        $$UnrecognizedMessagesTableAnnotationComposer,
        $$UnrecognizedMessagesTableCreateCompanionBuilder,
        $$UnrecognizedMessagesTableUpdateCompanionBuilder,
        (UnrecognizedMessage, $$UnrecognizedMessagesTableReferences),
        UnrecognizedMessage,
        PrefetchHooks Function({bool userId})>;
typedef $$RawSmsTableCreateCompanionBuilder = RawSmsCompanion Function({
  required String id,
  required String body,
  required String sender,
  required DateTime receivedAt,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$RawSmsTableUpdateCompanionBuilder = RawSmsCompanion Function({
  Value<String> id,
  Value<String> body,
  Value<String> sender,
  Value<DateTime> receivedAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$RawSmsTableReferences
    extends BaseReferences<_$AppDatabase, $RawSmsTable, RawSmsEntry> {
  $$RawSmsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ParsedSmsTable, List<ParsedSmsEntry>>
      _parsedSmsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.parsedSms,
          aliasName: $_aliasNameGenerator(db.rawSms.id, db.parsedSms.smsId));

  $$ParsedSmsTableProcessedTableManager get parsedSmsRefs {
    final manager = $$ParsedSmsTableTableManager($_db, $_db.parsedSms)
        .filter((f) => f.smsId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_parsedSmsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RawSmsTableFilterComposer
    extends Composer<_$AppDatabase, $RawSmsTable> {
  $$RawSmsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sender => $composableBuilder(
      column: $table.sender, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> parsedSmsRefs(
      Expression<bool> Function($$ParsedSmsTableFilterComposer f) f) {
    final $$ParsedSmsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.parsedSms,
        getReferencedColumn: (t) => t.smsId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ParsedSmsTableFilterComposer(
              $db: $db,
              $table: $db.parsedSms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RawSmsTableOrderingComposer
    extends Composer<_$AppDatabase, $RawSmsTable> {
  $$RawSmsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sender => $composableBuilder(
      column: $table.sender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$RawSmsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RawSmsTable> {
  $$RawSmsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> parsedSmsRefs<T extends Object>(
      Expression<T> Function($$ParsedSmsTableAnnotationComposer a) f) {
    final $$ParsedSmsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.parsedSms,
        getReferencedColumn: (t) => t.smsId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ParsedSmsTableAnnotationComposer(
              $db: $db,
              $table: $db.parsedSms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RawSmsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RawSmsTable,
    RawSmsEntry,
    $$RawSmsTableFilterComposer,
    $$RawSmsTableOrderingComposer,
    $$RawSmsTableAnnotationComposer,
    $$RawSmsTableCreateCompanionBuilder,
    $$RawSmsTableUpdateCompanionBuilder,
    (RawSmsEntry, $$RawSmsTableReferences),
    RawSmsEntry,
    PrefetchHooks Function({bool parsedSmsRefs})> {
  $$RawSmsTableTableManager(_$AppDatabase db, $RawSmsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RawSmsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RawSmsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RawSmsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<String> sender = const Value.absent(),
            Value<DateTime> receivedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RawSmsCompanion(
            id: id,
            body: body,
            sender: sender,
            receivedAt: receivedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String body,
            required String sender,
            required DateTime receivedAt,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              RawSmsCompanion.insert(
            id: id,
            body: body,
            sender: sender,
            receivedAt: receivedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$RawSmsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({parsedSmsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (parsedSmsRefs) db.parsedSms],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (parsedSmsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$RawSmsTableReferences._parsedSmsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RawSmsTableReferences(db, table, p0)
                                .parsedSmsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.smsId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$RawSmsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RawSmsTable,
    RawSmsEntry,
    $$RawSmsTableFilterComposer,
    $$RawSmsTableOrderingComposer,
    $$RawSmsTableAnnotationComposer,
    $$RawSmsTableCreateCompanionBuilder,
    $$RawSmsTableUpdateCompanionBuilder,
    (RawSmsEntry, $$RawSmsTableReferences),
    RawSmsEntry,
    PrefetchHooks Function({bool parsedSmsRefs})>;
typedef $$ParsedSmsTableCreateCompanionBuilder = ParsedSmsCompanion Function({
  required String id,
  Value<String?> smsId,
  Value<String?> sender,
  Value<DateTime?> receivedAt,
  Value<String?> bankName,
  Value<String?> accountType,
  Value<String?> accountLast4,
  Value<String?> cardType,
  Value<String?> merchant,
  Value<int?> amount,
  Value<bool?> isDebit,
  Value<int?> availableBalance,
  Value<String?> referenceNumber,
  Value<String?> upiId,
  Value<String?> paymentMethod,
  Value<String?> purpose,
  Value<int?> billAmount,
  Value<int?> minDue,
  Value<int?> outstandingAmount,
  Value<DateTime?> dueDate,
  Value<DateTime?> statementDate,
  Value<DateTime?> paymentDate,
  Value<String?> category,
  Value<String?> subcategory,
  Value<String?> transactionType,
  Value<double?> confidenceScore,
  Value<String?> duplicateHash,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$ParsedSmsTableUpdateCompanionBuilder = ParsedSmsCompanion Function({
  Value<String> id,
  Value<String?> smsId,
  Value<String?> sender,
  Value<DateTime?> receivedAt,
  Value<String?> bankName,
  Value<String?> accountType,
  Value<String?> accountLast4,
  Value<String?> cardType,
  Value<String?> merchant,
  Value<int?> amount,
  Value<bool?> isDebit,
  Value<int?> availableBalance,
  Value<String?> referenceNumber,
  Value<String?> upiId,
  Value<String?> paymentMethod,
  Value<String?> purpose,
  Value<int?> billAmount,
  Value<int?> minDue,
  Value<int?> outstandingAmount,
  Value<DateTime?> dueDate,
  Value<DateTime?> statementDate,
  Value<DateTime?> paymentDate,
  Value<String?> category,
  Value<String?> subcategory,
  Value<String?> transactionType,
  Value<double?> confidenceScore,
  Value<String?> duplicateHash,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$ParsedSmsTableReferences
    extends BaseReferences<_$AppDatabase, $ParsedSmsTable, ParsedSmsEntry> {
  $$ParsedSmsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RawSmsTable _smsIdTable(_$AppDatabase db) => db.rawSms
      .createAlias($_aliasNameGenerator(db.parsedSms.smsId, db.rawSms.id));

  $$RawSmsTableProcessedTableManager? get smsId {
    if ($_item.smsId == null) return null;
    final manager = $$RawSmsTableTableManager($_db, $_db.rawSms)
        .filter((f) => f.id($_item.smsId!));
    final item = $_typedResult.readTableOrNull(_smsIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ParsedSmsTableFilterComposer
    extends Composer<_$AppDatabase, $ParsedSmsTable> {
  $$ParsedSmsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sender => $composableBuilder(
      column: $table.sender, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bankName => $composableBuilder(
      column: $table.bankName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountType => $composableBuilder(
      column: $table.accountType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountLast4 => $composableBuilder(
      column: $table.accountLast4, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cardType => $composableBuilder(
      column: $table.cardType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get merchant => $composableBuilder(
      column: $table.merchant, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDebit => $composableBuilder(
      column: $table.isDebit, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get availableBalance => $composableBuilder(
      column: $table.availableBalance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get referenceNumber => $composableBuilder(
      column: $table.referenceNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get upiId => $composableBuilder(
      column: $table.upiId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get purpose => $composableBuilder(
      column: $table.purpose, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get billAmount => $composableBuilder(
      column: $table.billAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minDue => $composableBuilder(
      column: $table.minDue, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get outstandingAmount => $composableBuilder(
      column: $table.outstandingAmount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get statementDate => $composableBuilder(
      column: $table.statementDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get paymentDate => $composableBuilder(
      column: $table.paymentDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subcategory => $composableBuilder(
      column: $table.subcategory, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transactionType => $composableBuilder(
      column: $table.transactionType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get confidenceScore => $composableBuilder(
      column: $table.confidenceScore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get duplicateHash => $composableBuilder(
      column: $table.duplicateHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$RawSmsTableFilterComposer get smsId {
    final $$RawSmsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.smsId,
        referencedTable: $db.rawSms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RawSmsTableFilterComposer(
              $db: $db,
              $table: $db.rawSms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ParsedSmsTableOrderingComposer
    extends Composer<_$AppDatabase, $ParsedSmsTable> {
  $$ParsedSmsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sender => $composableBuilder(
      column: $table.sender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bankName => $composableBuilder(
      column: $table.bankName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountType => $composableBuilder(
      column: $table.accountType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountLast4 => $composableBuilder(
      column: $table.accountLast4,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cardType => $composableBuilder(
      column: $table.cardType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get merchant => $composableBuilder(
      column: $table.merchant, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDebit => $composableBuilder(
      column: $table.isDebit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get availableBalance => $composableBuilder(
      column: $table.availableBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get referenceNumber => $composableBuilder(
      column: $table.referenceNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get upiId => $composableBuilder(
      column: $table.upiId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get purpose => $composableBuilder(
      column: $table.purpose, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get billAmount => $composableBuilder(
      column: $table.billAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minDue => $composableBuilder(
      column: $table.minDue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get outstandingAmount => $composableBuilder(
      column: $table.outstandingAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get statementDate => $composableBuilder(
      column: $table.statementDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get paymentDate => $composableBuilder(
      column: $table.paymentDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subcategory => $composableBuilder(
      column: $table.subcategory, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transactionType => $composableBuilder(
      column: $table.transactionType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get confidenceScore => $composableBuilder(
      column: $table.confidenceScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get duplicateHash => $composableBuilder(
      column: $table.duplicateHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$RawSmsTableOrderingComposer get smsId {
    final $$RawSmsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.smsId,
        referencedTable: $db.rawSms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RawSmsTableOrderingComposer(
              $db: $db,
              $table: $db.rawSms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ParsedSmsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ParsedSmsTable> {
  $$ParsedSmsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => column);

  GeneratedColumn<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<String> get accountType => $composableBuilder(
      column: $table.accountType, builder: (column) => column);

  GeneratedColumn<String> get accountLast4 => $composableBuilder(
      column: $table.accountLast4, builder: (column) => column);

  GeneratedColumn<String> get cardType =>
      $composableBuilder(column: $table.cardType, builder: (column) => column);

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<bool> get isDebit =>
      $composableBuilder(column: $table.isDebit, builder: (column) => column);

  GeneratedColumn<int> get availableBalance => $composableBuilder(
      column: $table.availableBalance, builder: (column) => column);

  GeneratedColumn<String> get referenceNumber => $composableBuilder(
      column: $table.referenceNumber, builder: (column) => column);

  GeneratedColumn<String> get upiId =>
      $composableBuilder(column: $table.upiId, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => column);

  GeneratedColumn<String> get purpose =>
      $composableBuilder(column: $table.purpose, builder: (column) => column);

  GeneratedColumn<int> get billAmount => $composableBuilder(
      column: $table.billAmount, builder: (column) => column);

  GeneratedColumn<int> get minDue =>
      $composableBuilder(column: $table.minDue, builder: (column) => column);

  GeneratedColumn<int> get outstandingAmount => $composableBuilder(
      column: $table.outstandingAmount, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get statementDate => $composableBuilder(
      column: $table.statementDate, builder: (column) => column);

  GeneratedColumn<DateTime> get paymentDate => $composableBuilder(
      column: $table.paymentDate, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get subcategory => $composableBuilder(
      column: $table.subcategory, builder: (column) => column);

  GeneratedColumn<String> get transactionType => $composableBuilder(
      column: $table.transactionType, builder: (column) => column);

  GeneratedColumn<double> get confidenceScore => $composableBuilder(
      column: $table.confidenceScore, builder: (column) => column);

  GeneratedColumn<String> get duplicateHash => $composableBuilder(
      column: $table.duplicateHash, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$RawSmsTableAnnotationComposer get smsId {
    final $$RawSmsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.smsId,
        referencedTable: $db.rawSms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RawSmsTableAnnotationComposer(
              $db: $db,
              $table: $db.rawSms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ParsedSmsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ParsedSmsTable,
    ParsedSmsEntry,
    $$ParsedSmsTableFilterComposer,
    $$ParsedSmsTableOrderingComposer,
    $$ParsedSmsTableAnnotationComposer,
    $$ParsedSmsTableCreateCompanionBuilder,
    $$ParsedSmsTableUpdateCompanionBuilder,
    (ParsedSmsEntry, $$ParsedSmsTableReferences),
    ParsedSmsEntry,
    PrefetchHooks Function({bool smsId})> {
  $$ParsedSmsTableTableManager(_$AppDatabase db, $ParsedSmsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ParsedSmsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ParsedSmsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ParsedSmsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> smsId = const Value.absent(),
            Value<String?> sender = const Value.absent(),
            Value<DateTime?> receivedAt = const Value.absent(),
            Value<String?> bankName = const Value.absent(),
            Value<String?> accountType = const Value.absent(),
            Value<String?> accountLast4 = const Value.absent(),
            Value<String?> cardType = const Value.absent(),
            Value<String?> merchant = const Value.absent(),
            Value<int?> amount = const Value.absent(),
            Value<bool?> isDebit = const Value.absent(),
            Value<int?> availableBalance = const Value.absent(),
            Value<String?> referenceNumber = const Value.absent(),
            Value<String?> upiId = const Value.absent(),
            Value<String?> paymentMethod = const Value.absent(),
            Value<String?> purpose = const Value.absent(),
            Value<int?> billAmount = const Value.absent(),
            Value<int?> minDue = const Value.absent(),
            Value<int?> outstandingAmount = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<DateTime?> statementDate = const Value.absent(),
            Value<DateTime?> paymentDate = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String?> subcategory = const Value.absent(),
            Value<String?> transactionType = const Value.absent(),
            Value<double?> confidenceScore = const Value.absent(),
            Value<String?> duplicateHash = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ParsedSmsCompanion(
            id: id,
            smsId: smsId,
            sender: sender,
            receivedAt: receivedAt,
            bankName: bankName,
            accountType: accountType,
            accountLast4: accountLast4,
            cardType: cardType,
            merchant: merchant,
            amount: amount,
            isDebit: isDebit,
            availableBalance: availableBalance,
            referenceNumber: referenceNumber,
            upiId: upiId,
            paymentMethod: paymentMethod,
            purpose: purpose,
            billAmount: billAmount,
            minDue: minDue,
            outstandingAmount: outstandingAmount,
            dueDate: dueDate,
            statementDate: statementDate,
            paymentDate: paymentDate,
            category: category,
            subcategory: subcategory,
            transactionType: transactionType,
            confidenceScore: confidenceScore,
            duplicateHash: duplicateHash,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> smsId = const Value.absent(),
            Value<String?> sender = const Value.absent(),
            Value<DateTime?> receivedAt = const Value.absent(),
            Value<String?> bankName = const Value.absent(),
            Value<String?> accountType = const Value.absent(),
            Value<String?> accountLast4 = const Value.absent(),
            Value<String?> cardType = const Value.absent(),
            Value<String?> merchant = const Value.absent(),
            Value<int?> amount = const Value.absent(),
            Value<bool?> isDebit = const Value.absent(),
            Value<int?> availableBalance = const Value.absent(),
            Value<String?> referenceNumber = const Value.absent(),
            Value<String?> upiId = const Value.absent(),
            Value<String?> paymentMethod = const Value.absent(),
            Value<String?> purpose = const Value.absent(),
            Value<int?> billAmount = const Value.absent(),
            Value<int?> minDue = const Value.absent(),
            Value<int?> outstandingAmount = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<DateTime?> statementDate = const Value.absent(),
            Value<DateTime?> paymentDate = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String?> subcategory = const Value.absent(),
            Value<String?> transactionType = const Value.absent(),
            Value<double?> confidenceScore = const Value.absent(),
            Value<String?> duplicateHash = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ParsedSmsCompanion.insert(
            id: id,
            smsId: smsId,
            sender: sender,
            receivedAt: receivedAt,
            bankName: bankName,
            accountType: accountType,
            accountLast4: accountLast4,
            cardType: cardType,
            merchant: merchant,
            amount: amount,
            isDebit: isDebit,
            availableBalance: availableBalance,
            referenceNumber: referenceNumber,
            upiId: upiId,
            paymentMethod: paymentMethod,
            purpose: purpose,
            billAmount: billAmount,
            minDue: minDue,
            outstandingAmount: outstandingAmount,
            dueDate: dueDate,
            statementDate: statementDate,
            paymentDate: paymentDate,
            category: category,
            subcategory: subcategory,
            transactionType: transactionType,
            confidenceScore: confidenceScore,
            duplicateHash: duplicateHash,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ParsedSmsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({smsId = false}) {
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
                if (smsId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.smsId,
                    referencedTable: $$ParsedSmsTableReferences._smsIdTable(db),
                    referencedColumn:
                        $$ParsedSmsTableReferences._smsIdTable(db).id,
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

typedef $$ParsedSmsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ParsedSmsTable,
    ParsedSmsEntry,
    $$ParsedSmsTableFilterComposer,
    $$ParsedSmsTableOrderingComposer,
    $$ParsedSmsTableAnnotationComposer,
    $$ParsedSmsTableCreateCompanionBuilder,
    $$ParsedSmsTableUpdateCompanionBuilder,
    (ParsedSmsEntry, $$ParsedSmsTableReferences),
    ParsedSmsEntry,
    PrefetchHooks Function({bool smsId})>;
typedef $$BillsTableCreateCompanionBuilder = BillsCompanion Function({
  required String id,
  required String userId,
  Value<String?> accountId,
  required String title,
  required int amount,
  Value<int?> minDue,
  Value<DateTime?> dueDate,
  Value<DateTime?> statementDate,
  required String status,
  Value<String?> billingCycle,
  Value<String?> paymentTransactionId,
  Value<String?> paymentSourceAccountId,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$BillsTableUpdateCompanionBuilder = BillsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String?> accountId,
  Value<String> title,
  Value<int> amount,
  Value<int?> minDue,
  Value<DateTime?> dueDate,
  Value<DateTime?> statementDate,
  Value<String> status,
  Value<String?> billingCycle,
  Value<String?> paymentTransactionId,
  Value<String?> paymentSourceAccountId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$BillsTableReferences
    extends BaseReferences<_$AppDatabase, $BillsTable, Bill> {
  $$BillsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) =>
      db.users.createAlias($_aliasNameGenerator(db.bills.userId, db.users.id));

  $$UsersTableProcessedTableManager? get userId {
    if ($_item.userId == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id($_item.userId!));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) => db.accounts
      .createAlias($_aliasNameGenerator(db.bills.accountId, db.accounts.id));

  $$AccountsTableProcessedTableManager? get accountId {
    if ($_item.accountId == null) return null;
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id($_item.accountId!));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $TransactionsTable _paymentTransactionIdTable(_$AppDatabase db) =>
      db.transactions.createAlias($_aliasNameGenerator(
          db.bills.paymentTransactionId, db.transactions.id));

  $$TransactionsTableProcessedTableManager? get paymentTransactionId {
    if ($_item.paymentTransactionId == null) return null;
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.id($_item.paymentTransactionId!));
    final item =
        $_typedResult.readTableOrNull(_paymentTransactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _paymentSourceAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias($_aliasNameGenerator(
          db.bills.paymentSourceAccountId, db.accounts.id));

  $$AccountsTableProcessedTableManager? get paymentSourceAccountId {
    if ($_item.paymentSourceAccountId == null) return null;
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id($_item.paymentSourceAccountId!));
    final item =
        $_typedResult.readTableOrNull(_paymentSourceAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BillsTableFilterComposer extends Composer<_$AppDatabase, $BillsTable> {
  $$BillsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minDue => $composableBuilder(
      column: $table.minDue, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get statementDate => $composableBuilder(
      column: $table.statementDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get billingCycle => $composableBuilder(
      column: $table.billingCycle, builder: (column) => ColumnFilters(column));

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

  $$TransactionsTableFilterComposer get paymentTransactionId {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.paymentTransactionId,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  $$AccountsTableFilterComposer get paymentSourceAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.paymentSourceAccountId,
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
}

class $$BillsTableOrderingComposer
    extends Composer<_$AppDatabase, $BillsTable> {
  $$BillsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minDue => $composableBuilder(
      column: $table.minDue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get statementDate => $composableBuilder(
      column: $table.statementDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get billingCycle => $composableBuilder(
      column: $table.billingCycle,
      builder: (column) => ColumnOrderings(column));

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

  $$TransactionsTableOrderingComposer get paymentTransactionId {
    final $$TransactionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.paymentTransactionId,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableOrderingComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get paymentSourceAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.paymentSourceAccountId,
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

class $$BillsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BillsTable> {
  $$BillsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get minDue =>
      $composableBuilder(column: $table.minDue, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get statementDate => $composableBuilder(
      column: $table.statementDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get billingCycle => $composableBuilder(
      column: $table.billingCycle, builder: (column) => column);

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

  $$TransactionsTableAnnotationComposer get paymentTransactionId {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.paymentTransactionId,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  $$AccountsTableAnnotationComposer get paymentSourceAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.paymentSourceAccountId,
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
}

class $$BillsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BillsTable,
    Bill,
    $$BillsTableFilterComposer,
    $$BillsTableOrderingComposer,
    $$BillsTableAnnotationComposer,
    $$BillsTableCreateCompanionBuilder,
    $$BillsTableUpdateCompanionBuilder,
    (Bill, $$BillsTableReferences),
    Bill,
    PrefetchHooks Function(
        {bool userId,
        bool accountId,
        bool paymentTransactionId,
        bool paymentSourceAccountId})> {
  $$BillsTableTableManager(_$AppDatabase db, $BillsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BillsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BillsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BillsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> accountId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<int?> minDue = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<DateTime?> statementDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> billingCycle = const Value.absent(),
            Value<String?> paymentTransactionId = const Value.absent(),
            Value<String?> paymentSourceAccountId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BillsCompanion(
            id: id,
            userId: userId,
            accountId: accountId,
            title: title,
            amount: amount,
            minDue: minDue,
            dueDate: dueDate,
            statementDate: statementDate,
            status: status,
            billingCycle: billingCycle,
            paymentTransactionId: paymentTransactionId,
            paymentSourceAccountId: paymentSourceAccountId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            Value<String?> accountId = const Value.absent(),
            required String title,
            required int amount,
            Value<int?> minDue = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<DateTime?> statementDate = const Value.absent(),
            required String status,
            Value<String?> billingCycle = const Value.absent(),
            Value<String?> paymentTransactionId = const Value.absent(),
            Value<String?> paymentSourceAccountId = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BillsCompanion.insert(
            id: id,
            userId: userId,
            accountId: accountId,
            title: title,
            amount: amount,
            minDue: minDue,
            dueDate: dueDate,
            statementDate: statementDate,
            status: status,
            billingCycle: billingCycle,
            paymentTransactionId: paymentTransactionId,
            paymentSourceAccountId: paymentSourceAccountId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$BillsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {userId = false,
              accountId = false,
              paymentTransactionId = false,
              paymentSourceAccountId = false}) {
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
                    referencedTable: $$BillsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$BillsTableReferences._userIdTable(db).id,
                  ) as T;
                }
                if (accountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.accountId,
                    referencedTable: $$BillsTableReferences._accountIdTable(db),
                    referencedColumn:
                        $$BillsTableReferences._accountIdTable(db).id,
                  ) as T;
                }
                if (paymentTransactionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.paymentTransactionId,
                    referencedTable:
                        $$BillsTableReferences._paymentTransactionIdTable(db),
                    referencedColumn: $$BillsTableReferences
                        ._paymentTransactionIdTable(db)
                        .id,
                  ) as T;
                }
                if (paymentSourceAccountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.paymentSourceAccountId,
                    referencedTable:
                        $$BillsTableReferences._paymentSourceAccountIdTable(db),
                    referencedColumn: $$BillsTableReferences
                        ._paymentSourceAccountIdTable(db)
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

typedef $$BillsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BillsTable,
    Bill,
    $$BillsTableFilterComposer,
    $$BillsTableOrderingComposer,
    $$BillsTableAnnotationComposer,
    $$BillsTableCreateCompanionBuilder,
    $$BillsTableUpdateCompanionBuilder,
    (Bill, $$BillsTableReferences),
    Bill,
    PrefetchHooks Function(
        {bool userId,
        bool accountId,
        bool paymentTransactionId,
        bool paymentSourceAccountId})>;
typedef $$MerchantsTableCreateCompanionBuilder = MerchantsCompanion Function({
  required String id,
  required String rawName,
  required String cleanName,
  Value<String?> category,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$MerchantsTableUpdateCompanionBuilder = MerchantsCompanion Function({
  Value<String> id,
  Value<String> rawName,
  Value<String> cleanName,
  Value<String?> category,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$MerchantsTableFilterComposer
    extends Composer<_$AppDatabase, $MerchantsTable> {
  $$MerchantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rawName => $composableBuilder(
      column: $table.rawName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cleanName => $composableBuilder(
      column: $table.cleanName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$MerchantsTableOrderingComposer
    extends Composer<_$AppDatabase, $MerchantsTable> {
  $$MerchantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rawName => $composableBuilder(
      column: $table.rawName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cleanName => $composableBuilder(
      column: $table.cleanName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$MerchantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MerchantsTable> {
  $$MerchantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rawName =>
      $composableBuilder(column: $table.rawName, builder: (column) => column);

  GeneratedColumn<String> get cleanName =>
      $composableBuilder(column: $table.cleanName, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MerchantsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MerchantsTable,
    MerchantEntity,
    $$MerchantsTableFilterComposer,
    $$MerchantsTableOrderingComposer,
    $$MerchantsTableAnnotationComposer,
    $$MerchantsTableCreateCompanionBuilder,
    $$MerchantsTableUpdateCompanionBuilder,
    (
      MerchantEntity,
      BaseReferences<_$AppDatabase, $MerchantsTable, MerchantEntity>
    ),
    MerchantEntity,
    PrefetchHooks Function()> {
  $$MerchantsTableTableManager(_$AppDatabase db, $MerchantsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MerchantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MerchantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MerchantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> rawName = const Value.absent(),
            Value<String> cleanName = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MerchantsCompanion(
            id: id,
            rawName: rawName,
            cleanName: cleanName,
            category: category,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String rawName,
            required String cleanName,
            Value<String?> category = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              MerchantsCompanion.insert(
            id: id,
            rawName: rawName,
            cleanName: cleanName,
            category: category,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MerchantsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MerchantsTable,
    MerchantEntity,
    $$MerchantsTableFilterComposer,
    $$MerchantsTableOrderingComposer,
    $$MerchantsTableAnnotationComposer,
    $$MerchantsTableCreateCompanionBuilder,
    $$MerchantsTableUpdateCompanionBuilder,
    (
      MerchantEntity,
      BaseReferences<_$AppDatabase, $MerchantsTable, MerchantEntity>
    ),
    MerchantEntity,
    PrefetchHooks Function()>;
typedef $$AiLearningsTableCreateCompanionBuilder = AiLearningsCompanion
    Function({
  required String id,
  required String userId,
  required String patternKey,
  required String userValue,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$AiLearningsTableUpdateCompanionBuilder = AiLearningsCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> patternKey,
  Value<String> userValue,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$AiLearningsTableReferences
    extends BaseReferences<_$AppDatabase, $AiLearningsTable, AiLearning> {
  $$AiLearningsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.aiLearnings.userId, db.users.id));

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

class $$AiLearningsTableFilterComposer
    extends Composer<_$AppDatabase, $AiLearningsTable> {
  $$AiLearningsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get patternKey => $composableBuilder(
      column: $table.patternKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userValue => $composableBuilder(
      column: $table.userValue, builder: (column) => ColumnFilters(column));

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
}

class $$AiLearningsTableOrderingComposer
    extends Composer<_$AppDatabase, $AiLearningsTable> {
  $$AiLearningsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get patternKey => $composableBuilder(
      column: $table.patternKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userValue => $composableBuilder(
      column: $table.userValue, builder: (column) => ColumnOrderings(column));

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

class $$AiLearningsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiLearningsTable> {
  $$AiLearningsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get patternKey => $composableBuilder(
      column: $table.patternKey, builder: (column) => column);

  GeneratedColumn<String> get userValue =>
      $composableBuilder(column: $table.userValue, builder: (column) => column);

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
}

class $$AiLearningsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AiLearningsTable,
    AiLearning,
    $$AiLearningsTableFilterComposer,
    $$AiLearningsTableOrderingComposer,
    $$AiLearningsTableAnnotationComposer,
    $$AiLearningsTableCreateCompanionBuilder,
    $$AiLearningsTableUpdateCompanionBuilder,
    (AiLearning, $$AiLearningsTableReferences),
    AiLearning,
    PrefetchHooks Function({bool userId})> {
  $$AiLearningsTableTableManager(_$AppDatabase db, $AiLearningsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiLearningsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiLearningsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiLearningsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> patternKey = const Value.absent(),
            Value<String> userValue = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AiLearningsCompanion(
            id: id,
            userId: userId,
            patternKey: patternKey,
            userValue: userValue,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String patternKey,
            required String userValue,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AiLearningsCompanion.insert(
            id: id,
            userId: userId,
            patternKey: patternKey,
            userValue: userValue,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AiLearningsTableReferences(db, table, e)
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
                        $$AiLearningsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$AiLearningsTableReferences._userIdTable(db).id,
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

typedef $$AiLearningsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AiLearningsTable,
    AiLearning,
    $$AiLearningsTableFilterComposer,
    $$AiLearningsTableOrderingComposer,
    $$AiLearningsTableAnnotationComposer,
    $$AiLearningsTableCreateCompanionBuilder,
    $$AiLearningsTableUpdateCompanionBuilder,
    (AiLearning, $$AiLearningsTableReferences),
    AiLearning,
    PrefetchHooks Function({bool userId})>;
typedef $$DuplicateHashesTableCreateCompanionBuilder = DuplicateHashesCompanion
    Function({
  required String id,
  required String hash,
  Value<String?> transactionId,
  Value<String?> billId,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$DuplicateHashesTableUpdateCompanionBuilder = DuplicateHashesCompanion
    Function({
  Value<String> id,
  Value<String> hash,
  Value<String?> transactionId,
  Value<String?> billId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$DuplicateHashesTableFilterComposer
    extends Composer<_$AppDatabase, $DuplicateHashesTable> {
  $$DuplicateHashesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hash => $composableBuilder(
      column: $table.hash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transactionId => $composableBuilder(
      column: $table.transactionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get billId => $composableBuilder(
      column: $table.billId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$DuplicateHashesTableOrderingComposer
    extends Composer<_$AppDatabase, $DuplicateHashesTable> {
  $$DuplicateHashesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hash => $composableBuilder(
      column: $table.hash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transactionId => $composableBuilder(
      column: $table.transactionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get billId => $composableBuilder(
      column: $table.billId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$DuplicateHashesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DuplicateHashesTable> {
  $$DuplicateHashesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
      column: $table.transactionId, builder: (column) => column);

  GeneratedColumn<String> get billId =>
      $composableBuilder(column: $table.billId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DuplicateHashesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DuplicateHashesTable,
    DuplicateHash,
    $$DuplicateHashesTableFilterComposer,
    $$DuplicateHashesTableOrderingComposer,
    $$DuplicateHashesTableAnnotationComposer,
    $$DuplicateHashesTableCreateCompanionBuilder,
    $$DuplicateHashesTableUpdateCompanionBuilder,
    (
      DuplicateHash,
      BaseReferences<_$AppDatabase, $DuplicateHashesTable, DuplicateHash>
    ),
    DuplicateHash,
    PrefetchHooks Function()> {
  $$DuplicateHashesTableTableManager(
      _$AppDatabase db, $DuplicateHashesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DuplicateHashesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DuplicateHashesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DuplicateHashesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> hash = const Value.absent(),
            Value<String?> transactionId = const Value.absent(),
            Value<String?> billId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DuplicateHashesCompanion(
            id: id,
            hash: hash,
            transactionId: transactionId,
            billId: billId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String hash,
            Value<String?> transactionId = const Value.absent(),
            Value<String?> billId = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DuplicateHashesCompanion.insert(
            id: id,
            hash: hash,
            transactionId: transactionId,
            billId: billId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DuplicateHashesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DuplicateHashesTable,
    DuplicateHash,
    $$DuplicateHashesTableFilterComposer,
    $$DuplicateHashesTableOrderingComposer,
    $$DuplicateHashesTableAnnotationComposer,
    $$DuplicateHashesTableCreateCompanionBuilder,
    $$DuplicateHashesTableUpdateCompanionBuilder,
    (
      DuplicateHash,
      BaseReferences<_$AppDatabase, $DuplicateHashesTable, DuplicateHash>
    ),
    DuplicateHash,
    PrefetchHooks Function()>;

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
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$SubscriptionsTableTableManager get subscriptions =>
      $$SubscriptionsTableTableManager(_db, _db.subscriptions);
  $$FinancialReportsTableTableManager get financialReports =>
      $$FinancialReportsTableTableManager(_db, _db.financialReports);
  $$AgentLogsTableTableManager get agentLogs =>
      $$AgentLogsTableTableManager(_db, _db.agentLogs);
  $$FinancialPredictionsTableTableManager get financialPredictions =>
      $$FinancialPredictionsTableTableManager(_db, _db.financialPredictions);
  $$AppNotificationsTableTableManager get appNotifications =>
      $$AppNotificationsTableTableManager(_db, _db.appNotifications);
  $$UnrecognizedMessagesTableTableManager get unrecognizedMessages =>
      $$UnrecognizedMessagesTableTableManager(_db, _db.unrecognizedMessages);
  $$RawSmsTableTableManager get rawSms =>
      $$RawSmsTableTableManager(_db, _db.rawSms);
  $$ParsedSmsTableTableManager get parsedSms =>
      $$ParsedSmsTableTableManager(_db, _db.parsedSms);
  $$BillsTableTableManager get bills =>
      $$BillsTableTableManager(_db, _db.bills);
  $$MerchantsTableTableManager get merchants =>
      $$MerchantsTableTableManager(_db, _db.merchants);
  $$AiLearningsTableTableManager get aiLearnings =>
      $$AiLearningsTableTableManager(_db, _db.aiLearnings);
  $$DuplicateHashesTableTableManager get duplicateHashes =>
      $$DuplicateHashesTableTableManager(_db, _db.duplicateHashes);
}
