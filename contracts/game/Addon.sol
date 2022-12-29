//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Resource.sol";
import "../interface/IValidator.sol";

contract Addon is Resource {

    IERC20 landToken;
    IValidator validator;

    constructor(
        address _settingAddress,
        address _houseAddress,
        address _helperAddress,
        address _validatorAddress
    ) Resource(_settingAddress, _houseAddress, _helperAddress) {
        validator = IValidator(_validatorAddress);
    }

    /** 
        @notice Buy base ddon
        @param tokenId: House NFT Id
        @param addonId: Addon id
    */
    function buyAddon(uint tokenId, uint addonId) external {
        if (!validator.canBuyAddon(tokenId, addonId, msg.sender)) return;
        
        /// Buy baseAddon: add baseAddon to house set value true
        uint[5] memory cost = setting.getBaseAddonCostById(addonId);
        subResource(msg.sender, tokenId, cost);

        house.setHasAddon(tokenId, true, addonId);

        emit BuyAddon(msg.sender, tokenId, addonId);
    }

    /** 
        @notice Salvage base addon
        @param tokenId: House NFT Id
        @param addonId: Addon id
    */
    function salvageAddon(uint tokenId, uint addonId) external {
        if (!validator.canSalvageAddon(tokenId, addonId, msg.sender)) return;

        bool[12] memory hasAddon = house.getHasAddons(tokenId);
        uint[5] memory sellCost;
        uint[5] memory salvageCost;
        (salvageCost, sellCost) = setting.getSalvageCost(addonId, hasAddon);

        subResource(msg.sender, tokenId, sellCost);
        addResource(msg.sender, salvageCost);

        house.setHasAddon(tokenId, false, addonId);

        emit SalvageAddon(msg.sender, tokenId, addonId);
    }

    /**
        @notice Fortilize Garden
        @param tokenId: House NFT Id
    */
    function fertilizeGarden(uint tokenId) external {
        if (!validator.canFertilizeGarden(tokenId, msg.sender)) return;

        subResource(msg.sender, tokenId, setting.getFertilizeGardenCost());

        // Update token reward and update lastFertilizedGardenTime
        house.fertilizeGarden(tokenId);

        emit FertilizeGarden(msg.sender, tokenId);
    }

    /**
        @notice Buy specific type of toolshed
        @param tokenId: House NFT Id
        @param _type: type of toolshed
     */
    function buyToolshed(uint tokenId, uint _type) external {
        if (!validator.canBuyToolshed(tokenId, _type, msg.sender)) return;
        
        uint[5] memory cost = setting.getToolshedBuildCost(_type);
        
        subResource(msg.sender, tokenId, cost);
        house.setToolshed(tokenId, _type);

        emit BuyToolshed(msg.sender, tokenId, _type);
    }

    /**
        @notice Switch type of toolshed
        @param tokenId: House NFT Id
        @param _type: type to switch
     */
    function switchToolshed(uint tokenId, uint _type) external {
        bool isValid;
        uint activeToolshedType;
        (isValid, activeToolshedType) = validator.canSwitchToolshed(tokenId, _type, msg.sender);
        if (!isValid) return;
        
        uint[5] memory cost = setting.getToolshedSwitchCost();
        subResource(msg.sender, tokenId, cost);
        house.setToolshed(tokenId, _type);

        emit SwitchToolshed(msg.sender, tokenId, activeToolshedType, _type);
    }

    /**
        @notice Buy fireplace
        @param tokenId: House NFT Id
    */
    function buyFireplace(uint tokenId) external {
        if (!validator.canBuyFireplace(tokenId, msg.sender)) return;
        
        uint[5] memory cost = setting.getFireplaceCost();

        subResource(msg.sender, tokenId, cost);
        house.setHasFireplace(tokenId, true);

        emit BuyFireplace(msg.sender, tokenId);
    }
    
    /**
        @notice Burn lumber to generate power on fireplace
        @param tokenId: House NFT Id
        @param lumber: Lumber amount to burn
    */
    function burnLumberToMakePower(uint tokenId, uint lumber) external {
        bool isValid;
        uint generatedPower;
        (isValid, generatedPower) = validator.canBurnLumber(tokenId, lumber, userResources[msg.sender][1], house.calculateUserPower(tokenId, userResources[msg.sender][0]), msg.sender);
        if (!isValid) return;

        /// Subtract lumber from user and add generated power to uer
        subResource(msg.sender, tokenId, [0, lumber, 0, 0, 0]);
        addResource(msg.sender, [generatedPower, 0, 0, 0, 0]);

        emit BurnLumber(msg.sender, tokenId, lumber, generatedPower);
    }

    /**
        @notice Buy harvester
        @param tokenId: House NFT Id
    */
    function buyHarvester(uint tokenId) external {
        if (!validator.canBuyHarvester(tokenId, msg.sender)) return;

        uint[5] memory cost = setting.getHarvesterCost();
        subResource(msg.sender, tokenId, cost);
        house.setHasHarvester(tokenId, true);

        emit BuyHarvester(msg.sender, tokenId);
    }

    /**
        @notice Buy concrete founcation
    */
    function buyConcreteFoundation(uint tokenId) external {
        if (!validator.canBuyConcreteFoundation(tokenId, msg.sender)) return;

        uint[5] memory cost = setting.getDurabilityDiscountCost();
        subResource(msg.sender, tokenId, cost);
        house.setHasConcreteFoundation(tokenId, true);

        emit ConcreteFoundation(msg.sender, tokenId);
    }

    /**
        @notice Hire handyman
    */
    function hireHandyman(uint tokenId) external payable {
        bool isValid;
        uint cost;
        (isValid, cost) = validator.canHireHandyman(tokenId, msg.sender);
        if (!isValid) return;

        landToken.transferFrom(msg.sender, address(this), cost);
        house.repairByHandyman(tokenId);

        emit RepairByHandyman(msg.sender, tokenId);
    }
}
