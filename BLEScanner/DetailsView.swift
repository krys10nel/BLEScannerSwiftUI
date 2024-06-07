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
                case "LIGHT-DISPLAY":
                    aveoLightDisplayDevice
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
        GeometryReader { geo in
            if #available(iOS 16.0, *) {
                List {
                    if let deviceInformationService = device.discoveredServices.first(where: { device.knownServiceNames[$0.uuid.uuidString] == "Device Information"}) {
                        DisclosureGroup {
                            VStack(alignment: .leading) {
                                ReadOnlyGroupView(device: device, service: deviceInformationService)
                            }
                            .padding()
                        } label: {
                            HStack {
                                Text("Device Information")
                                    .foregroundStyle(.red)
                            }
                        }
                        .tint(.red)
                    }
                    
                    if let landingLightsService = device.discoveredServices.first(where: {device.knownServiceNames[$0.uuid.uuidString] == "Landing Lights"}) {
                        DisclosureGroup {
                            VStack(alignment: .leading) {
                                LightGroupView(device: device, service: landingLightsService, proxy: geo)
                            }
                        } label: {
                            HStack {
                                Text("Landing Lights")
                                    .foregroundStyle(.red)
                            }
                        }
                        .tint(.red)
                    }
                    
                    if let antiCollisionLightsService = device.discoveredServices.first(where: {device.knownServiceNames[$0.uuid.uuidString] == "Anti-Collision Lights"}) {
                        DisclosureGroup {
                            VStack(alignment: .leading) {
                                LightGroupView(device: device, service: antiCollisionLightsService, proxy: geo)
                            }
                        } label: {
                            HStack {
                                Text("Anti-Collision Lights")
                                    .foregroundStyle(.red)
                            }
                        }
                        .tint(.red)
                    }
                }
                .listStyle(.insetGrouped)
                .disclosureGroupStyle(LightDisclosureStyle())
                .navigationBarTitle(self.device.connectedPeripheral.deviceName)
                .navigationBarItems(trailing: self.device.isConnected ? Text("Connected").foregroundStyle(.green) : Text("Disconnected").foregroundStyle(.red))
            } else {
                // Fallback on earlier versions
                GeometryReader { geo in
                    VStack {
                        if let deviceInformationService = device.discoveredServices.first(where: { device.knownServiceNames[$0.uuid.uuidString] == "Device Information"}) {
                            DisclosureGroup {
                                VStack(alignment: .leading) {
                                    ReadOnlyGroupView(device: device, service: deviceInformationService)
                                }
                            } label: {
                                HStack {
                                    Text("Device Information")
                                        .foregroundStyle(.red)
                                }
                            }
                            .tint(.red)
                        }
                        
                        if let landingLightsService = device.discoveredServices.first(where: {device.knownServiceNames[$0.uuid.uuidString] == "Landing Lights"}) {
                            DisclosureGroup {
                                VStack(alignment: .leading) {
                                    LightGroupView(device: device, service: landingLightsService, proxy: geo)
                                }
                            } label: {
                                HStack {
                                    Text("Landing Lights")
                                        .foregroundStyle(.red)
                                }
                            }
                            .tint(.red)
                        }
                        
                        if let antiCollisionLightsService = device.discoveredServices.first(where: {device.knownServiceNames[$0.uuid.uuidString] == "Anti-Collision Lights"}) {
                            DisclosureGroup {
                                VStack(alignment: .leading) {
                                    LightGroupView(device: device, service: antiCollisionLightsService, proxy: geo)
                                }
                            } label: {
                                HStack {
                                    Text("Anti-Collision Lights")
                                        .foregroundStyle(.red)
                                }
                            }
                            .tint(.red)
                        }
                    }
                    .navigationBarTitle(self.device.connectedPeripheral.deviceName)
                    .navigationBarItems(trailing: self.device.isConnected ? Text("Connected").foregroundStyle(.green) : Text("Disconnected").foregroundStyle(.red))
                }
            }
        }
        
    }
    
    private var aveoZipTipDevice: some View {
        GeometryReader { geo in
            VStack {
                if let aveoZipTip = device.discoveredServices.first(where: {device.knownServiceNames[$0.uuid.uuidString] == "AVEO-ZTVL"}) {
                    LightGroupView(device: device, service: aveoZipTip, proxy: geo)
                } else {
                    Text("Landing Lights service not available")
                }
            }
        }
    }
}

struct ReadOnlyGroupView: View {
    @ObservedObject var device: BluetoothScanner
    var service: Service
    
    var body: some View {
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
    }
}

struct LightGroupView: View {
    @ObservedObject var device : BluetoothScanner
    var service: Service
    var proxy: GeometryProxy
    
    var body: some View {
        HStack {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: proxy.size.width * 0.25))], alignment: .leading, spacing: 5) {
                ForEach(device.discoveredCharacteristics, id: \.uuid) { characteristic in
                    if characteristic.service.uuid == service.uuid {
                        let properties = characteristic.characteristic.properties
                        if properties.contains(.write) {
                            HStack {
                                VStack {
                                    Spacer()
                                    Text("\(characteristic.characteristicName)")
                                        .frame(idealWidth: .infinity, maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                    Spacer()
                                    Text("\(characteristic.description)")
                                        .frame(idealWidth: .infinity, maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    Spacer()
                                    Button(action: {
                                        print("Clicked on \(characteristic)")
                                        self.device.toggleCharacteristic(characteristic: characteristic)
                                        
                                        // TODO: while characteristic name == previous characteristic name
                                    }) {
                                        Image(systemName: "power.circle")
                                            .font(.system(size: 50))
                                            .foregroundStyle(characteristic.readValue == "01" ? Color.green : Color.gray)
                                    }
                                    .buttonStyle(.bordered)
                                    Spacer()
                                }
                                .frame(width: proxy.size.width * 0.25, alignment: .topLeading)
                            }
                        }
                    }
                }
            }
        }
    }
}

@available(iOS 16.0, *)
struct LightDisclosureStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            HStack(alignment: .firstTextBaseline) {
                configuration.label
                    .padding([.top, .bottom], 10)
                    .lineLimit(1)
                    .layoutPriority(1)
                Image(systemName: configuration.isExpanded ? "chevron.down" : "chevron.right")
                    .foregroundStyle(.red)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .animation(.easeInOut(duration: 0.3), value: configuration.isExpanded)
            }
            .onTapGesture {
                configuration.isExpanded.toggle()
            }
            .contentShape(Rectangle())
            
            if configuration.isExpanded {
                configuration.content
                    .padding(.leading, 0)
            }
        }
    }
}

#Preview {
    DetailsView(device: BluetoothScanner())
}
