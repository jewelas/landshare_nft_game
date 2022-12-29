//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract IGameEvents {
    event UpdateResource(address indexed user, uint[5] updatedResource);
    event BuyPower(address indexed user, uint landtoken, uint power);
    event GatherLumber(address indexed user, uint lumberAmount, uint powerAmount);
    event UpgradeFacility(address indexed user, uint indexed tokenId, uint _type, uint level);
    event BuyAddon(address indexed user, uint indexed tokenId, uint addonId);
    event SalvageAddon(address indexed user, uint indexed tokenId, uint addonId);
    event BuyToolshed(address indexed user, uint indexed tokenId, uint _type);
    event SwitchToolshed(address indexed user, uint indexed tokenId, uint _fromType, uint _toType);
    event BuyFireplace(address indexed user, uint indexed tokenId);
    event BurnLumber(address indexed user, uint indexed tokenId, uint lumber, uint power);
    event BuyHarvester(address indexed user, uint indexed tokenId);
    event Repair(address indexed user, uint indexed tokenId, uint amount);
    event Fortify(address indexed user, uint indexed tokenId, uint _type);
    event Harvest(address indexed user, uint indexed tokenId, uint[5] harvestedResource);
    event Activate(address indexed user, uint indexed tokenId);
    event FrontloadFirepit(address indexed user, uint indexed tokenId, uint lumberAmount);
    event FertilizeGarden(address indexed user, uint indexed tokenId);
    event BuyResourceOverdrive(address indexed user, uint indexed tokenId, uint facilityType);
    event BuyTokenOverdrive(address indexed user, uint indexed tokenId);
    event ConcreteFoundation(address indexed user, uint indexed tokenId);
    event RepairByHandyman(address indexed user, uint indexed tokenId);
    event OnSale(address indexed user, uint indexed tokenId, uint indexed price);
    event OffSale(address indexed user, uint indexed tokenId);

}