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
  const CuteMoneyTrackerApp({Key? key}) : super(key: key);

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

class Transaction {
  final int? id;
  final String type; // 'income' or 'expense'
  final double amount;
  final String category;
  final String description;
  final DateTime date;

  Transaction({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.millisecondsSinceEpoch,
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
    );
  }
}

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
      version: 1,
      onCreate: _onCreate,
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
        date INTEGER NOT NULL
      )
    ''');
  }

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

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Transaction> _transactions = [];
  String _selectedFilter = 'daily';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTransactions();
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

    final transactions = await _dbHelper.getTransactionsByDateRange(start, end);
    setState(() {
      _transactions = transactions;
    });
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
              const SizedBox(height: 10),
              _buildFilterTabs(),
              const SizedBox(height: 20),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDashboard(),
                    _buildTransactionsList(),
                    _buildMonthlyReport(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildCuteFloatingActionButton(context),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
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
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Yuk kelola uang kamu hari ini',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFFFF69B4),
          borderRadius: BorderRadius.circular(25),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFFFF69B4),
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: '💰 Dashboard'),
          Tab(text: '📝 Transaksi'),
          Tab(text: '📊 Laporan'),
        ],
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildFilterButton('daily', 'Harian', '📅'),
              const SizedBox(width: 10),
              _buildFilterButton('monthly', 'Bulanan', '📆'),
              const SizedBox(width: 10),
              _buildFilterButton('yearly', 'Tahunan', '🗓️'),
            ],
          ),
          const SizedBox(height: 20),
          _buildBalanceCard(balance, totalIncome, totalExpense),
          const SizedBox(height: 25),
          Text(
            'Kategori Pengeluaran 🛍️',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF69B4),
            ),
          ),
          const SizedBox(height: 15),
          Container(
            height: 300,
            child: _buildCategoryChart(),
          ),
          const SizedBox(height: 20),
        ],
      ),
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
                color: Colors.pink.withValues(alpha: 0.3),
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
          colors: [Color(0xFFFF69B4), Color(0xFFFFB6C1)],
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
            'Saldo Kamu 💎',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Rp ${NumberFormat('#,###').format(balance)}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildIncomeExpenseCard('Pemasukan', income, '💚', Colors.green),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildIncomeExpenseCard('Pengeluaran', expense, '💸', Colors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseCard(String title, double amount, String emoji, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            '$emoji $title',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Rp ${NumberFormat('#,###').format(amount)}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart() {
    Map<String, double> categoryTotals = {};
    
    for (var transaction in _transactions.where((t) => t.type == 'expense')) {
      categoryTotals[transaction.category] = 
          (categoryTotals[transaction.category] ?? 0) + transaction.amount;
    }

    if (categoryTotals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌸', style: TextStyle(fontSize: 50)),
            const SizedBox(height: 10),
            Text(
              'Belum ada pengeluaran nih',
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    List<PieChartSectionData> sections = [];
    List<Color> colors = [
      const Color(0xFFFF69B4),
      const Color(0xFFFFB6C1),
      const Color(0xFFFFC0CB),
      const Color(0xFFFF1493),
      const Color(0xFFFF6347),
      const Color(0xFFDA70D6),
    ];

    int index = 0;
    categoryTotals.forEach((category, amount) {
      sections.add(
        PieChartSectionData(
          color: colors[index % colors.length],
          value: amount,
          title: category,
          radius: 60,
          titleStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      index++;
    });

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildTransactionsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaksi Terbaru 📝',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF69B4),
            ),
          ),
          const SizedBox(height: 15),
          _transactions.isEmpty
              ? Container(
                  height: 400,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🌸', style: TextStyle(fontSize: 80)),
                        const SizedBox(height: 20),
                        Text(
                          'Belum ada transaksi',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'Yuk mulai catat keuangan kamu!',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: _transactions.asMap().entries.map((entry) {
                    int index = entry.key;
                    Transaction transaction = entry.value;
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildTransactionCard(transaction),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    bool isIncome = transaction.type == 'income';
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
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
              color: isIncome ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              isIncome ? Icons.trending_up : Icons.trending_down,
              color: isIncome ? Colors.green : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.category,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: const Color(0xFF333333),
                  ),
                ),
                Text(
                  transaction.description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(transaction.date),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'} Rp ${NumberFormat('#,###').format(transaction.amount)}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isIncome ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyReport() {
    Map<String, Map<String, double>> monthlyData = {};
    
    for (var transaction in _transactions) {
      String monthYear = DateFormat('MMM yyyy').format(transaction.date);
      if (!monthlyData.containsKey(monthYear)) {
        monthlyData[monthYear] = {'income': 0, 'expense': 0};
      }
      monthlyData[monthYear]![transaction.type] = 
          (monthlyData[monthYear]![transaction.type] ?? 0) + transaction.amount;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Laporan Bulanan 📊',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF69B4),
            ),
          ),
          const SizedBox(height: 15),
          monthlyData.isEmpty
              ? Container(
                  height: 400,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📈', style: TextStyle(fontSize: 80)),
                        const SizedBox(height: 20),
                        Text(
                          'Belum ada data bulanan',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: monthlyData.entries.map((entry) {
                    String month = entry.key;
                    Map<String, double> data = entry.value;
                    double income = data['income'] ?? 0;
                    double expense = data['expense'] ?? 0;
                    double balance = income - expense;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(20),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            month,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFF69B4),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMonthlyStatCard('💚 Pemasukan', income, Colors.green),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildMonthlyStatCard('💸 Pengeluaran', expense, Colors.orange),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildMonthlyStatCard('💰 Saldo', balance, 
                                    balance >= 0 ? Colors.green : Colors.red),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStatCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            'Rp ${NumberFormat('#,###').format(amount)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCuteFloatingActionButton(BuildContext context) {
  return FloatingActionButton(
    onPressed: () {
      _showAddTransactionDialog(context); // ✅ sekarang benar
    },
    backgroundColor: const Color(0xFFFF69B4),
    child: const Icon(Icons.add, color: Colors.white, size: 30),
    elevation: 8,
  );
}


  void _showAddTransactionDialog(BuildContext parentContext) {
  showDialog(
    context: parentContext,
    builder: (BuildContext dialogContext) => AddTransactionDialog(
      onTransactionAdded: (String message) {
        _loadTransactions();
        if (mounted) {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            SnackBar(
              content: Text(
                message,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              backgroundColor: const Color(0xFFFF69B4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          );
        }
      },
    ),
  );
}


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class AddTransactionDialog extends StatefulWidget {
  final Function(String) onTransactionAdded;

  const AddTransactionDialog({super.key, required this.onTransactionAdded});

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedType = 'expense';
  String _selectedCategory = 'Daily';
  
  final List<String> _expenseCategories = [
    'Daily', 'Skincare', 'Pendidikan', 'Transportasi', 'Makanan', 
    'Fashion', 'Hiburan', 'Kesehatan', 'Lainnya'
  ];
  
  final List<String> _incomeCategories = [
    'Gaji', 'Bonus', 'Investasi', 'Side Job', 'Hadiah', 'Lainnya'
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF0F5), Color(0xFFFFE4E1)],
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tambah Transaksi 💕',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF69B4),
                ),
              ),
              const SizedBox(height: 20),
              
              // Type selection
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton('expense', '💸 Pengeluaran'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTypeButton('income', '💰 Pemasukan'),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              
              // Category dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.pink.withValues(alpha: 0.3)),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: 'Kategori',
                    labelStyle: TextStyle(color: Color(0xFFFF69B4)),
                  ),
                  dropdownColor: Colors.white,
                  style: GoogleFonts.poppins(color: const Color(0xFF333333)),
                  items: (_selectedType == 'expense' ? _expenseCategories : _incomeCategories)
                      .map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                ),
              ),
              const SizedBox(height: 15),
              
              // Amount input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.pink.withOpacity(0.3)),
                ),
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: 'Jumlah (Rp)',
                    labelStyle: TextStyle(color: Color(0xFFFF69B4)),
                    prefixText: 'Rp ',
                    prefixStyle: TextStyle(color: Color(0xFFFF69B4)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan jumlah ya sayang!';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 15),
              
              // Description input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.pink.withOpacity(0.3)),
                ),
                child: TextFormField(
                  controller: _descriptionController,
                  style: GoogleFonts.poppins(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: 'Deskripsi',
                    labelStyle: TextStyle(color: Color(0xFFFF69B4)),
                    hintText: 'Ceritain buat apa nih...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Isi deskripsi dong!';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 25),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        if (mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF69B4),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        'Simpan 💕',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String type, String label) {
    bool isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          // Reset category when type changes
          _selectedCategory = type == 'expense' ? _expenseCategories[0] : _incomeCategories[0];
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF69B4) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFFFF69B4),
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.pink.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : const Color(0xFFFF69B4),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final transaction = Transaction(
        type: _selectedType,
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        description: _descriptionController.text,
        date: DateTime.now(),
      );

      await DatabaseHelper().insertTransaction(transaction);
      
      // Close dialog first - gunakan mounted check untuk safety
      if (mounted) {
        Navigator.of(context).pop();
        
        // Call callback with success message
        widget.onTransactionAdded('✨ Transaksi berhasil disimpan!');
      }
    }
  }
}