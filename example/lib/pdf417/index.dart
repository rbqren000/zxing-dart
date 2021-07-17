import 'package:flutter/cupertino.dart';

class IndexPage extends StatefulWidget {
  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Pdf417 Demo'),
      ),
      child: Center(
        child: Text('pdf417'),
      ),
    );
  }
}