import 'package:isar/isar.dart';

part 'wishlist_entity.g.dart';

@collection
class WishlistEntity {
  Id id = Isar.autoIncrement;

  late String name;

  late double price;

  bool isAchieved = false; // Status apakah barang sudah terbeli
}