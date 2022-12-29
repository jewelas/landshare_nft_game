//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract IValidator {
    function canRepair(uint tokenId, uint percent, address sender) external view virtual returns (bool);
    function canUpgradeFacility(uint tokenId, uint facilityType, address sender) external view virtual returns (bool);
    function canHarvest(uint tokenId, bool[5] memory harvestingReward, address sender) external view virtual returns (bool, uint, uint);
    function canBuyPowerWithLandtoken(uint tokenId, uint amount, uint totalPowerAmount, address user) external view virtual returns (bool, uint);
    function canGatherLumberWithPower(uint tokenId, uint amount, uint[3] memory lastGatherLumberTime, address sender) external view virtual returns (bool);
    function canFrontloadFirepit(uint tokenId, uint lumberAmount, address sender) external view virtual returns (bool);
    function canBuyResourceOverdrive(uint tokenId, uint facilityType, address sender) external view virtual returns (bool);
    function canBuyTokenOverdrive(uint tokenId, address sender) external view virtual returns (bool);
    function canBuyAddon(uint tokenId, uint addonId, address sender) external view virtual returns (bool);
    function canSalvageAddon(uint tokenId, uint addonId, address sender) external view virtual returns (bool);
    function canFertilizeGarden(uint tokenId, address sender) external view virtual returns (bool);
    function canBuyToolshed(uint tokenId, uint _type, address sender) external view virtual returns (bool);
    function canSwitchToolshed(uint tokenId, uint _type, address sender) external view virtual returns (bool, uint);
    function canBuyFireplace(uint tokenId, address sender) external view virtual returns (bool);
    function canBurnLumber(uint tokenId, uint lumber, uint userLumberResource, uint totalPowerAmout, address sender) external view virtual returns (bool, uint);
    function canBuyHarvester(uint tokenId, address sender) external view virtual returns (bool);
    function canBuyConcreteFoundation(uint tokenId, address sender) external view virtual returns (bool);
    function canHireHandyman(uint tokenId, address sender) external view virtual returns (bool, uint);
}
