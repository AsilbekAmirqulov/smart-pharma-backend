import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const SmartPharmaApp());
}

class SmartPharmaApp extends StatelessWidget {
  const SmartPharmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Pharma',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const SearchScreen(),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List pharmacies = [];
  bool isLoading = false;

  // FastAPI backend-dan dorilarni qidirish (IP o'zgartirildi: 192.168.100.88)
  Future<void> searchMedicine(String name) async {
    if (name.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.100.88:8000/search-medicine/?name=$name'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          pharmacies = data['pharmacies'] ?? [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik yuz berdi: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Elektron navbat olish (IP o'zgartirildi: 192.168.100.88)
  Future<void> bookQueue(int pharmacyId, String medicineName) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.88:8000/book-queue/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'pharmacy_id': pharmacyId,
          'medicine_name': medicineName,
          'pickup_time': '18:30',
          'user_phone': '+998901234567',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final booking = data['booking_details'];

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Navbat band qilindi! 🎟️'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Buyurtma ID: ${booking['booking_id']}'),
                Text('Holat: ${booking['status']}'),
                const SizedBox(height: 10),
                Image.network(booking['qr_code_data']),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Yopish'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navbat olishda xatolik: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Pharma — Dori Qidiruv'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Dori nomini kiriting (masalan: paracetamol)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search, size: 30, color: Colors.green),
                  onPressed: () => searchMedicine(_searchController.text),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isLoading) const CircularProgressIndicator(),
            Expanded(
              child: ListView.builder(
                itemCount: pharmacies.length,
                itemBuilder: (context, index) {
                  final item = pharmacies[index];
                  return Card(
                    child: ListTile(
                      title: Text(item['name']),
                      subtitle: Text('Manzil: ${item['address']} (${item['distance_km']} km)'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${item['price_uzs']} so\'m',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white),
                            onPressed: () => bookQueue(
                                item['id'], _searchController.text),
                            child: const Text('Navbat olish'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}