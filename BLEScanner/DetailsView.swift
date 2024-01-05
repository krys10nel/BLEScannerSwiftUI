//
//  DetailsView.swift
//  BLEScanner
//
//  Created by Krystene Maceda on 11/30/23.
//

import SwiftUI

struct DetailsView: View {
    @ObservedObject var device : BluetoothScanner
    // @State var isOn : Bool = false
    
    // TODO: stay on device screen when disconnecting
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
                                // TODO: put this in another file or in another var
                                ForEach(device.discoveredCharacteristics, id: \.uuid) { characteristic in
                                    if characteristic.service.uuid == service.uuid {
                                        let properties = characteristic.characteristic.properties
                                        VStack {
                                            // Characteristic in service
                                            Spacer()
                                            Text("\(characteristic.uuid)")
                                                .frame(minWidth: 111, idealWidth: .infinity, maxWidth: .infinity, alignment: .leading)
                                            HStack {
                                                // TODO: add condition for nav strobe and position etc.
                                                if properties.contains(.write) {
                                                    HStack {
                                                        Button(action: {
                                                            print("Clicked on \(characteristic)")
                                                            // self.isOn.toggle()
                                                            // TODO: write value into characteristic
                                                            /*if characteristic.readValue == "01" {
                                                                let writeValue = Data([0x00])
                                                                write(writeValue, characteristic.characteristic)
                                                                
                                                                
                                                             } else {
                                                             
                                                             }*/
                                                        }) {
                                                            /*Image(systemName: self.isOn == true ? "poweron" : "poweroff")
                                                             .foregroundStyle(self.isOn == true ? Color.green : Color.red)
                                                             */
                                                            Image(systemName: "power.circle")
                                                                .imageScale(.large)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
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
