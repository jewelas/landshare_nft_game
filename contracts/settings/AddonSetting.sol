// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../settings/constants.sol";

contract AddonSetting is Ownable {

    uint[5][12] private baseAddonCost;
    uint[5] private baseAddonSellCost;
    uint[12] public baseAddonMultiplier;
    mapping(uint => uint[]) private baseAddonDependency;  /// addon dependency
    mapping(uint => uint[]) private requiredAddons;  /// required addon
    uint[12] public baseAddonFortDependency;  /// addon fortification dependency
    uint private baseAddonSalvagePercent;
    uint private lastingGardenDays;
    uint[5] private fertilizeGardenCost;
    uint private lastingFertilizedGardenDays;
    uint public fertilizedGardenMultiplier;

    constructor () {
        uint[] memory dataArr1 = new uint[](1);
        uint[] memory dataArr2 = new uint[](2);

        /**
            0 : Hardwood Floors
            1 : Landscaping
            2 : Garden -> requires [Landscaping]
            3 : Tree
            4 : Kitchen Model
            5 : Bathroom Remodel
            6 : Jacuzzi Tub -> requires [Bathroom Remodel]
            7 : Steel Sliding -> requires [Concrete Fortification]
            8 : Steel Application -> requires [Kitchen model]
            9 : Root cellar -> requires [Brick fortification]
            10: Finished Basement -> requires [Kitchen model and Bathroom Remodel] & [Steel Fortification]
            11: Firepit
        */

        /// Initialize base addon build cost
       
        baseAddonCost[0] = [uint(20), 2, 0, 0, 0];
        baseAddonCost[1] = [uint(20), 0, 5, 0, 0];
        baseAddonCost[2] = [uint(30), 0, 0, 0, 0];
        baseAddonCost[3] = [uint(20), 3, 0, 0, 0];
        baseAddonCost[4] = [uint(20), 6, 6, 3, 0];
        baseAddonCost[5] = [uint(20), 6, 4, 5, 0];
        baseAddonCost[6] = [uint(20), 0, 0, 8, 0];
        baseAddonCost[7] = [uint(20), 0, 0, 0, 8];
        baseAddonCost[8] = [uint(20), 0, 0, 0, 6];
        baseAddonCost[9] = [uint(20), 6, 8, 0, 2];
        baseAddonCost[10] = [uint(30), 8, 8, 8, 8];
        baseAddonCost[11] = [uint(20), 0, 2, 0, 0];

        /// Addon sell cost
        baseAddonSellCost = [uint(20), 0, 0, 0, 0];

        /// Initialize base addon multiplier
        baseAddonMultiplier[0] = 110;
        baseAddonMultiplier[1] = 105;
        baseAddonMultiplier[2] = 105;
        baseAddonMultiplier[3] = 110;
        baseAddonMultiplier[4] = 110;
        baseAddonMultiplier[5] = 115;
        baseAddonMultiplier[6] = 105;
        baseAddonMultiplier[7] = 110;
        baseAddonMultiplier[8] = 105;
        baseAddonMultiplier[9] = 110;
        baseAddonMultiplier[10] = 115;
        baseAddonMultiplier[11] = 115;

        /// Landscaping addon dependency require: Garden
        dataArr1[0] = 1;
        baseAddonDependency[2] = dataArr1;
        /// Jacuzzi Tub addon dependency require: Bathroom Remodel
        dataArr1[0] = 5;
        baseAddonDependency[6] = dataArr1;
        /// Steel appliances addon dependency require: Kitchen Model
        dataArr1[0] = 4;
        baseAddonDependency[8] = dataArr1;
        /// Finished Basement adddon dependency require: Kitchen Model & Bathroom Remodel
        dataArr2[0] = 4;
        dataArr2[1] = 5;
        baseAddonDependency[10] = dataArr2;

        dataArr1[0] = 2;
        requiredAddons[1] = dataArr1;

        dataArr2[0] = 8;
        dataArr2[1] = 10;
        requiredAddons[4] = dataArr2;

        dataArr2[0] = 6;
        dataArr2[1] = 10;
        requiredAddons[5] = dataArr2;

        /// Initialize base addon fortification dependency 1 => brick, 2 => concrete, 3 => steel
        baseAddonFortDependency[7] = 2;
        baseAddonFortDependency[9] = 1;
        baseAddonFortDependency[10] = 3;

        /// Initialize base addon salvage percent
        baseAddonSalvagePercent = 50;

        /// Initialize expire days after garden is purchased
        lastingGardenDays = 7;

        /// Initialize fertilizing garden setting
        fertilizeGardenCost = [uint(10), 0, 3, 0, 0];
        lastingFertilizedGardenDays = 3;
        fertilizedGardenMultiplier = 110;
    }

    /**
        @notice Get addon setting
    */
    function getAddonSetting() external view returns(uint[5][12] memory, uint[12] memory, uint[5] memory, uint, uint) {
        return (
            baseAddonCost,
            baseAddonMultiplier,
            fertilizeGardenCost,
            lastingFertilizedGardenDays,
            fertilizedGardenMultiplier
        );
    }

    /** 
        @notice Get base addon cost
        @return Base addon cost
    */
    function getBaseAddonCost() external view returns (uint[5][12] memory) {
        return baseAddonCost;
    }

    /** 
        @notice Get base addon cost
        @param id: Addon id
        @return Addon cost -> resource type
    */
    function getBaseAddonCostById(uint id) external view returns (uint[5] memory) {
        uint[5] memory cost;

        for (uint i = 0; i < 5; i++) cost[i] = baseAddonCost[id][i] * PRECISION;

        return cost;
    }

    /** 
        @notice Set base addon cost
        @param id: Addon id
        @param cost: Addon cost -> resource type
    */
    function setBaseAddonCost(uint id, uint[5] memory cost) external onlyOwner {
        baseAddonCost[id] = cost;
    }

    /**
        @notice Set addon sell cost
        @param sellCost: Sell cost per addon
    */
    function setBaseAddonSellCost(uint[5] memory sellCost) external onlyOwner {
        baseAddonSellCost = sellCost;
    }

    /** 
        @notice Get base addon multiplier
        @return Addon multiplier
    */
    function getBaseAddonMultiplier() external view returns (uint[12] memory) {
        return baseAddonMultiplier;
    }

    /** 
        @notice Set base addon multiplier
        @param id: Addon id
        @param multiplier: Addon multiplier
    */
    function setBaseAddonMultiplier(uint id, uint multiplier) external onlyOwner {
        baseAddonMultiplier[id] = multiplier;
    }

    /** 
        @notice Get base addon dependency
        @param id: Addon id
        @return Addon dependency
    */
    function getBaseAddonDependency(uint id) external view returns (uint[] memory) {
        return baseAddonDependency[id];
    }

    /** 
        @notice Set base addon dependency
        @param id: Addon id
        @param dependency: dependency
    */
    function setBaseAddonDependency(uint id, uint[] memory dependency) external onlyOwner {
        baseAddonDependency[id] = dependency;
    }

    /** 
        @notice Get required addons
        @param id: Addon id
        @return requiredAddons
    */
    function getRequiredAddons(uint id) external view returns (uint[] memory) {
        return requiredAddons[id];
    }

    /** 
        @notice Set requried addons
        @param id: Addon id
        @param addons: required addons
    */
    function setRequiredAddons(uint id, uint[] memory addons) external onlyOwner {
        requiredAddons[id] = addons;
    }

    /** 
        @notice Get addon fortification dependency
        @param id : Addon id
        @return Addon fortification dependency
    */
    function getBaseAddonFortDependency(uint id) external view returns (uint) {
        return baseAddonFortDependency[id];
    }

    /** 
        @notice Set addon fortification dependency
        @param id: Addon id
        @param fortDependency: 1 => brick, 2 => concrete, 3 => steel
    */
    function setBaseAddonFortDependency(uint id, uint fortDependency) external onlyOwner {
        baseAddonFortDependency[id] = fortDependency;
    }

    /** 
        @notice Get base addon salvage percent
        @return Addon salvage percent
    */
    function getBaseAddonSalvagePercent() external view returns (uint) {
        return baseAddonSalvagePercent;
    }

    /** 
        @notice Set base addon salvage percent
        @param percent: Salvage percent
    */
    function setBaseAddonSalvagePercent(uint percent) external onlyOwner {
        baseAddonSalvagePercent = percent;
    }

    /**
        @notice Get lasting days after garden is purchased
        @return number of days
    */
    function getLastingGardenDays() external view returns (uint) {
        return lastingGardenDays * SECONDS_IN_A_DAY;
    }

    /**
        @notice Set lasting days after garden is purchased
        @param numberOfDays: days
    */
    function setLastingGardenDays(uint numberOfDays) external onlyOwner {
        lastingGardenDays = numberOfDays;
    }

    /**
        @notice Get fertilizing Cost
     */
    function getFertilizeGardenCost() external view returns (uint[5] memory) {
        uint[5] memory cost;

        for (uint i = 0; i < 5; i++) cost[i] = fertilizeGardenCost[i] * PRECISION;

        return cost;
    }
    
    /**
        @notice Get fertilizing lasting days
     */
    function getFertilizeGardenLastingDays() external view returns (uint) {

        return lastingFertilizedGardenDays * SECONDS_IN_A_DAY;
    }

    /**
        @notice Get multiplier if garden is fertiized
    */
    function getFertilizedGardenMultiplier() external view returns (uint) {
        return fertilizedGardenMultiplier;
    }

    /**
        @notice Set multiplier if garden is fertiized
    */
    function setFertilizedGardenMultiplier(uint multiplier) external onlyOwner {
        fertilizedGardenMultiplier = multiplier;
    }

    /**
        @notice Get sum of cost for salvaging a addon and addons depends on it
        @param addonId: addon Id
        @return salvageCost: salavage cost, sellCost: sell cost for addon
    */
    function getSalvageCost(uint addonId, bool[12] memory hasAddon) external view returns (uint[5] memory, uint[5] memory) {
        uint[5] memory salvageCost;
        uint[5] memory sellCost;

        uint count = 1;
        for (uint i = 1; i < 5; i++) salvageCost[i] = baseAddonCost[addonId][i] * PRECISION;

        for (uint i = 0; i < requiredAddons[addonId].length; i++) {
            if (requiredAddons[addonId][i] == 2) continue;
            
            if (hasAddon[requiredAddons[addonId][i]]) {
                for (uint j = 1; j < 5; j++) salvageCost[j] += baseAddonCost[requiredAddons[addonId][i]][j] * PRECISION;

                count++;
            }
        }

        for (uint i = 1; i < 5; i++)
            salvageCost[i] = salvageCost[i] * baseAddonSalvagePercent / 100;
        
        for (uint i  = 0; i < 5; i++)
            sellCost[i] = baseAddonSellCost[i] * count * PRECISION;

        return (salvageCost, sellCost);
    }
}
