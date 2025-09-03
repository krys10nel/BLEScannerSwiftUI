# Bluetooth Scanner App for iOS and macOS

This app scans for nearby Bluetooth Low Energy (BLE) devices filtered for Aveo lights and displays them in a list. The list can be further filtered by a search field. The app also displays the RSSI (received signal strength indicator) value for each device and is converted to an icon. The app has a button for starting or stopping the scan. 

# Features

- Scan for nearby BLE devices
- Display discovered devices in a list and RSSI for each device using icon
- Filter list by search field
- Start and stop scan with a button
- Tap device to connect
- Toggle characteristics on/off on tap

Future:

- Display device info
- Connect to 2 bluetooth devices

# Requirements

- iOS 12.0 or later, preferrably iOS 16.0+
- macOS 13 or Later
- Xcode 11 or later

# Installation

To install the app, clone or download the repository and open the .xcodeproj file in Xcode. Build and run the app on a device or simulator with iOS 13.0 or later.

# Credits

Forked from Christian Moeller, Nov 2023
Edited by Krystene Maceda, Nov 2023

# License

This app is available under the MIT License. See the LICENSE file for more info.

---

# More Technical Info

## Project overview:

This is an iOS application written in SwiftUI designed to function as a universal controller for the company’s BLE enabled lighting products.

It uses a service-driven dynamic user interface instead of hardcoded buttons. The app connects to a BLE peripheral, discovers its GATT services and characteristics, generates the appropriate UI controls (buttons, toggles, informational text) in real-time, which allows it to be highly scalable, and enables it to control new future products with minimal-to-no changes to the app’s source code, provided the products adhere to the expected BLE GATT structure.

## Core Architecture:

The app utilizes standard SwiftUI MVVM architecture. The state of the entire application is managed by a single ```ObservableObject```.

- ```BluetoothScanner.swift```: Source of truth for all BLE-related state and logic. Handles scanning, connecting, managing peripherals, and holds all lists of discovered services and characteristics. UI observes this object and updates automatically whenever ```@Published``` properties change.
- ```ContentView.swift```: Primary responsibility is to display a list of discovered and filtered BLE peripherals (```discoveredPeripherals```) and provide UI for initiating and stopping a scan. Tapping on a device listed initiates connection process.
- ```DetailsView.swift```: When a connection is established, this view is displayed. Primary responsibility is dynamically rendering the controls for the connected device. The switch statement allows for generic default UI and specialized polished UIs for known devices.

## Components:

```BLEScannerClass.swift```
- **State Management**: Uses ```@Published``` properties (```isScanning```, ```isConnected```, etc.) to automatically notify the SwiftUI views of any changes.
- **Data**: Defines simple, ```Identifiable``` ```structs``` (```Peripheral```, ```Service```, ```Characteristic```) to represent BLE hierarchy in a way that's easy for SwiftUI to use.
- **Hardcoded Parts**: some of these can be refactored
  - ```allowedDevices```: String-match filter to only show relevant company products.
  - ```knownServiceNames```, ```knownLandingLights```, ```knownAntiCollisionLights```: dictionaries that map ```CBUUID``` strings to human-readable names.
- **Core BLE Delegate Logic**: conforms to ```CBCentralManagerDelegate``` for scanning/connecting and ```CBPeripheralDelegate``` for discovering services/characteristics.
  1. ```centralManagerDidUpdateState```: Checks if the phone's Bluetooth is on.
  2. ```didDiscover peripheral```: Device is found. Filtered against ```allowedDevices``` and added to ```discoveredPeripherals``` array.
  3. ```didConnect```: Connection is successful, then app calls ```discoverServices()```.
  4. ```didDiscoverServices```: Services on the peripheral are found. App loops through them and calls ```didDiscoverCharacteristics()``` for each one.
  5. ```didDiscoverCharacteristicsFor service```: Characteristics found, app calls ```didDiscoverDescriptors()``` to get human-readable description.
  6. ```didUpdateValueFor characteristic/descriptor```: App receives data from peripheral (e.g. is the the strobe for this light on/off?) and updates ```discoveredCharacteristics``` array, which updates the UI.
- **Device-Specific Business Logic**: The ```toggleCharacteristic``` and ```resetOtherServices``` functions contain logic specific to the light display board due to constraints in power.

```ContentView.swift```
- This displays a list of nearby and relevant BLE peripherals discovered by the ```BluetoothScanner```.
- Includes the start and stop of the scanning process, initiates connection when the user selects a device from the list, and automatically navigate to ```DetailsView``` upon successful connection.
- **State Management**:
  - ```@ObservedObject var bluetoothScanner = BluetoothScanner()```: The ```ContentView``` subscribes to the ```bluetoothScanner``` object. Any time a ```@Publlished``` property in the scanner changes, the view's body is automatically re-rendered to reflect the new state.
  - ```@State private var searchText = ""```: This is a local state variable that holds the current text from the searchable UI component.
  - ```$bluetoothScanner.isConnected```: The ```isActive``` property of the ```NavigationLink``` is bound directly to the ```isConnected``` boolean in the ```bluetoothScanner```. The navigation is not triggered bya an explicit command but by the state of ```isConnected``` changing to ```true```.
- **UI Components**:
  - ```LoadingView```: Simple initial view shown for 3 seconds on first launch.
  - ```NavigationView```: View that provides the navigation bar, title, and allows pushing the ```DetailsView``` onto the stack.
  - ```NavigationLink(...)```: An invisible link that is activated when ```$bluetoothScanner.isConnected``` becomes true, causing the transition to ```DetailsView```.
  - ```deviceCards```

```DetailsView.swift```
- This view iterates over ```discoveredServices``` and ```discoveredCharacteristics``` arrays published by ```BluetoothScanner```.
- The ```generalDevice``` view is a fallback that will attempt to render controls for *any* BLE device as long as it gets passed the app's filters.
- ```aveoLightDisplayDevice``` view is a custom, more user-friendly layout that uses ```DisclosureGroup S``` for the specific known services of that product. This pattern can be replicated for other known products.

## Future Roadmap & Recommended Next Steps

This can be a "one-stop shop" platform for both civilian and military lights. The logic is almost directly translatable to Android using Kotlin and Jetpack Compose. Recommended next steps:

- **Refactor configuration to an external file (important)**: All hardcoded UUIDs and device names should be moved out of ```BLEScannerClass.swift``` and into an external JSON configuration file. The app would parse this file at startup and it would make it easier to add support for new products without editing source code and recompiling the app.
- **Implement secure connection logic (for military use)**: To support military-grade products, the app needs to handle BLE bonding. Peripheral firmware should be set to require encryption for its control characteristics, and the iOS app will then need to handle the pairing request initiated by the firmware, which will likely involve a PIN entry prompt. The app can detect whether the device is "military" via a specific service UUID and could indicate a "secure" or "unsecure" connection state in the UI.
- **Improve connection state management**: Add more robust hanlding for unexpected disconnections. UI should remain on ```DetailsView``` upon disconnect, allowing user to attempt a reconnect without having to go back into the scan list.
- **Android port**: As mentioned, the iOS application serves as a valid blueprint for an Android version. Estimated time would be ~2 months for an experienced Android BLE developer.
