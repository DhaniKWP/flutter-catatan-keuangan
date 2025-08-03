import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const CuteMoneyTrackerApp());
}

class CuteMoneyTrackerApp extends StatelessWidget {
  const CuteMoneyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cute Money Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        fontFamily: GoogleFonts.poppins().fontFamily,
        scaffoldBackgroundColor: const Color(0xFFFFF0F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFF69B4),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

// Model Classes
class Transaction {
  final int? id;
  final String type; // 'income' or 'expense'
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final String wallet; // New field for multi-wallet

  Transaction({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.wallet = 'Cash',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'wallet': wallet,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      type: map['type'],
      amount: map['amount'],
      category: map['category'],
      description: map['description'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      wallet: map['wallet'] ?? 'Cash',
    );
  }
}

class SavingGoal {
  final int? id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String emoji;
  final DateTime createdDate;
  final DateTime? targetDate;

  SavingGoal({
    this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    this.emoji = '💰',
    required this.createdDate,
    this.targetDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'emoji': emoji,
      'createdDate': createdDate.millisecondsSinceEpoch,
      'targetDate': targetDate?.millisecondsSinceEpoch,
    };
  }

  factory SavingGoal.fromMap(Map<String, dynamic> map) {
    return SavingGoal(
      id: map['id'],
      name: map['name'],
      targetAmount: map['targetAmount'],
      currentAmount: map['currentAmount'] ?? 0,
      emoji: map['emoji'] ?? '💰',
      createdDate: DateTime.fromMillisecondsSinceEpoch(map['createdDate']),
      targetDate: map['targetDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['targetDate'])
          : null,
    );
  }

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
}

class WishlistItem {
  final int? id;
  final String name;
  final double price;
  final String emoji;
  final String priority; // 'low', 'medium', 'high'
  final DateTime createdDate;

  WishlistItem({
    this.id,
    required this.name,
    required this.price,
    this.emoji = '🛍️',
    this.priority = 'medium',
    required this.createdDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'emoji': emoji,
      'priority': priority,
      'createdDate': createdDate.millisecondsSinceEpoch,
    };
  }

  factory WishlistItem.fromMap(Map<String, dynamic> map) {
    return WishlistItem(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      emoji: map['emoji'] ?? '🛍️',
      priority: map['priority'] ?? 'medium',
      createdDate: DateTime.fromMillisecondsSinceEpoch(map['createdDate']),
    );
  }
}

class UserBadge {
  final int? id;
  final String name;
  final String description;
  final String emoji;
  final DateTime earnedDate;
  final String type; // 'saving', 'spending', 'streak', 'goal'

  UserBadge({
    this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.earnedDate,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'emoji': emoji,
      'earnedDate': earnedDate.millisecondsSinceEpoch,
      'type': type,
    };
  }

  factory UserBadge.fromMap(Map<String, dynamic> map) {
    return UserBadge(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      emoji: map['emoji'],
      earnedDate: DateTime.fromMillisecondsSinceEpoch(map['earnedDate']),
      type: map['type'],
    );
  }
}

// Enhanced Database Helper
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = p.join(await getDatabasesPath(), 'money_tracker.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        date INTEGER NOT NULL,
        wallet TEXT DEFAULT 'Cash'
      )
    ''');

    await db.execute('''
      CREATE TABLE saving_goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        currentAmount REAL DEFAULT 0,
        emoji TEXT DEFAULT '💰',
        createdDate INTEGER NOT NULL,
        targetDate INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE wishlist(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        emoji TEXT DEFAULT '🛍️',
        priority TEXT DEFAULT 'medium',
        createdDate INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE badges(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        emoji TEXT NOT NULL,
        earnedDate INTEGER NOT NULL,
        type TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN wallet TEXT DEFAULT "Cash"');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS saving_goals(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          targetAmount REAL NOT NULL,
          currentAmount REAL DEFAULT 0,
          emoji TEXT DEFAULT '💰',
          createdDate INTEGER NOT NULL,
          targetDate INTEGER
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS wishlist(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          price REAL NOT NULL,
          emoji TEXT DEFAULT '🛍️',
          priority TEXT DEFAULT 'medium',
          createdDate INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS badges(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          emoji TEXT NOT NULL,
          earnedDate INTEGER NOT NULL,
          type TEXT NOT NULL
        )
      ''');
    }
  }

  // Transaction methods
  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<Transaction>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  Future<List<Transaction>> getTransactionsByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  Future<List<Transaction>> getTransactionsByWallet(String wallet) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'wallet = ?',
      whereArgs: [wallet],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  Future<List<Transaction>> getFilteredTransactions({
    String? wallet,
    String? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (wallet != null && wallet != 'All') {
      whereClause += 'wallet = ?';
      whereArgs.add(wallet);
    }
    
    if (type != null && type != 'All') {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'type = ?';
      whereArgs.add(type);
    }
    
    if (category != null && category != 'All') {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'category = ?';
      whereArgs.add(category);
    }
    
    if (startDate != null && endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date BETWEEN ? AND ?';
      whereArgs.addAll([startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch]);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // Saving Goals methods
  Future<int> insertSavingGoal(SavingGoal goal) async {
    final db = await database;
    return await db.insert('saving_goals', goal.toMap());
  }

  Future<List<SavingGoal>> getSavingGoals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'saving_goals',
      orderBy: 'createdDate DESC',
    );

    return List.generate(maps.length, (i) {
      return SavingGoal.fromMap(maps[i]);
    });
  }

  Future<int> updateSavingGoal(SavingGoal goal) async {
    final db = await database;
    return await db.update(
      'saving_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> deleteSavingGoal(int id) async {
    final db = await database;
    return await db.delete('saving_goals', where: 'id = ?', whereArgs: [id]);
  }

  // Wishlist methods
  Future<int> insertWishlistItem(WishlistItem item) async {
    final db = await database;
    return await db.insert('wishlist', item.toMap());
  }

  Future<List<WishlistItem>> getWishlistItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'wishlist',
      orderBy: 'createdDate DESC',
    );

    return List.generate(maps.length, (i) {
      return WishlistItem.fromMap(maps[i]);
    });
  }

  Future<int> deleteWishlistItem(int id) async {
    final db = await database;
    return await db.delete('wishlist', where: 'id = ?', whereArgs: [id]);
  }

  // Badge methods
  Future<int> insertBadge(UserBadge badge) async {
    final db = await database;
    return await db.insert('badges', badge.toMap());
  }

  Future<List<UserBadge>> getBadges() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'badges',
      orderBy: 'earnedDate DESC',
    );

    return List.generate(maps.length, (i) {
      return UserBadge.fromMap(maps[i]);
    });
  }
}

// Main Screen with Enhanced Navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Transaction> _transactions = [];
  List<SavingGoal> _savingGoals = [];
  List<WishlistItem> _wishlistItems = [];
  List<UserBadge> _badges = [];
  List<Transaction> _allTransactions = [];
  String _selectedFilter = 'daily';
  String _selectedWallet = 'All';

  final List<String> _wallets = ['All', 'Cash', 'E-Wallet', 'Bank', 'Tabungan'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _loadAllTransactions();
    await _loadTransactions();
    await _loadSavingGoals();
    await _loadWishlistItems();
    await _loadBadges();
    await _checkAndAwardBadges();
  }

  Future<void> _loadAllTransactions() async {
    final allTransactions = await _dbHelper.getTransactions();
    setState(() {
      _allTransactions = allTransactions;
    });
  }

  Future<void> _loadTransactions() async {
    DateTime now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_selectedFilter) {
      case 'daily':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'monthly':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'yearly':
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      default:
        start = DateTime(now.year, now.month, now.day);
    }

    List<Transaction> transactions;
    if (_selectedWallet == 'All') {
      transactions = await _dbHelper.getTransactionsByDateRange(start, end);
    } else {
      final allTransactions = await _dbHelper.getTransactionsByWallet(_selectedWallet);
      transactions = allTransactions.where((t) => 
        t.date.isAfter(start.subtract(const Duration(seconds: 1))) && 
        t.date.isBefore(end.add(const Duration(seconds: 1)))
      ).toList();
    }

    setState(() {
      _transactions = transactions;
    });
  }

  Future<void> _loadSavingGoals() async {
    final goals = await _dbHelper.getSavingGoals();
    setState(() {
      _savingGoals = goals;
    });
  }

  Future<void> _loadWishlistItems() async {
    final items = await _dbHelper.getWishlistItems();
    setState(() {
      _wishlistItems = items;
    });
  }

  Future<void> _loadBadges() async {
    final badges = await _dbHelper.getBadges();
    setState(() {
      _badges = badges;
    });
  }

  Future<void> _checkAndAwardBadges() async {
    // Check for new badges based on user activity
    final allTransactions = await _dbHelper.getTransactions();
    
    // First transaction badge
    if (allTransactions.length == 1 && !_badges.any((b) => b.type == 'first')) {
      final badge = UserBadge(
        name: 'Langkah Pertama',
        description: 'Transaksi pertama kamu! Keep going!',
        emoji: '🌟',
        earnedDate: DateTime.now(),
        type: 'first',
      );
      await _dbHelper.insertBadge(badge);
    }

    // Hemat Banget badge
    final now = DateTime.now();
    final startMonth = DateTime(now.year, now.month, 1);
    final endMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    final monthlyTransactions = await _dbHelper.getTransactionsByDateRange(startMonth, endMonth);
    final monthlyIncome = monthlyTransactions.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount);
    final monthlyExpense = monthlyTransactions.where((t) => t.type == 'expense').fold(0.0, (sum, t) => sum + t.amount);
    
    if (monthlyIncome > monthlyExpense && monthlyExpense > 0 && !_badges.any((b) => b.type == 'saving' && b.earnedDate.month == now.month)) {
      final badge = UserBadge(
        name: 'Hemat Banget',
        description: 'Kamu lebih banyak nabung daripada belanja bulan ini!',
        emoji: '🏆',
        earnedDate: DateTime.now(),
        type: 'saving',
      );
      await _dbHelper.insertBadge(badge);
    }

    // Goal Achievement badge
    for (var goal in _savingGoals) {
      if (goal.progress >= 1.0 && !_badges.any((b) => b.type == 'goal_${goal.id}')) {
        final badge = UserBadge(
          name: 'Goal Master',
          description: 'Berhasil capai target ${goal.name}!',
          emoji: '🎯',
          earnedDate: DateTime.now(),
          type: 'goal_${goal.id}',
        );
        await _dbHelper.insertBadge(badge);
      }
    }

    // Reload badges
    await _loadBadges();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFB6C1),
              Color(0xFFFFF0F5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDashboard(),
                    _buildTransactionsList(),
                    _buildSavingGoals(),
                    _buildWishlist(),
                    _buildBadgesAndAnalytics(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildEnhancedTabBar(),
      floatingActionButton: _buildCuteFloatingActionButton(context),
    );
  }

  Widget _buildHeader() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: Color(0xFFFF69B4),
            size: 30,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo Cantik! 💕',
                style: GoogleFonts.poppins(
                  fontSize: 22, // Kecilkan sedikit
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Yuk kelola uang kamu hari ini',
                style: GoogleFonts.poppins(
                  fontSize: 13, // Kecilkan sedikit
                  color: Colors.white70,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Badge count indicator dengan constraint
        if (_badges.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 60),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${_badges.length}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

Widget _buildEnhancedTabBar() {
  return Container(
    margin: const EdgeInsets.fromLTRB(20, 0, 20, 20), // margin dari kiri, atas, kanan, bawah
    height: 75, // Tinggi diperbesar
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(35), // Radius diperbesar
      boxShadow: [
        BoxShadow(
          color: Colors.pink.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    clipBehavior: Clip.hardEdge,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF69B4), Color(0xFFFF1493)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(27), // Sesuaikan dengan padding
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFFFF69B4),
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600, 
          fontSize: 13, // Sedikit diperbesar
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        isScrollable: false,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        tabs: [
          _buildCustomTab('💰', 'Home'),
          _buildCustomTab('📝', 'Transaksi'),
          _buildCustomTab('🎯', 'Goal'),
          _buildCustomTab('🛍️', 'Wish'),
          _buildCustomTab('🏆', 'Badge'),
        ],
      ),
    ),
  );
}

// Helper method untuk membuat custom tab yang lebih rapi
Widget _buildCustomTab(String emoji, String text) {
  return Tab(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16), // Emoji lebih besar
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildDashboard() {
  double totalIncome = _transactions
      .where((t) => t.type == 'income')
      .fold(0, (sum, t) => sum + t.amount);
  double totalExpense = _transactions
      .where((t) => t.type == 'expense')
      .fold(0, (sum, t) => sum + t.amount);
  double balance = totalIncome - totalExpense;

  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter buttons with proper spacing
        SizedBox(
          height: 50,
          child: Row(
            children: [
              _buildFilterButton('daily', 'Harian', '📅'),
              const SizedBox(width: 10),
              _buildFilterButton('monthly', 'Bulanan', '📆'),
              const SizedBox(width: 10),
              _buildFilterButton('yearly', 'Tahunan', '🗓️'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Wallet filter
        SizedBox(
          height: 45,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _wallets.map((wallet) => 
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildWalletFilter(wallet),
                )
              ).toList(),
            ),
          ),
        ),
        const SizedBox(height: 25),

        // Balance card
        _buildBalanceCard(balance, totalIncome, totalExpense),
        const SizedBox(height: 25),

        // Analytics insight
        _buildAnalyticsInsight(),
        const SizedBox(height: 25),

        // Active goals preview
        if (_savingGoals.isNotEmpty) ...[
          _buildActiveGoalsPreview(),
          const SizedBox(height: 25),
        ],

        // Category chart section
        Text(
          'Kategori Pengeluaran 🛍️',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFF69B4),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 280,
          child: _buildCategoryChart(),
        ),
        const SizedBox(height: 30),
      ],
    ),
  );
}


  Widget _buildWalletFilter(String wallet) {
  bool isSelected = _selectedWallet == wallet;
  return GestureDetector(
    onTap: () {
      setState(() {
        _selectedWallet = wallet;
      });
      _loadTransactions();
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFF69B4) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF69B4).withAlpha(77), // 0.3 * 255 ≈ 77
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withAlpha(25), // 0.1 * 255 ≈ 25
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '${_getWalletEmoji(wallet)} $wallet',
        style: GoogleFonts.poppins(
          color: isSelected ? Colors.white : const Color(0xFFFF69B4),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    ),
  );
}


  String _getWalletEmoji(String wallet) {
    switch (wallet) {
      case 'Cash':
        return '💵';
      case 'E-Wallet':
        return '📱';
      case 'Bank':
        return '🏦';
      case 'Tabungan':
        return '🐷';
      default:
        return '💰';
    }
  }

  Widget _buildAnalyticsInsight() {
    // Calculate this month vs last month
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // Get transactions for comparison
    double thisMonthExpense = _transactions
        .where((t) => t.type == 'expense' && 
                     t.date.isAfter(thisMonthStart.subtract(const Duration(seconds: 1))) &&
                     t.date.isBefore(thisMonthEnd.add(const Duration(seconds: 1))))
        .fold(0, (sum, t) => sum + t.amount);

    String insightText = '';
    String insightEmoji = '';
    Color insightColor = Colors.green;

    if (thisMonthExpense < 500000) {
      insightText = 'Kamu hemat banget bulan ini! Keep it up!';
      insightEmoji = '🌟';
      insightColor = Colors.green;
    } else if (thisMonthExpense > 1000000) {
      insightText = 'Pengeluaran lumayan besar nih, coba lebih hemat ya!';
      insightEmoji = '⚠️';
      insightColor = Colors.orange;
    } else {
      insightText = 'Pengeluaran kamu masih wajar, good job!';
      insightEmoji = '👍';
      insightColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [insightColor.withValues(alpha: 0.1), Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: insightColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: insightColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(insightEmoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analisa Keuangan',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: insightColor,
                  ),
                ),
                Text(
                  insightText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveGoalsPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Goal Aktif 🎯',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF69B4),
              ),
            ),
            TextButton(
              onPressed: () => _tabController.animateTo(2),
              child: Text(
                'Lihat Semua',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFFFF69B4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _savingGoals.take(3).length,
            itemBuilder: (context, index) {
              final goal = _savingGoals[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withValues(alpha: 0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(goal.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            goal.name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF333333),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rp ${NumberFormat('#,###').format(goal.currentAmount)} / Rp ${NumberFormat('#,###').format(goal.targetAmount)}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: goal.progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        goal.progress >= 1.0 ? Colors.green : const Color(0xFFFF69B4),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${(goal.progress * 100).toInt()}%',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: goal.progress >= 1.0 ? Colors.green : const Color(0xFFFF69B4),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String filter, String label, String emoji) {
    bool isSelected = _selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
          _loadTransactions();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF69B4) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$emoji $label',
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : const Color(0xFFFF69B4),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance, double income, double expense) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFF69B4),
          Color(0xFFFF1493),
        ],
      ),
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: Colors.pink.withValues(alpha: 0.4),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          'Saldo Kamu',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        FittedBox(
          child: Text(
            'Rp ${NumberFormat('#,###').format(balance)}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_downward, color: Colors.greenAccent, size: 18),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Pemasukan',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    FittedBox(
                      child: Text(
                        'Rp ${NumberFormat('#,###').format(income)}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_upward, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Pengeluaran',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    FittedBox(
                      child: Text(
                        'Rp ${NumberFormat('#,###').format(expense)}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildCategoryChart() {
    Map<String, double> categoryData = {};
    
    for (var transaction in _transactions.where((t) => t.type == 'expense')) {
      categoryData[transaction.category] = 
          (categoryData[transaction.category] ?? 0) + transaction.amount;
    }

    if (categoryData.isEmpty) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📊', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                'Belum ada pengeluaran nih',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              Text(
                'Yuk mulai catat pengeluaran kamu!',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    List<PieChartSectionData> sections = [];
    List<Color> colors = [
      const Color(0xFFFF69B4),
      const Color(0xFF9C27B0),
      const Color(0xFF3F51B5),
      const Color(0xFF00BCD4),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFFF44336),
    ];

    int colorIndex = 0;
    categoryData.forEach((category, amount) {
      sections.add(
        PieChartSectionData(
          value: amount,
          title: '${(amount / categoryData.values.reduce((a, b) => a + b) * 100).toInt()}%',
          color: colors[colorIndex % colors.length],
          radius: 60,
          titleStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                startDegreeOffset: -90,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 15,
            runSpacing: 10,
            children: categoryData.entries.map((entry) {
              int index = categoryData.keys.toList().indexOf(entry.key);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.key,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter section
          Row(
            children: [
              Expanded(
                child: _buildTransactionFilter(),
              ),
              const SizedBox(width: 10),
              _buildAddTransactionButton(),
            ],
          ),
          const SizedBox(height: 20),
          
          // Transactions list
          if (_transactions.isEmpty) 
            _buildEmptyTransactionState()
          else
            _buildTransactionItems(),
        ],
      ),
    );
  }

  Widget _buildTransactionFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedWallet,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFFF69B4)),
          style: GoogleFonts.poppins(color: const Color(0xFFFF69B4)),
          onChanged: (String? newValue) {
            setState(() {
              _selectedWallet = newValue!;
            });
            _loadTransactions();
          },
          items: _wallets.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text('${_getWalletEmoji(value)} $value'),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAddTransactionButton() {
    return GestureDetector(
      onTap: () => _showAddTransactionDialog(),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFFF69B4),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withValues(alpha: 0.3),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildEmptyTransactionState() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📝', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              'Belum ada transaksi',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Yuk mulai catat pemasukan dan\npengeluaran kamu!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showAddTransactionDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF69B4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(
                '+ Tambah Transaksi',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItems() {
    return AnimationLimiter(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildTransactionItem(_transactions[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: transaction.type == 'income' 
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              transaction.type == 'income' 
                  ? Icons.arrow_downward 
                  : Icons.arrow_upward,
              color: transaction.type == 'income' ? Colors.green : Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      transaction.category,
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '• ${_getWalletEmoji(transaction.wallet)} ${transaction.wallet}',
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(transaction.date),
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.type == 'income' ? '+' : '-'} Rp ${NumberFormat('#,###').format(transaction.amount)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: transaction.type == 'income' ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: () => _deleteTransaction(transaction.id!),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavingGoals() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Target Tabungan',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF69B4),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => _showAddGoalDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF69B4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                '+ Goal Baru',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Expanded(
          child: _savingGoals.isEmpty
              ? _buildEmptyGoalsState()
              : _buildGoalsList(),
        ),
      ],
    ),
  );
}



  Widget _buildWishlist() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Wishlist Belanja',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF69B4),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _showAddWishlistDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF69B4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  '+ Tambah Item',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (_wishlistItems.isEmpty)
            _buildEmptyWishlistState()
          else
            _buildWishlistItems(),
        ],
      ),
    );
  }

  Widget _buildEmptyWishlistState() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🛍️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              'Wishlist masih kosong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Yuk tambahkan barang impian\nyang pengen kamu beli!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showAddWishlistDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF69B4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(
                '+ Tambah ke Wishlist',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistItems() {
    // Sort by priority: high -> medium -> low
    List<WishlistItem> sortedItems = List.from(_wishlistItems);
    sortedItems.sort((a, b) {
      const priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
      return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
    });

    return AnimationLimiter(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedItems.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildWishlistItem(sortedItems[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWishlistItem(WishlistItem item) {
    Color priorityColor;
    String priorityText;
    
    switch (item.priority) {
      case 'high':
        priorityColor = Colors.red;
        priorityText = 'Prioritas Tinggi';
        break;
      case 'medium':
        priorityColor = Colors.orange;
        priorityText = 'Prioritas Sedang';
        break;
      case 'low':
        priorityColor = Colors.green;
        priorityText = 'Prioritas Rendah';
        break;
      default:
        priorityColor = Colors.grey;
        priorityText = 'Prioritas Sedang';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: priorityColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              item.emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Rp ${NumberFormat('#,###').format(item.price)}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF69B4),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    priorityText,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: priorityColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () => _deleteWishlistItem(item.id!),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _buyWishlistItem(item),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shopping_cart,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

    Widget _buildBadgesAndAnalytics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Badge & Pencapaian 🏆',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF69B4),
            ),
          ),
          const SizedBox(height: 20),

          // Stats overview
          _buildStatsOverview(),
          const SizedBox(height: 25),

          // Badges section
          Text(
            'Badge Kamu 🎖️',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF69B4),
            ),
          ),
          const SizedBox(height: 15),

          if (_badges.isEmpty)
            _buildEmptyBadgesState()
          else
            _buildBadgesList(),

          const SizedBox(height: 25),

          // Monthly spending chart
          Text(
            'Grafik Pengeluaran Bulanan 📊',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF69B4),
            ),
          ),
          const SizedBox(height: 15),
          
          // ✅ Ganti Container ke SizedBox
          SizedBox(
            height: 250,
            child: _buildMonthlyChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    // Calculate overall statistics
    final allTransactions = _transactions;
    final totalIncome = allTransactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = allTransactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    final completedGoals = _savingGoals.where((g) => g.progress >= 1.0).length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF69B4), Color(0xFFFF1493)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Statistik Kamu ✨',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '💰',
                  'Total Pemasukan',
                  'Rp ${NumberFormat('#,###').format(totalIncome)}',
                ),
              ),
              Container(width: 1, height: 50, color: Colors.white30),
              Expanded(
                child: _buildStatItem(
                  '💸',
                  'Total Pengeluaran',
                  'Rp ${NumberFormat('#,###').format(totalExpense)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(height: 1, color: Colors.white30),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '🎯',
                  'Goal Tercapai',
                  '$completedGoals dari ${_savingGoals.length}',
                ),
              ),
              Container(width: 1, height: 50, color: Colors.white30),
              Expanded(
                child: _buildStatItem(
                  '🏆',
                  'Badge Terkumpul',
                  '${_badges.length} Badge',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyBadgesState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 15),
            Text(
              'Belum ada badge',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            Text(
              'Yuk mulai catat transaksi dan\ncapai goal untuk dapetin badge!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

    Widget _buildBadgesList() {
      return SizedBox(
        height: 230, // ⬅️ Batasi tinggi agar tidak overflow
        child: GridView.builder(
          scrollDirection: Axis.horizontal, // ⬅️ Ubah jadi horizontal scroll
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            childAspectRatio: 1.1,
            mainAxisSpacing: 15,
          ),
          itemCount: _badges.length,
          itemBuilder: (context, index) {
            final badge = _badges[index];
            return Container(
              width: 160,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      badge.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    badge.name,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    badge.description,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('dd MMM yyyy').format(badge.earnedDate),
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }


  Widget _buildMonthlyChart() {
  // Get data for the last 6 months
  final now = DateTime.now();
  List<FlSpot> spots = [];
  List<String> months = [];
  double maxExpense = 0;
  
  for (int i = 5; i >= 0; i--) {
    final month = DateTime(now.year, now.month - i, 1);
    final nextMonth = DateTime(now.year, now.month - i + 1, 1);
    
    // ✅ FIX: Get all transactions from database instead of using filtered _transactions
    // Use FutureBuilder or make this async, but for now we'll use a sync approach
    // by getting all transactions that are already loaded
    
    // Get monthly expense by filtering ALL transactions, not just _transactions
    double monthlyExpense = 0;
    
    // We need to get all transactions from database for this chart
    // Since we can't make this async easily, let's use a different approach
    // We'll use the stored transactions but get them differently
    
    // Alternative: Use a class variable to store all transactions
    monthlyExpense = _allTransactions
        .where((t) => t.type == 'expense' &&
                     t.date.isAfter(month.subtract(const Duration(seconds: 1))) &&
                     t.date.isBefore(nextMonth))
        .fold(0.0, (sum, t) => sum + t.amount);
    
    // Simpan nilai maksimum untuk scaling
    if (monthlyExpense > maxExpense) {
      maxExpense = monthlyExpense;
    }
    
    spots.add(FlSpot((5 - i).toDouble(), monthlyExpense));
    months.add(DateFormat('MMM').format(month));
  }

  // Rest of the function remains the same...
  // Jika tidak ada data, tampilkan chart kosong
  if (maxExpense == 0) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📈', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Belum ada data pengeluaran',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Mulai catat pengeluaran untuk melihat grafik',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tentukan interval Y-axis yang lebih smart
  double yInterval;
  if (maxExpense > 10000000) { // > 10 juta
    yInterval = 2000000; // interval 2 juta
  } else if (maxExpense > 5000000) { // > 5 juta
    yInterval = 1000000; // interval 1 juta
  } else if (maxExpense > 1000000) { // > 1 juta
    yInterval = 500000; // interval 500rb
  } else if (maxExpense > 500000) { // > 500rb
    yInterval = 200000; // interval 200rb
  } else {
    yInterval = 100000; // interval 100rb
  }

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.pink.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      children: [
        // Header info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengeluaran 6 Bulan Terakhir',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                Text(
                  'Maksimal: Rp ${NumberFormat('#,###').format(maxExpense)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF69B4).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Trend',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFFFF69B4),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Chart
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yInterval,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withValues(alpha: 0.2),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    interval: yInterval,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const Text('');
                      
                      String label;
                      if (value >= 1000000) {
                        label = '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
                      } else if (value >= 1000) {
                        label = '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 0)}K';
                      } else {
                        label = value.toStringAsFixed(0);
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < months.length && value.toInt() >= 0) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            months[value.toInt()],
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 1),
                  bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 1),
                ),
              ),
              minX: 0,
              maxX: 5,
              minY: 0,
              maxY: (maxExpense * 1.2).ceilToDouble(), // Tambah 20% ruang di atas
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                 tooltipBgColor: const Color(0xFFFF69B4),
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      final monthIndex = barSpot.x.toInt();
                      final amount = barSpot.y;
                      
                      return LineTooltipItem(
                        '${months[monthIndex]}\nRp ${NumberFormat('#,###').format(amount)}',
                        GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
                handleBuiltInTouches: true,
                getTouchLineStart: (data, index) => 0,
                getTouchLineEnd: (data, index) => double.infinity,
                touchSpotThreshold: 50,
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF69B4),
                      Color(0xFFFF1493),
                      Color(0xFFDC143C),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 6,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: const Color(0xFFFF69B4),
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF69B4).withValues(alpha: 0.3),
                        const Color(0xFFFF69B4).withValues(alpha: 0.1),
                        const Color(0xFFFF69B4).withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  shadow: Shadow(
                    color: const Color(0xFFFF69B4).withValues(alpha: 0.3),
                    offset: const Offset(0, 3),
                    blurRadius: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Legend dan info tambahan
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF69B4).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFF69B4).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF69B4), Color(0xFFFF1493)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pengeluaran Bulanan - Ketuk titik untuk detail',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFFFF69B4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

    Widget _buildCuteFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showAddTransactionDialog(),
      backgroundColor: const Color(0xFFFF69B4),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF69B4), Color(0xFFFF1493)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withAlpha(102), // ✅ diperbaiki
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.star,
          size: 12,
          color: Colors.white,
        ),
      ),
    );
  }



  Widget _buildEmptyGoalsState() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              'Belum ada target tabungan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Yuk bikin target tabungan untuk\nmewujudkan impian kamu!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showAddGoalDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF69B4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(
                '+ Buat Target Baru',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsList() {
    return AnimationLimiter(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _savingGoals.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildGoalItem(_savingGoals[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoalItem(SavingGoal goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: goal.progress >= 1.0 
                      ? Colors.green.withValues(alpha: 0.1)
                      : const Color(0xFFFF69B4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  goal.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Target: Rp ${NumberFormat('#,###').format(goal.targetAmount)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    if (goal.targetDate != null)
                      Text(
                        'Deadline: ${DateFormat('dd MMM yyyy').format(goal.targetDate!)}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'add_money') {
                    _showAddMoneyToGoalDialog(goal);
                  } else if (value == 'delete') {
                    _deleteGoal(goal.id!);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'add_money',
                    child: Text('💰 Tambah Uang'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('🗑️ Hapus Goal'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Progress bar
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: goal.progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: goal.progress >= 1.0 
                            ? [Colors.green, Colors.lightGreen]
                            : [const Color(0xFFFF69B4), const Color(0xFFFF1493)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terkumpul',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Rp ${NumberFormat('#,###').format(goal.currentAmount)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: goal.progress >= 1.0 
                      ? Colors.green
                      : const Color(0xFFFF69B4),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '${(goal.progress * 100).toInt()}%',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          if (goal.progress >= 1.0)
            Container(
              margin: const EdgeInsets.only(top: 15),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'Target tercapai! Selamat! 🎊',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Dialog Methods
  void _showAddTransactionDialog() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String selectedType = 'expense';
    String selectedCategory = 'Makanan';
    String selectedWallet = 'Cash';
    
    final List<String> expenseCategories = [
      'Makanan', 'Transport', 'Belanja', 'Hiburan', 'Kesehatan', 
      'Pendidikan', 'Tagihan', 'Lainnya'
    ];
    
    final List<String> incomeCategories = [
      'Gaji', 'Bonus', 'Freelance', 'Investasi', 'Hadiah', 'Lainnya'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
  builder: (context, setState) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(25),
        topRight: Radius.circular(25),
      ),
    ),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tambah Transaksi 💰',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF69B4),
              ),
            ),
            const SizedBox(height: 25),
                
                // Type selection
                Text(
                  'Tipe Transaksi',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          selectedType = 'expense';
                          if (!expenseCategories.contains(selectedCategory)) {
                            selectedCategory = expenseCategories.first;
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: selectedType == 'expense' 
                                ? Colors.red.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: selectedType == 'expense' 
                                  ? Colors.red 
                                  : Colors.grey.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward,
                                color: selectedType == 'expense' ? Colors.red : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pengeluaran',
                                style: GoogleFonts.poppins(
                                  color: selectedType == 'expense' ? Colors.red : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          selectedType = 'income';
                          if (!incomeCategories.contains(selectedCategory)) {
                            selectedCategory = incomeCategories.first;
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: selectedType == 'income' 
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: selectedType == 'income' 
                                  ? Colors.green 
                                  : Colors.grey.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward,
                                color: selectedType == 'income' ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pemasukan',
                                style: GoogleFonts.poppins(
                                  color: selectedType == 'income' ? Colors.green : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Amount input
                Text(
                  'Jumlah',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      hintText: 'Masukkan jumlah',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      prefixText: 'Rp ',
                      prefixStyle: GoogleFonts.poppins(
                        color: const Color(0xFFFF69B4),
                        fontWeight: FontWeight.bold,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Category selection
                Text(
                  'Kategori',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFFF69B4)),
                      style: GoogleFonts.poppins(color: const Color(0xFF333333)),
                      onChanged: (String? newValue) {
                        setState(() => selectedCategory = newValue!);
                      },
                      items: (selectedType == 'expense' ? expenseCategories : incomeCategories)
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Wallet selection
                Text(
                  'Dompet',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedWallet,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFFF69B4)),
                      style: GoogleFonts.poppins(color: const Color(0xFF333333)),
                      onChanged: (String? newValue) {
                        setState(() => selectedWallet = newValue!);
                      },
                      items: _wallets.skip(1).map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text('${_getWalletEmoji(value)} $value'),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Description input
                Text(
                  'Keterangan',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: descriptionController,
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      hintText: 'Tambahkan keterangan...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (amountController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                        final transaction = Transaction(
                          type: selectedType,
                          amount: double.parse(amountController.text),
                          category: selectedCategory,
                          description: descriptionController.text,
                          date: DateTime.now(),
                          wallet: selectedWallet,
                        );
                        
                        await _dbHelper.insertTransaction(transaction);
                        await _loadAllData();

                        if (!context.mounted) return;
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Transaksi berhasil ditambahkan! 💕',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: const Color(0xFFFF69B4),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF69B4),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      'Simpan Transaksi 💰',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  void _showAddGoalDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController targetController = TextEditingController();
    String selectedEmoji = '💰';
    DateTime? selectedDate;
    
    final List<String> emojiOptions = [
      '💰', '🎯', '🏠', '🚗', '📱', '👗', '🎮', '📚', '✈️', '💍'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Buat Target Tabungan 🎯',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF69B4),
                  ),
                ),
                const SizedBox(height: 25),
                
                // Name input
                Text(
                  'Nama Target',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: nameController,
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      hintText: 'Contoh: iPhone baru, Liburan ke Bali',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Target amount
                Text(
                  'Target Jumlah',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      hintText: 'Masukkan target jumlah',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      prefixText: 'Rp ',
                      prefixStyle: GoogleFonts.poppins(
                        color: const Color(0xFFFF69B4),
                        fontWeight: FontWeight.bold,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Emoji selection
                Text(
                  'Pilih Emoji',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: emojiOptions.length,
                    itemBuilder: (context, index) {
                      final emoji = emojiOptions[index];
                      return GestureDetector(
                        onTap: () => setState(() => selectedEmoji = emoji),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: selectedEmoji == emoji 
                                ? const Color(0xFFFF69B4).withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: selectedEmoji == emoji 
                                  ? const Color(0xFFFF69B4)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                
                // Target date (optional)
                Text(
                  'Target Tanggal (Opsional)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFFFF69B4)),
                        const SizedBox(width: 15),
                        Text(
                          selectedDate != null 
                              ? DateFormat('dd MMM yyyy').format(selectedDate!)
                              : 'Pilih tanggal target',
                          style: GoogleFonts.poppins(
                            color: selectedDate != null 
                                ? const Color(0xFF333333)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                
                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isNotEmpty && targetController.text.isNotEmpty) {
                        final goal = SavingGoal(
                          name: nameController.text,
                          targetAmount: double.parse(targetController.text),
                          emoji: selectedEmoji,
                          createdDate: DateTime.now(),
                          targetDate: selectedDate,
                        );
                        
                        await _dbHelper.insertSavingGoal(goal);
                        await _loadAllData();
                        
                        // Check if the widget is still mounted before using context
                        if (context.mounted) {
                          Navigator.pop(context);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Target tabungan berhasil dibuat! 🎯',
                                style: GoogleFonts.poppins(),
                              ),
                              backgroundColor: const Color(0xFFFF69B4),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF69B4),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      'Buat Target 🎯',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Perbaikan untuk method _showAddWishlistDialog()
void _showAddWishlistDialog() {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  String selectedEmoji = '🛍️';
  String selectedPriority = 'medium';
  
  final List<String> emojiOptions = [
    '🛍️', '👗', '👠', '💄', '📱', '💻', '🎮', '📚', '🏠', '🚗'
  ];
  
  final List<Map<String, dynamic>> priorities = [
    {'value': 'high', 'label': 'Prioritas Tinggi', 'color': Colors.red},
    {'value': 'medium', 'label': 'Prioritas Sedang', 'color': Colors.orange},
    {'value': 'low', 'label': 'Prioritas Rendah', 'color': Colors.green},
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Container(
        height: MediaQuery.of(context).size.height * 0.85, // Tinggi diperbesar jadi 85%
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Tambah ke Wishlist 🛍️',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF69B4),
                ),
              ),
              const SizedBox(height: 25),
              
              // BAGIAN FORM DALAM SCROLLABLE
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name input
                      Text(
                        'Nama Barang',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextField(
                          controller: nameController,
                          style: GoogleFonts.poppins(),
                          decoration: InputDecoration(
                            hintText: 'Contoh: Dress cantik, Sepatu heels',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Price input
                      Text(
                        'Harga',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(),
                          decoration: InputDecoration(
                            hintText: 'Masukkan harga',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey),
                            prefixText: 'Rp ',
                            prefixStyle: GoogleFonts.poppins(
                              color: const Color(0xFFFF69B4),
                              fontWeight: FontWeight.bold,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Emoji selection
                      Text(
                        'Pilih Emoji',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: emojiOptions.length,
                          itemBuilder: (context, index) {
                            final emoji = emojiOptions[index];
                            return GestureDetector(
                              onTap: () => setState(() => selectedEmoji = emoji),
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: selectedEmoji == emoji 
                                      ? const Color(0xFFFF69B4).withValues(alpha: 0.2)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: selectedEmoji == emoji 
                                        ? const Color(0xFFFF69B4)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Text(emoji, style: const TextStyle(fontSize: 24)),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Priority selection
                      Text(
                        'Prioritas',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: priorities.map((priority) {
                          return GestureDetector(
                            onTap: () => setState(() => selectedPriority = priority['value']),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: selectedPriority == priority['value']
                                    ? priority['color'].withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: selectedPriority == priority['value']
                                      ? priority['color']
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: priority['color'],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Text(
                                    priority['label'],
                                    style: GoogleFonts.poppins(
                                      color: selectedPriority == priority['value']
                                          ? priority['color']
                                          : Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 30), // Extra space sebelum tombol
                    ],
                  ),
                ),
              ),
              
              // TOMBOL SELALU TERLIHAT DI BAWAH (TIDAK IKUT SCROLL)
              Container(
                padding: const EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Validasi input
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Nama barang tidak boleh kosong!',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      if (priceController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Harga tidak boleh kosong!',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      try {
                        final item = WishlistItem(
                          name: nameController.text.trim(),
                          price: double.parse(priceController.text),
                          emoji: selectedEmoji,
                          priority: selectedPriority,
                          createdDate: DateTime.now(),
                        );
                        
                        // Simpan ke database
                        await _dbHelper.insertWishlistItem(item);
                        
                        // Refresh data
                        await _loadAllData();
                        
                        // Tutup dialog jika context masih valid
                        if (context.mounted) {
                          Navigator.pop(context);
                          
                          // Tampilkan notifikasi sukses
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Text(
                                    '✅ ${item.emoji} ${item.name} berhasil ditambahkan!',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFFFF69B4),
                              duration: const Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        // Handle error parsing harga
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Format harga tidak valid! Masukkan angka saja.',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF69B4),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFFFF69B4).withValues(alpha: 0.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🛍️', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Text(
                          'Tambah ke Wishlist',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  void _showAddMoneyToGoalDialog(SavingGoal goal) {
  final TextEditingController amountController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Goal info
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF69B4), Color(0xFFFF1493)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(goal.emoji, style: const TextStyle(fontSize: 24)),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Rp ${NumberFormat('#,###').format(goal.currentAmount)} / Rp ${NumberFormat('#,###').format(goal.targetAmount)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      Text(
                        'Tambah Uang ke Target 💰',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF69B4),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Jumlah Uang',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(),
                          decoration: InputDecoration(
                            hintText: 'Masukkan jumlah',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey),
                            prefixText: 'Rp ',
                            prefixStyle: GoogleFonts.poppins(
                              color: const Color(0xFFFF69B4),
                              fontWeight: FontWeight.bold,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Jumlah Cepat',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          _buildQuickAmountButton('50K', 50000, amountController),
                          const SizedBox(width: 10),
                          _buildQuickAmountButton('100K', 100000, amountController),
                          const SizedBox(width: 10),
                          _buildQuickAmountButton('500K', 500000, amountController),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (amountController.text.isNotEmpty) {
                              final amount = double.parse(amountController.text);
                              final updatedGoal = SavingGoal(
                                id: goal.id,
                                name: goal.name,
                                targetAmount: goal.targetAmount,
                                currentAmount: goal.currentAmount + amount,
                                emoji: goal.emoji,
                                createdDate: goal.createdDate,
                                targetDate: goal.targetDate,
                              );

                              await _dbHelper.updateSavingGoal(updatedGoal);
                              await _loadAllData();

                              if (!context.mounted) return;

                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Berhasil menambah Rp ${NumberFormat('#,###').format(amount)} ke ${goal.name}! 💰',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: const Color(0xFFFF69B4),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF69B4),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            'Tambah Uang 💰',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

  Widget _buildQuickAmountButton(String label, double amount, TextEditingController controller) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.text = amount.toInt().toString(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF69B4).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFFF69B4).withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: const Color(0xFFFF69B4),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Delete methods
  void _deleteTransaction(int id) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Hapus Transaksi? 🗑️',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: Text(
        'Kamu yakin mau hapus transaksi ini?',
        style: GoogleFonts.poppins(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Batal',
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ),
        TextButton(
          onPressed: () async {
            await _dbHelper.deleteTransaction(id);
            await _loadAllData();

            if (!context.mounted) return;

            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Transaksi berhasil dihapus! 🗑️',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.red,
              ),
            );
          },
          child: Text(
            'Hapus',
            style: GoogleFonts.poppins(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}


  void _deleteGoal(int id) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Hapus Target? 🎯',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: Text(
        'Kamu yakin mau hapus target tabungan ini?',
        style: GoogleFonts.poppins(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Batal',
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ),
        TextButton(
          onPressed: () async {
            await _dbHelper.deleteSavingGoal(id);
            await _loadAllData();

            if (!context.mounted) return;

            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Target berhasil dihapus! 🗑️',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.red,
              ),
            );
          },
          child: Text(
            'Hapus',
            style: GoogleFonts.poppins(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}


  void _deleteWishlistItem(int id) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Hapus dari Wishlist? 🛍️',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: Text(
        'Kamu yakin mau hapus item ini dari wishlist?',
        style: GoogleFonts.poppins(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Batal',
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ),
        TextButton(
          onPressed: () async {
            await _dbHelper.deleteWishlistItem(id);
            await _loadAllData();

            if (!context.mounted) return;

            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Item berhasil dihapus dari wishlist! 🗑️',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.red,
              ),
            );
          },
          child: Text(
            'Hapus',
            style: GoogleFonts.poppins(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}


  void _buyWishlistItem(WishlistItem item) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Beli Item? 🛒',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Kamu mau beli ${item.name}?',
            style: GoogleFonts.poppins(),
          ),
          const SizedBox(height: 10),
          Text(
            'Harga: Rp ${NumberFormat('#,###').format(item.price)}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF69B4),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Item akan dihapus dari wishlist dan ditambahkan sebagai transaksi pengeluaran.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Batal',
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ),
        TextButton(
          onPressed: () async {
            final transaction = Transaction(
              type: 'expense',
              amount: item.price,
              category: 'Belanja',
              description: item.name,
              date: DateTime.now(),
              wallet: 'Cash',
            );

            await _dbHelper.insertTransaction(transaction);
            await _dbHelper.deleteWishlistItem(item.id!);
            await _loadAllData();

            if (!context.mounted) return;

            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Yeay! ${item.name} berhasil dibeli! 🛒✨',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.green,
              ),
            );
          },
          child: Text(
            'Beli Sekarang',
            style: GoogleFonts.poppins(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}