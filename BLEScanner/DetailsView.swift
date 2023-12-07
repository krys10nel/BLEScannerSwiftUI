//
//  DetailsView.swift
//  BLEScanner
//
//  Created by Krystene Maceda on 11/30/23.
//

import SwiftUI

struct DetailsView: View {
    @EnvironmentObject var device : BluetoothScanner
    
    var body: some View {
        NavigationView{
            VStack {
                List(device.discoveredServices, id: \.id) { discoveredServices in
                    VStack {
                        Text("\(discoveredServices.id)")
                        characteristicView
                    }
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
        Text("Characteristic 1")
    }
}

#Preview {
    DetailsView().environmentObject(BluetoothScanner())
}
