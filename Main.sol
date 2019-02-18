pragma solidity ^0.4.24;

contract Combined {
    
    //measurements
    
    struct SmartMeter{
        address owner;
        string place;
    }

    struct Metering {
        uint smID;
        uint timestamp;
        uint production;
        uint consumption;
    }
    
    struct Storage {
        address owner;
        uint capacity;
    }
    
    uint lastBlockNum;
    
    uint numMetering;
    uint numSmartMeter;
    uint numStorage;

    int currentProduction;
    int currentConsumption;
    int energyState;
    int energyStateCalc;
    int capacityTotal;
    int capacityLoad;
    int overload;
    int energyLack;
    uint pointerEnergy;
    uint pointerCapacity;
    uint pointerManagement;
    
    SmartMeter[] public smartMetersArray;
    Metering[] public meteringsArray;
    Storage[] public storagesArray;
    address[] public ownersOfSmartMeterArray;
    address[] public ownersOfStorageArray;
    
    mapping (uint => Metering) public meteringsMap;
    mapping (uint => SmartMeter) public smartMetersMap;
    mapping (address => uint[]) public ownerToSmartMeterIdMap;
    mapping (uint => Storage) public storagesMap;
    mapping (address => uint[]) public ownerToStorageIdMap;
    
    event energyStateChangedEvent(int prod, int cons, int energy);
    event capacityTotalUpdatedEvent(int totalCapacity);
    event energyManagementEvent(int capacityLoad, int overload, int energyLack);

    //add new metering
    function newMetering(uint _smID, uint _production, uint _consumption) public returns (uint meteringID) {
        meteringID = numMetering++;
        meteringsMap[meteringID] = Metering(_smID, now, _production, _consumption);
        meteringsArray.push(Metering(_smID, now, _production, _consumption));
        currentEnergyState();
        EnergyManagementFunc();
    }
    
    //add new smart meter
    function newSmartMeter(string _place) public returns (uint smartMeterID) {
        smartMeterID = numSmartMeter++;
        smartMetersMap[smartMeterID] = SmartMeter(msg.sender, _place);
        smartMetersArray.push(SmartMeter(msg.sender, _place));
        if (ownerToSmartMeterIdMap[msg.sender].length == 0) {
            ownersOfSmartMeterArray.push(msg.sender);
        }
        ownerToSmartMeterIdMap[msg.sender].push(smartMeterID);
    }
    
    function newStorage(uint _capacity) public returns (uint storageID) {
        storageID = numStorage++;
        storagesMap[storageID] = Storage(msg.sender, _capacity);
        storagesArray.push(Storage(msg.sender, _capacity));
        if (ownerToStorageIdMap[msg.sender].length == 0) {
            ownersOfStorageArray.push(msg.sender);
        }
        ownerToStorageIdMap[msg.sender].push(storageID);
        currentCapacity();   
    }

    //energy management
    
    function currentEnergyState() internal  {
        if (meteringsArray.length > pointerEnergy) {
            uint i = pointerEnergy;
            energyStateCalc = 0;
            if (lastBlockNum < block.number) {
                energyState = 0;
                currentProduction = 0;
                currentConsumption = 0;
                lastBlockNum = block.number;
            }

            for (i; i < meteringsArray.length; i++) {
                energyState = energyState + int(meteringsArray[i].production);
                energyState = energyState - int(meteringsArray[i].consumption);
                currentProduction = currentProduction + int(meteringsArray[i].production);
                currentConsumption = currentConsumption + int(meteringsArray[i].consumption);
                
                energyStateCalc = energyStateCalc + int(meteringsArray[i].production);
                energyStateCalc = energyStateCalc - int(meteringsArray[i].consumption);
            }
            pointerEnergy = meteringsArray.length;
        }
        emit energyStateChangedEvent(currentProduction, currentConsumption, energyState);
    }
    
    function getEnergyState() public view returns(int) {
        return energyState;
    }
    
    function getProduction() public view returns(int) {
        return currentProduction;
    }
    
    function getConsumption() public view returns(int) {
        return currentConsumption;
    }
    
    function currentCapacity() internal {
        if (storagesArray.length > pointerCapacity) {
            uint i = pointerCapacity;
            for (i; i<storagesArray.length; i++) {
                capacityTotal = capacityTotal + int(storagesArray[i].capacity);
            }
            pointerCapacity = storagesArray.length;
        }
        emit capacityTotalUpdatedEvent(capacityTotal);
    }
    
    function getCapacity() public view returns(int) {
        return capacityTotal;
    }
    
    function EnergyManagementFunc() internal {
        if (meteringsArray.length > pointerManagement) {
            if (energyStateCalc > 0) {
                if (capacityLoad + energyStateCalc <= capacityTotal) {
                    capacityLoad = capacityLoad + energyStateCalc;
                } else {
                    int extraEnergy = capacityLoad + energyStateCalc;
                    overload = overload + (extraEnergy - capacityTotal);
                    capacityLoad = capacityTotal;
                }
            }
            if (energyStateCalc < 0) {
                if (capacityLoad + energyStateCalc >= 0) {
                    capacityLoad = capacityLoad + energyStateCalc;
                } else {
                    int lack = energyStateCalc - capacityLoad;
                    energyLack = energyLack + lack;
                }
            }
            pointerManagement = meteringsArray.length;
        }
        emit energyManagementEvent(capacityLoad, overload, energyLack);
    }
    
    function getCapacityLoad() public view returns(int) {
        return capacityLoad;
    }
    
    function getOverload() public view returns(int) {
        return overload;
    }
    
    function getEnergyLack() public view returns(int) {
        return energyLack;
    }

}
