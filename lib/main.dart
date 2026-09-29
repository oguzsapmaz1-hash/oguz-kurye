import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const OguzKuryeApp());
}

class OguzKuryeApp extends StatelessWidget {
  const OguzKuryeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Oğuz Kurye',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const AnaGezinmeEkrani(),
    );
  }
}

class AnaGezinmeEkrani extends StatefulWidget {
  const AnaGezinmeEkrani({super.key});

  @override
  State<AnaGezinmeEkrani> createState() => _AnaGezinmeEkraniState();
}

class _AnaGezinmeEkraniState extends State<AnaGezinmeEkrani> {
  int _seciliSekme = 0;

  final List<Widget> _sayfalar = [
    const KazancEkrani(),
    const HaritaEkrani(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _sayfalar[_seciliSekme],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _seciliSekme,
        onTap: (index) => setState(() => _seciliSekme = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Kazanç Takibi'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Uşak Haritası'),
        ],
      ),
    );
  }
}

// ---------------- KAZANÇ EKRANI ----------------
class KazancEkrani extends StatefulWidget {
  const KazancEkrani({super.key});

  @override
  State<KazancEkrani> createState() => _KazancEkraniState();
}

class _KazancEkraniState extends State<KazancEkrani> {
  final paketController = TextEditingController();
  final yakitController = TextEditingController();
  double netKazanc = 0.0;
  final double paketUcreti = 45.0; // Paket başı varsayılan ücret

  void hesapla() {
    setState(() {
      int paket = int.tryParse(paketController.text) ?? 0;
      double yakit = double.tryParse(yakitController.text) ?? 0.0;
      netKazanc = (paket * paketUcreti) - yakit;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Oğuz Kurye - Günlük Kazanç')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: paketController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Teslim Edilen Paket Sayısı', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: yakitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Yakıt Gideri (TL)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: hesapla,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Hesapla', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 32),
            Card(
              color: Colors.deepOrange.shade50,
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text('Bugünkü Net Kazancın', style: TextStyle(fontSize: 16, color: Colors.black54)),
                    const SizedBox(height: 8),
                    Text(
                      '₺${netKazanc.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepOrange.shade800),
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

// ---------------- HARİTA EKRANI ----------------
class HaritaEkrani extends StatefulWidget {
  const HaritaEkrani({super.key});

  @override
  State<HaritaEkrani> createState() => _HaritaEkraniState();
}

class _HaritaEkraniState extends State<HaritaEkrani> {
  LatLng anlikKonum = const LatLng(38.6742, 29.4059); // Uşak Merkez
  final MapController haritaKontrolcusu = MapController();

  @override
  void initState() {
    super.initState();
    _konumAl();
  }

  Future<void> _konumAl() async {
    bool servisAcik = await Geolocator.isLocationServiceEnabled();
    if (!servisAcik) return;

    LocationPermission izin = await Geolocator.checkPermission();
    if (izin == LocationPermission.denied) {
      izin = await Geolocator.requestPermission();
      if (izin == LocationPermission.denied) return;
    }

    Position pozisyon = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      anlikKonum = LatLng(pozisyon.latitude, pozisyon.longitude);
      haritaKontrolcusu.move(anlikKonum, 15.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uşak Canlı Rota')),
      body: FlutterMap(
        mapController: haritaKontrolcusu,
        options: MapOptions(
          initialCenter: anlikKonum,
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.oguz.kurye',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: anlikKonum,
                width: 50,
                height: 50,
                child: const Icon(Icons.motorcycle, color: Colors.deepOrange, size: 40),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _konumAl,
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
