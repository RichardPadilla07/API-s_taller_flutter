# Laboratorio 
# Consumo de API's con Flutter

El presente repositorio contiene una aplicación Flutter que consume dos APIs: **PokeAPI** y **AviationStack** (API de Vuelos).

---

## 📋 Descripción de las Actividades

**Actividad 1:** Generar una aplicación que permita buscar y mostrar Pokémons con todas sus características, incluida su foto.

**Actividad 2:** Implementar una aplicación que utilice cualquiera de los API's mostrados en: https://github.com/public-apis/public-apis

---

# ✈️ API de Vuelos - AviationStack

## 📖 Descripción

Para la **Actividad 2**, se implementó el consumo de la API de **AviationStack**, que proporciona información en tiempo real sobre vuelos de aerolíneas de todo el mundo.

**API utilizada:** [AviationStack](https://aviationstack.com/)

**Endpoint base:** `http://api.aviationstack.com/v1/flights`

---

## 🔧 Proceso de Implementación

### 1. Obtención de la API Key

Primero, se registró una cuenta en [AviationStack](https://aviationstack.com/) para obtener una clave de acceso (API Key) gratuita.

<!-- CAPTURA: Página de registro de AviationStack -->

![Captura de pantalla 2025-12-01 121456](https://github.com/user-attachments/assets/fcf2a6b6-7bc6-406e-99ef-bfeebb361d6b)


### 2. Configuración del Proyecto Flutter

Se agregó la dependencia `http` en el archivo `pubspec.yaml` para realizar peticiones HTTP:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
```

<!-- CAPTURA: Archivo pubspec.yaml con la dependencia -->

![Captura de pantalla 2025-12-01 121722](https://github.com/user-attachments/assets/d3a5b7ce-f299-4f48-adcc-d41d42a57b91)


### 3. Importación de Librerías

En el archivo `main.dart` se importaron las librerías necesarias:

```dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
```

<!-- CAPTURA: Imports en el código -->

![Captura de pantalla 2025-12-01 121809](https://github.com/user-attachments/assets/b7c31fbe-31ee-4f9a-8a70-0cf4b7e73e2a)


### 4. Definición de la API Key

Se definió la constante con la clave de acceso:

```dart
static const String _apiKey = 'TU_API_KEY_AQUI';
```

<!-- CAPTURA: Definición de la API Key en el código -->



### 5. Función para Consumir la API

Se creó el método `_fetchFlights()` que realiza la petición GET a la API:

```dart
Future<void> _fetchFlights({String? flightNumber}) async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
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
      }
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Error de conexión';
      _isLoading = false;
    });
  }
}
```

<!-- CAPTURA: Función fetchFlights completa -->



### 6. Parseo de la Respuesta JSON

La API devuelve un JSON con la siguiente estructura y se parseó de la siguiente manera:

```dart
String _formatFlightDetails(Map<String, dynamic> flight) {
  String flightNumber = flight['flight']?['iata'] ?? 'N/A';
  String airline = flight['airline']?['name'] ?? 'N/A';
  String status = flight['flight_status'] ?? 'N/A';
  
  // Datos de salida
  String depAirport = flight['departure']?['airport'] ?? 'N/A';
  String depIata = flight['departure']?['iata'] ?? '';
  String depScheduled = flight['departure']?['scheduled'] ?? 'N/A';
  
  // Datos de llegada
  String arrAirport = flight['arrival']?['airport'] ?? 'N/A';
  String arrIata = flight['arrival']?['iata'] ?? '';
  String arrScheduled = flight['arrival']?['scheduled'] ?? 'N/A';
  
  return '''
  Vuelo: $flightNumber
  Aerolínea: $airline
  Estado: $status
  Salida: $depAirport ($depIata) - $depScheduled
  Llegada: $arrAirport ($arrIata) - $arrScheduled
  ''';
}
```

<!-- CAPTURA: Función de formateo de detalles -->



### 7. Construcción de la Interfaz de Usuario

Se creó la pantalla `FlightsScreen` con:
- Barra de búsqueda para filtrar vuelos por código
- Lista de vuelos con tarjetas expandibles
- Indicador de estado del vuelo con colores
- Botón para datos de demostración (cuando la API no está disponible)

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Vuelos en Tiempo Real'),
      backgroundColor: Colors.indigo,
    ),
    body: Column(
      children: [
        // Buscador
        Padding(
          padding: EdgeInsets.all(8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar vuelo (ej: AA100)',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        // Lista de vuelos
        Expanded(
          child: ListView.builder(
            itemCount: _flights.length,
            itemBuilder: (context, index) {
              // Construir tarjeta de vuelo
            },
          ),
        ),
      ],
    ),
  );
}
```

<!-- CAPTURA: Código de la interfaz de usuario -->



### 8. Sistema de Estados de Vuelo

Se implementó un método para colorear el estado de cada vuelo:

```dart
Color _getStatusColor(String? status) {
  switch (status?.toLowerCase()) {
    case 'active':
    case 'en-route':
      return Colors.green;    // En vuelo
    case 'landed':
      return Colors.blue;     // Aterrizó
    case 'scheduled':
      return Colors.orange;   // Programado
    case 'cancelled':
      return Colors.red;      // Cancelado
    case 'delayed':
      return Colors.amber;    // Retrasado
    default:
      return Colors.grey;
  }
}
```

<!-- CAPTURA: Método de colores de estado -->



### 9. Datos de Demostración

Debido a que la API gratuita de AviationStack solo soporta HTTP (no HTTPS), se implementó un sistema de datos de demostración para probar la funcionalidad en navegadores web:

```dart
final List<Map<String, dynamic>> _demoFlights = [
  {
    'flight': {'iata': 'AA100', 'number': '100'},
    'airline': {'name': 'American Airlines', 'iata': 'AA'},
    'flight_status': 'active',
    'departure': {
      'airport': 'John F Kennedy International',
      'iata': 'JFK',
      'scheduled': '2025-12-01T08:00:00+00:00',
    },
    'arrival': {
      'airport': 'Los Angeles International',
      'iata': 'LAX',
      'scheduled': '2025-12-01T11:30:00+00:00',
    },
  },
  // ... más vuelos de demostración
];
```

<!-- CAPTURA: Datos de demostración -->



---

## 📱 Capturas de la Aplicación en Ejecución

### Pantalla Principal de Vuelos

<!-- CAPTURA: Pantalla principal mostrando lista de vuelos -->



### Búsqueda de Vuelo

<!-- CAPTURA: Buscando un vuelo específico -->



### Detalles Expandidos de un Vuelo

<!-- CAPTURA: Vuelo expandido mostrando todos los detalles -->



### Estados de Vuelos (Colores)

<!-- CAPTURA: Mostrando diferentes estados con colores -->



### Modo Demostración

<!-- CAPTURA: Usando datos de demostración -->



---

## 🚀 Cómo Ejecutar el Proyecto

1. Clonar el repositorio:
```bash
git clone https://github.com/RichardPadilla07/API-s_taller_flutter.git
```

2. Instalar dependencias:
```bash
flutter pub get
```

3. Ejecutar la aplicación:
```bash
flutter run
```

**Nota:** Para usar la API real de AviationStack, se recomienda ejecutar en Android/iOS ya que la versión gratuita solo soporta HTTP.

---

## 📚 Estructura del Código

```
lib/
└── main.dart
    ├── MyApp (Widget principal)
    ├── HomeScreen (Navegación con pestañas)
    ├── PokemonScreen (Actividad 1 - PokeAPI)
    └── FlightsScreen (Actividad 2 - AviationStack)
```

---

## 👥 Integrantes

<!-- Agregar nombres de los integrantes del grupo -->

- Richard Padilla
- 

---

## 📝 Referencias

- [AviationStack API Documentation](https://aviationstack.com/documentation)
- [Flutter HTTP Package](https://pub.dev/packages/http)
- [Public APIs Repository](https://github.com/public-apis/public-apis)

