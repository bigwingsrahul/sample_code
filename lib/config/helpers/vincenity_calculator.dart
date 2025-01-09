import 'dart:math';

class VincentyDistance {
  // Constants for WGS-84 ellipsoid
  static const double a = 6378137.0; // semi-major axis in meters
  static const double f = 1 / 298.257223563; // flattening
  static const double b = (1 - f) * a; // semi-minor axis in meters
  static const double e2 = f * (2 - f); // square of eccentricity

  // Vincenty distance formula
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // If the two points are the same, return 0
    if (lat1 == lat2 && lon1 == lon2) {
      return 0.0; // No distance if the points are identical
    }

    // Convert degrees to radians
    lat1 = _degToRad(lat1);
    lon1 = _degToRad(lon1);
    lat2 = _degToRad(lat2);
    lon2 = _degToRad(lon2);

    // Difference in longitudes
    double L = lon2 - lon1;

    // Initial values for iteration
    double U1 = atan((1 - f) * tan(lat1));
    double U2 = atan((1 - f) * tan(lat2));

    double sinU1 = sin(U1);
    double cosU1 = cos(U1);
    double sinU2 = sin(U2);
    double cosU2 = cos(U2);

    double lambda = L; // initial guess for the longitude difference
    double sinLambda, cosLambda, sinSigma, cosSigma, sigma, sinAlpha, cos2Alpha, cos2SigmaM, C;

    int iterCount = 0;
    const int maxIter = 1000;
    double lambdaPrime;

    // Iterative calculation
    while (true) {
      sinLambda = sin(lambda);
      cosLambda = cos(lambda);

      sinSigma = sqrt(pow(cosU2 * sinLambda, 2) +
          pow(cosU1 * sinU2 - sinU1 * cosU2 * cosLambda, 2));
      cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
      sigma = atan2(sinSigma, cosSigma);

      sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
      cos2Alpha = double.tryParse((1 - pow(sinAlpha, 2)).toString()) ?? 0.0;
      cos2SigmaM = cosSigma - 2 * sinU1 * sinU2 / cos2Alpha;

      C = f / 16 * cos2Alpha * (4 + f * (4 - 3 * cos2Alpha));
      lambdaPrime = lambda;
      lambda = L + (1 - C) * f * sinAlpha *
          (sigma +
              C * sinSigma * (cos2SigmaM + C * cosSigma *
                  (-1 + 2 * pow(cos2SigmaM, 2))));

      // Convergence check
      iterCount++;
      if ((lambda - lambdaPrime).abs() < 1e-12 || iterCount > maxIter) {
        break;
      }
    }

    // Calculate the distance in meters
    double u2 = cos2Alpha * (pow(a, 2) - pow(b, 2)) / pow(b, 2);
    double A = 1 + u2 / 16384 * (4096 + u2 * (-768 + u2 * (320 - 175 * u2)));
    double B = u2 / 1024 * (256 + u2 * (-128 + u2 * (74 - 47 * u2)));
    double deltaSigma = u2 / 1024 *
        (256 + u2 * (-128 + u2 * (74 - 47 * u2))) *
        sinSigma *
        (cos2SigmaM + u2 * cosSigma * (-1 + 2 * pow(cos2SigmaM, 2)));

    double distanceInMeters = b * A * (sigma - deltaSigma);

    // Convert the distance from meters to miles
    double distanceInMiles = distanceInMeters / 1609.344;

    // Handle NaN
    if (distanceInMiles.isNaN) {
      return 0.0; // Return 0 if NaN
    }

    return distanceInMiles; // in miles
  }

  // Convert degrees to radians
  static double _degToRad(double degrees) {
    return degrees * pi / 180;
  }
}