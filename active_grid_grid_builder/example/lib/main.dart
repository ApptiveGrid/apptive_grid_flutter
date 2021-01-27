import 'package:active_grid_grid_builder/active_grid_grid_builder.dart';
import 'package:flutter/material.dart';

/// Shows a contact List
///
/// Set Up your Grid in Active Grid using Text Columns
/// | First Name | Last Name | imgUrl
void main() {
  runApp(ActiveGrid(
      options: ActiveGridOptions(
        environment: ActiveGridEnvironment.alpha,
        authentication: ActiveGridAuthentication(
          username: 'USERNAME',
          password: 'PASSWORD',
        ),
      ),
      child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Active Grid',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ActiveGridGridBuilderState> _builderKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grid Builder'),
      ),
      body: ActiveGridGridBuilder(
          key: _builderKey,
          user: 'USER_ID',
          space: 'SPACE_ID',
          grid: 'GRID_ID',
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            } else if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else {
              return RefreshIndicator(
                onRefresh: () {
                  return _builderKey.currentState?.reload();
                },
                child: ListView.separated(
                  itemCount: snapshot.data.rows.length,
                  separatorBuilder: (context, index) {
                    return Divider();
                  },
                  itemBuilder: (context, index) {
                    final row = snapshot.data.rows[index];
                    return ListTile(
                      leading: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10000),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Image.network(
                              row.entries
                                  .firstWhere((element) =>
                                      element.field.name == 'imgUrl')
                                  .data
                                  .value,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(row.entries
                              .firstWhere((element) =>
                                  element.field.name == 'First Name')
                              .data
                              .value),
                          Text(' '),
                          Text(
                            row.entries
                                .firstWhere((element) =>
                                    element.field.name == 'Last Name')
                                .data
                                .value,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }
          }),
    );
  }
}