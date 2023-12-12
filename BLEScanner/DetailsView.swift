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
                    List($device.discoveredServices, id: \.id) { discoveredServices in
                        Button(action: {
                            print("Clicked on \(discoveredServices)")
                        }) {
                            VStack {
                                HStack {
                                    Text("\(discoveredServices.id)")
                                        .frame(minWidth: 111, idealWidth: .infinity, maxWidth: .infinity, alignment: .leading)
                                    Spacer()
                                }
                                characteristicView
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
    
    private var characteristicView: some View {
        //TODO: input characteristics for services
        List {
            HStack {
                Text("Characteristic 1")
                    .font(.caption)
                    .foregroundStyle(.gray)
                Spacer()
            }
        }
    }
}

#Preview {
    DetailsView(device: BluetoothScanner())
}
