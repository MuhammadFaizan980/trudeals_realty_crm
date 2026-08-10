import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../domain/entities/contact.dart';

class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String? _phone;
  String? _email;
  LeadType _type = LeadType.seller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Lead')),
      body: Padding(
        padding: EdgeInsets.all(24.px),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Phone'),
                onSaved: (value) => _phone = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                onSaved: (value) => _email = value,
              ),
              DropdownButtonFormField<LeadType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Lead Type'),
                items: LeadType.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase())))
                    .toList(),
                onChanged: (value) => setState(() => _type = value!),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // Use _name, _phone, _email here
                    debugPrint('Create contact: $_name, $_phone, $_email, $_type');
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50.px),
                  backgroundColor: Colors.blueGrey[800],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Create Lead'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
