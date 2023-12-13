import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:weather_app/components/weather_item.dart';
import 'package:weather_app/constants.dart';
import 'package:weather_app/ui/detail_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _cityController = TextEditingController();
  final Constants _constants = Constants();

  static String API_KEY = '271dcb82349b4dc0b7f161606231212'; //Your API Here
  List<WeatherInfo> favoriteWeatherInfo = [];//List using weatherInfo class

  String location = 'London'; //Default location
  String weatherIcon = 'sunny.webp';//Default Icon

  int temperature = 0;
  int windSpeed = 0;
  int humidity = 0;
  int cloud = 0;
  String currentDate = '';

  List hourlyWeatherForecast = [];
  List dailyWeatherForecast = [];

  String currentWeatherStatus = '';

  //API Call
  String searchWeatherAPI = "https://api.weatherapi.com/v1/forecast.json?key=" +
      API_KEY +
      "&days=7&q=";//query link

  void fetchWeatherData(String searchText) async {
    try {
      var searchResult =
      await http.get(Uri.parse(searchWeatherAPI + searchText));

      final weatherData = Map<String, dynamic>.from(
          json.decode(searchResult.body) ?? 'No data');

      var locationData = weatherData["location"];

      var currentWeather = weatherData["current"];

      setState(() {
        location = getShortLocationName(locationData["name"]);

        var parsedDate =
        DateTime.parse(locationData["localtime"].substring(0, 10));
        var newDate = DateFormat('MMMMEEEEd').format(parsedDate);
        currentDate = newDate;

        //updateWeather
        currentWeatherStatus = currentWeather["condition"]["text"];
        weatherIcon =
            currentWeatherStatus.replaceAll(' ', '').toLowerCase() + ".webp";
        temperature = currentWeather["temp_c"].toInt();
        windSpeed = currentWeather["wind_kph"].toInt();
        humidity = currentWeather["humidity"].toInt();
        cloud = currentWeather["cloud"].toInt();

        //Forecast data
        dailyWeatherForecast = weatherData["forecast"]["forecastday"];
        hourlyWeatherForecast = dailyWeatherForecast[0]["hour"];
        print(dailyWeatherForecast);
      });
    } catch (e) {
      //debugPrint(e);
    }
  }

  //function to return the first two names of the string location
  static String getShortLocationName(String s) {
    List<String> wordList = s.split(" ");

    if (wordList.isNotEmpty) {
      if (wordList.length > 1) {
        return wordList[0] + " " + wordList[1];
      } else {
        return wordList[0];
      }
    } else {
      return " ";
    }
  }
  void addToFavorites(String location) {
    // Check if the location is not already in favorites
    if (!favoriteWeatherInfo.any((info) => info.location == location)) {
      fetchFavoriteWeatherData(location); // Fetch weather data for the new location
    }
  }

  void removeFromFavorites(String location) {
    // Remove the location from favorites
    favoriteWeatherInfo.removeWhere((info) => info.location == location);
    // Perform any other necessary operations, such as updating UI, etc.
  }

  void _showFavoritesModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
              _constants.primaryColor, _constants.secondaryColor
            ]), // Set the background color as needed
          ),
          height: 300,
          child: Column(
            children: [
              AppBar(
                shadowColor: Colors.transparent,
                title: const Text(
                  'Favorite Locations',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                backgroundColor: _constants.primaryColor,
                iconTheme: IconThemeData(color: Colors.white),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: favoriteWeatherInfo.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(favoriteWeatherInfo[index].location),
                          Row(
                            children: [
                              Text('${favoriteWeatherInfo[index].temperature}°C'),
                              Image.asset(
                                'assets/${favoriteWeatherInfo[index].weatherIcon}',
                                width: 20,
                                height: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          removeFromFavorites(favoriteWeatherInfo[index].location);
                          Navigator.pop(context);
                        },
                      ),
                      onTap: () {
                        // Do something when a favorite location is tapped
                        // For example, navigate to a detail page, etc.
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }


// Rest of the code...


  Future<void> fetchFavoriteWeatherData(String location) async {
    try {
      var searchResult = await http.get(Uri.parse(searchWeatherAPI + location));

      final weatherData = Map<String, dynamic>.from(json.decode(searchResult.body) ?? {});

      var currentWeather = weatherData["current"];

      var temperature = currentWeather["temp_c"].toInt();
      var currentWeatherStatus = currentWeather["condition"]["text"];
      var weatherIcon = currentWeatherStatus.replaceAll(' ', '').toLowerCase() + ".webp";

      setState(() {
        favoriteWeatherInfo.add(
          WeatherInfo(
            location: location,
            temperature: temperature,
            weatherIcon: weatherIcon,
          ),
        );
      });
    } catch (e) {
      // Handle error
    }
  }




  @override
  void initState() {
    fetchWeatherData(location);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          width: size.width,
          height: size.height+85,
          padding: const EdgeInsets.only(top: 40, left: 10, right: 10),
          color: _constants.primaryColor.withOpacity(.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 90,
                padding: const EdgeInsets.only(top: 10,bottom: 10,left: 10,right: 10),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (searchText) {
                        fetchWeatherData(searchText);
                      },
                      controller: _cityController,
                      autofocus: true,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.search,
                          color: _constants.primaryColor,
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () => _cityController.clear(),
                          child: Icon(
                            Icons.close,
                            color: _constants.primaryColor,
                          ),
                        ),
                        hintText: 'Search city e.g. London',
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _constants.primaryColor,
                            width: 2.0, // Modify the border width as needed
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey, // Set the color for the border when it's not focused
                            width: 1.0, // Modify the border width as needed
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                height: size.height * .7,
                decoration: BoxDecoration(
                  gradient: _constants.linearGradientBlue,
                  boxShadow: [
                    BoxShadow(
                      color: _constants.primaryColor.withOpacity(.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  //crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap:(){
                            _showFavoritesModal();
                          },
                          child: Image.asset(
                            "assets/menu.webp",
                            width: 40,
                            height: 40,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/pin.webp",
                              width: 20,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              location,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          // Heart icon
                          icon: Icon(
                            CupertinoIcons.heart,
                            size: 40,
                            color: favoriteWeatherInfo.any((info) => info.location == location) ? Colors.red : Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              if (!favoriteWeatherInfo.any((info) => info.location == location)) {
                                addToFavorites(location);
                              } else {
                                removeFromFavorites(location);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 160,
                      child: Image.asset("assets/" + weatherIcon),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            temperature.toString(),
                            style: TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                              foreground: Paint()..shader = _constants.shader,
                            ),
                          ),
                        ),
                        Text(
                          'o',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()..shader = _constants.shader,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      currentWeatherStatus,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 20.0,
                      ),
                    ),
                    Text(
                      currentDate,
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Divider(
                        color: Colors.white70,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          WeatherItem(
                            value: windSpeed.toInt(),
                            unit: 'km/h',
                            imageUrl: 'assets/windspeed.webp',
                          ),
                          WeatherItem(
                            value: humidity.toInt(),
                            unit: '%',
                            imageUrl: 'assets/humidity.webp',
                          ),
                          WeatherItem(
                            value: cloud.toInt(),
                            unit: '%',
                            imageUrl: 'assets/cloud.webp',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 10),
                height: size.height * .21,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Today',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_)=> DetailPage(dailyForecastWeather: dailyWeatherForecast,))), //this will open forecast screen
                          child: Text(
                            'Forecasts',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: _constants.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        itemCount: hourlyWeatherForecast.length,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (BuildContext context, int index) {
                          String currentTime =
                          DateFormat('HH:mm:ss').format(DateTime.now());
                          String currentHour = currentTime.substring(0, 2);

                          String forecastTime = hourlyWeatherForecast[index]
                          ["time"]
                              .substring(11, 16);
                          String forecastHour = hourlyWeatherForecast[index]
                          ["time"]
                              .substring(11, 13);

                          String forecastWeatherName =
                          hourlyWeatherForecast[index]["condition"]["text"];
                          String forecastWeatherIcon = forecastWeatherName
                              .replaceAll(' ', '')
                              .toLowerCase() +
                              ".webp";

                          String forecastTemperature =
                          hourlyWeatherForecast[index]["temp_c"]
                              .round()
                              .toString();
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            margin: const EdgeInsets.only(right: 20),
                            width: 65,
                            decoration: BoxDecoration(
                                color: currentHour == forecastHour
                                    ? Colors.white
                                    : _constants.primaryColor,
                                borderRadius:
                                const BorderRadius.all(Radius.circular(50)),
                                boxShadow: [
                                  BoxShadow(
                                    offset: const Offset(0, 1),
                                    blurRadius: 5,
                                    color:
                                    _constants.primaryColor.withOpacity(.2),
                                  ),
                                ]),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  forecastTime,
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: _constants.greyColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Image.asset(
                                  'assets/' + forecastWeatherIcon,
                                  width: 20,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      forecastTemperature,
                                      style: TextStyle(
                                        color: _constants.greyColor,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'o',
                                      style: TextStyle(
                                        color: _constants.greyColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 17,
                                        fontFeatures: const [
                                          FontFeature.enable('sups'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
    );
  }
}
//Class for favourate locations
class WeatherInfo {
  final String location;
  final int temperature;
  final String weatherIcon;

  WeatherInfo({
    required this.location,
    required this.temperature,
    required this.weatherIcon,
  });
}
