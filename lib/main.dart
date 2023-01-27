import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_spinbox/material.dart';
import 'package:provider/provider.dart';
import 'package:quantity_input/quantity_input.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ItemListModel(),
      child: const MyApp()
    )
  );
}

class Item {
  String name = '';
  Item(this.name);
}

class ItemListModel extends ChangeNotifier {
  final List<Item> _items = [];

  UnmodifiableListView<Item> get items =>
    UnmodifiableListView(_items);

  void add(Item item) {
    _items.add(item);
    notifyListeners();
  }
  void remove(Item item) {
    _items.removeWhere((listItem) => listItem.name == item.name);
    notifyListeners();
  }
  void clear() {
    _items.clear();
    notifyListeners();
  }
  void edit(Item oldItem, Item newItem) {
    final index = _items.indexOf(oldItem);
    if (index == -1) {
      throw 'Unable to find item to edit.';
    }
    _items[index] = newItem;
    notifyListeners();
  }

  // void _print() {
  //   for (var item in items) {
  //     print(item.name);
  //   }
  // }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Listpicker',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void addToList(BuildContext context, Item item) {
    var itemList = context.read<ItemListModel>();
    itemList.add(item);
  }

  final _textFieldController = TextEditingController();
  int _numToPick = 1;

  List<Item> pickFromList(BuildContext context, int quantity) {
    final itemList = context.read<ItemListModel>();
    final items = [...itemList.items];
    items.shuffle();
    return items.sublist(0, quantity - 1);
  }

  @override
  Widget build(BuildContext context) {
    final itemList = context.read<ItemListModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('List Picker'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _textFieldController,
              onSubmitted: (value) {
                var item = Item(value);
                addToList(context, item);
                _textFieldController.clear();
              },
              style: const TextStyle(
                fontSize: 32,
              ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Add an item to the list',
              ),
            ),
            const SizedBox(height: 22.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:  [
                ElevatedButton.icon(
                  // onPressed: onPressed,
                  label: const Text('Pick'),
                  icon: const Icon(Icons.casino),
                  style: ButtonStyle(
                    minimumSize: MaterialStateProperty.all(const Size(100, 50)),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                  ),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (dialogContext) => PickDialog(quantity: _numToPick)
                  ),
                ),
                const SizedBox(width: 24),
                QuantityInput(
                  value: _numToPick, 
                  onChanged: (value) => setState(() => _numToPick = int.parse(value)),
                  minValue: 1,
                  maxValue: itemList.items.isEmpty ? 1 : itemList.items.length,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                )
              ],
            ),
            const SizedBox(height: 22.5),
            ItemListView(itemList: itemList),
          ],
        ),
      ),
    );
  }
}

class PickDialog extends StatelessWidget {
  const PickDialog({
    Key? key,
    required this.quantity,
  }) : super(key: key);

  final int quantity;

  @override
  Widget build(BuildContext context) {

    final itemList = context.read<ItemListModel>();
    final items = [...itemList.items];
    items.shuffle();
    final pickedItems = items.sublist(0, quantity);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var item in pickedItems)
              Text(
                item.name,
                style: const TextStyle(fontSize: 24),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              }, 
              style: ButtonStyle(
                minimumSize: MaterialStateProperty.all(const Size(100, 40)),
                textStyle: MaterialStateProperty.all(
                  const TextStyle(
                    fontSize: 20,
                  )
                ),
              ),
              child: const Text('Close'),
            )
          ],
        ),
      ),
    );
  }
}

class ItemListView extends StatelessWidget {
  const ItemListView({
    Key? key,
    required this.itemList,
  }) : super(key: key);

  final ItemListModel itemList;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        key: Key(itemList.items.length.toString()),
        padding: const EdgeInsets.all(20),
        children: [
          Column(
            children: [
              Consumer<ItemListModel>(
                builder: (context, item, child) => Column(
                  children: [
                    for (var i in item.items)
                      ItemWidget(
                        item: i,
                        key: Key(i.name),
                      )
                  ],
                )
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ItemWidget extends StatefulWidget {
  const ItemWidget({
    Key? key,
    required this.item,
  }) : super(key: key);

  final Item item;

  @override
  State<ItemWidget> createState() => _ItemWidgetState();
}

class _ItemWidgetState extends State<ItemWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller.text = widget.item.name;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onEditingComplete: () {
                  var newItem = Item(_controller.text);
                  var itemModel = context.read<ItemListModel>();
                  itemModel.edit(widget.item, newItem);
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 12,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 24,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                var itemModel = context.read<ItemListModel>();
                itemModel.remove(widget.item);
              },
              icon: const Icon(Icons.delete),
            ),
          ],
        ),
      ),
    );
  }
}

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});
//
//   final String title;
//
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;
//
//   void _incrementCounter() {
//     setState(() {
//       _counter++;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text(
//               'You have pushed the button this many times:',
//             ),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headline4,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
