import 'package:flutter/material.dart';
import 'package:p2p_task/screens/counter_example_screen.dart';
import 'package:p2p_task/screens/task_form_screen.dart';
import 'package:p2p_task/screens/task_list_screen.dart';
import 'package:p2p_task/widgets/bottom_navigation.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Builder(
        builder: (context) {
          switch (_selectedIndex) {
            case 0:
              return TaskListScreen();
            case 1:
              return CounterExampleScreen();
            case 2:
              return Center(child: Text('Nothing yet.'));
            case 3:
              return Center(child: Text('Nothing yet.'));
            default:
              return Center(child: Text('Default.'));
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => TaskFormScreen())),
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
      bottomNavigationBar: BottomNavigation(
        onTap: (index) => setState(() {
          _selectedIndex = index;
        }),
      ),
    );
  }
}
