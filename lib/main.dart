import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APIs App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

// Pantalla principal con pestañas
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    PokemonScreen(),
    FlightsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.catching_pokemon),
            label: 'Pokemon',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flight),
            label: 'Vuelos',
          ),
        ],
      ),
    );
  }
}

// ==================== PANTALLA DE POKEMON ====================
class PokemonScreen extends StatefulWidget {
  @override
  _PokemonScreenState createState() => _PokemonScreenState();
}

class _PokemonScreenState extends State<PokemonScreen> {
  List<Map<String, dynamic>> _pokemonList = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  int? _expandedIndex;
  Map<String, dynamic>? _expandedDetails;
  bool _loadingDetails = false;

  Map<String, dynamic>? _searchedPokemon;
  Map<String, dynamic>? _searchedDetails;
  bool _searchExpanded = false;

  @override
  void initState() {
    super.initState();
    fetchPokemon();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchPokemon() async {
    setState(() { _isLoading = true; });

    final url = Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=50');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];

        List<Map<String, dynamic>> pokemonWithImages = [];

        for (var pokemon in results) {
          final detailsResponse = await http.get(Uri.parse(pokemon['url']));
          if (detailsResponse.statusCode == 200) {
            final detailsData = json.decode(detailsResponse.body);
            pokemonWithImages.add({
              'name': pokemon['name'],
              'image': detailsData['sprites']['front_default'],
            });
          }
        }

        setState(() {
          _pokemonList = pokemonWithImages;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }

  void _searchPokemon() async {
    String name = _searchController.text.trim().toLowerCase();
    if (name.isEmpty) return;

    setState(() {
      _loadingDetails = true;
      _searchedPokemon = null;
      _searchedDetails = null;
      _searchExpanded = false;
    });

    try {
      final url = Uri.parse('https://pokeapi.co/api/v2/pokemon/$name');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _searchedPokemon = {'name': data['name'], 'image': data['sprites']['front_default']};
          _searchedDetails = data;
          _loadingDetails = false;
        });
      } else {
        setState(() { _loadingDetails = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pokemon no encontrado')));
      }
    } catch (e) {
      setState(() { _loadingDetails = false; });
    }
  }

  void _toggleExpand(int index, String pokemonName) async {
    if (_expandedIndex == index) {
      setState(() { _expandedIndex = null; _expandedDetails = null; });
      return;
    }

    setState(() { _expandedIndex = index; _expandedDetails = null; _loadingDetails = true; });

    try {
      final url = Uri.parse('https://pokeapi.co/api/v2/pokemon/$pokemonName');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() { _expandedDetails = json.decode(response.body); _loadingDetails = false; });
      }
    } catch (e) {
      setState(() { _loadingDetails = false; });
    }
  }

  String _formatDetails(Map<String, dynamic> data) {
    int id = data['id'];
    int altura = data['height'];
    int peso = data['weight'];
    int expBase = data['base_experience'] ?? 0;
    List tipos = data['types'];
    String tiposStr = tipos.map((t) => t['type']['name']).join(', ');
    List habilidades = data['abilities'];
    String habilidadesStr = habilidades.map((a) => a['ability']['name']).join(', ');
    List stats = data['stats'];
    String statsStr = stats.map((s) => '  ' + s['stat']['name'] + ': ' + s['base_stat'].toString()).join('\n');

    return 'ID: $id\nAltura: ${(altura / 10)} m\nPeso: ${(peso / 10)} kg\nExp Base: $expBase\nTipos: $tiposStr\nHabilidades: $habilidadesStr\nEstadisticas:\n$statsStr';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pokemon API'), backgroundColor: Colors.red, foregroundColor: Colors.white),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(hintText: 'Buscar Pokemon', border: OutlineInputBorder()),
                    onSubmitted: (_) => _searchPokemon(),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(onPressed: _searchPokemon, child: Text('Buscar')),
              ],
            ),
          ),
          if (_searchedPokemon != null)
            Card(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.yellow[100],
              child: Column(
                children: [
                  ListTile(
                    leading: _searchedPokemon!['image'] != null ? Image.network(_searchedPokemon!['image']) : Icon(Icons.image_not_supported),
                    title: Text(_searchedPokemon!['name'].toString().toUpperCase()),
                    subtitle: Text('Resultado de busqueda'),
                    trailing: Icon(_searchExpanded ? Icons.expand_less : Icons.expand_more),
                    onTap: () { setState(() { _searchExpanded = !_searchExpanded; }); },
                  ),
                  if (_searchExpanded && _searchedDetails != null)
                    Padding(padding: EdgeInsets.all(16), child: Text(_formatDetails(_searchedDetails!))),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _pokemonList.length,
                    itemBuilder: (context, index) {
                      final pokemon = _pokemonList[index];
                      bool isExpanded = _expandedIndex == index;
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Column(
                          children: [
                            ListTile(
                              leading: pokemon['image'] != null ? Image.network(pokemon['image']) : Icon(Icons.image_not_supported),
                              title: Text(pokemon['name']),
                              trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                              onTap: () => _toggleExpand(index, pokemon['name']),
                            ),
                            if (isExpanded)
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: _loadingDetails ? CircularProgressIndicator() : _expandedDetails != null ? Text(_formatDetails(_expandedDetails!)) : Text('Error al cargar'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ==================== PANTALLA DE VUELOS ====================
class FlightsScreen extends StatefulWidget {
  @override
  _FlightsScreenState createState() => _FlightsScreenState();
}

class _FlightsScreenState extends State<FlightsScreen> {
  static const String _apiKey = 'a5cd0dce6da5f4621325362b316605f3';
  
  List<dynamic> _flights = [];
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  
  int? _expandedIndex;
  bool _usingDemoData = false;

  // Datos de demostración
  final List<Map<String, dynamic>> _demoFlights = [
    {
      'flight': {'iata': 'AA100', 'number': '100'},
      'airline': {'name': 'American Airlines', 'iata': 'AA'},
      'flight_status': 'active',
      'departure': {'airport': 'John F Kennedy International', 'iata': 'JFK', 'scheduled': '2025-12-01T08:00:00+00:00', 'terminal': '8', 'gate': 'B22'},
      'arrival': {'airport': 'Los Angeles International', 'iata': 'LAX', 'scheduled': '2025-12-01T11:30:00+00:00', 'terminal': '4', 'gate': 'A15'},
    },
    {
      'flight': {'iata': 'UA456', 'number': '456'},
      'airline': {'name': 'United Airlines', 'iata': 'UA'},
      'flight_status': 'scheduled',
      'departure': {'airport': 'Chicago O Hare International', 'iata': 'ORD', 'scheduled': '2025-12-01T14:00:00+00:00', 'terminal': '1', 'gate': 'C12'},
      'arrival': {'airport': 'Miami International', 'iata': 'MIA', 'scheduled': '2025-12-01T18:30:00+00:00', 'terminal': 'N', 'gate': 'D8'},
    },
    {
      'flight': {'iata': 'DL789', 'number': '789'},
      'airline': {'name': 'Delta Air Lines', 'iata': 'DL'},
      'flight_status': 'landed',
      'departure': {'airport': 'Hartsfield Jackson Atlanta International', 'iata': 'ATL', 'scheduled': '2025-12-01T06:00:00+00:00', 'terminal': 'S', 'gate': 'A10'},
      'arrival': {'airport': 'Boston Logan International', 'iata': 'BOS', 'scheduled': '2025-12-01T09:15:00+00:00', 'terminal': 'A', 'gate': 'B5'},
    },
    {
      'flight': {'iata': 'SW321', 'number': '321'},
      'airline': {'name': 'Southwest Airlines', 'iata': 'SW'},
      'flight_status': 'delayed',
      'departure': {'airport': 'Denver International', 'iata': 'DEN', 'scheduled': '2025-12-01T10:00:00+00:00', 'terminal': 'B', 'gate': 'B45'},
      'arrival': {'airport': 'Phoenix Sky Harbor International', 'iata': 'PHX', 'scheduled': '2025-12-01T11:30:00+00:00', 'terminal': '4', 'gate': 'C3'},
    },
    {
      'flight': {'iata': 'IB001', 'number': '001'},
      'airline': {'name': 'Iberia', 'iata': 'IB'},
      'flight_status': 'active',
      'departure': {'airport': 'Madrid Barajas', 'iata': 'MAD', 'scheduled': '2025-12-01T10:30:00+00:00', 'terminal': '4', 'gate': 'K76'},
      'arrival': {'airport': 'Mariscal Sucre International', 'iata': 'UIO', 'scheduled': '2025-12-01T15:45:00+00:00', 'terminal': '1', 'gate': 'A2'},
    },
    {
      'flight': {'iata': 'AV123', 'number': '123'},
      'airline': {'name': 'Avianca', 'iata': 'AV'},
      'flight_status': 'scheduled',
      'departure': {'airport': 'El Dorado International', 'iata': 'BOG', 'scheduled': '2025-12-01T16:00:00+00:00', 'terminal': '1', 'gate': 'B12'},
      'arrival': {'airport': 'Mariscal Sucre International', 'iata': 'UIO', 'scheduled': '2025-12-01T17:30:00+00:00', 'terminal': '1', 'gate': 'A5'},
    },
    {
      'flight': {'iata': 'LA800', 'number': '800'},
      'airline': {'name': 'LATAM Airlines', 'iata': 'LA'},
      'flight_status': 'cancelled',
      'departure': {'airport': 'Mariscal Sucre International', 'iata': 'UIO', 'scheduled': '2025-12-01T08:00:00+00:00', 'terminal': '1', 'gate': 'A1'},
      'arrival': {'airport': 'Jorge Chavez International', 'iata': 'LIM', 'scheduled': '2025-12-01T10:00:00+00:00', 'terminal': '1', 'gate': 'C10'},
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchFlights();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFlights({String? flightNumber}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _usingDemoData = false;
    });

    try {
      String urlStr = 'http://api.aviationstack.com/v1/flights?access_key=$_apiKey&limit=50';
      if (flightNumber != null && flightNumber.isNotEmpty) {
        urlStr += '&flight_iata=$flightNumber';
      }
      
      final url = Uri.parse(urlStr);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          setState(() {
            _flights = data['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['error']?['message'] ?? 'Error al cargar vuelos';
            _isLoading = false;
          });
        }
      } else {
        // Si falla, mostrar opción de usar datos demo
        setState(() {
          _errorMessage = 'La API de AviationStack no funciona en navegadores web (solo HTTP).\n\nPuedes usar datos de demostracion o ejecutar la app en Android/iOS.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexion.\n\nLa API gratuita no soporta HTTPS (requerido en web).\n\nUsa datos de demostracion o ejecuta en Android/iOS.';
        _isLoading = false;
      });
    }
  }

  void _loadDemoData({String? searchTerm}) {
    setState(() {
      _usingDemoData = true;
      _errorMessage = null;
      if (searchTerm != null && searchTerm.isNotEmpty) {
        _flights = _demoFlights.where((f) => 
          f['flight']['iata'].toString().toUpperCase().contains(searchTerm.toUpperCase()) ||
          f['airline']['name'].toString().toUpperCase().contains(searchTerm.toUpperCase())
        ).toList();
      } else {
        _flights = List.from(_demoFlights);
      }
    });
  }

  void _searchFlight() {
    String flight = _searchController.text.trim().toUpperCase();
    if (_usingDemoData) {
      _loadDemoData(searchTerm: flight);
    } else {
      _fetchFlights(flightNumber: flight.isEmpty ? null : flight);
    }
  }

  String _formatFlightDetails(Map<String, dynamic> flight) {
    // Datos del vuelo
    String flightNumber = flight['flight']?['iata'] ?? 'N/A';
    String airline = flight['airline']?['name'] ?? 'N/A';
    String status = flight['flight_status'] ?? 'N/A';
    
    // Salida
    String depAirport = flight['departure']?['airport'] ?? 'N/A';
    String depIata = flight['departure']?['iata'] ?? '';
    String depScheduled = flight['departure']?['scheduled'] ?? 'N/A';
    String depTerminal = flight['departure']?['terminal'] ?? 'N/A';
    String depGate = flight['departure']?['gate'] ?? 'N/A';
    
    // Llegada
    String arrAirport = flight['arrival']?['airport'] ?? 'N/A';
    String arrIata = flight['arrival']?['iata'] ?? '';
    String arrScheduled = flight['arrival']?['scheduled'] ?? 'N/A';
    String arrTerminal = flight['arrival']?['terminal'] ?? 'N/A';
    String arrGate = flight['arrival']?['gate'] ?? 'N/A';

    return '''
Vuelo: $flightNumber
Aerolinea: $airline
Estado: $status

SALIDA:
  Aeropuerto: $depAirport ($depIata)
  Hora programada: $depScheduled
  Terminal: $depTerminal
  Puerta: $depGate

LLEGADA:
  Aeropuerto: $arrAirport ($arrIata)
  Hora programada: $arrScheduled
  Terminal: $arrTerminal
  Puerta: $arrGate
''';
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
      case 'en-route':
        return Colors.green;
      case 'landed':
        return Colors.blue;
      case 'scheduled':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'delayed':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vuelos en Tiempo Real'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar vuelo (ej: AA100)',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _searchFlight(),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchFlight,
                  child: Text('Buscar'),
                ),
              ],
            ),
          ),
          
          // Boton para recargar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _fetchFlights(),
                    icon: Icon(Icons.refresh),
                    label: Text('API Real'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _loadDemoData(),
                    icon: Icon(Icons.flight_takeoff),
                    label: Text('Datos Demo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (_usingDemoData)
            Container(
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.green[700]),
                  SizedBox(width: 8),
                  Text('Usando datos de demostracion', style: TextStyle(color: Colors.green[700])),
                ],
              ),
            ),
          
          SizedBox(height: 8),
          
          // Lista de vuelos
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_off, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(_errorMessage!, textAlign: TextAlign.center),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _loadDemoData(),
                              icon: Icon(Icons.flight_takeoff),
                              label: Text('Usar Datos de Demostracion'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                            SizedBox(height: 8),
                            TextButton(
                              onPressed: () => _fetchFlights(),
                              child: Text('Reintentar API Real'),
                            ),
                          ],
                        ),
                      )
                    : _flights.isEmpty
                        ? Center(child: Text('No hay vuelos disponibles'))
                        : ListView.builder(
                            itemCount: _flights.length,
                            itemBuilder: (context, index) {
                              final flight = _flights[index];
                              bool isExpanded = _expandedIndex == index;
                              
                              String flightNum = flight['flight']?['iata'] ?? 'N/A';
                              String airline = flight['airline']?['name'] ?? 'Desconocida';
                              String status = flight['flight_status'] ?? 'N/A';
                              String depIata = flight['departure']?['iata'] ?? '???';
                              String arrIata = flight['arrival']?['iata'] ?? '???';
                              
                              return Card(
                                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: Icon(Icons.flight, color: Colors.indigo, size: 32),
                                      title: Row(
                                        children: [
                                          Text(flightNum, style: TextStyle(fontWeight: FontWeight.bold)),
                                          SizedBox(width: 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(status),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(status.toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 10)),
                                          ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(airline),
                                          Text('$depIata → $arrIata', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                                      onTap: () {
                                        setState(() {
                                          _expandedIndex = isExpanded ? null : index;
                                        });
                                      },
                                    ),
                                    if (isExpanded)
                                      Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(_formatFlightDetails(flight)),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
