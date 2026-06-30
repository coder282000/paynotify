import 'package:flutter/material.dart';

class StationProfileForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController registrationController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController countyController;
  final TextEditingController postalController;
  final VoidCallback onChanged;

  const StationProfileForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.registrationController,
    required this.phoneController,
    required this.emailController,
    required this.addressController,
    required this.cityController,
    required this.countyController,
    required this.postalController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Station Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Station Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store),
                      ),
                      onChanged: (_) => onChanged(),
                      validator: (value) => value?.isEmpty == true ? 'Station name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: registrationController,
                      decoration: const InputDecoration(
                        labelText: 'Registration Number *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      onChanged: (_) => onChanged(),
                      validator: (value) => value?.isEmpty == true ? 'Registration number is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      onChanged: (_) => onChanged(),
                      validator: (value) => value?.isEmpty == true ? 'Phone number is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      onChanged: (_) => onChanged(),
                      validator: (value) => value?.isEmpty == true ? 'Address is required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: cityController,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => onChanged(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: countyController,
                            decoration: const InputDecoration(
                              labelText: 'County',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => onChanged(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: postalController,
                      decoration: const InputDecoration(
                        labelText: 'Postal Code',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}