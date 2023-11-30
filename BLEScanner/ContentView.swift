//
//  ContentView.swift
//  BLEScanner
//
//  Created by Christian Möller on 02.01.23.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @ObservedObject private var bluetoothScanner = BluetoothScanner()
    @State private var searchText = ""
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.font : UIFont(name: "Helvetica-Bold", size: 25)!]
    }

    var body: some View {
        NavigationView {
            VStack {
                // Text field for entering search text
                TextField("Search",
                          text: $searchText)
                .onAppear{UITextField.appearance().clearButtonMode = .whileEditing}
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
                deviceCards
                
                Spacer()
                // Button for starting or stopping scanning
                Button(action: {
                    if self.bluetoothScanner.isScanning {
                        self.bluetoothScanner.stopScan()
                    } else {
                        self.bluetoothScanner.startScan()
                    }
                }) {
                    if bluetoothScanner.isScanning {
                        Text("Stop Scanning")
                    } else {
                        Text("Scan for Devices")
                    }
                }
                // Button looks cooler this way on iOS
                .padding()
                .background(bluetoothScanner.isScanning ? Color.red : Color.blue)
                .foregroundColor(Color.white)
                .cornerRadius(5.0)
            }
            .navigationBarTitle(Text("Bluetooth Devices"))
            .navigationViewStyle(StackNavigationViewStyle())
            .padding()
        }
    }
    
    private var deviceCards: some View {
        // List of discovered peripherals filtered by search text
        List(bluetoothScanner.discoveredPeripherals.filter {
            self.searchText.isEmpty ? true : $0.peripheral.name?.lowercased().contains(self.searchText.lowercased()) == true
        }, id: \.peripheral.identifier) { discoveredPeripheral in
            Button(action: {
                print("Connecting to " + (discoveredPeripheral.peripheral.name ?? "Unknown Device"))
            }) {
                Text(discoveredPeripheral.peripheral.name ?? "Unknown Device")
                    .frame(minWidth: 111, idealWidth: .infinity, maxWidth: .infinity, alignment: .leading)
                Text(discoveredPeripheral.advertisedData)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            .frame(minWidth: 111, idealWidth: .infinity, maxWidth: .infinity, alignment: .leading)
        }
        .listStyle(PlainListStyle())
    }
}

struct SuperTextField: View {
    var placeholder: Text
    @Binding var text: String
    var editingChanged: (Bool)->() = { _ in }
    var commit: ()->() = { }
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty { placeholder }
            TextField(
                "",
                text: $text,
                onEditingChanged: editingChanged,
                onCommit: commit
            )
        }
    }
}

struct Previews: PreviewProvider {
    static var previews: some View {
        ContentView().preferredColorScheme(.dark)
        ContentView().preferredColorScheme(.light)
    }
}
