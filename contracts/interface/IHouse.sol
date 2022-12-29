//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract IHouse {
    function activate(uint tokenId) external virtual;
    function getHasAddons(uint tokenId) external view virtual returns (bool[12] memory);

    function getHousesByOwner(address _owner) public view virtual returns (uint[] memory);
    function getActiveHouseByOwner(address _owner) public view virtual returns(uint);
    function getOwnerAndStatus(uint tokenId) public view virtual returns (address, bool, uint);

    function getDepositedBalance(uint tokenId) public view virtual returns (uint);
    function deposit(uint tokenId, uint balance) public virtual;
    function withdraw(uint tokenId, uint balance) public virtual;
    
    function getTokenReward(uint tokenId) public view virtual returns (uint);
    function getHasConcreteFoundation(uint tokenId) external view virtual returns (bool);
    function setHasConcreteFoundation(uint tokenId, bool hasConcreteFoundation) external virtual;
    
    function getHasAddon(uint tokenId, uint addonId) public view virtual returns (bool);
    function setHasAddon(uint tokenId, bool addon, uint addonId) public virtual;
    
    function getHasFireplace(uint tokenId) public view virtual returns (bool);
    function setHasFireplace(uint tokenId, bool hasFireplace) public virtual;
    
    function getHasHarvester(uint tokenId) public view virtual returns (bool);
    function setHasHarvester(uint tokenId, bool hasHarvester) public virtual;
    
    function getToolshed(uint tokenId) public view virtual returns (bool[5] memory);
    function setToolshed(uint tokenId, uint _type) external virtual;

    function getActiveToolshedType(uint tokenId) public view virtual returns (uint);
    
    function getFacilityLevel(uint tokenId, uint _type) public view virtual returns (uint);
    function setFacilityLevel(uint tokenId, uint _level) public virtual;
    
    function getLastFortificationTime(uint tokenId) public view virtual returns (uint[3] memory);
    function setLastFirepitTime(uint tokenId, uint amount) external virtual;

    function getFirepitRemainDays(uint tokenId) external view virtual returns (uint);

    function setAfterHarvest(uint tokenId, bool[5] memory harvestingReward, uint harvestTokenAmount) external virtual;
    function setPowerRewardTime(uint tokenId) external virtual;

    function getResourceReward(uint tokenId) external view virtual returns (uint[5] memory);
    function calculateUserPower(uint tokenId, uint userPowerAmount) external view virtual returns(uint);
    function calculateMaxPowerLimitByUser(uint tokenId) public view virtual returns(uint);

    function checkHavingTree(uint tokenId) external view virtual returns (bool);
    function fertilizeGarden(uint tokenId) external virtual;

    function setAfterRepair(uint tokenId, uint repairedDurability) external virtual;
    function setAfterFortify(uint tokenId, uint _type) external virtual;
    function buyResourceOverdrive(uint tokenId, uint facilityType) external virtual;
    function buyTokenOverdrive(uint tokenId) external virtual;
    function canOverDrive(uint tokenId, uint facilityType) external view virtual returns(bool);

    function getHireHandymanHiredTime(uint tokenId) public view virtual returns(uint);
    function repairByHandyman(uint tokenId) external virtual;

    function validateHarvest(uint tokenId) external view virtual returns (bool);
    function getAddonSalvageCost(uint tokenId, uint addonId) external view virtual returns(uint[5] memory, uint[5] memory);
    function getBuyAddonDetails(uint tokenId) external view virtual returns (address, bool, uint, bool[12] memory, uint, uint[3] memory);
    function getHelperDetails(uint tokenId) external view virtual returns (bool, bool, uint, uint, uint, uint, uint, uint, uint, bool, bool);
    
    function getHasaddonAndToolshedType(uint tokenId) external view virtual returns(bool[12] memory, uint);
    function setOnsale(uint tokenId, bool isSale) external virtual;
}
