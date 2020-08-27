import "package:flutter/material.dart";
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List _toDo = [];
  Map<String, dynamic> _lastDelete;
  int _positionLastDelete;
  TextEditingController _fieldText = new TextEditingController();

  @override
  void initState() {
    super.initState();
    _readData().then((data){
      setState(() {
        _toDo = jsonDecode(data);
      });
    });
  }

  Future <Null> refresh() async{
      await Future.delayed(Duration(seconds: 1));
      setState(() {
        _toDo.sort((a, b){
          if(a["complete"] == true && b["complete"] == false){
            return 1;
          }

          else if(a["complete"] == false && b["complete"] == true){
            return -1;
          }

          else{
            return 0;
          }
          _saveData();
        });
      });
  }

  void addItemToList() {
    setState(() {
      Map<String, dynamic> newToDo = new Map();
      newToDo["title"] = _fieldText.text;
      newToDo["complete"] = false;
      _fieldText.text = "";
      _toDo.add(newToDo);
      _saveData();
    });
  }

  Widget buildItem (BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white,),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text("${_toDo[index]["title"]}"),
        value: _toDo[index]["complete"],
        secondary: CircleAvatar(
          child: Icon(_toDo[index]["complete"] ? Icons.check : Icons.error),
        ),
        onChanged: (check) {
          setState(() {
            _toDo[index]["complete"] = check;
            _saveData();
          });
        },
      ),
      onDismissed: (direction){
        setState(() {
          var _lastRemoved = Map.from(_toDo[index]);
          _positionLastDelete = index;
          _toDo.removeAt(index);
          _saveData();

          final snackBar = new SnackBar(content:
            Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: (){
                setState(() {
                  _toDo.insert(_positionLastDelete, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snackBar);
        });
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 8, 1),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fieldText,
                    decoration: InputDecoration(
                        labelText: "Nova tarefa!",
                        labelStyle: TextStyle(
                          color: Colors.blueAccent,
                        )),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text(
                    "Adicionar",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: addItemToList,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refresh,
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10),
                itemCount: _toDo.length,
                itemBuilder: buildItem,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<File> _getFile() async {
    final pathFile = await getApplicationDocumentsDirectory();
    return File("${pathFile.path}/database.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDo);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (ex) {
      return ex;
    }
  }
}
