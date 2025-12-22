@preconcurrency import Combine
@preconcurrency import CoreLocation

/// A class that retains the CLLocationManager and its delegate to ensure they stay alive.
/// Created on main thread but can be accessed from any thread (CLLocationManager is thread-safe).
private final class LocationManagerHolder: @unchecked Sendable {
  let manager: CLLocationManager
  let delegateSubject: PassthroughSubject<LocationManagerClient.Action, Never>
  let locationDelegate: LocationManagerDelegate

  init() {
    if Thread.isMainThread {
      self.manager = CLLocationManager()
      self.delegateSubject = PassthroughSubject<LocationManagerClient.Action, Never>()
      self.locationDelegate = LocationManagerDelegate(delegateSubject)
      self.manager.delegate = locationDelegate
    } else {
      let result = DispatchQueue.main.sync {
        let m = CLLocationManager()
        let subject = PassthroughSubject<LocationManagerClient.Action, Never>()
        let delegate = LocationManagerDelegate(subject)
        m.delegate = delegate
        return (m, subject, delegate)
      }
      self.manager = result.0
      self.delegateSubject = result.1
      self.locationDelegate = result.2
    }
  }

  var delegateStream: AsyncPublisher<AnyPublisher<LocationManagerClient.Action, Never>> {
    delegateSubject
      .share()
      .eraseToAnyPublisher()
      .values
  }
}

extension LocationManagerClient {
  /// The live implementation of the `LocationManagerClient`. This implementation creates a real
  /// `CLLocationManager` instance and directly interacts with the system's Core Location services.
  public static let live: Self = {
    // Create holder on main thread - this retains the manager and delegate
    let holder: LocationManagerHolder = {
      if Thread.isMainThread {
        return LocationManagerHolder()
      } else {
        return DispatchQueue.main.sync {
          LocationManagerHolder()
        }
      }
    }()

    return Self(
      accuracyAuthorization: {
        #if os(iOS) || os(macOS) || os(watchOS) || targetEnvironment(macCatalyst)
          AccuracyAuthorization(holder.manager.accuracyAuthorization)
        #else
          nil
        #endif
      },
      authorizationStatus: {
        holder.manager.authorizationStatus
      },
      delegate: {
        holder.delegateStream
      },
      dismissHeadingCalibrationDisplay: {
        #if os(iOS) || os(macOS) || os(watchOS) || targetEnvironment(macCatalyst)
          holder.manager.dismissHeadingCalibrationDisplay()
        #endif
      },
      heading: {
        #if os(iOS) || os(watchOS) || targetEnvironment(macCatalyst)
          holder.manager.heading.map(Heading.init(rawValue:))
        #else
          nil
        #endif
      },
      headingAvailable: {
        CLLocationManager.headingAvailable()
      },
      isRangingAvailable: {
        CLLocationManager.isRangingAvailable()
      },
      location: {
        holder.manager.location.map(Location.init(rawValue:))
      },
      locationServicesEnabled: CLLocationManager.locationServicesEnabled,
      maximumRegionMonitoringDistance: {
        #if os(iOS) || os(macOS) || targetEnvironment(macCatalyst)
          holder.manager.maximumRegionMonitoringDistance
        #else
          CLLocationDistanceMax
        #endif
      },
      monitoredRegions: {
        #if os(iOS) || os(macOS) || targetEnvironment(macCatalyst)
          Set(holder.manager.monitoredRegions.map(Region.init(rawValue:)))
        #else
          []
        #endif
      },
      requestAlwaysAuthorization: {
        #if os(iOS) || os(macOS) || os(watchOS) || targetEnvironment(macCatalyst)
          holder.manager.requestAlwaysAuthorization()
        #endif
      },
      requestLocation: {
        holder.manager.requestLocation()
      },
      requestWhenInUseAuthorization: {
        #if os(iOS) || os(macOS) || os(watchOS) || targetEnvironment(macCatalyst)
          holder.manager.requestWhenInUseAuthorization()
        #endif
      },
      requestTemporaryFullAccuracyAuthorization: { purposeKey in
        try await withCheckedThrowingContinuation { continuation in
          holder.manager.requestTemporaryFullAccuracyAuthorization(
            withPurposeKey: purposeKey
          ) { error in
            if let error = error {
              continuation.resume(throwing: error)
            } else {
              continuation.resume(returning: ())
            }
          }
        }
      },
      set: { properties in
        #if os(iOS) || os(watchOS) || targetEnvironment(macCatalyst)
          if let activityType = properties.activityType {
            holder.manager.activityType = activityType
          }
          if let allowsBackgroundLocationUpdates = properties.allowsBackgroundLocationUpdates {
            holder.manager.allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates
          }
        #endif
        #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
          if let desiredAccuracy = properties.desiredAccuracy {
            holder.manager.desiredAccuracy = desiredAccuracy
          }
          if let distanceFilter = properties.distanceFilter {
            holder.manager.distanceFilter = distanceFilter
          }
        #endif
        #if os(iOS) || os(watchOS) || targetEnvironment(macCatalyst)
          if let headingFilter = properties.headingFilter {
            holder.manager.headingFilter = headingFilter
          }
          if let headingOrientation = properties.headingOrientation {
            holder.manager.headingOrientation = headingOrientation
          }
        #endif
        #if os(iOS) || targetEnvironment(macCatalyst)
          if let pausesLocationUpdatesAutomatically = properties
            .pausesLocationUpdatesAutomatically
          {
            holder.manager.pausesLocationUpdatesAutomatically = pausesLocationUpdatesAutomatically
          }
          if let showsBackgroundLocationIndicator = properties.showsBackgroundLocationIndicator {
            holder.manager.showsBackgroundLocationIndicator = showsBackgroundLocationIndicator
          }
        #endif
      },
      significantLocationChangeMonitoringAvailable: {
        CLLocationManager.significantLocationChangeMonitoringAvailable()
      },
      startMonitoringForRegion: { region in
        #if os(iOS) || os(macOS) || targetEnvironment(macCatalyst)
          holder.manager.startMonitoring(for: region.rawValue!)
        #endif
      },
      startMonitoringSignificantLocationChanges: {
        #if os(iOS) || targetEnvironment(macCatalyst)
          holder.manager.startMonitoringSignificantLocationChanges()
        #endif
      },
      startMonitoringVisits: {
        #if os(iOS) || targetEnvironment(macCatalyst)
          holder.manager.startMonitoringVisits()
        #endif
      },
      startUpdatingHeading: {
        #if os(iOS) || os(macOS) || os(watchOS) || targetEnvironment(macCatalyst)
          holder.manager.startUpdatingHeading()
        #endif
      },
      startUpdatingLocation: {
        #if os(iOS) || os(macOS) || os(watchOS) || targetEnvironment(macCatalyst)
          holder.manager.startUpdatingLocation()
        #endif
      },
      stopMonitoringForRegion: { region in
        #if os(iOS) || os(macOS) || targetEnvironment(macCatalyst)
          holder.manager.stopMonitoring(for: region.rawValue!)
        #endif
      },
      stopMonitoringSignificantLocationChanges: {
        #if os(iOS) || targetEnvironment(macCatalyst)
          holder.manager.stopMonitoringSignificantLocationChanges()
        #endif
      },
      stopMonitoringVisits: {
        #if os(iOS) || targetEnvironment(macCatalyst)
          holder.manager.stopMonitoringVisits()
        #endif
      },
      stopUpdatingHeading: {
        #if os(iOS) || os(watchOS) || targetEnvironment(macCatalyst)
          holder.manager.stopUpdatingHeading()
        #endif
      },
      stopUpdatingLocation: {
        #if os(iOS) || os(macOS) || os(watchOS) || targetEnvironment(macCatalyst)
          holder.manager.stopUpdatingLocation()
        #endif
      }
    )
  }()
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
