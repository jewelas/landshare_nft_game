// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SpecialAddonSetting.sol";

contract DurabilitySetting is SpecialAddonSetting {

    uint public durabilityReductionPercent; // durability reduction percent: default to 10%
    uint private fortLastDays; // fortification last days: default to set 7 days
    uint[5][3] private fortifyCost;

    constructor() {
        // Initialize durability reduction percent to 20 % / 48 hours
        durabilityReductionPercent = 20;

        // Initialize fortification last days
        fortLastDays = 7;

        // Initialize fortification power cost
        fortifyCost[0] = [30, 0, 4, 0, 0];
        fortifyCost[1] = [30, 0, 0, 14, 0];
        fortifyCost[2] = [30, 0, 0, 0, 14];
    }

    /**
        @notice Get durability setting
    */
    function getDurabilitySetting() external view returns(uint, uint[5][3] memory) {
        return (
            fortLastDays,
            fortifyCost
        );
    }

    /** 
        @notice Get durability reduction percent
        @return Reduction percent
    */
    function getDurabilityReductionPercent(bool hasConcreteFoundation) external view returns(uint) {
        return hasConcreteFoundation ? durabilityDiscountPercent * PRECISION : durabilityReductionPercent * PRECISION;
    }

    /** 
        @notice Set durability reduction percent
        @param percent: Durabiity reduction percent
    */
    function setDurabilityReductionPercent(uint percent) external onlyOwner {
        durabilityReductionPercent = percent;
    }

     /** 
        @notice Get fortification last days
        @return Last days
    */
    function getFortLastDays() external view returns(uint) {
        return fortLastDays * SECONDS_IN_A_DAY;
    }

    /** 
        @notice Set fortification last days
        @param lastDays: Fortification last days
    */
    function setFortLastDays(uint lastDays) external onlyOwner {
        fortLastDays = lastDays;
    }

    /** 
        @notice Get fortification cost
        @return _type: Fortification type
    */
    function getFortifyCost(uint _type) external view returns(uint[5] memory) {
        uint[5] memory cost;
        for(uint i = 0; i < 5; i++)
            cost[i] = fortifyCost[_type][i] * PRECISION;

        return cost;
    }

    /** 
        @notice Set fortification cost
        @param _type: Fortification type: 0 -> Brick, 1 -> Concrete, 2 -> Steel
        @param cost: Fortification resource cost
    */
    function setFortifyCost(uint _type, uint[5] memory cost) external onlyOwner {
        require(_type < 3, "Invalid type");
        fortifyCost[_type] = cost;
    }

}