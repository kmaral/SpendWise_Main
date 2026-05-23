import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/data_manager.dart';
import '../../models/models.dart';

class CategoriesScreen extends StatefulWidget {
  final String currency;

  const CategoriesScreen({super.key, required this.currency});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  List<Category> _categories = [];
  StreamSubscription<List<Category>>? _categoriesSubscription;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _setupRealtimeListeners();
    // Fallback one-shot load only if streams aren't available (e.g. Firebase
    // disabled). When streams are wired, their first emission fills the list.
    if (DataManager.watchCategories() == null) _load();
  }

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _setupRealtimeListeners() {
    final categoriesStream = DataManager.watchCategories();
    if (categoriesStream != null) {
      _categoriesSubscription = categoriesStream.listen((categories) {
        if (mounted) {
          setState(() {
            _categories = categories;
          });
        }
      });
    }
  }

  Future<void> _load() async {
    final cats = await DataManager.getCategories();
    if (!mounted) return;
    setState(() => _categories = cats);
  }

  @override
  Widget build(BuildContext context) {
    final expenseCats = _categories.where((c) => c.type == 'expense').toList();
    final incomeCats = _categories.where((c) => c.type == 'income').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.arrow_upward),
              text: 'Expense (${expenseCats.length})',
            ),
            Tab(
              icon: const Icon(Icons.arrow_downward),
              text: 'Income (${incomeCats.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList(expenseCats, 'expense'),
          _buildCategoryList(incomeCats, 'income'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final activeType = _tabController.index == 0 ? 'expense' : 'income';
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddCategoryScreen(
                currency: widget.currency,
                initialType: activeType,
              ),
            ),
          );
          if (mounted) _load();
        },
        icon: const Icon(Icons.add),
        label: Text(
          'Add ${_tabController.index == 0 ? 'Expense' : 'Income'}',
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<Category> cats, String type) {
    if (cats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'expense' ? Icons.arrow_upward : Icons.arrow_downward,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${type == 'expense' ? 'expense' : 'income'} categories yet',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add one',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cats.length,
      itemBuilder: (context, i) {
        final cat = cats[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: cat.colorData,
              child: Icon(cat.iconData, color: Colors.white),
            ),
            title: Text(cat.name),
            subtitle: Text(
              cat.budgetLimit != null
                  ? 'Budget: ${widget.currency}${cat.budgetLimit!.toStringAsFixed(0)}'
                  : 'No budget set',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditCategoryScreen(
                          category: cat,
                          currency: widget.currency,
                        ),
                      ),
                    );
                    if (mounted) _load();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _delete(cat),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _delete(Category cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${cat.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!mounted || confirm != true) return;

    await DataManager.deleteCategory(cat.id);
    if (!mounted) return;
    setState(() => _categories.removeWhere((c) => c.id == cat.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Category "${cat.name}" deleted')),
    );
  }
}

class AddCategoryScreen extends StatefulWidget {
  final String currency;
  final String initialType;

  const AddCategoryScreen({
    super.key,
    required this.currency,
    this.initialType = 'expense',
  });

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  int _selectedIconCode = 0xe59c;
  int _selectedColorValue = 0xFF4CAF50;
  late String _type;
  bool _hasBudget = false;

  final List<Map<String, dynamic>> _iconOptions = [
    {'icon': Icons.shopping_cart, 'label': 'Shopping Cart'},
    {'icon': Icons.restaurant, 'label': 'Restaurant'},
    {'icon': Icons.home, 'label': 'Home'},
    {'icon': Icons.directions_car, 'label': 'Car'},
    {'icon': Icons.movie, 'label': 'Entertainment'},
    {'icon': Icons.medical_services, 'label': 'Health'},
    {'icon': Icons.school, 'label': 'Education'},
    {'icon': Icons.flight, 'label': 'Travel'},
  ];

  final List<Color> _colorOptions = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.brown,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _selectedIconCode = _iconOptions[0]['icon'].codePoint;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Category')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Expense')),
                ButtonSegment(value: 'income', label: Text('Income')),
              ],
              selected: {_type},
              onSelectionChanged: (v) => setState(() => _type = v.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Icon:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _iconOptions.map((opt) {
                final icon = opt['icon'] as IconData;
                return FilterChip(
                  selected: _selectedIconCode == icon.codePoint,
                  label: Icon(icon),
                  onSelected: (selected) =>
                      setState(() => _selectedIconCode = icon.codePoint),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Color:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorOptions.map((color) {
                return FilterChip(
                  selected: _selectedColorValue == color.value,
                  label: Container(width: 24, height: 24, color: color),
                  onSelected: (selected) =>
                      setState(() => _selectedColorValue = color.value),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Set Budget Limit'),
              value: _hasBudget,
              onChanged: (v) => setState(() => _hasBudget = v),
            ),
            if (_hasBudget) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _budgetCtrl,
                decoration: InputDecoration(
                  labelText: 'Budget Limit',
                  border: const OutlineInputBorder(),
                  prefixText: widget.currency,
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: const Text('Add Category'),
            ),
          ),
        ),
      ),
    );
  }

  String _getIconNameFromCode(int code) {
    final iconMap = {
      Icons.shopping_cart.codePoint: 'ShoppingCart',
      Icons.shopping_bag.codePoint: 'ShoppingBag',
      Icons.store.codePoint: 'Store',
      Icons.restaurant.codePoint: 'Restaurant',
      Icons.fastfood.codePoint: 'FastFood',
      Icons.local_cafe.codePoint: 'Cafe',
      Icons.local_pizza.codePoint: 'Pizza',
      Icons.lunch_dining.codePoint: 'Lunch',
      Icons.dinner_dining.codePoint: 'Dinner',
      Icons.home.codePoint: 'Home',
      Icons.house.codePoint: 'House',
      Icons.apartment.codePoint: 'Apartment',
      Icons.directions_car.codePoint: 'Car',
      Icons.local_gas_station.codePoint: 'GasStation',
      Icons.local_taxi.codePoint: 'Taxi',
      Icons.directions_bus.codePoint: 'Bus',
      Icons.directions_subway.codePoint: 'Subway',
      Icons.train.codePoint: 'Train',
      Icons.two_wheeler.codePoint: 'Bike',
      Icons.movie.codePoint: 'Movie',
      Icons.theater_comedy.codePoint: 'Theater',
      Icons.music_note.codePoint: 'Music',
      Icons.sports_soccer.codePoint: 'Sports',
      Icons.fitness_center.codePoint: 'Fitness',
      Icons.medical_services.codePoint: 'MedicalServices',
      Icons.local_hospital.codePoint: 'Hospital',
      Icons.medication.codePoint: 'Medication',
      Icons.school.codePoint: 'School',
      Icons.book.codePoint: 'Book',
      Icons.library_books.codePoint: 'Library',
      Icons.flight.codePoint: 'Flight',
      Icons.hotel.codePoint: 'Hotel',
      Icons.luggage.codePoint: 'Luggage',
      Icons.phone.codePoint: 'Phone',
      Icons.phone_android.codePoint: 'Mobile',
      Icons.wifi.codePoint: 'Internet',
      Icons.tv.codePoint: 'TV',
      Icons.computer.codePoint: 'Computer',
      Icons.electric_bolt.codePoint: 'Electricity',
      Icons.water_drop.codePoint: 'Water',
      Icons.local_laundry_service.codePoint: 'Laundry',
      Icons.pets.codePoint: 'Pets',
      Icons.child_care.codePoint: 'ChildCare',
      Icons.cake.codePoint: 'Gifts',
      Icons.checkroom.codePoint: 'Clothing',
      Icons.spa.codePoint: 'Beauty',
      Icons.content_cut.codePoint: 'Haircut',
      Icons.work.codePoint: 'Work',
      Icons.business.codePoint: 'Business',
      Icons.account_balance.codePoint: 'Bank',
      Icons.savings.codePoint: 'Savings',
      Icons.attach_money.codePoint: 'Money',
      Icons.wallet.codePoint: 'Wallet',
      Icons.credit_card.codePoint: 'CreditCard',
      Icons.receipt.codePoint: 'Receipt',
      Icons.category.codePoint: 'Category',
    };
    return iconMap[code] ?? 'Category';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Convert iconCode to icon name
    final iconName = _getIconNameFromCode(_selectedIconCode);
    // Convert colorValue to hex string
    final colorHex =
        '#${(_selectedColorValue & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

    final category = Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text,
      icon: iconName,
      color: colorHex,
      type: _type,
      iconCode: _selectedIconCode,
      colorValue: _selectedColorValue,
      budgetLimit: _hasBudget ? double.tryParse(_budgetCtrl.text) : null,
      createdAt: DateTime.now(),
    );

    final categories = await DataManager.getCategories();
    categories.add(category);
    await DataManager.saveCategories(categories);

    if (mounted) Navigator.pop(context);
  }
}

class EditCategoryScreen extends StatefulWidget {
  final Category category;
  final String currency;

  const EditCategoryScreen({
    super.key,
    required this.category,
    required this.currency,
  });

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _budgetCtrl;
  late int _selectedIconCode;
  late int _selectedColorValue;
  late String _type;
  late bool _hasBudget;

  final List<Map<String, dynamic>> _iconOptions = [
    {'icon': Icons.shopping_cart, 'label': 'Shopping Cart'},
    {'icon': Icons.shopping_bag, 'label': 'Shopping Bag'},
    {'icon': Icons.store, 'label': 'Store'},
    {'icon': Icons.restaurant, 'label': 'Restaurant'},
    {'icon': Icons.fastfood, 'label': 'Fast Food'},
    {'icon': Icons.local_cafe, 'label': 'Cafe'},
    {'icon': Icons.local_pizza, 'label': 'Pizza'},
    {'icon': Icons.lunch_dining, 'label': 'Lunch'},
    {'icon': Icons.dinner_dining, 'label': 'Dinner'},
    {'icon': Icons.home, 'label': 'Home'},
    {'icon': Icons.house, 'label': 'House'},
    {'icon': Icons.apartment, 'label': 'Apartment'},
    {'icon': Icons.directions_car, 'label': 'Car'},
    {'icon': Icons.local_gas_station, 'label': 'Gas Station'},
    {'icon': Icons.local_taxi, 'label': 'Taxi'},
    {'icon': Icons.directions_bus, 'label': 'Bus'},
    {'icon': Icons.directions_subway, 'label': 'Subway'},
    {'icon': Icons.train, 'label': 'Train'},
    {'icon': Icons.two_wheeler, 'label': 'Bike'},
    {'icon': Icons.movie, 'label': 'Entertainment'},
    {'icon': Icons.theater_comedy, 'label': 'Theater'},
    {'icon': Icons.music_note, 'label': 'Music'},
    {'icon': Icons.sports_soccer, 'label': 'Sports'},
    {'icon': Icons.fitness_center, 'label': 'Fitness'},
    {'icon': Icons.medical_services, 'label': 'Health'},
    {'icon': Icons.local_hospital, 'label': 'Hospital'},
    {'icon': Icons.medication, 'label': 'Medication'},
    {'icon': Icons.school, 'label': 'Education'},
    {'icon': Icons.book, 'label': 'Book'},
    {'icon': Icons.library_books, 'label': 'Library'},
    {'icon': Icons.flight, 'label': 'Travel'},
    {'icon': Icons.hotel, 'label': 'Hotel'},
    {'icon': Icons.luggage, 'label': 'Luggage'},
    {'icon': Icons.phone, 'label': 'Phone'},
    {'icon': Icons.phone_android, 'label': 'Mobile'},
    {'icon': Icons.wifi, 'label': 'Internet'},
    {'icon': Icons.tv, 'label': 'TV'},
    {'icon': Icons.computer, 'label': 'Computer'},
    {'icon': Icons.electric_bolt, 'label': 'Electricity'},
    {'icon': Icons.water_drop, 'label': 'Water'},
    {'icon': Icons.local_laundry_service, 'label': 'Laundry'},
    {'icon': Icons.pets, 'label': 'Pets'},
    {'icon': Icons.child_care, 'label': 'Child Care'},
    {'icon': Icons.cake, 'label': 'Gifts'},
    {'icon': Icons.checkroom, 'label': 'Clothing'},
    {'icon': Icons.spa, 'label': 'Beauty'},
    {'icon': Icons.content_cut, 'label': 'Haircut'},
    {'icon': Icons.work, 'label': 'Work'},
    {'icon': Icons.business, 'label': 'Business'},
    {'icon': Icons.account_balance, 'label': 'Bank'},
    {'icon': Icons.savings, 'label': 'Savings'},
    {'icon': Icons.attach_money, 'label': 'Money'},
    {'icon': Icons.wallet, 'label': 'Wallet'},
    {'icon': Icons.credit_card, 'label': 'Credit Card'},
    {'icon': Icons.receipt, 'label': 'Receipt'},
    {'icon': Icons.category, 'label': 'Other'},
  ];

  final List<Color> _colorOptions = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.brown,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category.name);
    _budgetCtrl = TextEditingController(
      text: widget.category.budgetLimit?.toString() ?? '',
    );
    _selectedIconCode = widget.category.iconCode ?? Icons.category.codePoint;
    _selectedColorValue = widget.category.colorValue ?? 0xFF2196F3;
    _type = widget.category.type;
    _hasBudget = widget.category.budgetLimit != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Category')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Expense')),
                ButtonSegment(value: 'income', label: Text('Income')),
              ],
              selected: {_type},
              onSelectionChanged: (v) => setState(() => _type = v.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Icon:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _iconOptions.map((opt) {
                final icon = opt['icon'] as IconData;
                return FilterChip(
                  selected: _selectedIconCode == icon.codePoint,
                  label: Icon(icon),
                  onSelected: (selected) =>
                      setState(() => _selectedIconCode = icon.codePoint),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Color:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorOptions.map((color) {
                return FilterChip(
                  selected: _selectedColorValue == color.value,
                  label: Container(width: 24, height: 24, color: color),
                  onSelected: (selected) =>
                      setState(() => _selectedColorValue = color.value),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Set Budget Limit'),
              value: _hasBudget,
              onChanged: (v) => setState(() => _hasBudget = v),
            ),
            if (_hasBudget) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _budgetCtrl,
                decoration: InputDecoration(
                  labelText: 'Budget Limit',
                  border: const OutlineInputBorder(),
                  prefixText: widget.currency,
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _update,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: const Text('Update Category'),
            ),
          ),
        ),
      ),
    );
  }

  String _getIconNameFromCode(int code) {
    final iconMap = {
      Icons.shopping_cart.codePoint: 'ShoppingCart',
      Icons.shopping_bag.codePoint: 'ShoppingBag',
      Icons.store.codePoint: 'Store',
      Icons.restaurant.codePoint: 'Restaurant',
      Icons.fastfood.codePoint: 'FastFood',
      Icons.local_cafe.codePoint: 'Cafe',
      Icons.local_pizza.codePoint: 'Pizza',
      Icons.lunch_dining.codePoint: 'Lunch',
      Icons.dinner_dining.codePoint: 'Dinner',
      Icons.home.codePoint: 'Home',
      Icons.house.codePoint: 'House',
      Icons.apartment.codePoint: 'Apartment',
      Icons.directions_car.codePoint: 'Car',
      Icons.local_gas_station.codePoint: 'GasStation',
      Icons.local_taxi.codePoint: 'Taxi',
      Icons.directions_bus.codePoint: 'Bus',
      Icons.directions_subway.codePoint: 'Subway',
      Icons.train.codePoint: 'Train',
      Icons.two_wheeler.codePoint: 'Bike',
      Icons.movie.codePoint: 'Movie',
      Icons.theater_comedy.codePoint: 'Theater',
      Icons.music_note.codePoint: 'Music',
      Icons.sports_soccer.codePoint: 'Sports',
      Icons.fitness_center.codePoint: 'Fitness',
      Icons.medical_services.codePoint: 'MedicalServices',
      Icons.local_hospital.codePoint: 'Hospital',
      Icons.medication.codePoint: 'Medication',
      Icons.school.codePoint: 'School',
      Icons.book.codePoint: 'Book',
      Icons.library_books.codePoint: 'Library',
      Icons.flight.codePoint: 'Flight',
      Icons.hotel.codePoint: 'Hotel',
      Icons.luggage.codePoint: 'Luggage',
      Icons.phone.codePoint: 'Phone',
      Icons.phone_android.codePoint: 'Mobile',
      Icons.wifi.codePoint: 'Internet',
      Icons.tv.codePoint: 'TV',
      Icons.computer.codePoint: 'Computer',
      Icons.electric_bolt.codePoint: 'Electricity',
      Icons.water_drop.codePoint: 'Water',
      Icons.local_laundry_service.codePoint: 'Laundry',
      Icons.pets.codePoint: 'Pets',
      Icons.child_care.codePoint: 'ChildCare',
      Icons.cake.codePoint: 'Gifts',
      Icons.checkroom.codePoint: 'Clothing',
      Icons.spa.codePoint: 'Beauty',
      Icons.content_cut.codePoint: 'Haircut',
      Icons.work.codePoint: 'Work',
      Icons.business.codePoint: 'Business',
      Icons.account_balance.codePoint: 'Bank',
      Icons.savings.codePoint: 'Savings',
      Icons.attach_money.codePoint: 'Money',
      Icons.wallet.codePoint: 'Wallet',
      Icons.credit_card.codePoint: 'CreditCard',
      Icons.receipt.codePoint: 'Receipt',
      Icons.category.codePoint: 'Category',
    };
    return iconMap[code] ?? 'Category';
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;

    // Convert iconCode to icon name
    final iconName = _getIconNameFromCode(_selectedIconCode);
    // Convert colorValue to hex string
    final colorHex =
        '#${(_selectedColorValue & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

    final updated = widget.category.copyWith(
      name: _nameCtrl.text,
      icon: iconName,
      color: colorHex,
      type: _type,
      iconCode: _selectedIconCode,
      colorValue: _selectedColorValue,
      budgetLimit: _hasBudget ? double.tryParse(_budgetCtrl.text) : null,
      updatedAt: DateTime.now(),
    );

    final categories = await DataManager.getCategories();
    final index = categories.indexWhere((c) => c.id == widget.category.id);
    categories[index] = updated;
    await DataManager.saveCategories(categories);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category "${updated.name}" updated')),
      );
      Navigator.pop(context);
    }
  }
}
