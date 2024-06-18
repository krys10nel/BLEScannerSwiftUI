//
//  ContentView.swift
//  BLEScanner
//
//  Created by Krystene Maceda on 11/30/23.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @State private var isLoading = true
    @ObservedObject var bluetoothScanner = BluetoothScanner()
    @State private var searchText = ""
    @State private var showingSheet = false
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.font : UIFont(name: "Helvetica-Bold", size: 25)!]
    }

    var body: some View {
        Group {
            if isLoading {
                StartUpLoadingView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                isLoading = false
                            }
                        }
                    }
            } else {
                NavigationView {
                    VStack {
                        NavigationLink("", destination: DetailsView(device: bluetoothScanner), isActive: $bluetoothScanner.isConnected)
                        
                        // Text field for entering search text
                        //                TextField("Search",
                        //                          text: $searchText)
                        //                .onAppear{UITextField.appearance().clearButtonMode = .whileEditing}
                        //                .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        ZStack {
                            deviceCards
                            // Company info button
                            VStack {
                                Spacer()
                                Button(action: {showingSheet.toggle()}) {
                                    Image(systemName: "questionmark.circle")
                                        .resizable()
                                        .frame(width: 35.0, height: 35.0)
                                        .padding(5)
                                        .background(.blue)
                                        .foregroundStyle(.white)
                                        .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/, style: /*@START_MENU_TOKEN@*/FillStyle()/*@END_MENU_TOKEN@*/)
                                }
                                .sheet(isPresented: $showingSheet) {
                                    SheetView()
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(10)
                        }
                        
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
                        .foregroundStyle(Color.white)
                        .cornerRadius(5.0)
                        Spacer()
                    }
                    .navigationTitle(Text("Bluetooth Devices"))
                    .navigationBarTitleDisplayMode(.automatic)
                    .navigationBarItems(trailing: bluetoothScanner.isPowered ? Text("BT ON").foregroundStyle(.green) : Text("BT OFF").foregroundStyle(.red))
                    .searchable(text: $searchText)
                }
            }
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
                    self.bluetoothScanner.stopScan()
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
                            Text("\(discoveredPeripherals.id)")
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

struct SheetView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            ZStack {
                HStack {
                    Spacer()
                    Text("Contact Us")
                        .font(.title)
                        .padding()
                    Spacer()
                }
                HStack {
                    Spacer()
                    Button("Dismiss") {
                        dismiss()
                    }
                    .font(.callout)
                    .padding()
                }
            }
            
            ScrollView {
                HStack {
                    Text("Application in development for ZipTip Vegas")
                        .padding(15)
                    Spacer()
                }
                
                HStack {
                    Text("""
                        **_Aveo Engineering_**
                            377 Palm Coast Pkwy S.W. Unit 1
                            Palm Coast, FL 32137 USA
                            jake@aveoengineering.com
                    
                            Pribram Airport-LKPM, Drasov 202,
                            261 01 Drasov, Czech republic
                            petra@aveoengineering.com
                    """).padding(20)
                    Spacer()
                }
                
                HStack {
                    Text("Please feel free to contact us via email:")
                        .padding(15)
                    Spacer()
                }
                
                HStack {
                    Text("""
                    General Inquiries (Aviation, Marine, Vehicle, Specialty Lighting):
                        inquiry@aveoengineering.com
                    General Sales:
                        sales@aveoengineering.com
                    Aircraft Manufacturer:
                        oem@aveoengineering.com
                    Military/Defense:
                        defense@aveoengineering.com
                    """).padding(.leading, 20)
                    Spacer()
                }.padding(.bottom, 20)
                
                HStack {
                    Text("Visit www.aveoengineering.com for more information")
                        .padding(15)
                    Spacer()
                }
            }
        }
    }
}

//struct SuperTextField: View {
//    var placeholder: Text
//    @Binding var text: String
//    var editingChanged: (Bool)->() = { _ in }
//    var commit: ()->() = { }
//    
//    var body: some View {
//        ZStack(alignment: .leading) {
//            if text.isEmpty { placeholder }
//            TextField(
//                "",
//                text: $text,
//                onEditingChanged: editingChanged,
//                onCommit: commit
//            )
//        }
//    }
//}

struct Previews: PreviewProvider {
    static var previews: some View {
        ContentView().preferredColorScheme(.dark)
        ContentView().preferredColorScheme(.light)
    }
}
