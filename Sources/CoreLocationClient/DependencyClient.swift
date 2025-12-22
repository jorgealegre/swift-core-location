import CoreLocation
import Dependencies

extension LocationManagerClient: DependencyKey {
  /// The live value for the location manager dependency.
  ///
  /// This is automatically provided when running on device or simulator.
  public static let liveValue: Self = .live

  /// The test value for the location manager dependency.
  ///
  /// This value fails immediately when any endpoint is accessed, forcing you to explicitly
  /// override the endpoints you need for testing.
  public static let testValue: Self = .failing
}

extension DependencyValues {
  /// A location manager client that wraps `CLLocationManager` for dependency injection.
  ///
  /// To access this dependency in your code:
  ///
  /// ```swift
  /// @Dependency(\.locationManager) var locationManager
  /// ```
  ///
  /// To override this dependency in tests or previews:
  ///
  /// ```swift
  /// withDependencies {
  ///   $0.locationManager.authorizationStatus = { .authorizedWhenInUse }
  ///   $0.locationManager.requestLocation = { }
  /// } operation: {
  ///   // Your test code here
  /// }
  /// ```
  public var locationManager: LocationManagerClient {
    get { self[LocationManagerClient.self] }
    set { self[LocationManagerClient.self] = newValue }
  }
}
