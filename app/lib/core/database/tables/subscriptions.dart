import 'package:drift/drift.dart';
import 'users.dart';

@DataClassName('Subscription')
class Subscriptions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id).named('user_id')();
  TextColumn get title => text()();
  IntColumn get monthlyCost => integer().named('monthly_cost')();
  IntColumn get annualCost => integer().named('annual_cost')();
  TextColumn get billingCycle => text().named('billing_cycle')();
  DateTimeColumn get renewalDate => dateTime().named('renewal_date')();
  TextColumn get providerName => text().named('provider_name')();
  RealColumn get confidence => real()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}
