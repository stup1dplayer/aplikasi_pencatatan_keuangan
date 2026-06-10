import '../../domain/entities/transaction_entity.dart';

class CategoryPredictor {
  // Kamus pintar pengelompokan kata kunci
  static const Map<TransactionTag, List<String>> _dictionary = {
    TransactionTag.primer: [
      'makan', 'minum', 'nasi', 'warteg', 'bensin', 'pertalite', 'pertamax',
      'kos', 'listrik', 'air', 'obat', 'kuliah', 'spp', 'buku', 'hosting', 'server'
    ],
    TransactionTag.sekunder: [
      'kuota', 'pulsa', 'indihome', 'wifi', 'shopee', 'tokopedia', 'paket',
      'kabel', 'router', 'adaptor', 'baju', 'sepatu', 'sabun', 'laundry',
      'editing', 'software', 'langganan'
    ],
    TransactionTag.tersier: [
      'game', 'steam', 'top up', 'diamond', 'nongkrong', 'cafe', 'kopi',
      'boba', 'bioskop', 'netflix', 'spotify', 'liburan', 'hotel', 'pantai',
      'gelang', 'aksesoris', 'mainan'
    ],
  };

  /// Fungsi untuk menebak tag berdasarkan teks deskripsi
  static TransactionTag predict(String description) {
    if (description.isEmpty) return TransactionTag.none;

    // Ubah teks menjadi huruf kecil semua agar mudah dicocokkan
    final lowerDesc = description.toLowerCase();

    // Cek setiap kategori di dalam kamus
    for (var entry in _dictionary.entries) {
      for (var keyword in entry.value) {
        // Jika kata kunci ditemukan di dalam teks deskripsi
        if (lowerDesc.contains(keyword)) {
          return entry.key; // Kembalikan tag yang cocok
        }
      }
    }

    return TransactionTag.none; // Jika tidak ada yang cocok
  }
}