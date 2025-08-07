import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'login_page.dart';
import 'signup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCWeEVqYHNWJuYleFwpDHMtS4irS60Df2w",
        authDomain: "weather-app-1f3f8.firebaseapp.com",
        projectId: "weather-app-1f3f8",
        storageBucket: "weather-app-1f3f8.firebasestorage.app",
        messagingSenderId: "498335810556",
        appId: "1:498335810556:web:c39bde67d6a0dd97482879",
        measurementId: "G-M5ZMN2H9X2",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'SF Pro Display',
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.hasData ? const WeatherPage() : const LoginPage();
      },
    );
  }
}

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  // Note: Move API key to .env file or secure storage in production
  final String apiKey = 'bbc76d76cf351e4cd76e04e36e1b99eb';
  Map<String, dynamic>? weatherData;
  List<dynamic>? hourlyForecast;
  bool isLoading = false;
  String errorMessage = '';
  String currentTime = '';
  String currentDate = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      currentTime = DateFormat('HH:mm').format(DateTime.now());
      currentDate = DateFormat('EEEE, MMMM d').format(DateTime.now());
    });
    _timer = Timer(const Duration(seconds: 1), _updateTime);
  }

  Future<void> fetchWeather(String city) async {
    if (city.trim().isEmpty) {
      setState(() {
        errorMessage = 'Please enter a city name';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    _animationController.reset();

    final weatherUrl =
        'https://api.openweathermap.org/data/2.5/weather?q=${Uri.encodeComponent(city.trim())}&appid=$apiKey&units=metric';
    final forecastUrl =
        'https://api.openweathermap.org/data/2.5/forecast?q=${Uri.encodeComponent(city.trim())}&appid=$apiKey&units=metric';

    try {
      final weatherResponse = await http.get(Uri.parse(weatherUrl));
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      if (weatherResponse.statusCode == 200 &&
          forecastResponse.statusCode == 200) {
        setState(() {
          weatherData = jsonDecode(weatherResponse.body);
          hourlyForecast =
              jsonDecode(forecastResponse.body)['list'].take(5).toList();
        });
        _animationController.forward();
      } else if (weatherResponse.statusCode == 404) {
        setState(() {
          errorMessage = 'City not found! Please try again.';
        });
      } else {
        setState(() {
          errorMessage = 'Failed to fetch weather data. Status: ${weatherResponse.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error. Please check your connection.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Color _getGradientColor(String? condition) {
    if (condition == null) return const Color(0xFF0A0E21);

    switch (condition.toLowerCase()) {
      case 'clear':
        return const Color(0xFFFFD740);
      case 'clouds':
        return const Color(0xFF90A4AE);
      case 'rain':
      case 'drizzle':
        return const Color(0xFF40C4FF);
      case 'thunderstorm':
        return const Color(0xFF1C2526);
      case 'snow':
        return const Color(0xFFB0BEC5);
      case 'mist':
      case 'fog':
        return const Color(0xFFCFD8DC);
      default:
        return const Color(0xFF0A0E21);
    }
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny_rounded;
      case 'clouds':
        return Icons.cloud_rounded;
      case 'rain':
        return Icons.water_drop_rounded;
      case 'drizzle':
        return Icons.grain_rounded;
      case 'thunderstorm':
        return Icons.bolt_rounded;
      case 'snow':
        return Icons.ac_unit_rounded;
      case 'mist':
      case 'fog':
        return Icons.foggy;
      default:
        return Icons.cloud_queue_rounded;
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Transform.rotate(
        angle: -0.03,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00FF80).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FF80).withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            onSubmitted: (value) => fetchWeather(value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Search for a city...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              suffixIcon: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF80).withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.search_rounded,
                      color: Colors.white, size: 28),
                  onPressed: () => fetchWeather(_controller.text),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherInfo() {
    if (isLoading) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF40C4FF).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF40C4FF).withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 4,
              ),
              const SizedBox(height: 20),
              Text(
                'Fetching weather data...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFFFF2E63).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFF2E63).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFFF2E63),
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: const TextStyle(
                  color: Color(0xFFFF2E63),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (weatherData == null) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00FF80).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.search_rounded,
                color: Colors.white.withOpacity(0.7),
                size: 72,
              ),
              const SizedBox(height: 20),
              Text(
                'Search for a city to see weather',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    double temp = weatherData!['main']['temp'];
    double tempMax = weatherData!['main']['temp_max'];
    double tempMin = weatherData!['main']['temp_min'];
    String weatherCondition = weatherData!['weather'][0]['main'];
    String description = weatherData!['weather'][0]['description'];
    String cityName = weatherData!['name'];
    String country = weatherData!['sys']['country'];
    int humidity = weatherData!['main']['humidity'];
    double windSpeed = weatherData!['wind']['speed'];
    int pressure = weatherData!['main']['pressure'];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          children: [
            Transform.rotate(
              angle: -0.02,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: const Color(0xFF00FF80).withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF80).withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$cityName, $country',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Transform.rotate(
              angle: 0.02,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: const Color(0xFFFFD740).withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD740).withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      _getWeatherIcon(weatherCondition),
                      size: 100,
                      color: const Color(0xFFFFD740),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${temp.toStringAsFixed(0)}°C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description.replaceFirst(
                          description[0], description[0].toUpperCase()),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'H: ${tempMax.toStringAsFixed(0)}°  L: ${tempMin.toStringAsFixed(0)}°',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWeatherDetail(
                    'Humidity', '$humidity%', Icons.water_drop_rounded, -0.03),
                _buildWeatherDetail(
                    'Wind', '${windSpeed.toStringAsFixed(1)} m/s', Icons.air_rounded, 0.0),
                _buildWeatherDetail(
                    'Pressure', '$pressure hPa', Icons.compress_rounded, 0.03),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(
      String label, String value, IconData icon, double rotation) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE91E63).withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyForecast() {
    if (hourlyForecast == null || hourlyForecast!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Transform.rotate(
      angle: 0.02,
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE91E63).withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Hourly Forecast',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: hourlyForecast!.asMap().entries.map((entry) {
                  var forecast = entry.value;
                  String time = DateFormat('HH:mm').format(
                      DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000));
                  String temp =
                      '${forecast['main']['temp'].toStringAsFixed(0)}°';
                  String condition = forecast['weather'][0]['main'];

                  return Container(
                    margin: const EdgeInsets.only(right: 20),
                    child: _buildHourlyItem(time, temp, condition, entry.key),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyItem(String time, String temp, String condition, int index) {
    return Transform.rotate(
      angle: -0.02,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF00FF80).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FF80).withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              time,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Icon(
              _getWeatherIcon(condition),
              color: Colors.white,
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              temp,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Logged out successfully"),
        backgroundColor: const Color(0xFF00FF80),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        elevation: 10,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? currentCondition = weatherData?['weather']?[0]?['main'];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getGradientColor(currentCondition),
              _getGradientColor(currentCondition).withOpacity(0.7),
              const Color(0xFF0A0E21),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 100,
                left: 20,
                right: 20,
                child: Transform.rotate(
                  angle: -0.02,
                  child: Container(
                    height: 600,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Transform.rotate(
                          angle: 0.02,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFFE91E63).withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE91E63).withOpacity(0.2),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],4 
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentTime,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  currentDate,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                            border: Border.all(
                                color: const Color(0xFFFF2E63).withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF2E63).withOpacity(0.2),
                                blurRadius: 15,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: logout,
                            icon: const Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSearchBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildWeatherInfo(),
                          const SizedBox(height: 28),
                          if (hourlyForecast != null && hourlyForecast!.isNotEmpty)
                            _buildHourlyForecast(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}