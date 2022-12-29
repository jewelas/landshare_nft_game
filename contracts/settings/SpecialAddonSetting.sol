// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AddonSetting.sol";

contract SpecialAddonSetting is AddonSetting {

    mapping(uint => uint[5]) private toolshedBuildCost;
    mapping(uint => uint[5]) private toolshedDiscountPercent;
    uint[5] private fireplaceCost; // fireplace cost
    uint[5] private harvesterCost; // harvester cost
    uint private fireplaceBurnRatio; // fireplace burn ratio: lumber * ratio/100 = power
    uint private harvesterReductionRatio; // harvester reduction ratio: powerAmountForHarvest * ratio = currentHarvestValue;
    uint[5] toolshedSwitchCost;
    uint durabilityDiscountPercent;
    uint[5] durabilityDiscountCost;
    uint overdrivePowerCost;
    uint lastingOverdriveDays;
    uint percentIncreasedByResourceOverdrive;
    uint percentIncreasedByTokenOverdrive;
    uint handymanLastDays;

    constructor () {
        // Initialize toolshoed build cost types => 1, 2, 3, 4
        toolshedBuildCost[1] = [10, 1, 0, 0, 0];
        toolshedBuildCost[2] = [10, 0, 1, 0, 0];
        toolshedBuildCost[3] = [10, 0, 0, 1, 0];
        toolshedBuildCost[4] = [10, 0, 0, 0, 1];

        // Initialize toolshoed build cost
        toolshedSwitchCost = [10, 0, 0, 0, 0];

        // Initialize toolshoed discount repair percent types => 1, 2, 3, 4
        toolshedDiscountPercent[1] = [30, 30, 0, 0, 0];
        toolshedDiscountPercent[2] = [30, 0, 30, 0, 0];
        toolshedDiscountPercent[3] = [30, 0, 0, 30, 0];
        toolshedDiscountPercent[4] = [30, 0, 0, 0, 30];

        // Initialize fireplace cost & ratio
        fireplaceCost = [0, 0, 2, 0, 0];
        fireplaceBurnRatio = 1000; // lumber * ratio/100 = power

        // Initialize fireplace cost & ratio
        harvesterCost = [0, 0, 0, 0, 8];
        harvesterReductionRatio = 50; // powerAmountForHarvest * ratio = currentHarvestValue;

        // Initialize concrete foundation durabilityReductionPercent
        durabilityDiscountPercent = 18;
        durabilityDiscountCost = [20, 0, 0, 8, 0];

        overdrivePowerCost = 15;
        lastingOverdriveDays = 1;
        percentIncreasedByResourceOverdrive = 130;
        percentIncreasedByTokenOverdrive = 105;

        // Initialize handyman last days and cost
        handymanLastDays = 7;
    }

    /// Allowd types : 1, 2, 3, 4
    modifier onlyToolshedType(uint _type) {
        require(_type > 0 && _type <= 4, "Not allowed toolshed types");
        _;
    }

    /**
        @notice Get Toolshed Setting
    */
    function getToolshedSetting() external view returns(uint[5][4] memory, uint[5] memory, uint[5][4] memory) {
        uint[5][4] memory buildCost;
        uint[5][4] memory discountPercent;

        for(uint i = 0; i < 4; i++) {
            buildCost[i] = toolshedBuildCost[i + 1];
            discountPercent[i] = toolshedDiscountPercent[i + 1];
        }

        return (
            buildCost,
            toolshedSwitchCost,
            discountPercent
        );
    }

    /**
        @notice Get special addon setting
    */
    function getSpecialAddonSetting() external view returns(
        uint[5] memory, 
        uint, 
        uint[5] memory, 
        uint, 
        uint, 
        uint[5] memory, 
        uint, 
        uint, 
        uint, 
        uint, 
        uint
        ) {
        return (
            fireplaceCost,
            fireplaceBurnRatio,
            harvesterCost,
            harvesterReductionRatio,
            durabilityDiscountPercent,
            durabilityDiscountCost,
            overdrivePowerCost,
            percentIncreasedByResourceOverdrive,
            percentIncreasedByTokenOverdrive,
            lastingOverdriveDays,
            handymanLastDays
        );
    }

    /** 
        @notice Get toolshed build cost based on type
        @param _type : toolshed type
        @return _resource array
    */
    function getToolshedBuildCost(uint _type) external view onlyToolshedType(_type) returns(uint[5] memory) {
        uint[5] memory cost;

        for (uint i = 0; i < 5; i++) {
            cost[i] = toolshedBuildCost[_type][i] * PRECISION;
        }

        return cost;
    }

    /** 
        @notice Set toolshed build cost based on type
        @param _type : toolshed type
    */
    function setToolshedBuildCost(uint _type, uint[5] memory _resource) external onlyOwner onlyToolshedType(_type) {
        toolshedBuildCost[_type] = _resource;
    }

    /** 
        @notice Get toolshed switch cost based on type
        @return _resource array
    */
    function getToolshedSwitchCost() external view returns(uint[5] memory) {
        uint[5] memory cost;

        for (uint i = 0; i < 5; i++) {
            cost[i] = toolshedSwitchCost[i] * PRECISION;
        }

        return cost;
    }

    /** 
        @notice Set toolshed switch cost
        @param _resource: resource cost in arrray
    */
    function setToolshedSwitchCost(uint8[5] memory _resource) external onlyOwner {
        toolshedSwitchCost = _resource;
    }

    /** 
        @notice Get toolshed discount percent based on type
        @param _type : toolshed type
        @return resource array
    */
    function getToolshedDiscountPercent(uint _type) external view onlyToolshedType(_type) returns(uint[5] memory)  {
        return toolshedDiscountPercent[_type];
    }

    /** 
        @notice Set toolshed discount percent based on type
        @param _type : toolshed type
    */
    function setToolshedDiscountPercent(uint _type, uint[5] memory _resource) external onlyOwner onlyToolshedType(_type) {
        toolshedDiscountPercent[_type] = _resource;
    }

    /** 
        @notice Get fireplace cost
        @return resource array (with PRECISION)
    */
    function getFireplaceCost() external view returns(uint[5] memory)  {
        uint[5] memory cost;

        for (uint i = 0; i < 5; i++) {
            cost[i] = fireplaceCost[i] * PRECISION;
        }

        return cost;
    }

    /** 
        @notice Set fireplace cost
        @param cost : fireplace cost -> resource type
    */
    function setFireplaceCost(uint[5] memory cost) external onlyOwner {
        fireplaceCost = cost;
    }

    /** 
        @notice Get fireplace burn ratio
        @return ratio value
    */
    function getFireplaceBurnRatio() external view returns (uint)  {
        return fireplaceBurnRatio;
    }

    /** 
        @notice Set fireplace burn ratio
        @param ratio : ratio value
    */
    function setFireplaceBurnRatio(uint ratio) external onlyOwner {
        fireplaceBurnRatio = ratio;
    }

    /** 
        @notice Get harvester cost
        @return resource array (with PRECISION)
    */
    function getHarvesterCost() external view returns(uint[5] memory)  {
        uint[5] memory cost;

        for (uint i = 0; i < 5; i++) {
            cost[i] = harvesterCost[i] * PRECISION;
        }

        return cost;
    }

    /** 
        @notice Set harvester cost
        @param cost : harvester cost -> resource type
    */
    function setHarvesterCost(uint[5] memory cost) external onlyOwner {
        harvesterCost = cost;
    }

    /** 
        @notice Get harvester reduction ratio
        @return ratio value
    */
    function getHarvesterReductionRatio() external view returns(uint)  {
        return harvesterReductionRatio;
    }

    /** 
        @notice Set harvester reduction ratio
        @param ratio : ratio value
    */
    function setHarvesterReductionRatio(uint ratio) external onlyOwner {
        harvesterReductionRatio = ratio;
    }

    /** 
        @notice Get durability discount percent
        @return durabilityDiscountPercent discount percent
    */
    function getDurabilityDiscountPercent() external view returns(uint)  {
        return durabilityDiscountPercent;
    }

    /** 
        @notice Set durabiity discount percent
        @param percent : discount percent
    */
    function setDurabilityDiscountPercent(uint percent) external onlyOwner {
        durabilityDiscountPercent = percent;
    }

    /** 
        @notice Get durability discount cost
        @return durabilityDiscountCost discount cost
    */
    function getDurabilityDiscountCost() external view returns(uint[5] memory)  {
        return durabilityDiscountCost;
    }

    /** 
        @notice Set durabiity discount cost
        @param cost : discount cost
    */
    function setDurabilityDiscountCost(uint[5] memory cost) external onlyOwner {
        durabilityDiscountCost = cost;
    }
    
    /**
        @notice Get Overdrive power cost
    */
    function getOverdrivePowerCost() external view returns(uint) {
        return overdrivePowerCost * PRECISION;
    }

    /**
        @notice Get Overdrive days
    */
    function getOverdriveDays() external view returns(uint) {
        return lastingOverdriveDays * SECONDS_IN_A_DAY;
    }
    
    /**
        @notice Get Resource Overdrive percent
    */
    function getResourceOverdrivePercent() external view returns(uint) {
        return percentIncreasedByResourceOverdrive;
    }

    /**
        @notice Get Token Overdrive percent
    */
    function getTokenOverdrivePercent() external view returns(uint) {
        return percentIncreasedByTokenOverdrive;
    }

    /** 
        @notice Get handyman last days
        @return handymanLastDays
    */
    function getHandymanLastDays() external view returns(uint) {
        return handymanLastDays * SECONDS_IN_A_DAY;
    }

    /** 
        @notice Set handyman last days
        @param lastDays: handyman last days
    */
    function setHandymanLastDays(uint lastDays) external onlyOwner {
        handymanLastDays = lastDays;
    }

}
