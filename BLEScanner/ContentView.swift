//
//  ContentView.swift
//  BLEScanner
//
//  Created by Christian Möller on 02.01.23.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @ObservedObject var bluetoothScanner = BluetoothScanner()
    @State private var searchText = ""
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.font : UIFont(name: "Helvetica-Bold", size: 25)!]
    }

    var body: some View {
        NavigationView {
            VStack {
                NavigationLink("", destination: DetailsView().environmentObject(bluetoothScanner), isActive: $bluetoothScanner.isConnected)
                
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
                .padding()
                .background(bluetoothScanner.isScanning ? Color.red : Color.blue)
                .foregroundColor(Color.white)
                .cornerRadius(5.0)
            }
            .navigationBarTitle(Text("Bluetooth Devices"))
            .navigationBarItems(trailing: bluetoothScanner.isPowered ? Text("Bluetooth ON").foregroundColor(.green) : Text("Bluetooth OFF").foregroundColor(.red))
            .navigationViewStyle(StackNavigationViewStyle())
            .padding()
        }
    }
    
    private var deviceCards: some View {
        // List of discovered peripherals filtered by search text
        List(bluetoothScanner.discoveredPeripherals.filter {
            self.searchText.isEmpty ? true : $0.deviceName.lowercased().contains(self.searchText.lowercased()) == true
        }, id: \.id) { discoveredPeripherals in
            Button(action: {
                self.bluetoothScanner.connectPeripheral(discoveredPeripherals)
            }) {
                VStack {
                    HStack {
                        // TODO: replace rssi numbers with images
                        Text(String(discoveredPeripherals.rssi))
                        Text(discoveredPeripherals.deviceName)
                            .frame(minWidth: 111, idealWidth: .infinity, maxWidth: .infinity, alignment: .leading)
                        Spacer()
                    }
                    Text("\(discoveredPeripherals.id)\n" + "Services: \(discoveredPeripherals.advertisedData["kCBAdvDataServiceUUIDs"] ?? "None Found")")
                     .font(.caption)
                     .foregroundColor(.gray)
                }
                .padding(.vertical)
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
