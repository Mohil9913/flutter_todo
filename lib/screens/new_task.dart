import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NewTask extends StatefulWidget {
  final Map? task;
  final bool? toggleComplete;

  const NewTask({
    super.key,
    this.task,
    this.toggleComplete,
  });

  @override
  State<NewTask> createState() => _NewTaskState();
}

class _NewTaskState extends State<NewTask> {
  bool isLoading = false;
  bool isEdited = false;
  TextEditingController nameController = TextEditingController();
  TextEditingController taskController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.task != null) {
      isEdited = true;
      nameController.text = widget.task!['title'];
      taskController.text = widget.task!['description'];
      if (widget.toggleComplete!) {
        updateTask();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdited ? 'Edit Task' : 'New Task'),
      ),
      body: Visibility(
        visible: !isLoading,
        replacement: const Center(child: CupertinoActivityIndicator()),
        child: ListView(
          padding: const EdgeInsets.all(30),
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Name'),
            ),
            const SizedBox(
              height: 20,
            ),
            TextField(
              controller: taskController,
              decoration: const InputDecoration(hintText: 'Task'),
              keyboardType: TextInputType.multiline,
              minLines: 2,
              maxLines: 8,
            ),
            const SizedBox(
              height: 30,
            ),
            ElevatedButton(
              onPressed: isEdited ? updateTask : submitTask,
              child: Text(isEdited ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> updateTask() async {
    setState(() {
      isLoading = true;
    });

    final name = nameController.text;
    final task = taskController.text;
    final isCompleted = widget.toggleComplete!
        ? !widget.task!["is_completed"]
        : widget.task!["is_completed"];
    final data = {
      "title": name,
      "description": task,
      "is_completed": isCompleted,
    };

    final id = widget.task!['_id'] as String;
    final encodedId = Uri.encodeComponent(id);
    final url = 'https://api.nstack.in/v1/todos/$encodedId';
    final uri = Uri.parse(url);
    final response = await http.put(
      uri,
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
    setState(() {
      isLoading = false;
    });
    print(response.body);
    showSnackBar(response.statusCode);
  }

  Future<void> submitTask() async {
    setState(() {
      isLoading = true;
    });
    final name = nameController.text;
    final task = taskController.text;
    final data = {
      "title": name,
      "description": task,
      "is_completed": false,
    };

    const url = 'https://api.nstack.in/v1/todos';
    final uri = Uri.parse(url);
    final response = await http.post(
      uri,
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
    setState(() {
      isLoading = false;
    });
    showSnackBar(response.statusCode);
  }

  void showSnackBar(int status) {
    bool isSuccess = status >= 200 ? true : false;

    final snackBar = SnackBar(
      content: Text(
        ((isSuccess)
            ? ((isEdited)
                ? ('Task Updated Successfully!')
                : ('Task Added Successfully!'))
            : ('Something Went Wrong!')),
      ),
      backgroundColor: isSuccess ? Colors.green : Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    if (isSuccess) {
      Navigator.pop(context);
    }
  }
}
