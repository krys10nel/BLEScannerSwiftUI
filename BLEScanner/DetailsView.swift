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
    // TODO: keep device name on details view
    var body: some View {
        NavigationView{
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
                                HStack(alignment: .top) {
                                    ForEach(device.discoveredCharacteristics, id: \.uuid) { characteristic in
                                        if characteristic.service.uuid == service.uuid {
                                            let properties = characteristic.characteristic.properties
                                            //HStack {
                                            // TODO: light controls ONLY as buttons
                                            // TODO: device information etc. are gray captioned
                                            if properties.contains(.write) {
                                                //HStack {
                                                Button(action: {
                                                    print("Clicked on \(characteristic)")
                                                    self.device.toggleCharacteristic(characteristic: characteristic)
                                                }) {
                                                    VStack {
                                                        Text("\(characteristic.uuid)")
                                                            .frame(idealWidth: .infinity, maxWidth: .infinity, alignment: .leading)
                                                            .foregroundStyle(.white)
                                                            .lineLimit(1)
                                                        Spacer()
                                                        // TODO: Bigger button
                                                        Image(systemName: "power.circle")
                                                            .imageScale(.large)
                                                            .foregroundStyle(characteristic.readValue == "01" ? Color.green : Color.gray)
                                                    }
                                                    .frame(width: geo.size.width * 0.20, alignment: .topLeading)
                                                }
                                                //}
                                            }
                                            //}
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
            .navigationBarItems(leading: self.device.isConnected ? Text("Connected") : Text("Disconnected"))
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
                Text("Return and disconnect")
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
