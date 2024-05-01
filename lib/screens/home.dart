import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:todo/screens/new_task.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isLoading = false;
  List tasks = [];

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do App'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: navigateToAddPage,
        label: const Text('New Task'),
      ),
      body: Visibility(
        visible: !isLoading,
        replacement: const Center(
          child: CupertinoActivityIndicator(),
        ),
        child: tasks.isEmpty
            ? const Center(
                child: Text(
                  'No Tasks to Display!',
                  textAlign: TextAlign.center,
                ),
              )
            : RefreshIndicator(
                onRefresh: fetchTasks,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index] as Map;
                    final id = task['_id'] as String;
                    return Card(
                      child: ListTile(
                        title: Text(
                          task['title'],
                          style: task['is_completed']
                              ? const TextStyle(
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                )
                              : const TextStyle(),
                        ),
                        subtitle: Text(
                          task['description'],
                          style: task['is_completed']
                              ? const TextStyle(
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                )
                              : const TextStyle(),
                        ),
                        trailing: PopupMenuButton(
                          onSelected: (value) {
                            if (value == 'complete') {
                              editById(task, true);
                            } else if (value == 'edit') {
                              editById(task, false);
                            } else if (value == 'delete') {
                              deleteById(id);
                            }
                          },
                          itemBuilder: (context) {
                            return [
                              PopupMenuItem(
                                value: 'complete',
                                child: Text(task["is_completed"]
                                    ? 'Make Incomplete'
                                    : 'Make Completed'),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ];
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Future<void> navigateToAddPage() async {
    final route = MaterialPageRoute(
      builder: ((context) => const NewTask()),
    );

    setState(() {
      isLoading = true;
    });
    await Navigator.push(context, route);
    setState(() {
      isLoading = false;
    });
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    setState(() {
      isLoading = true;
    });
    const url = 'https://api.nstack.in/v1/todos?page=1&limit=20';
    final uri = Uri.parse(url);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map;
      final result = data["items"] as List;
      setState(() {
        tasks = result;
      });
    }

    showSnackBar(response.statusCode);

    setState(() {
      isLoading = false;
    });
  }

  Future<void> editById(Map task, bool toggleComplete) async {
    final route = MaterialPageRoute(
      builder: ((context) => NewTask(
            task: task,
            toggleComplete: toggleComplete,
          )),
    );

    setState(() {
      isLoading = true;
    });
    await Navigator.push(context, route);
    setState(() {
      isLoading = false;
    });
    fetchTasks();
  }

  Future<void> deleteById(String id) async {
    setState(() {
      isLoading = true;
    });
    final encodedId = Uri.encodeComponent(id);
    final url = 'https://api.nstack.in/v1/todos/$encodedId';
    final uri = Uri.parse(url);
    final response = await http.delete(uri);

    showSnackBar(response.statusCode);

    setState(() {
      isLoading = false;
    });
    fetchTasks();
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task Deleted!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showSnackBar(int status) {
    if (status >= 400) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something Went Wrong!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
