import CoreLocation
import CoreMotion
import Foundation

@MainActor
final class SensorManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorization: CLAuthorizationStatus = .notDetermined
    @Published private(set) var heading: Double?
    @Published private(set) var horizontalAccuracy: Double?
    @Published private(set) var steps: Int = 0
    @Published private(set) var walkedMeters: Double = 0

    private let locationManager = CLLocationManager()
    private let pedometer = CMPedometer()
    private var walkingStart: Date?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.headingFilter = 3
        authorization = locationManager.authorizationStatus
    }

    func requestPermissionsAndStart() {
        locationManager.requestWhenInUseAuthorization()
        startSensors()
    }

    func startSensors() {
        locationManager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() { locationManager.startUpdatingHeading() }
        guard CMPedometer.isStepCountingAvailable() else { return }
        let start = Date()
        walkingStart = start
        pedometer.startUpdates(from: start) { [weak self] data, _ in
            guard let data else { return }
            Task { @MainActor in
                self?.steps = data.numberOfSteps.intValue
                self?.walkedMeters = data.distance?.doubleValue ?? Double(data.numberOfSteps.intValue) * 0.72
            }
        }
    }

    func stopSensors() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        pedometer.stopUpdates()
        walkingStart = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
        if authorization == .authorizedWhenInUse || authorization == .authorizedAlways { startSensors() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        horizontalAccuracy = locations.last?.horizontalAccuracy
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
    }
}

