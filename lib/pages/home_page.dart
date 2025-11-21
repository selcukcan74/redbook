// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:redbook/pages/products/products_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Senin sayfaların
import 'package:redbook/pages/dashboard/dashboard_page.dart';
//import 'package:redbook/pages/products/products_list_page.dart';
import 'package:redbook/pages/customers/customers_list_page.dart';
import 'package:redbook/pages/quotes/quotes_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> pages = const [
    DashboardPage(),
    ProductsPage(),
    CustomersListPage(),
    QuotesPage(),
  ];

  void _onTabChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final bool isWide = size.width >= 800; // masaüstü – mobil ayrımı

    return Scaffold(
      extendBody: true,

      // -----------------------------
      // ÜST BAR (AppBar)
      // -----------------------------
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.2),
              elevation: 0,
              title: const Text(
                "Yönetim Paneli",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (!mounted) return;
                    Navigator.pushReplacementNamed(context, '/');
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),

      // -----------------------------
      // GÖVDE
      // -----------------------------
      body: Row(
        children: [
          if (isWide) _buildGlassNavigationRail(theme),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Container(
                key: ValueKey(_selectedIndex),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.surface.withOpacity(0.98),
                      theme.colorScheme.surfaceVariant.withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: pages[_selectedIndex],
              ),
            ),
          ),
        ],
      ),

      // -----------------------------
      // MOBİL ALT NAVBAR
      // -----------------------------
      bottomNavigationBar: isWide
          ? null
          : ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: BottomNavigationBar(
                  backgroundColor: Colors.white.withOpacity(0.85),
                  currentIndex: _selectedIndex,
                  onTap: _onTabChanged,
                  selectedItemColor: theme.colorScheme.primary,
                  unselectedItemColor: Colors.grey[600],
                  type: BottomNavigationBarType.fixed,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard),
                      label: "Dashboard",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.inventory_2),
                      label: "Ürünler",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.people),
                      label: "Müşteriler",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.receipt_long),
                      label: "Teklifler",
                    ),
                  ],
                ),
              ),
            ),

      // ❌ Artık floatingActionButton YOK
    );
  }

  // -----------------------------
  // GLASS NAVIGATION RAIL
  // -----------------------------
  Widget _buildGlassNavigationRail(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            width: 90,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.2,
              ),
            ),
            child: NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onTabChanged,
              backgroundColor: Colors.transparent,
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: IconThemeData(
                color: theme.colorScheme.primary,
                size: 28,
              ),
              unselectedIconTheme: const IconThemeData(
                color: Colors.black54,
                size: 24,
              ),
              selectedLabelTextStyle: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text("Dash"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: Text("Ürün"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: Text("Müş"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: Text("Teklif"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
