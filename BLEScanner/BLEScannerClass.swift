//
//  ContentView.swift
//  BLEScanner
//
//  Created by Christian Möller on 02.01.23.
//

import SwiftUI
import CoreBluetooth

struct Peripheral: Identifiable {
    var id: UUID
    
    // Struct to represent a discovered peripheral
    var peripheral: CBPeripheral
    var deviceName: String
    var advertisedData: [String : Any]
    var rssi: Int
}

class BluetoothScanner: NSObject, CBCentralManagerDelegate, ObservableObject {
    @Published var discoveredPeripherals = [Peripheral]()
    @Published var isScanning = false
    @Published var isConnected = false
    @Published var isPowered = false
    var centralManager: CBCentralManager!
    // Set to store unique peripherals that have been discovered
    var discoveredPeripheralSet = Set<CBPeripheral>()
    var timer: Timer?
    
    private var connectedPeripheral: Peripheral!

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            stopScan()
        case .resetting:
            stopScan()
        case .unsupported:
            stopScan()
        case .unauthorized:
            stopScan()
        case .poweredOff:
            isPowered = false
            stopScan()
        case .poweredOn:
            isPowered = true
            startScan()
        @unknown default:
            print("central.state is unknown")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Build a string representation of the advertised data and sort it by names
        // var advertisedData = advertisementData.map { "\($0): \($1)" }.sorted(by: { $0 < $1 }).joined(separator: "\n")
        
        // let serviceUUID = advertisementData["kCBAdvDataServiceUUIDs"]
        
        // let advertisedData = "ID: \(peripheral.identifier)\n" + "Service UUIDs: \(serviceUUID ?? "None")\n"

        // Convert the timestamp into human readable format and insert it to the advertisedData String
        /* let timestampValue = advertisementData["kCBAdvDataTimestamp"] as! Double
        // print(timestampValue)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let dateString = dateFormatter.string(from: Date(timeIntervalSince1970: timestampValue))

        advertisedData = "actual rssi: \(RSSI) dB\n" + "Timestamp: \(dateString)\n" + advertisedData
        */
        var peripheralName: String!
        
        // Checks if LocalNameKey can be type-casted to name as a String, otherwise name will be nil
        if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            peripheralName = name
        } else {
            peripheralName = "No Name"
        }
        
        // If the peripheral is not already in the list
        if !discoveredPeripheralSet.contains(peripheral) {
            // Add it to the list and the set
            discoveredPeripherals.append(Peripheral(id: peripheral.identifier, peripheral: peripheral, deviceName: peripheralName, advertisedData: advertisementData, rssi: RSSI.intValue))
            discoveredPeripheralSet.insert(peripheral)
            objectWillChange.send()
            print(Peripheral(id: peripheral.identifier, peripheral: peripheral, deviceName: peripheralName, advertisedData: advertisementData, rssi: RSSI.intValue))
        } else {
            // If the peripheral is already in the list, update its advertised data
            if let index = discoveredPeripherals.firstIndex(where: { $0.peripheral == peripheral }) {
                discoveredPeripherals[index].advertisedData = advertisementData
                objectWillChange.send()
            }
        }
    }
    
    func startScan() {
        if centralManager.state == .poweredOn {
            print("startScan")
            // Set isScanning to true and clear the discovered peripherals list
            isScanning = true
            discoveredPeripherals.removeAll()
            discoveredPeripheralSet.removeAll()
            objectWillChange.send()

            // Start scanning for peripherals
            centralManager.scanForPeripherals(withServices: nil, options: nil)

            // Start a timer to stop and restart the scan every 2 seconds
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
                self?.centralManager.stopScan()
                self?.centralManager.scanForPeripherals(withServices: nil, options: nil)
            }
        }
    }

    func stopScan() {
        print("stopScan")
        // Set isScanning to false and stop the timer
        isScanning = false
        timer?.invalidate()
        centralManager.stopScan()
    }
    
    func connectPeripheral(_ selectPeripheral: Peripheral?) {
        guard let connectPeripheral = selectPeripheral else { return }
        connectedPeripheral = selectPeripheral
        centralManager.connect(connectPeripheral.peripheral, options: nil)
    }
    
    func disconnectPeripheral() {
        guard let connectedPeripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(connectedPeripheral.peripheral)
    }
    
    func navigateToDetailView(isDetailViewLinkActive: Binding<Bool>) -> some View {
        let navigateToDetailView = NavigationLink("", destination: DetailsView(), isActive: isDetailViewLinkActive)
        return navigateToDetailView
    }
}
