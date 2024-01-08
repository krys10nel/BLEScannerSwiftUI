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
            VStack {
                GeometryReader { geo in
                    List(device.discoveredServices, id: \.uuid) { service in
                        Button(action: {
                            print("Clicked on \(service.uuid)")
                        }) {
                            VStack {
                                HStack {
                                    // TODO: change uuid to characteristic name (assuming it exists in firmware)
                                    Text("\(service.uuid)")
                                        .frame(minWidth: 111, idealWidth: .infinity, maxWidth: .infinity, alignment: .leading)
                                        .foregroundStyle(.red)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                //characteristicView
                                // TODO: light controls ONLY, as buttons
                                // TODO: device information etc. are gray captioned
                                VStack {
                                    ForEach(device.discoveredCharacteristics, id: \.uuid) { characteristic in
                                        if characteristic.service.uuid == service.uuid {
                                            let properties = characteristic.characteristic.properties
                                            if properties.contains(.read) && !properties.contains(.write) {
                                                VStack {
                                                    Text("\(characteristic.uuid) : \(characteristic.readValue)")
                                                        .frame(idealWidth: .infinity, maxWidth: .infinity, alignment: .leading)
                                                        .foregroundStyle(.gray)
                                                        .font(.caption)
                                                        .lineLimit(2)
                                                }
                                            }
                                        }
                                    }
                                }
                                // Buttons only
                                HStack {
                                    ForEach(device.discoveredCharacteristics, id: \.uuid) { characteristic in
                                        if characteristic.service.uuid == service.uuid {
                                            let properties = characteristic.characteristic.properties
                                            if properties.contains(.write) {
                                                VStack {
                                                    Spacer()
                                                    Text("\(characteristic.uuid)")
                                                        .frame(idealWidth: .infinity, maxWidth: .infinity, alignment: .leading)
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
                                    Spacer()
                                }
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
            .navigationBarItems(trailing: self.device.isConnected ? Text("Connected") : Text("Disconnected"))
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
    
//    private var characteristicView: some View {
//        ForEach($device.discoveredCharacteristics) { discoveredCharacteristics in
//            Text("Service Name: \(discoveredCharacteristics.id)")}
//    }
}

#Preview {
    DetailsView(device: BluetoothScanner())
}
