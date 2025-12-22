@preconcurrency import Combine
@preconcurrency import CoreLocation

extension LocationManagerClient {
  /// The live implementation of the `LocationManagerClient`. This implementation creates a real
  /// `CLLocationManager` instance and directly interacts with the system's Core Location services.
  public static let live: Self = {
    let implementation: LiveImplementation

    if Thread.isMainThread {
      implementation = MainActor.assumeIsolated {
        LiveImplementation()
      }
    } else {
      implementation = DispatchQueue.main.sync {
        MainActor.assumeIsolated {
          LiveImplementation()
        }
      }
    }

    return Self(
      accuracyAuthorization: {
        await implementation.accuracyAuthorization()
      },
      authorizationStatus: {
        await implementation.authorizationStatus()
      },
      delegate: {
        await implementation.delegate()
      },
      dismissHeadingCalibrationDisplay: {
        await implementation.dismissHeadingCalibrationDisplay()
      },
      heading: {
        await implementation.heading()
      },
      headingAvailable: {
        CLLocationManager.headingAvailable()
      },
      isRangingAvailable: {
        CLLocationManager.isRangingAvailable()
      },
      location: {
        await implementation.location()
      },
      locationServicesEnabled: CLLocationManager.locationServicesEnabled,
      maximumRegionMonitoringDistance: {
        await implementation.maximumRegionMonitoringDistance()
      },
      monitoredRegions: {
        await implementation.monitoredRegions()
      },
      requestAlwaysAuthorization: {
        await implementation.requestAlwaysAuthorization()
      },
      requestLocation: {
        await implementation.requestLocation()
      },
      requestWhenInUseAuthorization: {
        await implementation.requestWhenInUseAuthorization()
      },
      requestTemporaryFullAccuracyAuthorization: { purposeKey in
        try await implementation.requestTemporaryFullAccuracyAuthorization(purposeKey: purposeKey)
      },
      set: { properties in
        await implementation.set(properties: properties)
      },
      significantLocationChangeMonitoringAvailable: {
        CLLocationManager.significantLocationChangeMonitoringAvailable()
      },
      startMonitoringForRegion: { region in
        await implementation.startMonitoringForRegion(region: region)
      },
      startMonitoringSignificantLocationChanges: {
        await implementation.startMonitoringSignificantLocationChanges()
      },
      startMonitoringVisits: {
        await implementation.startMonitoringVisits()
      },
      startUpdatingHeading: {
        await implementation.startUpdatingHeading()
      },
      startUpdatingLocation: {
        await implementation.startUpdatingLocation()
      },
      stopMonitoringForRegion: { region in
        await implementation.stopMonitoringForRegion(region: region)
      },
      stopMonitoringSignificantLocationChanges: {
        await implementation.stopMonitoringSignificantLocationChanges()
      },
      stopMonitoringVisits: {
        await implementation.stopMonitoringVisits()
      },
      stopUpdatingHeading: {
        await implementation.stopUpdatingHeading()
      },
      stopUpdatingLocation: {
        await implementation.stopUpdatingLocation()
      }
    )
  }()
}

/// The live implementation that owns the `CLLocationManager` and handles all interactions with it.
/// This class is MainActor-isolated to ensure all Core Location operations happen on the main thread.
@MainActor
private final class LiveImplementation {
  private let manager: CLLocationManager
  private let delegateSubject: PassthroughSubject<LocationManagerClient.Action, Never>
  private let locationDelegate: LocationManagerDelegate

  init() {
    self.manager = CLLocationManager()
    self.delegateSubject = PassthroughSubject<LocationManagerClient.Action, Never>()
    self.locationDelegate = LocationManagerDelegate(self.delegateSubject)
    self.manager.delegate = self.locationDelegate
  }

  func accuracyAuthorization() -> AccuracyAuthorization? {
    AccuracyAuthorization(manager.accuracyAuthorization)
  }

  func authorizationStatus() -> CLAuthorizationStatus {
    manager.authorizationStatus
  }

  func delegate() -> AsyncPublisher<AnyPublisher<LocationManagerClient.Action, Never>> {
    delegateSubject
      .share()
      .eraseToAnyPublisher()
      .values
  }

  func dismissHeadingCalibrationDisplay() {
    #if os(iOS) || os(macOS) || os(watchOS) || targetEnvironment(macCatalyst)
      manager.dismissHeadingCalibrationDisplay()
    #endif
  }

  func heading() -> Heading? {
    #if os(iOS) || os(watchOS) || targetEnvironment(macCatalyst)
      return manager.heading.map(Heading.init(rawValue:))
    #else
      return nil
    #endif
  }

  func location() -> Location? {
    manager.location.map(Location.init(rawValue:))
  }

  func maximumRegionMonitoringDistance() -> CLLocationDistance {
    #if os(iOS) || os(macOS) || targetEnvironment(macCatalyst)
      return manager.maximumRegionMonitoringDistance
    #else
      return CLLocationDistanceMax
    #endif
  }

  func monitoredRegions() -> Set<Region> {
    #if os(iOS) || os(macOS) || targetEnvironment(macCatalyst)
      return Set(manager.monitoredRegions.map(Region.init(rawValue:)))
    #else
      return []
    #endif
  }

  func requestAlwaysAuthorization() {
    #if os(iOS) || os(macOS) || os(watchOS) || targetEnvironment(macCatalyst)
      manager.requestAlwaysAuthorization()
    #endif
  }

  func requestLocation() {
    manager.requestLocation()
  }

  func requestWhenInUseAuthorization() {
    #if os(iOS) || os(macOS) || os(watchOS) || targetEnvironment(macCatalyst)
      manager.requestWhenInUseAuthorization()
    #endif
  }

  func requestTemporaryFullAccuracyAuthorization(purposeKey: String) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      manager.requestTemporaryFullAccuracyAuthorization(
        withPurposeKey: purposeKey
      ) { error in
        if let error = error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume(returning: ())
        }
      }
    }
  }

  func set(properties: LocationManagerClient.Properties) {
    #if os(iOS) || os(watchOS) || targetEnvironment(macCatalyst)
      if let activityType = properties.activityType {
        manager.activityType = activityType
      }
      if let allowsBackgroundLocationUpdates = properties.allowsBackgroundLocationUpdates {
        manager.allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates
      }
    #endif
    #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
      if let desiredAccuracy = properties.desiredAccuracy {
        manager.desiredAccuracy = desiredAccuracy
      }
      if let distanceFilter = properties.distanceFilter {
        manager.distanceFilter = distanceFilter
      }
    #endif
    #if os(iOS) || os(watchOS) || targetEnvironment(macCatalyst)
      if let headingFilter = properties.headingFilter {
        manager.headingFilter = headingFilter
      }
      if let headingOrientation = properties.headingOrientation {
        manager.headingOrientation = headingOrientation
      }
    #endif
    #if os(iOS) || targetEnvironment(macCatalyst)
      if let pausesLocationUpdatesAutomatically = properties
        .pausesLocationUpdatesAutomatically
      {
        manager.pausesLocationUpdatesAutomatically = pausesLocationUpdatesAutomatically
      }
      if let showsBackgroundLocationIndicator = properties.showsBackgroundLocationIndicator {
        manager.showsBackgroundLocationIndicator = showsBackgroundLocationIndicator
      }
    #endif
  }

  func startMonitoringForRegion(region: Region) {
    #if os(iOS) || os(macOS) || targetEnvironment(macCatalyst)
      manager.startMonitoring(for: region.rawValue!)
    #endif
  }

  func startMonitoringSignificantLocationChanges() {
    #if os(iOS) || targetEnvironment(macCatalyst)
      manager.startMonitoringSignificantLocationChanges()
    #endif
  }

  func startMonitoringVisits() {
    #if os(iOS) || targetEnvironment(macCatalyst)
      manager.startMonitoringVisits()
    #endif
  }

  func startUpdatingHeading() {
    #if os(iOS) || os(macOS) || os(watchOS) || targetEnvironment(macCatalyst)
      manager.startUpdatingHeading()
    #endif
  }

  func startUpdatingLocation() {
    #if os(iOS) || os(macOS) || os(watchOS) || targetEnvironment(macCatalyst)
      manager.startUpdatingLocation()
    #endif
  }

  func stopMonitoringForRegion(region: Region) {
    #if os(iOS) || os(macOS) || targetEnvironment(macCatalyst)
      manager.stopMonitoring(for: region.rawValue!)
    #endif
  }

  func stopMonitoringSignificantLocationChanges() {
    #if os(iOS) || targetEnvironment(macCatalyst)
      manager.stopMonitoringSignificantLocationChanges()
    #endif
  }

  func stopMonitoringVisits() {
    #if os(iOS) || targetEnvironment(macCatalyst)
      manager.stopMonitoringVisits()
    #endif
  }

  func stopUpdatingHeading() {
    #if os(iOS) || os(watchOS) || targetEnvironment(macCatalyst)
      manager.stopUpdatingHeading()
    #endif
  }

  func stopUpdatingLocation() {
    #if os(iOS) || os(macOS) || os(watchOS) || targetEnvironment(macCatalyst)
      manager.stopUpdatingLocation()
    #endif
  }
}

/// The delegate class that receives `CLLocationManager` callbacks and forwards them to the subject.
/// Note: This cannot be @MainActor because CLLocationManagerDelegate protocol is not actor-isolated.
/// However, CLLocationManager ensures delegate methods are called on the thread where it was created (main thread).
private final class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
  let subject: PassthroughSubject<LocationManagerClient.Action, Never>

  init(_ subject: PassthroughSubject<LocationManagerClient.Action, Never>) {
    self.subject = subject
  }

  func locationManager(
    _ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus
  ) {
    self.subject.send(.didChangeAuthorization(status))
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    self.subject.send(.didFailWithError(LocationManagerClient.Error(error)))
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    self.subject.send(.didUpdateLocations(locations.map(Location.init(rawValue:))))
  }

  #if os(macOS)
    func locationManager(
      _ manager: CLLocationManager, didUpdateTo newLocation: CLLocation,
      from oldLocation: CLLocation
    ) {
      self.subject.send(
        .didUpdateTo(
          newLocation: Location(rawValue: newLocation),
          oldLocation: Location(rawValue: oldLocation)
        )
      )
    }
  #endif

  #if os(iOS) || os(macOS) || targetEnvironment(macCatalyst)
    func locationManager(
      _ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?
    ) {
      self.subject.send(
        .didFinishDeferredUpdatesWithError(error.map(LocationManagerClient.Error.init))
      )
    }
  #endif

  #if os(iOS) || targetEnvironment(macCatalyst)
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
      self.subject.send(.didPauseLocationUpdates)
    }
  #endif

  #if os(iOS) || targetEnvironment(macCatalyst)
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
      self.subject.send(.didResumeLocationUpdates)
    }
  #endif

  #if os(iOS) || os(watchOS) || targetEnvironment(macCatalyst)
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
      self.subject.send(.didUpdateHeading(newHeading: Heading(rawValue: newHeading)))
    }
  #endif

  #if os(iOS) || os(macOS) || targetEnvironment(macCatalyst)
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
      self.subject.send(.didEnterRegion(Region(rawValue: region)))
    }
  #endif

  #if os(iOS) || os(macOS) || targetEnvironment(macCatalyst)
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
      self.subject.send(.didExitRegion(Region(rawValue: region)))
    }
  #endif

  #if os(iOS) || os(macOS) || targetEnvironment(macCatalyst)
    func locationManager(
      _ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion
    ) {
      self.subject.send(.didDetermineState(state, region: Region(rawValue: region)))
    }
  #endif

  #if os(iOS) || os(macOS) || targetEnvironment(macCatalyst)
    func locationManager(
      _ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error
    ) {
      self.subject.send(
        .monitoringDidFail(
          region: region.map(Region.init(rawValue:)), error: LocationManagerClient.Error(error)))
    }
  #endif

  #if os(iOS) || os(macOS) || targetEnvironment(macCatalyst)
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
      self.subject.send(.didStartMonitoring(region: Region(rawValue: region)))
    }
  #endif

  #if os(iOS) || targetEnvironment(macCatalyst)
    func locationManager(
      _ manager: CLLocationManager, didRange beacons: [CLBeacon],
      satisfying beaconConstraint: CLBeaconIdentityConstraint
    ) {
      self.subject.send(
        .didRangeBeacons(
          beacons.map(Beacon.init(rawValue:)), satisfyingConstraint: beaconConstraint
        )
      )
    }
  #endif

  #if os(iOS) || targetEnvironment(macCatalyst)
    func locationManager(
      _ manager: CLLocationManager, didFailRangingFor beaconConstraint: CLBeaconIdentityConstraint,
      error: Error
    ) {
      self.subject.send(
        .didFailRanging(beaconConstraint: beaconConstraint, error: LocationManagerClient.Error(error))
      )
    }
  #endif

  #if os(iOS) || targetEnvironment(macCatalyst)
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
      self.subject.send(.didVisit(Visit(visit: visit)))
    }
  #endif
}
