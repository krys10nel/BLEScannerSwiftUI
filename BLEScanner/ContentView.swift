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
                NavigationLink("", destination: DetailsView(device: bluetoothScanner), isActive: $bluetoothScanner.isConnected)
                    
                // TODO: get rid of the space between search bar and navigation title
                // TODO: add loading screen

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
        GeometryReader { geo in
            List(bluetoothScanner.discoveredPeripherals.filter {
                self.searchText.isEmpty ? true : $0.deviceName.lowercased().contains(self.searchText.lowercased()) == true
            }, id: \.id) { discoveredPeripherals in
                Button(action: {
                    self.bluetoothScanner.connectPeripheral(discoveredPeripherals)
                }) {
                    HStack {
                            // RSSI to symbol, normalized to range 0-1 using max -40 and min -105
                            // rssi < -80 is far, > -50 is immediate, between is near
                            // distance = 0.76 is full bars, 0.25 is dot
                            // ((-28.0)/Double(discoveredPeripherals.rssi))
                            if #available(iOS 16.0, *) {
                                VStack(alignment: .leading) {
                                     Image(systemName: "dot.radiowaves.up.forward", variableValue: (Double(discoveredPeripherals.rssi)+105)/(-40+105))
                                        .imageScale(.large)
                                        .foregroundStyle(.blue, .gray)
                                     Spacer()
                                }
                                .frame(width: geo.size.width * 0.10, alignment: .top)
                             } else {
                                 VStack(alignment: .leading) {
                                     Text(String(Int(pow(10, ((-56-Double(discoveredPeripherals.rssi))/(10*2)))*3.2808)) + "m")
                                     Spacer()
                                 }
                                 .frame(width: geo.size.width * 0.14, alignment: .topLeading)
                            }
                        
                        
                        VStack {
                            Text(discoveredPeripherals.deviceName)
                                .frame(minWidth: 0, idealWidth: .infinity, maxWidth: .infinity, alignment: .leading)
                            Spacer()
                            Text("\(discoveredPeripherals.id)\n"/* + "Services: \(discoveredPeripherals.advertisedData["kCBAdvDataServiceUUIDs"] ?? "None Found")"*/)
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                    }
                    .padding(.vertical)

                }
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                .frame(minWidth: 200, idealWidth: .infinity, maxWidth: .infinity, alignment: .leading)
            }
            .listStyle(PlainListStyle())
        }
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
