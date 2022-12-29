// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./DurabilitySetting.sol";

contract Setting is DurabilitySetting {

    mapping(uint => mapping(uint => uint[5])) private facilityUpgradeCost;
    mapping(uint => mapping(uint => uint)) private resourceGenerationAmount;
    uint[5] private powerLimit; // power limit: default to 100
    uint[5] private repairBaselineCost; // repair baseline cost: resource type
    uint private powerAmountForHarvest; // power amount required when harvest: default to 10
    uint private powerPerLandtoken; // power amount to buy using land token: default to 25
    uint private powerPerLumber;
    uint private standardMultiplier;
    uint private rareMultiplier;
    uint private resourceGenerationLimit;
    uint[2] private harvestLimit;

    constructor() {
        // Maximium amount to harvest token in house
        harvestLimit[0] = 1000;
        harvestLimit[1] = 2500;

        // Resource Limit
        resourceGenerationLimit = 10;

        // Set multiplier
        standardMultiplier = 50 * PRECISION / 10;
        rareMultiplier = 55 * PRECISION / 10;

        // Wind Farm upgarde cost
        facilityUpgradeCost[0][1] = [0, 0, 0, 0, 0];
        facilityUpgradeCost[0][2] = [25, 3, 0, 0, 0];
        facilityUpgradeCost[0][3] = [30, 0, 4, 0, 0];
        facilityUpgradeCost[0][4] = [35, 0, 0, 4, 0];
        facilityUpgradeCost[0][5] = [40, 0, 0, 0, 4];

        // Lumber Mill upgrade cost
        facilityUpgradeCost[1][1] = [20, 0, 0, 0, 0];
        facilityUpgradeCost[1][2] = [25, 3, 0, 0, 0];
        facilityUpgradeCost[1][3] = [30, 6, 0, 0, 0];
        facilityUpgradeCost[1][4] = [35, 7, 4, 3, 0];
        facilityUpgradeCost[1][5] = [40, 8, 6, 4, 4];

        // Brick Factory upgrade cost
        facilityUpgradeCost[2][1] = [20, 4, 0, 0, 0];
        facilityUpgradeCost[2][2] = [25, 4, 4, 0, 0];
        facilityUpgradeCost[2][3] = [30, 4, 6, 2, 0];
        facilityUpgradeCost[2][4] = [35, 6, 7, 6, 0];
        facilityUpgradeCost[2][5] = [40, 6, 8, 6, 4];

        // Concrete Plant upgrade cost
        facilityUpgradeCost[3][1] = [35, 6, 4, 0, 0];
        facilityUpgradeCost[3][2] = [40, 4, 4, 3, 0];
        facilityUpgradeCost[3][3] = [45, 4, 4, 4, 2];
        facilityUpgradeCost[3][4] = [50, 4, 4, 5, 4];
        facilityUpgradeCost[3][5] = [55, 6, 6, 6, 4];

        // Steel Mill upgrade cost
        facilityUpgradeCost[4][1] = [40, 6, 6, 3, 0];
        facilityUpgradeCost[4][2] = [45, 4, 4, 4, 3];
        facilityUpgradeCost[4][3] = [50, 5, 5, 5, 4];
        facilityUpgradeCost[4][4] = [55, 6, 6, 6, 5];
        facilityUpgradeCost[4][5] = [60, 6, 6, 6, 6];

        // Initialize facility production amount
        for (uint8 i = 0; i < 5; i++) {
            if (i == 0) {
                resourceGenerationAmount[i][1] = 15;
                resourceGenerationAmount[i][2] = 20;
                resourceGenerationAmount[i][3] = 25;
                resourceGenerationAmount[i][4] = 30;
                resourceGenerationAmount[i][5] = 35;
            } else if (i == 1 || i == 2) {
                resourceGenerationAmount[i][1] = 2;
                resourceGenerationAmount[i][2] = 3;
                resourceGenerationAmount[i][3] = 4;
                resourceGenerationAmount[i][4] = 5;
                resourceGenerationAmount[i][5] = 6;
            } else if (i == 3 || i == 4) {
                resourceGenerationAmount[i][1] = 1;
                resourceGenerationAmount[i][2] = 2;
                resourceGenerationAmount[i][3] = 3;
                resourceGenerationAmount[i][4] = 4;
                resourceGenerationAmount[i][5] = 5;
            }
        }    
        
        // Initialize power production limit based on wind farm level
        powerLimit = [100, 110, 120, 125, 130];

        // Initialize harvest power amount to 10
        powerAmountForHarvest = 10;

        // Initialize repair home cost: resource type
        repairBaselineCost = [10, 0, 0, 0, 0];

        // Initialize power amount per land token
        powerPerLandtoken = 100;

        // Initialize power amount per lumber
        powerPerLumber =  15;
    }

    /// Allowd Levels : 1, 2, 3, 4, 5
    modifier onlyAllowedLevel(uint _level) {
        require(_level > 0 && _level <= 5, "Not allowed facility levels");
        _;
    }

    /// Allowed types : [0, 1, 2, 3, 4 ] = [power, lumber, brick, concrete, steel]
    modifier onlyAllowedType(uint _type) {
        require(_type < 5, "Undefined resource type");
        _;
    }

    /**
        @notice Get facility cost and yield
    */
    function getFacilitySetting() external view returns(uint[5][5][5] memory, uint[5][5] memory) {
        uint[5][5][5] memory cost;
        uint[5][5] memory yield;

        for (uint i = 0; i < 5; i++) {  // faclity type
            for (uint j = 0; j < 5; j++) {  // facility level
                yield[i][j] = resourceGenerationAmount[i][j + 1];

                for (uint k = 0; k < 5; k++) {
                    cost[i][j][k] = facilityUpgradeCost[i][j + 1][k];
                }
            }
        }

        return (cost, yield);
    }

    /**
        @notice Get setting details for multiplier check
    */
    function getDetailsForMultiplierCalc(bool isRare) external view returns(uint, uint, uint) {
        return (
            isRare ? rareMultiplier : standardMultiplier,
            fertilizedGardenMultiplier,
            percentIncreasedByTokenOverdrive
        );
    }

    /**
        @notice Get setting details for Helper contract
    */
    function getDetailsForHelper(bool isRare, bool hasConcreteFoundation) external view returns(uint[4] memory) {
        uint[4] memory settingData = [
            isRare ? rareMultiplier : standardMultiplier, 
            fertilizedGardenMultiplier, 
            percentIncreasedByTokenOverdrive,
            hasConcreteFoundation ? durabilityDiscountPercent * PRECISION : durabilityReductionPercent * PRECISION
        ];

        return settingData;
    }

    /**
        @notice Get standard multiplier
        @return standardMultiplier:  standard multiplier
    */
    function getStandardMultiplier() external view returns(uint) {
        return standardMultiplier;
    }

    /**
        @notice Set standard multiplier
        @param multiplier: standard multiplier
    */
    function setStandardMultiplier(uint multiplier) external onlyOwner {
        standardMultiplier = multiplier * PRECISION / 10;
    }

    /**
        @notice Get rare multiplier
        @return rareMultiplier: rare multiplier
    */
    function getRareMultiplier() external view returns(uint) {
        return rareMultiplier;
    }

    /**
        @notice Set rare multiplier
        @param multiplier: standard multiplier
    */
    function setRareMultiplier(uint multiplier) external onlyOwner {
        rareMultiplier = multiplier * PRECISION / 10;
    }

    /**
        @notice Get resource generation limit per harvest
    */
    function getResourceGenerationLimit() external view returns(uint) {
        return resourceGenerationLimit * PRECISION;
    }

    /**
        @notice Set resource generation limit per harvest
        @param limit: limit value
    */
    function setResourceGenerationLimit(uint limit) external onlyOwner {
        resourceGenerationLimit = limit;
    }

    /** 
        @notice Get facility upgrade cost based facility type and level
        @param _type: facility type
        @param _level: facility level
        @return resource array with PRECISION
    */
    function getFacilityUpgradeCost(uint _type, uint _level) external view onlyAllowedType(_type) onlyAllowedLevel(_level) returns(uint[5] memory) {
        uint[5] memory cost;
        for (uint i = 0; i < 5; i++) {
            cost[i] = uint(facilityUpgradeCost[_type][_level][i]) * PRECISION;
        }

        return cost;
    }

    /** 
        @notice Set facility upgrade cost based facility type and level
        @param _type: resource type
        @param _level: facility level
    */
    function setFacilityUpgradeCost(uint _type, uint _level, uint[5] memory _resource) external onlyOwner onlyAllowedLevel(_level) onlyAllowedType(_type)  { 
        facilityUpgradeCost[_type][_level] = _resource;
    }

    /** 
        @notice Get resource generation amount based on facility type and level
        @param _type: facility type
        @param _level: facility level
        @return generation amount
    */
    function getResourceGenerationAmount(uint _type, uint _level) external view onlyAllowedType(_type) onlyAllowedLevel(_level) returns(uint) {
        return resourceGenerationAmount[_type][_level] * PRECISION;
    }

    /** 
        @notice Set resource generation amount based on facility type and level
        @param _type: facility type
        @param _level: facility level
        @param amount: resource generation amount per type and level
    */
    function setResourceGenerationAmount(uint _type, uint _level, uint amount) external onlyOwner onlyAllowedLevel(_level) onlyAllowedType(_type) { 
        resourceGenerationAmount[_type][_level] = amount;
    }

    /** 
        @notice Get Power max capabillity per user by wind farm level
        @param level : wind farm level
        @return power limit
    */
    function getPowerLimit(uint level) external view onlyAllowedLevel(level) returns(uint) {
        return powerLimit[level-1] * PRECISION;
    }

    /** 
        @notice Set Power max capabillity per user by wind farm level
        @param powerAmount: Power amount for each levels -> [100, 200, 300, 400, 500]
    */
    function setPowerLimit(uint[5] memory powerAmount) external onlyOwner {
        powerLimit = powerAmount;
    }

    /** 
        @notice get power amount required when harvest
        @return power amount
    */
    function getPowerAmountForHarvest() external view returns(uint) {
        return powerAmountForHarvest * PRECISION;
    }

    /** 
        @notice set power amount required when harvest
        @param amount: power amount required for harvest 
    */
    function setPowerAmountForHarvest(uint amount) external onlyOwner {
        powerAmountForHarvest = amount;
    }    

    /** 
        @notice get repair baseline cost
        @return baselinecost -> resource type
    */
    function getRepairBaselineCost() external view returns(uint[5] memory) {
        uint[5] memory repairCost;
        for (uint i = 0; i < 5; i++) {
            repairCost[i] = uint(repairBaselineCost[i]) * PRECISION;
        }

        return repairCost;
    }

    /** 
        @notice set repair baseline cost
        @param cost: baseline cost resource type
    */
    function setRepairBaselineCost(uint[5] memory cost) external onlyOwner {
        repairBaselineCost = cost;
    }

    /** 
        @notice Get power amount per 1 land token
        @return power amount
    */
    function getPowerPerLandtoken() external view returns(uint) {
        return powerPerLandtoken;
    }

    /** 
        @notice Set power amount per 1 land token
        @param amount: power amount
    */
    function SetPowerPerLandtoken(uint amount) external onlyOwner {
        powerPerLandtoken = amount;
    }

    /** 
        @notice Get power amount per 1 lumber
        @return power amount
    */
    function getPowerPerLumber() external view returns(uint) {
        return powerPerLumber;
    }

    /** 
        @notice Set power amount per 1 lumber
        @param amount: power amount
    */
    function SetPowerPerLumber(uint amount) external onlyOwner {
        powerPerLumber = amount;
    }

    /**
        @notice Maximium amount to harvest token
        @param isRare: baseline multiplier
    */
    function getHarvestLimit(bool isRare) external view returns (uint) {
        uint _type = isRare ? 1 : 0;
        return harvestLimit[_type] * PRECISION;
    }

    function setHarvestLimit(uint standardLimmit, uint rareLimit) external onlyOwner {
        harvestLimit[0] = standardLimmit;
        harvestLimit[1] = rareLimit;
    }
}
