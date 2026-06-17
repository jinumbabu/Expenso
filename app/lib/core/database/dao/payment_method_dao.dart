import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/payment_methods.dart';

part 'payment_method_dao.g.dart';

@DriftAccessor(tables: [PaymentMethods])
class PaymentMethodDao extends DatabaseAccessor<AppDatabase> with _$PaymentMethodDaoMixin {
  PaymentMethodDao(super.db);

  Future<List<PaymentMethod>> getPaymentMethodsForUser(String userId) =>
      (select(paymentMethods)..where((t) => t.userId.equals(userId) | t.userId.equals('system'))).get();

  Future<PaymentMethod?> getPaymentMethodById(String id) =>
      (select(paymentMethods)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertPaymentMethod(PaymentMethod paymentMethod) => into(paymentMethods).insert(paymentMethod);
  Future<bool> updatePaymentMethod(PaymentMethod paymentMethod) => update(paymentMethods).replace(paymentMethod);
  Future<int> deletePaymentMethod(String id) =>
      (delete(paymentMethods)..where((t) => t.id.equals(id))).go();
}
