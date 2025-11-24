import 'package:flutter/material.dart';

class RevisionComparePage extends StatelessWidget {
  final Map<String, dynamic> revision;
  final Map<String, dynamic> current;

  const RevisionComparePage({
    super.key,
    required this.revision,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final revQ = revision["quote"] ?? {};
    final curQ = current["quote"] ?? {};

    final revC = revision["customer"] ?? {};
    final curC = current["customer"] ?? {};

    final revItems = List<Map<String, dynamic>>.from(revision["items"] ?? []);
    final curItems = List<Map<String, dynamic>>.from(current["items"] ?? []);

    return Scaffold(
      appBar: AppBar(title: const Text("Revizyon Karşılaştırma")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          _header("Teklif Bilgileri"),
          _infoCard([
            _diff("Tarih", revQ["issue_date"], curQ["issue_date"]),
            _diff("Numara", revQ["quote_number"], curQ["quote_number"]),
          ]),

          _header("Hesaplama Karşılaştırması"),
          _infoCard([
            _moneyDiff("Ara Toplam", revQ["subtotal"], curQ["subtotal"]),
            _moneyDiff("İndirim", revQ["discount"], curQ["discount"]),
            _moneyDiff("Vergi Matrahı", _matrah(revQ), _matrah(curQ)),
            _moneyDiff("KDV", revQ["tax"], curQ["tax"]),
            _moneyDiff("Genel Toplam", revQ["total"], curQ["total"]),
            _moneyDiff(
              "Net Ödenecek",
              revQ["total_after_discount"],
              curQ["total_after_discount"],
            ),
          ]),

          _header("Müşteri Bilgileri"),
          _infoCard([
            _diff("Firma", revC["company"], curC["company"]),
            _diff("Yetkili", revC["name"], curC["name"]),
            _diff("Telefon", revC["phone"], curC["phone"]),
          ]),

          _header("Ürün Karşılaştırması"),
          _productList(revItems, curItems),
        ],
      ),
    );
  }

  // ---------------------------------------------
  //  HEADER
  // ---------------------------------------------
  Widget _header(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ---------------------------------------------
  //  CARD WRAPPER
  // ---------------------------------------------
  Widget _infoCard(List<Widget> children) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  // ---------------------------------------------
  //  TEXT DIFF
  // ---------------------------------------------
  Widget _diff(String label, dynamic oldVal, dynamic newVal) {
    oldVal = oldVal?.toString() ?? "-";
    newVal = newVal?.toString() ?? "-";

    final changed = oldVal != newVal;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Eski: $oldVal",
                style: TextStyle(color: changed ? Colors.red : Colors.black),
              ),
              Text(
                "Yeni: $newVal",
                style: TextStyle(
                  color: changed ? Colors.green : Colors.black,
                  fontWeight: changed ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          if (changed)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.change_circle, color: Colors.blue, size: 22),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------
  //  MONEY DIFF
  // ---------------------------------------------
  Widget _moneyDiff(String label, dynamic oldVal, dynamic newVal) {
    double o = (oldVal ?? 0).toDouble();
    double n = (newVal ?? 0).toDouble();

    final changed = o != n;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Eski: ${o.toStringAsFixed(2)} ₺",
                style: TextStyle(color: changed ? Colors.red : Colors.black),
              ),
              Text(
                "Yeni: ${n.toStringAsFixed(2)} ₺",
                style: TextStyle(
                  color: changed ? Colors.green : Colors.black,
                  fontWeight: changed ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          if (changed)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.change_circle, color: Colors.blue, size: 22),
            ),
        ],
      ),
    );
  }

  double _matrah(Map<String, dynamic> q) {
    return (q["subtotal"] ?? 0).toDouble() - (q["discount"] ?? 0).toDouble();
  }

  // ---------------------------------------------
  //  PRODUCT DIFF LIST
  // ---------------------------------------------
  Widget _productList(
    List<Map<String, dynamic>> revItems,
    List<Map<String, dynamic>> curItems,
  ) {
    return Column(
      children: [
        for (final oldItem in revItems) _productItemCard(oldItem, curItems),
      ],
    );
  }

  Widget _productItemCard(
    Map<String, dynamic> oldItem,
    List<Map<String, dynamic>> curItems,
  ) {
    final newItem = curItems.firstWhere(
      (i) => i["description"] == oldItem["description"],
      orElse: () => {},
    );

    bool removed = newItem.isEmpty;
    bool changed =
        !removed &&
        (oldItem["total"].toDouble() != newItem["total"].toDouble());

    return Card(
      elevation: removed || changed ? 4 : 1,
      color: removed
          ? Colors.red.shade100
          : changed
          ? Colors.yellow.shade100
          : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        title: Text(
          oldItem["description"] ?? "",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: removed
            ? const Text("Ürün yeni teklifte yok.")
            : Text("Eski: ${oldItem["total"]} ₺ → Yeni: ${newItem["total"]} ₺"),
        trailing: Icon(
          removed
              ? Icons.remove_circle
              : changed
              ? Icons.change_circle
              : Icons.check_circle,
          color: removed
              ? Colors.red
              : changed
              ? Colors.orange
              : Colors.green,
        ),
      ),
    );
  }
}
