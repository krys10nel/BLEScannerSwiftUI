//
//  DetailsView.swift
//  BLEScanner
//
//  Created by Krystene Maceda on 11/30/23.
//

import SwiftUI

struct DetailsView: View {
    @ObservedObject var device : BluetoothScanner
    
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
                                    // TODO: fit id into list, no wrapping
                                    Text("\(service.uuid)")
                                        .frame(minWidth: 111, idealWidth: .infinity, maxWidth: .infinity, alignment: .leading)
                                    Spacer()
                                }
                                //characteristicView
                                //TODO: input characteristics for services
                                ForEach(device.discoveredCharacteristics, id: \.uuid) { characteristic in
                                    if characteristic.service.uuid == service.uuid {
                                        Button(action: {
                                            print("Clicked on \(characteristic.uuid)")
                                        }) {
                                            VStack {
                                                HStack {
                                                        Image(systemName: "togglepower")
                                                            .imageScale(.large)
                                                        Text("\(characteristic.uuid)")
                                                            .frame(minWidth: 111, idealWidth: .infinity, maxWidth: .infinity, alignment: .leading)
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
