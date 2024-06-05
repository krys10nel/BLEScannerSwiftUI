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
    var characteristicName: String
    var description: String
    var readValue: String
}

struct PendingWrite {
    var value: Data
    var characteristic: CBCharacteristic
}

class BluetoothScanner: NSObject, CBCentralManagerDelegate, ObservableObject {
    @Published var discoveredPeripherals = [Peripheral]()
    @Published var discoveredServices =  [Service]()
    @Published var discoveredCharacteristics = [Characteristic]()
    
    var bondedPeripheralIdentifiers: [UUID] = []
    
    @Published var isScanning = false
    @Published var isConnected = false
    @Published var isPowered = false
    
    var allowedDevices = [
        "AVEO-ZTVL",
        "AVEO-ZTVR",
        "LIGHT-DISPLAY"
    ]
    
    var knownServiceUUIDs: [CBUUID] = [
        CBUUID(string: "180A"),                                     // Device Information
        CBUUID(string: "F0001110-0451-4000-B000-000000000000"),     // Board LED
        CBUUID(string: "F0001140-0451-4000-B000-000000000000"),     // Test lights control
        CBUUID(string: "37E6A24C-EEC0-482E-9244-B92077EBA861"),     // Landing Lights
        CBUUID(string: "3C07F26F-302E-40EB-95C0-F9FDD5A9C51E")      // Anti-Collision Lights
        
    ]
    
    var knownServiceNames = [
        "180A" : "Device Information",
        "F0001110-0451-4000-B000-000000000000" : "BOARD LED",
        "F0001140-0451-4000-B000-000000000000" : "LIGHT CONTROL TEST",
        "37E6A24C-EEC0-482E-9244-B92077EBA861" : "Landing Lights",
        "3C07F26F-302E-40EB-95C0-F9FDD5A9C51E" : "Anti-Collision Lights",
    ]
    
    var knownLandingLights = [
        "FCDD0DE6-E6E5-497A-9AED-83592F3EC926" : "NUBION",
        "524E3679-AA69-42D9-92EF-2707239CFBB1" : "NUBION",
        "29D2E4B1-9860-4443-A9C4-59FDCF00A9F4" : "PACIFICA",
        "DDF795D5-492C-4157-8CC9-8834E54B78BF" : "HERCULES JP",
        "D8279C7C-3868-4ED3-B689-980535DBF7C9" : "HERCULES DI",
        "9222E34B-A5E1-4AE7-B3B7-77ECB89E6646" : "SAMSON JP",
        "83141066-BE5A-428F-8E04-7117661E8156" : "TITAN",
    ]
    
    var knownAntiCollisionLights = [
        "7252E959-306E-4979-8736-79C1037FAD41" : "ULTRA DAYLITE",
        "4EE069CE-138A-40AA-8482-C077D040666C" : "ULTRA DAYLITE",
        "56832316-4984-44DE-8125-FF3D1CA00EE8" : "ULTRA EMB",
        "7EEA0DCE-2346-42C4-BB81-7F86143FB586" : "ULTRA EMB",
        "6D081FAA-0A7B-4D13-933F-5B1571DBCC81" : "ANDROMEDA",
        "E6009D48-365F-45DA-8D57-9AD4D08CC49B" : "ANDROMEDA",
        "44095DDC-0BFA-4D5A-A465-D7680E988ED2" : "POWERBURST",
        "AD833097-353F-4DD6-958F-931BEE9F04C6" : "POWERBURST",
        "314A759D-0DC3-4260-AA9C-610B41A6D89E" : "AIRBURST NG",
        "C1ECE9DB-3887-479E-836F-8495709D04DD" : "SUPERNOVA FS",
        "CC7BB8B6-7388-4DF6-BEF5-8A3EA8D75043" : "RED BARON XP",
        "8E0B1889-E76A-473F-86E1-F89A528A252C" : "RED BARON NXT",
        "B111C15B-2777-419B-BC3A-CF40736CC6B9" : "POSISTROBE",
        "5478E018-6BA0-43AC-AA4E-6DD99F6EB3D3" : "POSISTROBE",
    ]

    private var centralManager: CBCentralManager!
    // Set to store unique peripherals that have been discovered
    var discoveredPeripheralSet = Set<CBPeripheral>()
    var retrievedPeripherals: [CBPeripheral] = []
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
        // Calls peirpheralIsReady
        if ((connectedPeripheral?.peripheral.canSendWriteWithoutResponse) != nil) {
            print("Writing value...")
            self.connectedPeripheral?.peripheral.writeValue(value, for: characteristic, type: .withoutResponse)
            print("Reading value...")
            readValue(characteristic: characteristic)
        }
    }
    /*
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheral] {
        let peripheral = self.centralManager.retrievePeripherals(withIdentifiers: identifiers).first
            
        for peripheral in retrievedPeripherals {
            if peripheral.state == .disconnected {
                centralManager.connect(peripheral, options: nil)
            }
        }
        
        return retrievedPeripherals
    }
    */
    
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
        // TODO: if service is not the same, toggle all characteristics in service off before attempting to write value into new characteristic
        
        let writeValue: Data
        
        if characteristic.readValue == "01" {
            writeValue = Data([0x00])
            // write(value: writeValue, characteristic: characteristic.characteristic)
        } else {
            writeValue = Data([0x01])
            // write(value: writeValue, characteristic: characteristic.characteristic)
        }
        
        print("Attempting to write \(writeValue) to \(characteristic.characteristic.uuid)")
        write(value: writeValue, characteristic: characteristic.characteristic)
    }
}

extension BluetoothScanner: CBPeripheralDelegate {
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        print("Peripheral is ready")
    }
    
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
            let characteristicUUIDString = characteristic.uuid.uuidString.uppercased()
            print("Checking for \(characteristicUUIDString) in dictionary")
            
            if let characteristicName = knownLandingLights[characteristicUUIDString] ?? knownAntiCollisionLights[characteristicUUIDString] {
                discoveredCharacteristics.append(Characteristic(uuid: characteristic.uuid, service: service, characteristic: characteristic, characteristicName: characteristicName, description: "", readValue: ""))
            } else {
                discoveredCharacteristics.append(Characteristic(uuid: characteristic.uuid, service: service, characteristic: characteristic, characteristicName: "Unnamed Characteristic", description: "", readValue: ""))
            }
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
