import 'package:here_sdk/core.dart';
import 'package:techtruckers/features/common/models/get_weather_data_model.dart';

class CityItem {
  String city;
  GeoCoordinates location;
  GeoBox geoBox;

  CityItem(this.city, this.location, this.geoBox);

  // Override == operator to compare by city name and exact GeoCoordinates
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CityItem) return false;

    // Check if city name is same
    return city == other.city;
  }

  // From JSON constructor
  factory CityItem.fromJson(Map<String, dynamic> json) {
    return CityItem(
      json['city'] as String,
      GeoCoordinates(
        json['location']['latitude'] as double,
        json['location']['longitude'] as double,
      ),
      GeoBox(
        GeoCoordinates(
          json['geoBox']['southWest']['latitude'] as double,
          json['geoBox']['southWest']['longitude'] as double,
        ),
        GeoCoordinates(
          json['geoBox']['northEast']['latitude'] as double,
          json['geoBox']['northEast']['longitude'] as double,
        ),
      ),
    );
  }

  // To JSON method
  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'geoBox': {
        'southWest': {
          'latitude': geoBox.southWestCorner.latitude,
          'longitude': geoBox.southWestCorner.longitude,
        },
        'northEast': {
          'latitude': geoBox.northEastCorner.latitude,
          'longitude': geoBox.northEastCorner.longitude,
        },
      },
    };
  }
}

class WeatherItem {
  CityItem? cityItem;
  GetWeatherDataModel? weatherData;

  WeatherItem(this.cityItem, this.weatherData);
}