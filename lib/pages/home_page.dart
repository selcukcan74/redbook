// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:redbook/pages/products/products_page.dart';
import 'package:redbook/pages/settings/settings_page.dart';
import 'package:redbook/pages/dashboard/dashboard_page.dart';
import 'package:redbook/pages/customers/customers_list_page.dart';
import 'package:redbook/pages/quotes/quotes_page.dart';

// Canlı badge verileri için servisler
import 'package:redbook/services/product_service.dart';
import 'package:redbook/services/customer_service.dart';
import 'package:redbook/services/quote_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isDark = false;

  final productService = ProductService();
  final customerService = CustomerService();
  final quoteService = QuoteService();

  int _productCount = 0;
  int _customerCount = 0;
  int _quoteCount = 0;

  void _onTabChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  void initState() {
    super.initState();
    _loadSidebarStats();
  }

  Future<void> _loadSidebarStats() async {
    try {
      final products = await productService.getProducts();
      final customers = await customerService.getCustomers();
      final quotes = await quoteService.getQuotes();

      setState(() {
        _productCount = products.length;
        _customerCount = customers.length;
        _quoteCount = quotes.length;
      });
    } catch (e) {
      debugPrint("Sidebar stats load error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isWide = size.width >= 800;

    // Apple Developer tarzı düz arkaplan
    final Color backgroundColor = _isDark
        ? const Color(0xFF0B0E14)
        : const Color(0xFFF5F6FA);

    final pages = [
      DashboardPage(isDark: _isDark),
      const ProductsPage(),
      const CustomersListPage(),
      const QuotesPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      extendBody: false,

      // -----------------------------
      // ÜST BAR
      // -----------------------------
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _isDark
            ? const Color(0xFF10131A)
            : const Color(0xFFFDFDFE),
        centerTitle: true,
        title: Text(
          "Yönetim Paneli",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: _isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        actions: [
          Row(
            children: [
              Icon(
                _isDark ? Icons.dark_mode : Icons.light_mode,
                size: 20,
                color: _isDark ? Colors.white70 : Colors.grey[700],
              ),
              Switch(
                value: _isDark,
                onChanged: (v) => setState(() => _isDark = v),
              ),
              IconButton(
                icon: Icon(
                  Icons.logout,
                  color: _isDark ? Colors.white70 : Colors.grey[800],
                ),
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, '/');
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),

      // -----------------------------
      // GÖVDE
      // -----------------------------
      body: Container(
        color: backgroundColor,
        child: Row(
          children: [
            if (isWide) _buildSidebar(),

            // CONTENT
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Container(
                  key: ValueKey('$_selectedIndex-$_isDark'),
                  color: backgroundColor,
                  child: pages[_selectedIndex],
                ),
              ),
            ),
          ],
        ),
      ),

      // -----------------------------
      // MOBİL ALT NAVBAR
      // -----------------------------
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              backgroundColor: _isDark ? const Color(0xFF10131A) : Colors.white,
              currentIndex: _selectedIndex,
              onTap: _onTabChanged,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: _isDark
                  ? Colors.white
                  : const Color(0xFF2563EB),
              unselectedItemColor: _isDark ? Colors.white54 : Colors.grey[600],
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  label: "Dashboard",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2_outlined),
                  label: "Ürünler",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  label: "Müşteriler",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: "Teklifler",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  label: "Ayarlar",
                ),
              ],
            ),
    );
  }

  // -----------------------------
  // APPLE DEV TARZI FULL CUSTOM SIDEBAR
  // -----------------------------
  Widget _buildSidebar() {
    final bool dark = _isDark;

    final Color sidebarColor = dark
        ? const Color(0xFF090B10)
        : Colors.white; // düz yüzey
    final Color borderColor = dark
        ? const Color(0xFF151823)
        : const Color(0xFFE5E7EB);

    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? "";
    final rawName =
        (user?.userMetadata?['full_name'] as String?) ?? email.split('@').first;
    final displayName = rawName.isEmpty ? "Kullanıcı" : rawName;
    final initials = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : "?";

    final List<Map<String, dynamic>> menu = [
      {"icon": Icons.dashboard_outlined, "label": "Dashboard", "badge": null},
      {
        "icon": Icons.inventory_2_outlined,
        "label": "Ürünler",
        "badge": _productCount,
      },
      {
        "icon": Icons.people_outline,
        "label": "Müşteriler",
        "badge": _customerCount,
      },
      {
        "icon": Icons.receipt_long_outlined,
        "label": "Teklifler",
        "badge": _quoteCount,
      },
      {"icon": Icons.settings_outlined, "label": "Ayarlar", "badge": null},
    ];

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: sidebarColor,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- LOGO + APP ADI ----
          Padding(
            padding: const EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF1F2937)
                        : const Color(0xFFE5EDFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_motion,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "RedBook",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: dark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: borderColor),

          const SizedBox(height: 8),

          // ---- MENU ITEMS ----
          for (int i = 0; i < menu.length; i++)
            _buildSidebarItem(
              index: i,
              icon: menu[i]["icon"] as IconData,
              label: menu[i]["label"] as String,
              badge: menu[i]["badge"] as int?,
              selected: _selectedIndex == i,
              onTap: () => _onTabChanged(i),
              dark: dark,
            ),

          const Spacer(),

          // ---- USER CARD ----
          _buildUserCard(
            dark: dark,
            initials: initials,
            displayName: displayName,
            email: email,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Tek tek menu item
  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required String label,
    required int? badge,
    required bool selected,
    required VoidCallback onTap,
    required bool dark,
  }) {
    final Color selectedColor = dark ? Colors.white : const Color(0xFF111827);
    final Color unselectedColor = dark ? Colors.white70 : Colors.grey[700]!;

    final Color bgSelected = dark
        ? const Color(0xFF11131A)
        : const Color(0xFFF3F4F6);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: dark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? bgSelected : Colors.transparent,
          ),
          child: Row(
            children: [
              // Sol ince bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: selected ? 3 : 0,
                height: 24,
                decoration: BoxDecoration(
                  color: dark ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),

              Icon(
                icon,
                size: 22,
                color: selected ? selectedColor : unselectedColor,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: selected ? 14.5 : 13.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? selectedColor : unselectedColor,
                  ),
                ),
              ),

              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF1F2937)
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: dark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Kullanıcı kartı
  Widget _buildUserCard({
    required bool dark,
    required String initials,
    required String displayName,
    required String email,
  }) {
    final Color cardColor = dark
        ? const Color(0xFF11131A)
        : const Color(0xFFF3F4F6);
    final Color textMain = dark ? Colors.white : const Color(0xFF111827);
    final Color textSub = dark ? Colors.white70 : Colors.grey[700]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: dark
                  ? const Color(0xFF1F2937)
                  : const Color(0xFFE5EDFF),
              child: Text(
                initials,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textMain,
                    ),
                  ),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: textSub),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
