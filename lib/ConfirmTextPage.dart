import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'Contact.dart';

class ConfirmTextPage extends StatefulWidget {
  final Map<String, dynamic> result;

  ConfirmTextPage({required this.result});

  @override
  _ConfirmTextPageState createState() => _ConfirmTextPageState();
}
class _ConfirmTextPageState extends State<ConfirmTextPage> {
  late TextEditingController _textController;
  late TextEditingController _num1Controller;
  late TextEditingController _num2Controller;
  late String _selectedType;

  @override
  void initState() {
    super.initState();

    _selectedType = widget.result['type'];
    _textController = TextEditingController();
    _num1Controller = TextEditingController();
    _num2Controller = TextEditingController();

    if (_selectedType == 'tunis') {
      _num1Controller.text = widget.result['num1'] ?? '';
      _num2Controller.text = widget.result['num2'] ?? '';
    } else if (_selectedType == 'TN' || _selectedType == 'other') {
      _textController.text = widget.result['num'] ?? '';
    }
  }


  Future<void> _searchAndCall() async {
    var box = await Hive.openBox<Contact>('contacts');
    String licensePlate;

    if (_selectedType == 'tunis') {
      licensePlate = '${_num1Controller.text} تونس ${_num2Controller.text}';
    } else if (_selectedType == 'TN'){
      licensePlate = '${_textController.text}ن ت';
    }else {
      licensePlate = _textController.text;
    }

    var contact = box.values.firstWhere(
          (contact) => contact.licensePlate == licensePlate,
      orElse: () => Contact(licensePlate: '', phoneNumber: ''),
    );

    if (contact.licensePlate.isNotEmpty) {
      String url = 'tel:${contact.phoneNumber}';
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url);
      } else {
        throw 'Could not launch $url';
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Contact Not Found'),
            content:
            Text('No contact found for the license plate $licensePlate.'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm License Plate'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedType,
              items: const [
                DropdownMenuItem(value: 'other', child: Text('Other')),
                DropdownMenuItem(value: 'tunis', child: Text('Tunis')),
                DropdownMenuItem(value: 'TN', child: Text('TN')),
              ],
              onChanged: (String? newValue) {
                setState(() {
                  _selectedType = newValue!;
                  _textController.clear();
                  _num1Controller.clear();
                  _num2Controller.clear();
                });
              },
            ),
            const SizedBox(height: 20),
            if (_selectedType == 'other' || _selectedType == 'TN') ...[
              TextField(
                controller: _textController,
                maxLength: _selectedType == 'TN' ? 6 : null,
                decoration: InputDecoration(
                  labelText: 'License Plate',
                  counterText: "",
                ),
              ),
            ] else
              if (_selectedType == 'tunis') ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _num1Controller,
                        maxLength: 3,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Num1 (max 3 digits)',
                          counterText: "",
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _num2Controller,
                        maxLength: 6,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Num2 (max 6 digits)',
                          counterText: "",
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _searchAndCall,
              child: const Text('Confirm and Call'),
            ),
          ],
        ),
      ),
    );
  }
}