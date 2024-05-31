//
//  DetailsView.swift
//  BLEScanner
//
//  Created by Krystene Maceda on 11/30/23.
//

import SwiftUI

struct DetailsView: View {
    @ObservedObject var device : BluetoothScanner
    
    // TODO: stay on device screen when disconnecting (for option to reconnect)
    var body: some View {
        ZStack {
            if let peripheral = device.connectedPeripheral {
                switch peripheral.deviceName {
                case "Aveo Light Display":
                    generalDevice   // TODO: change into aveoLightDisplayDevice
                case "AVEO-ZTVL":
                    aveoZipTipDevice
                case "AVEO-ZTVR":
                    aveoZipTipDevice
                default:
                    generalDevice
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            if self.device.isConnected {
                self.device.disconnectPeripheral()
            } else {
                self.device.startScan()
            }
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Return")
            }
        })
    }
    
    private var generalDevice: some View {
        VStack {
            GeometryReader { geo in
                List(device.discoveredServices, id: \.uuid) { service in
                    Button(action: {
                        print("Clicked on \(service.uuid)")
                    }) {
                        VStack {
                            // Service Name
                            HStack {
                                Text("\(service.serviceName)")
                                    .frame(minWidth: 111, idealWidth: .infinity, maxWidth: .infinity, alignment: .topLeading)
                                    .foregroundStyle(.red)
                                    .lineLimit(1)
                                Spacer()
                            }
                            //characteristicView
                            // Info Only Services
                            // Device information Services etc. are gray captioned
                            VStack {
                                ForEach(device.discoveredCharacteristics, id: \.uuid) { characteristic in
                                    if characteristic.service.uuid == service.uuid {
                                        let properties = characteristic.characteristic.properties
                                        if properties.contains(.read) && !properties.contains(.write) {
                                            VStack {
                                                Text("\(characteristic.uuid) : \(self.device.convertHexValueToASCII(hexValue: characteristic.readValue))")
                                                    .frame(idealWidth: .infinity, maxWidth: .infinity, alignment: .leading)
                                                    .foregroundStyle(.gray)
                                                    .font(.caption)
                                                    .lineLimit(2)
                                            }
                                        }
                                    }
                                }
                            }
                            // Toggle Only Services
                            HStack {
                                ScrollView {
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: geo.size.width * 0.25))], alignment: .leading, spacing: 10) {
                                        ForEach(device.discoveredCharacteristics, id: \.uuid) { characteristic in
                                            if characteristic.service.uuid == service.uuid {
                                                let properties = characteristic.characteristic.properties
                                                if properties.contains(.write) {
                                                    VStack {
                                                        Spacer()
                                                        Text("\(characteristic.description)")
                                                            .frame(idealWidth: .infinity, maxWidth: .infinity, alignment: .center)
                                                            .foregroundStyle(.white)
                                                            .lineLimit(1)
                                                        Spacer()
                                                        Button(action: {
                                                            print("Clicked on \(characteristic)")
                                                            self.device.toggleCharacteristic(characteristic: characteristic)
                                                        }) {
                                                            Image(systemName: "power.circle")
                                                                .font(.system(size: 50))
                                                                .foregroundStyle(characteristic.readValue == "01" ? Color.green : Color.gray)
                                                        }
                                                    }
                                                    .frame(width: geo.size.width * 0.25, alignment: .topLeading)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(width: geo.size.width, alignment: .topLeading)
                        }
                        .padding()
                    }
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .frame(minWidth: 111, idealWidth: .infinity, maxWidth: .infinity, alignment: .leading)
                }
                .listStyle(PlainListStyle())
            }
                
            Spacer()
            Button(action: {
                self.device.disconnectPeripheral()
                //self.device.stopScan()
            }) {
                if device.isConnected {
                    Text("Disconnect device")
                } else {
                    Text("Connect to device")
                }
            }
            .padding()
            .background(self.device.isConnected ? Color.red : Color.blue)
            .foregroundColor(Color.white)
            .cornerRadius(5.0)
            Spacer()
        }
        .navigationBarTitle(self.device.connectedPeripheral.deviceName)
        .navigationBarItems(trailing: self.device.isConnected ? Text("Connected").foregroundStyle(.green) : Text("Disconnected").foregroundStyle(.red))
    }
    
    private var aveoLightDisplayDevice: some View {
        VStack {
            if let landingLightsService = device.discoveredServices.first(where: {device.knownServiceNames[$0.uuid.uuidString] == "Landing Lights"}) {
                LightGroupView(device: device, service: landingLightsService, usingLightsDict: device.knownLandingLights)
            } else if let antiCollisionLightsService = device.discoveredServices.first(where: {device.knownServiceNames[$0.uuid.uuidString] == "Anti-Collision Lights"}) {
                LightGroupView(device: device, service: antiCollisionLightsService, usingLightsDict: device.knownAntiCollisionLights)
            } else {
                Text("Landing Lights service not available")
            }
        }
    }
    
    private var aveoZipTipDevice: some View {
        VStack {
            if let aveoZipTip = device.discoveredServices.first(where: {device.knownServiceNames[$0.uuid.uuidString] == "AVEO-ZTVL"}) {
                LightGroupView(device: device, service: aveoZipTip, usingLightsDict: device.knownAntiCollisionLights)
            } else {
                Text("Landing Lights service not available")
            }
        }
    }
}

struct LightGroupView: View {
    @ObservedObject var device : BluetoothScanner
    var service: Service
    var usingLightsDict: [String : String]
    
    var body: some View {
        GeometryReader { geo in
            HStack {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: geo.size.width * 0.25))], alignment: .leading, spacing: 10) {
                        ForEach(device.discoveredCharacteristics, id: \.uuid) { characteristic in
                            if characteristic.service.uuid == service.uuid {
                                let properties = characteristic.characteristic.properties
                                if properties.contains(.write) {
                                    HStack {
                                        // TODO: while characteristic name == previous characteristic name
                                        let currentLight = 
                                        VStack {
                                            Spacer()
                                            Text("\(characteristic.description)")
                                                .frame(idealWidth: .infinity, maxWidth: .infinity, alignment: .center)
                                                .foregroundStyle(.white)
                                                .lineLimit(1)
                                            Spacer()
                                            Button(action: {
                                                print("Clicked on \(characteristic)")
                                                self.device.toggleCharacteristic(characteristic: characteristic)
                                            }) {
                                                Image(systemName: "power.circle")
                                                    .font(.system(size: 50))
                                                    .foregroundStyle(characteristic.readValue == "01" ? Color.green : Color.gray)
                                            }
                                        }
                                        .frame(width: geo.size.width * 0.25, alignment: .topLeading)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .frame(width: geo.size.width, alignment: .topLeading)
        }
    }
}

#Preview {
    DetailsView(device: BluetoothScanner())
}
