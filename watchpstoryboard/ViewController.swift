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
    
    @IBOutlet var tableView: UITableView!
    var deviceNames = [String]()
    var centralManager: CBCentralManager!
    var myPeripheral: CBPeripheral!
    let notifCenter = UNUserNotificationCenter.current()
    var allBluetoothPeripherals = [CBPeripheral]()
    
    let arrayOfServices: [CBUUID] = [CBUUID(string: "0x180A")]
    
    var currentConnectedName = "NULL"
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
            self.tableView.reloadData()
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
        //for charasteristic in service.characteristics! {
          //  print("KARAKTERISTIKA")
            //peripheral.setNotifyValue(true, for: charasteristic)
            //print(peripheral.readValue(for: charasteristic))
        //}
        print(peripheral.readValue(for: service.characteristics![0]))

        
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let currentValue=characteristic.value
        print(characteristic.service)
        let value = [UInt8] (characteristic.value!)
        print("Trenutna vrijednost DEBUG RAW GATT DATA:\(currentValue)")
        let newValue = ((Int16(value[0])))
        let newHumidValue = ((Int16(value[1])))
        let intValue = Int(newValue)
        print("Trenutna vrijednost DEBUG DECOUPLE:\(intValue)")
        let interestedInValue=intValue
        print("Trenutna vrijednost DEBUG DECODE:\(interestedInValue)")
        print("Samo Humidty debuged:\(newHumidValue)")
        let newPressureValue1 = ((Int16(value[2])))
        let fixedPressureValue = "10" + String(newPressureValue1)
        currentTemperature = interestedInValue
        temperatureToShowLabel.text = String(interestedInValue) + " °C"
        humidityToShowLabel.text = String(newHumidValue) + " %"
        pressureToShowLabel.text = String(fixedPressureValue) + " hPa"
    }
    
    //FUNKCIJE ZA iBeacon LOKACIJU
    
    
    

    @IBOutlet weak var pressureToShowLabel: UILabel!
    @IBOutlet weak var humidityToShowLabel: UILabel!
    @IBOutlet weak var nameToShowLabel: UILabel!
    @IBOutlet weak var temperatureToShowLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        tableView.delegate = self
        tableView.dataSource = self
        
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
        print (deviceNames.count)
        return deviceNames.count
        }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = deviceNames[indexPath.row]
        return cell
    }
}
