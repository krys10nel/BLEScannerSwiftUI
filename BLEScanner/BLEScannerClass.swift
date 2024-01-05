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

struct Service: Identifiable {
    var id: UUID = UUID()
    
    var uuid: CBUUID
    var service: CBService
}

struct Characteristic: Identifiable {
    var id: UUID = UUID()
    
    var uuid: CBUUID
    var service: CBService
    var characteristic: CBCharacteristic
    var description: String
    var readValue: String
}

class BluetoothScanner: NSObject, CBCentralManagerDelegate, ObservableObject {
    @Published var discoveredPeripherals = [Peripheral]()
    @Published var discoveredServices =  [Service]()
    @Published var discoveredCharacteristics = [Characteristic]()
    
    @Published var isScanning = false
    @Published var isConnected = false
    @Published var isPowered = false

    private var centralManager: CBCentralManager!
    // Set to store unique peripherals that have been discovered
    var discoveredPeripheralSet = Set<CBPeripheral>()
    var timer: Timer?
    
    @Published var connectedPeripheral: Peripheral!
    
    private var readCharacteristic: CBCharacteristic?
    private var writeCharacteristic: CBCharacteristic?
    private var notifyCharacteristic: CBCharacteristic?

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
            if !isScanning && !isConnected {
                startScan()
            }
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
        } else if let name = peripheral.name {
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
            print("\n")
        } else {
            // If the peripheral is already in the list, update its advertised data
            if let index = discoveredPeripherals.firstIndex(where: { $0.peripheral == peripheral }) {
                discoveredPeripherals[index].advertisedData = advertisementData
                objectWillChange.send()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let connectedPeripheral = connectedPeripheral else { return }
        print("isConnected = \(isConnected)")
        print("Connected peripheral info: \(connectedPeripheral)")
        self.connectedPeripheral.peripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(connectedPeripheral.deviceName)")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            print("Disconnection error")
            return
        }
        print("Successfully didDisconnectPeripheral")
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
    
    func connectPeripheral(_ selectPeripheral: Peripheral!) {
        guard let connectPeripheral = selectPeripheral else { return }
        connectedPeripheral = selectPeripheral
        centralManager.connect(connectPeripheral.peripheral, options: nil)
        print("Connecting to " + (connectedPeripheral.deviceName))
        isConnected = true
    }
    
    func disconnectPeripheral() {
        guard let connectedPeripheral = connectedPeripheral else { return }
        print("Disconnecting from device")
        centralManager.cancelPeripheralConnection(connectedPeripheral.peripheral)
        isConnected = false
        discoveredServices.removeAll()
        discoveredCharacteristics.removeAll()
        print("isConnected : \(isConnected)")
    }
    
    func readValue(characteristic: CBCharacteristic) {
        self.connectedPeripheral?.peripheral.readValue(for: characteristic)
    }
    
    func write(value: Data, characteristic: Characteristic) {
        // if ((connectedPeripheral?.peripheral.canSendWriteWithoutResponse) != nil) {
        self.connectedPeripheral?.peripheral.writeValue(value, for: characteristic.characteristic, type: .withoutResponse)
        // }
    }
    /*
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        write(value: someValue, characteristic: someCharacteristic)
    }*/
}

extension BluetoothScanner: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            discoveredServices.append(Service(uuid: service.uuid, service: service))
            peripheral.discoverCharacteristics(nil, for: service)
        }
        
        print("didDiscoverServices")
        // print(discoveredServices)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
//        for characteristic in characteristics {
//            switch characteristic.properties {
//            case .read:
//                readCharacteristic = characteristic
//            case .write:
//                writeCharacteristic = characteristic
//            case .notify:
//                notifyCharacteristic = characteristic
//                peripheral.setNotifyValue(true, for: characteristic)
//            case .indicate: break
//            case .broadcast: break
//            default: break
//            }
//        }
        for characteristic in characteristics {
            discoveredCharacteristics.append(Characteristic(uuid: characteristic.uuid, service: service, characteristic: characteristic, description: "", readValue: ""))
            print("found characteristic: \(characteristic.uuid) for service: \(characteristic.service!.uuid)")
            peripheral.readValue(for: characteristic)
            peripheral.discoverDescriptors(for: characteristic)
        }
        print("didDiscoverCharacteristics")
        print(discoveredCharacteristics)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let value = characteristic.value else { return }
        
        // Find the corresponding Characteristic in the array
        if let index = discoveredCharacteristics.firstIndex(where: { $0.uuid.uuidString == characteristic.uuid.uuidString }) {
            // Create a new Characteristic instance with updated readValue
            var updatedCharacteristic = discoveredCharacteristics[index]
            updatedCharacteristic.readValue = value.map { String(format: "%02X", $0) }.joined()
            
            // Update the array with modified Characteristic
            discoveredCharacteristics[index] = updatedCharacteristic
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            return
        }
        print("Successfully didWriteValueFor \(characteristic.uuid.uuidString)")
    }
    
    // TODO: read descriptors etc.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        guard let descriptors = characteristic.descriptors else { return }
        
        // Get user description descriptor
        if let index = descriptors.firstIndex(where: { $0.uuid.uuidString == CBUUIDCharacteristicUserDescriptionString }) {
            // Read user description for characteristic
            var updatedDescriptor = discoveredCharacteristics[index]
            updatedDescriptor.readValue = String(describing: descriptors)
            
            discoveredCharacteristics[index] = updatedDescriptor
        }
        print("didDiscoverDescriptorsFor: \(characteristic)")
        print("Descriptors: \(String(describing: characteristic.descriptors))")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        if descriptor.uuid.uuidString == CBUUIDCharacteristicUserDescriptionString, let userDescription = descriptor.value as? String {
            print("Characteristic \(String(describing: descriptor.characteristic?.uuid.uuidString)) is also known as \(userDescription)")
        }
        print("didUpdateValueFor: \(descriptor)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        
    }
}
