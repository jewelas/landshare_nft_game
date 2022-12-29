// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IHouse.sol";
import "../interface/ISetting.sol";
import "../interface/IHelper.sol";
import "../settings/constants.sol";

contract Validator is Ownable {

    IERC20 landToken;
    ISetting setting;
    IHouse house;
    IHelper helper;

    address private gameContractAddress;

    constructor(
        address _landToken,
        address _settingAddress,
        address _houseAddress,
        address _helperAddres
    ) {
        landToken = IERC20(_landToken);
        setting = ISetting(_settingAddress);
        house = IHouse(_houseAddress);
        helper = IHelper(_helperAddres);
    }

    function setGameContractAddress(address _address) external onlyOwner {
        gameContractAddress = _address;
    }

    function canRepair(uint tokenId, uint percent, address sender) external view returns (bool) {
        address user;
        bool activated;
        uint deadTime;
        (user, activated, deadTime) = house.getOwnerAndStatus(tokenId);
        require(deadTime == 0, "House is dead");
        require(activated, "Activation required");
        require(sender == user, "Repair: PD");
        require(percent > 0, "Percent should above 0");

        return true;
    }

    function canUpgradeFacility(uint tokenId, uint facilityType, address sender) external view returns (bool) {
        address user;
        bool activated;
        uint deadTime;
        (user, activated, deadTime) = house.getOwnerAndStatus(tokenId);
        require(deadTime == 0, "House is dead");
        require(activated, "Activation required");
        require(sender == user, "Facility: PD");
        require(facilityType < 5, "Invalid facilty type");

        return true;
    }

    function canHarvest(uint tokenId, bool[5] memory harvestingReward, address sender) external view returns (bool, uint, uint) {
        address user;
        bool activated;
        uint deadTime;
        (user, activated, deadTime) = house.getOwnerAndStatus(tokenId);
        require(activated, "Activation required");
        require(sender == user, "Harvest: PD");
        
        uint harvestTokenAmount;

        if (harvestingReward[0]) {
            harvestTokenAmount = house.getTokenReward(tokenId);
            require(harvestTokenAmount > 0, "No amount for harvest");
            require(landToken.balanceOf(gameContractAddress) >= harvestTokenAmount, "Not enough landtoken");
        }

        return (true, harvestTokenAmount, deadTime);
    }

    function canBuyPowerWithLandtoken(uint tokenId, uint amount, uint totalPowerAmount, address sender) external view returns (bool, uint) {
        address user;
        bool activated;
        uint deadTime;
        (user, activated, deadTime) = house.getOwnerAndStatus(tokenId);
        require(activated, "Activation required");
        require(sender == user, "BuyPower: PD");
        require (amount > 0, "No amount paid");

        uint powerAmount = amount * setting.getPowerPerLandtoken();
        require(totalPowerAmount + powerAmount <= house.calculateMaxPowerLimitByUser(tokenId), "Exceed the max power limit");
        require(landToken.balanceOf(sender) >= amount, "Not enought landtoken");

        return (true, powerAmount);
    }

    function canGatherLumberWithPower(uint tokenId, uint amount, uint[3] memory lastGatherLumberTime, address sender) external view returns (bool) {
        address user;
        bool activated;
        uint deadTime;
        (user, activated, deadTime) = house.getOwnerAndStatus(tokenId);
        require(activated, "Activation required");
        require(sender == user, "GatherLumber: PD");

        bool havingTree = house.checkHavingTree(tokenId);
        if (havingTree) {
            require(amount == 1 || amount == 2 || amount == 3, "Invaild amount to gather");
        } else {
            require(amount == 1 || amount == 2, "Invaild amount to gather");
        }

        uint maxCountToGather = havingTree ? 3 : 2;
        uint countGatheredToday;

        for (uint i = 0; i < 3; i++)
            if (lastGatherLumberTime[i] + SECONDS_IN_A_DAY > block.timestamp) countGatheredToday++;

        require(countGatheredToday + amount <= maxCountToGather, "Exceed Gathering limit");

        return true;
    }

    function canFrontloadFirepit(uint tokenId, uint lumberAmount, address sender) external view returns (bool) {
        address user;
        bool activated;
        uint deadTime;
        (user, activated, deadTime) = house.getOwnerAndStatus(tokenId);
        require(deadTime == 0, "House is dead");
        require(activated, "Activation required");
        require(sender == user, "Frontload Firepit: PD");
        require(lumberAmount > 0, "No amount to fronload");
        require(lumberAmount <= 10 * PRECISION, "Exceed Frontload Lumbers");

        uint leftDays = house.getFirepitRemainDays(tokenId);
        require(leftDays + lumberAmount <= 10 * PRECISION, "Exceed Frontload Lumbers");

        return true;
    }

    function canBuyResourceOverdrive(uint tokenId, uint facilityType, address sender) external view returns (bool) {
        address user;
        bool activated;
        uint deadTime;
        (user, activated, deadTime) = house.getOwnerAndStatus(tokenId);
        require(deadTime == 0, "House is dead");
        require(activated, "Activation required");
        require(sender == user, "Buy Overdrive: PD");
        require(0 < facilityType && facilityType < 5, "Invalid facility type");
        require(house.canOverDrive(tokenId, facilityType), "Already in Overdrive");
        return true;
    }

    function canBuyTokenOverdrive(uint tokenId, address sender) external view returns (bool) {
        address user;
        bool activated;
        uint deadTime;
        (user, activated, deadTime) = house.getOwnerAndStatus(tokenId);
        require(deadTime == 0, "House is dead");
        require(activated, "Activation required");
        require(sender == user, "Buy Overdrive: PD");
        require(house.canOverDrive(tokenId, 0), "Already in Overdrive");

        return true;
    }

    function canBuyAddon(uint tokenId, uint addonId, address sender) external view returns (bool) {
        address owner;
        bool activated;
        bool[12] memory addons;
        uint deadTime;
        uint expireGardenTime;
        uint[3] memory lastFortificationTime;

        (owner, activated, deadTime, addons, expireGardenTime, lastFortificationTime) = house.getBuyAddonDetails(tokenId);
        require(deadTime == 0, "House is dead");
        require(activated, "Activation required");
        require(sender == owner, "BuyAddon: PD");
        
        require(
            addons[addonId] == false || 
            addonId == 2 && addons[2] && expireGardenTime < block.timestamp,
            "Addon already bought"
        );

        /// check dependencies
        uint[] memory dependency = setting.getBaseAddonDependency(addonId);
        bool isUnlocked = true;
        for (uint i = 0; i < dependency.length; i++) {
            if(addons[dependency[i]] == false) {
                isUnlocked = false;
            }
        }
        require(isUnlocked, "Need to buy dependency addons");

        /// Check fortification dependency
        uint fortDependency = setting.getBaseAddonFortDependency(addonId);
        if (fortDependency > 0) {
            require(lastFortificationTime[fortDependency - 1] > block.timestamp, "Doesn't meet fortification");
        }
        
        return true;
    }

    function canSalvageAddon(uint tokenId, uint addonId, address sender) external view returns (bool) {
        address user;
        bool activated;
        uint deadTime;
        (user, activated, deadTime) = house.getOwnerAndStatus(tokenId);
        require(deadTime == 0, "House is dead");
        require(activated, "Activation required");
        require(sender == user, "Salvage: PD");
        require(house.getHasAddon(tokenId, addonId), "Addon doesn't exist");

        return true;
    }

    function canFertilizeGarden(uint tokenId, address sender) external view returns (bool) {
        address user;
        bool activated;
        uint deadTime;
        (user, activated, deadTime) = house.getOwnerAndStatus(tokenId);
        require(deadTime == 0, "House is dead");
        require(activated, "Activation required");
        require(sender == user, "Fertilize Garden: PD");
        require(house.getHasAddon(tokenId, 2), "Garden should be active");

        return true;
    }

    function canBuyToolshed(uint tokenId, uint _type, address sender) external view returns (bool) {
        address user;
        bool activated;
        uint deadTime;
        (user, activated, deadTime) = house.getOwnerAndStatus(tokenId);
        require(deadTime == 0, "House is dead");
        require(activated, "Activation required");
        require(sender == user, "BuyToolshed: PD");
        require(_type > 0 && _type < 5, "Invalid Toolshed");
        bool[5] memory hasToolshed = house.getToolshed(tokenId);
        require(hasToolshed[_type] == false, "Already bought");

        return true;
    }

    function canSwitchToolshed(uint tokenId, uint _type, address sender) external view returns (bool, uint) {
        address user;
        bool activated;
        uint deadTime;
        (user, activated, deadTime) = house.getOwnerAndStatus(tokenId);
        require(deadTime == 0, "House is dead");
        require(activated, "Activation required");
        require (sender == user, "SwitchToolshed: PD");
        require (0 < _type && _type < 5, "Invalid type");

        uint activeToolshedType = house.getActiveToolshedType(tokenId);
        require (0 < activeToolshedType && activeToolshedType < 5, "Doesn't have an active one");

        bool[5] memory hasToolshed = house.getToolshed(tokenId);
        require (hasToolshed[_type] == true, "Did not buy yet");

        return (true, activeToolshedType);
    }

    function canBuyFireplace(uint tokenId, address sender) external view returns (bool) {
        address user;
        bool activated;
        uint deadTime;
        (user, activated, deadTime) = house.getOwnerAndStatus(tokenId);
        require(deadTime == 0, "House is dead");
        require(activated, "Activation required");
        require(sender == user, "BuyFireplace: PD");
        require(house.getHasFireplace(tokenId) == false, "Already have fireplace");

        return true;
    }

    function canBurnLumber(uint tokenId, uint lumber, uint userLumberResource, uint totalPowerAmout, address sender) external view returns (bool, uint) {
        address user;
        bool activated;
        uint deadTime;
        (user, activated, deadTime) = house.getOwnerAndStatus(tokenId);
        require(deadTime == 0, "House is dead");
        require(activated, "Activation required");
        require(sender == user, "BurnLumber: PD");
        require(lumber > 0, "No amount to burn");
        require(house.getHasFireplace(tokenId), "Fireplace need to be purchased"); 
        require(userLumberResource >= lumber, "Insufficient lumber");

        uint generatedPower = lumber * setting.getFireplaceBurnRatio() / 100;
        require(totalPowerAmout + generatedPower <= house.calculateMaxPowerLimitByUser(tokenId), "Exceed the max power limit");

        return (true, generatedPower);
    }

    function canBuyHarvester(uint tokenId, address sender) external view returns (bool) {
        address user;
        bool activated;
        uint deadTime;
        (user, activated, deadTime) = house.getOwnerAndStatus(tokenId);
        require(deadTime == 0, "House is dead");
        require(activated, "Activation required");
        require(sender == user, "BuyHarvester: PD");
        require(house.getHasHarvester(tokenId) == false, "Already have harvester");

        return true;
    }

    function canBuyConcreteFoundation(uint tokenId, address sender) external view returns (bool) {
        address user;
        bool activated;
        uint deadTime;
        (user, activated, deadTime) = house.getOwnerAndStatus(tokenId);
        require(deadTime == 0, "House is dead");
        require(activated, "Activation required");
        require(sender == user, "Concrete Foundation: PD");
        require(house.getHasConcreteFoundation(tokenId) == false, "Concrete Foundation Exist");

        return true;
    }

    function canHireHandyman(uint tokenId, address sender) external view returns (bool, uint) {
        address user;
        bool activated;
        uint deadTime;
        (user, activated, deadTime) = house.getOwnerAndStatus(tokenId);
        require(deadTime == 0, "House is dead");
        require(activated, "Activation required");
        require(sender == user, "HireHandyman: PD");
        require(house.getHireHandymanHiredTime(tokenId) < block.timestamp, "Already used");

        uint amount = 1 * PRECISION;
        require(landToken.balanceOf(sender) >= amount, "Not enough landtoken");

        return (true, amount);
    }
}
