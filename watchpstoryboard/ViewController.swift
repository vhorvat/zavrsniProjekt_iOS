//
//  ViewController.swift
//  watchpstoryboard
//
//  Created by Viktor Horvat on 12.04.2022..
//

import UIKit
import CoreBluetooth
import CoreLocation
import UserNotifications
import Foundation


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @IBOutlet weak var tableView1: UITableView!
    @IBOutlet weak var tableView2: UITableView!
    
    var allData = ["","","","","","","","","","","","","","","","",""]
    var deviceNames = [String]()
    var centralManager: CBCentralManager!
    var myPeripheral: CBPeripheral!
    var wPeripheral: CBPeripheral!
    var wCharacteristic: CBCharacteristic!
    
    
    let notifCenter = UNUserNotificationCenter.current()
    var allBluetoothPeripherals = [CBPeripheral]()
    
    let arrayOfServices: [CBUUID] = [CBUUID(string: "5701")]
    
    var currentConnectedName = "NULL"
    var stateOfDoors = "1"
    var currentTemperature = 0
    
    
    func scheduleNotification(){
        let content = UNMutableNotificationContent()
        content.title = "FER Watchplant"
        content.body = "Dostupan je novi senzor u blizini"
        let date = Date().addingTimeInterval(1)
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let uuidString = UUID().uuidString
        
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
        notifCenter.add(request) { (error) in
                }
        print("NOTIFIKACIJA!")
    }
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            print("BLE STATE ON")
            deviceNames.removeAll()
            central.scanForPeripherals(withServices: arrayOfServices, options: nil)
        }
        else {
            print("BLE PROBLEM")
            currentConnectedName="Error"
        
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let pname = peripheral.name {
            print (pname)
            deviceNames.append(pname)
            allBluetoothPeripherals.append(peripheral)
            self.tableView1.reloadData()
            scheduleNotification()
            print(deviceNames)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Spajam se...")
        self.myPeripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print ("Services:\(String(describing : peripheral.services))")
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Uređaj:\(peripheral) i servis na njemu: \(service)")
        for charasteristic in service.characteristics! {
            if (charasteristic.uuid) == CBUUID(string: "EBCB181A-E01F-11EC-9D64-0242AC120002"){
                peripheral.setNotifyValue(true, for: charasteristic)
            }
            if (charasteristic.uuid) == CBUUID(string: "FA2AF5EC-E01F-11EC-9D64-0242AC120002"){
                print("I WROTE")
                wPeripheral=peripheral
                wCharacteristic=charasteristic
                peripheral.writeValue(stateOfDoors.data(using: .utf8)!, for: charasteristic, type: .withoutResponse)
            }
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if (characteristic.uuid) == CBUUID(string: "EBCB181A-E01F-11EC-9D64-0242AC120002"){
            let currentValue = characteristic.value
            let decodedString = String(bytes: currentValue!, encoding: .utf8)
            let dataArray = decodedString!.components(separatedBy: ",")
            let timestamp = dataArray[0]
            let tempPCB = Double(dataArray[1])!/10000
            let magX = Double(dataArray[2])!/1000
            let magY = Double(dataArray[3])!/1000
            let magZ = Double(dataArray[4])!/1000
            let tempExternal = Double(dataArray[5])!/10000
            let lightExternal = Double(dataArray[6])!/799.4 - 0.75056
            let humidityExternalTemp = Double(dataArray[7])!
            let humidityExternal = (humidityExternalTemp*3/4200000-0.1515)/(0.006707256-0.0000137376*(tempExternal/10000))
            let differentialPotentialCH1 = dataArray[8]
            let differentialPotentialCH2 = dataArray[9]
            let RFpowerEmission = dataArray[10]
            let transpiration = Double(dataArray[11])!/1000
            let airPressure = Double(dataArray[12])!/100
            let soilMoisture = dataArray[13]
            let soilTemperature = Double(dataArray[14])!/10
            let mu_mm = dataArray[15]
            let mu_id = dataArray[16]
            let sensorname = dataArray[17]
            
            self.allData[0] = String("Timestamp: \(timestamp) °C")
            self.allData[1] = String("TempPCB: \(tempPCB) °C")
            self.allData[2] = String("MagX: \(magX) G")
            self.allData[3] = String("MagY: \(magY) G")
            self.allData[4] = String("MagZ: \(magZ) G")
            self.allData[5] = String("External temperature: \(tempExternal) °C")
            self.allData[6] = String("External light: \(lightExternal) Lux")
            self.allData[7] = String("External humidity: \(humidityExternal) %")
            self.allData[8] = String("Differential CH1: \(differentialPotentialCH1) uV")
            self.allData[9] = String("Differential CH2: \(differentialPotentialCH2) uV")
            self.allData[10] = String ("RF Power Emission: \(RFpowerEmission)")
            self.allData[11] = ("Transpiration: \(transpiration) %")
            self.allData[12] = String("Air Pressure: \(airPressure) mBar")
            self.allData[13] = String("Soil Moisture: \(soilMoisture)")
            self.allData[14] = String("Soil Temperature: \(soilTemperature) °C")
            self.allData[15] = String("mu_mm: \(mu_mm)")
            self.allData[16] = String("mu_id: \(mu_id)")
            self.tableView2.reloadData()
            
            if (characteristic.uuid) == CBUUID(string: "FA2AF5EC-E01F-11EC-9D64-0242AC120002"){
                print("I READ WRITE VALUE")
                let currentValue = characteristic.value
                let decodedString = String(bytes: currentValue!, encoding: .utf8)
            }
        }
        //let value = [UInt8] (characteristic.value!)
        //print("Trenutna vrijednost DEBUG RAW GATT DATA:\(currentValue)")
        //let newValue = ((Int16(value[0])))
        //let newHumidValue = ((Int16(value[1])))
        //let intValue = Int(newValue)
        // print("Trenutna vrijednost DEBUG DECOUPLE:\(intValue)")
        // let interestedInValue=intValue
        //print("Trenutna vrijednost DEBUG DECODE:\(interestedInValue)")
        //print("Samo Humidty debuged:\(newHumidValue)")
        //let newPressureValue1 = ((Int16(value[2])))
        //let fixedPressureValue = "10" + String(newPressureValue1)
        //currentTemperature = interestedInValue
        //temperatureToShowLabel.text = String(interestedInValue) + " °C"
        //humidityToShowLabel.text = String(newHumidValue) + " %"
        //pressureToShowLabel.text = String(fixedPressureValue) + " hPa"
    }
    
    //FUNKCIJE ZA iBeacon LOKACIJU
    
    
    @IBOutlet weak var greenhouseSwitch: UISwitch!
    @IBAction func switchDidChange(_ sender: UISwitch){
        if sender.isOn{
            stateOfDoors="1"
            print("ON")
            wPeripheral.writeValue(stateOfDoors.data(using: .utf8)!, for: wCharacteristic, type: .withResponse)
            wPeripheral.readValue(for: wCharacteristic)
            greenHouseDoorStatus.text = "OPEN"
        } else {
            stateOfDoors="0"
            print("OFF")
            wPeripheral.writeValue(stateOfDoors.data(using: .utf8)!, for: wCharacteristic, type: .withResponse)
            wPeripheral.readValue(for: wCharacteristic)
            greenHouseDoorStatus.text = "CLOSED"
        }
    }

    @IBOutlet weak var greenHouseDoorState: UILabel!
    @IBOutlet weak var nameToShowLabel: UILabel!
    @IBOutlet weak var greenHouseDoorStatus: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        tableView1.delegate = self
        tableView1.dataSource = self
        
        tableView2.delegate = self
        tableView2.dataSource = self
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
    }
    //UI:
}

extension ViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.allBluetoothPeripherals[indexPath.row].delegate=self

        print ("Stisnuo si redak:\(indexPath.row)")
        
        self.myPeripheral = allBluetoothPeripherals[indexPath.row]
        
        nameToShowLabel.text = myPeripheral.name //UPDATE NAME
        
        centralManager.stopScan()
        centralManager.connect(allBluetoothPeripherals[indexPath.row], options: nil)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
extension ViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == tableView1{
            return deviceNames.count
        }
        print(allData.count)
        return allData.count
        }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == tableView1{
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = deviceNames[indexPath.row]
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text=allData[indexPath.row]
            return cell
        }
    }
}
