//
//  ContentView.swift
//  BLEScanner
//
//  Created by Krystene Maceda on 11/30/23.
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
    var serviceName: String
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
    
    var allowedDevices = [
        "AVEO-ZTVL",
        "AVEO-ZTVR",
        "Aveo Light Display"
    ]
    
    var knownServiceUUIDs: [CBUUID] = [
        CBUUID(string: "180A"),
        CBUUID(string: "F0001110-0451-4000-B000-000000000000"),
        CBUUID(string: "F0001140-0451-4000-B000-000000000000")
    ]
    
    var knownServiceNames = [
        "180A" : "Device Information",
        "F0001110-0451-4000-B000-000000000000" : "BOARD LED",
        "F0001140-0451-4000-B000-000000000000" : "LIGHT 1 CONTROL"
    ]

    private var centralManager: CBCentralManager!
    // Set to store unique peripherals that have been discovered
    var discoveredPeripheralSet = Set<CBPeripheral>()
    var timer: Timer?
    
    // TODO: Connect to 2 bluetooth devices
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
        var peripheralName: String!
        
        // Checks if LocalNameKey can be type-casted to name as a String, otherwise name will be nil
        if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            peripheralName = name
        } else if let name = peripheral.name {
            peripheralName = name
        } else {
            peripheralName = "No Name"
        }
        
        // Allowed devices check
        if allowedDevices.contains(peripheralName) {
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
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let connectedPeripheral = connectedPeripheral else { return }
        print("isConnected = \(isConnected)")
        print("Connected peripheral info: \(connectedPeripheral)")
        self.connectedPeripheral.peripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(knownServiceUUIDs)
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
    
    func write(value: Data, characteristic: CBCharacteristic) {
        // if ((connectedPeripheral?.peripheral.canSendWriteWithoutResponse) != nil) {
        self.connectedPeripheral?.peripheral.writeValue(value, for: characteristic, type: .withoutResponse)
        readValue(characteristic: characteristic)
        // }
    }
    
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        
    }
    
    func convertHexValueToASCII(hexValue: String) -> String {
        var hex = hexValue
        var asciiString = ""
        
        while !hex.isEmpty {
            let hexPair = hex.prefix(2)
            hex = String(hex.dropFirst(2))
            
            if let byte = UInt8(hexPair, radix: 16) {
                asciiString.append(Character(UnicodeScalar(byte)))
            }
        }
        
        return asciiString
    }
    
    func toggleCharacteristic(characteristic: Characteristic) {
        if characteristic.readValue == "01" {
            let writeValue = Data([0x00])
            write(value: writeValue, characteristic: characteristic.characteristic)
         } else {
             let writeValue = Data([0x01])
             write(value: writeValue, characteristic: characteristic.characteristic)
         }
    }
}

extension BluetoothScanner: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        print("-------------------------------------------------------------------------------")
        for service in services {
            let serviceUUIDString = service.uuid.uuidString.uppercased()
            print("Checking for \(serviceUUIDString) in knownServices")
            
            if let serviceName = knownServiceNames[serviceUUIDString] {
                discoveredServices.append(Service(uuid: service.uuid, service: service, serviceName: serviceName))
                print("didDiscoverServices for \(service)\n")
                peripheral.discoverCharacteristics(nil, for: service)
            } else {
                discoveredServices.append(Service(uuid: service.uuid, service: service, serviceName: "Unnamed Service"))
                print("didDiscoverServices for \(service)\n")
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
        print("-------------------------------------------------------------------------------")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        print("-------------------------------------------------------------------------------")
        print("for \(service)\n")
        for characteristic in characteristics {
            discoveredCharacteristics.append(Characteristic(uuid: characteristic.uuid, service: service, characteristic: characteristic, description: "", readValue: ""))
            print("-----> found characteristic: \(characteristic)")
            peripheral.readValue(for: characteristic)
            peripheral.discoverDescriptors(for: characteristic)
        }
        print("-------------------------------------------------------------------------------")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let value = characteristic.value else { return }
        // Find the corresponding Characteristic in the array
        if let index = discoveredCharacteristics.firstIndex(where: { $0.uuid == characteristic.uuid }) {
            // Create a new Characteristic instance with updated readValue
            // var updatedCharacteristic = discoveredCharacteristics[index]
            discoveredCharacteristics[index].readValue = value.map { String(format: "%02X", $0) }.joined()
            // let hexValue = value.map { String(format: "%02X", $0) }.joined()
            /*
            if value.count > 2 {
                discoveredCharacteristics[index].readValue = convertHexValueToASCII(hexValue: hexValue)
            } else {
                discoveredCharacteristics[index].readValue = hexValue
            }
            */
            // Update the array with modified Characteristic
            // discoveredCharacteristics[index] = updatedCharacteristic
            print("----------> didUpdateValueFor characteristic: \(characteristic.uuid)")
        }
    }
        
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("Unsuccessful didWriteValueFor \(characteristic.uuid.uuidString)")
            return
        }
        print("Successfully didWriteValueFor \(characteristic.uuid.uuidString)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        guard let descriptors = characteristic.descriptors else { return }
        
        print("didDiscoverDescriptorsFor: \(characteristic.uuid)")
        if let userDescriptionDescriptor = descriptors.first(where: {
            return $0.uuid.uuidString == CBUUIDCharacteristicUserDescriptionString
        }) {
            peripheral.readValue(for: userDescriptionDescriptor)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        if descriptor.uuid.uuidString == CBUUIDCharacteristicUserDescriptionString,
           let userDescription = descriptor.value as? String {
            print("Characteristic \(String(describing: descriptor.characteristic?.uuid.uuidString)) is also known as \(userDescription)")
            // put descriptor in description value in discoveredCharacteristics
            if let index = discoveredCharacteristics.firstIndex(where: { $0.uuid.uuidString == descriptor.characteristic?.uuid.uuidString }) {
                discoveredCharacteristics[index].description = userDescription
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        
    }
}
