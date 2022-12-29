// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IHouse.sol";
import "../interface/ISetting.sol";
import "../settings/constants.sol";

contract Helper is Ownable {

    ISetting setting;
    IHouse house;

    uint[5][12] private baseAddonCost;
    uint[12] public baseAddonMultiplier;
    uint[12] public baseAddonFortDependency;

    constructor(
        address _settingAddress,
        address _houseAddress
    ) {
        setting = ISetting(_settingAddress);
        house = IHouse(_houseAddress);

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

        /// Initialize base addon fortification dependency 1 => brick, 2 => concrete, 3 => steel
        baseAddonFortDependency[7] = 2;
        baseAddonFortDependency[9] = 1;
        baseAddonFortDependency[10] = 3;
    }

    function setSettingAndHouseContractAddress(address _settingAddress, address _houseAddress) external onlyOwner {
        setting = ISetting(_settingAddress);
        house = IHouse(_houseAddress);
    }

    /** 
        @notice Get current multiplier of house
        @param tokenId: House NFT Id
        @return multiplier (with PRECISION)
    */
    function getMultiplierAtTimestamp(uint tokenId, uint timestamp) internal view returns (uint) {
        uint multiplier;
        uint expireGardenTime;
        uint lastFirepitTime;
        uint lastFertilizedGardenTime;
        uint fertilizedGardenMultiplier;

        {
            bool isRare;
            bool hasTokenBoost;
            uint baseMultiplier;
            uint tokenOverdrivePercent;
            
            (isRare, hasTokenBoost, expireGardenTime, lastFirepitTime, lastFertilizedGardenTime, , , , , ,) = house.getHelperDetails(tokenId);
            (baseMultiplier, fertilizedGardenMultiplier, tokenOverdrivePercent) = setting.getDetailsForMultiplierCalc(isRare);
            multiplier = baseMultiplier;

            if (hasTokenBoost)
                multiplier = multiplier * tokenOverdrivePercent / 100;
        }
        
        {
            bool[12] memory hasAddon = house.getHasAddons(tokenId);
            uint[3] memory lastFortificationTime = house.getLastFortificationTime(tokenId);

            for(uint i = 0; i < 12; i++) {
                if (hasAddon[i]) {
                    if (i == 2 && expireGardenTime < timestamp) continue;
                    if (i == 11 && lastFirepitTime < timestamp) continue;

                    /// Check fortification dependency
                    if (baseAddonFortDependency[i] > 0 && lastFortificationTime[baseAddonFortDependency[i] - 1] <= timestamp) {
                        continue;
                    }

                    if (i == 2 && lastFertilizedGardenTime > timestamp)
                        multiplier = multiplier *  fertilizedGardenMultiplier / 100;
                    else 
                        multiplier = multiplier * baseAddonMultiplier[i] / 100;
                }
            }
        }

        return multiplier;
    }

    function getMultiplierAtBreakpoint(uint timestamp, bool[12] memory hasAddon, bool hasTokenBoost, uint[3] memory lastFortificationTime, uint[4] memory timeData, uint[4] memory  settingData) internal view returns (uint) {
        /**
            timeData[0] - expire garden time
            timeData[1] - last firepit time 
            timeData[2] - last fertilized garden time 
            timeData[3] - last repair time 
        */
        uint multiplier = settingData[0];
        if (hasTokenBoost)
            multiplier = multiplier * settingData[2] / 100;
        
        for(uint i = 0; i < 12; i++) {
            if (hasAddon[i]) {
                if (i == 2 && timeData[0] < timestamp) continue;
                if (i == 11 && timeData[1] < timestamp) continue;

                /// Check fortification dependency
                if (baseAddonFortDependency[i] > 0 && lastFortificationTime[baseAddonFortDependency[i] - 1] <= timestamp) {
                    continue;
                }

                if (i == 2 && timeData[2] > timestamp)
                    multiplier = multiplier *  settingData[1] / 100;
                else 
                    multiplier = multiplier * baseAddonMultiplier[i] / 100;
            }
        }

        return multiplier;
    }

    /** 
        @notice Get count of fortification at given timestamp
        @param tokenId: House NFT id
        @return count of fortification
    */
    function getCountOfFortificationAtTimestamp(uint tokenId, uint timestamp) private view returns (uint) {
        uint[3] memory lastFortificationTime = house.getLastFortificationTime(tokenId);
        uint count;

        for (uint i = 0; i < 3; i++) {
            if (timestamp < lastFortificationTime[i]) count++;
        }

        return count;
    }

    /** 
        @notice Get durability of house at given timestamp
        @param tokenId: House NFT Id
        @param timestamp: block timestamp
        @return Durability in percent (with PRECISION)
    */
    function getDurabilityAtTimestamp(uint tokenId, uint timestamp) public view returns (uint) {
        uint lastRepairTime;
        uint lastDurability;
        bool hasConcreteFoundation;
        (, , , , , lastRepairTime, , lastDurability, , hasConcreteFoundation, ) = house.getHelperDetails(tokenId);
        uint durabilityReductionPercent = setting.getDurabilityReductionPercent(hasConcreteFoundation);
        
        uint daysSinceRepair = (timestamp - lastRepairTime) / SECONDS_IN_TWO_DAY;
        for (uint i = 0; i < daysSinceRepair; i++) {
            if(lastDurability < durabilityReductionPercent) {
                return 0;
            } else {
                lastDurability -= durabilityReductionPercent;
            }
        }

        uint expectedDurabilityByFortification = 100 * PRECISION + getCountOfFortificationAtTimestamp(tokenId, timestamp) * 10 * PRECISION;
        
        if (expectedDurabilityByFortification < lastDurability) {
            lastDurability = expectedDurabilityByFortification;
        }

        return lastDurability;  
    }

    function getDurabilityAtBreakpoint(uint timestamp, uint durabilityReductionPercent, uint[3] memory lastFortificationTime, uint[4] memory timeData, uint lastDurability) public pure returns (uint) {
        // timeData[3] - last repair time

        uint daysSinceRepair = (timestamp - timeData[3]) / SECONDS_IN_TWO_DAY;
        for (uint i = 0; i < daysSinceRepair; i++) {
            if(lastDurability < durabilityReductionPercent) {
                return 0;
            } else {
                lastDurability -= durabilityReductionPercent;
            }
        }

        uint count;
        for (uint i = 0; i < 3; i++) {
            if (timestamp < lastFortificationTime[i]) count++;
        }

        uint expectedDurabilityByFortification = 100 * PRECISION + count * 10 * PRECISION;
        
        if (expectedDurabilityByFortification < lastDurability) {
            lastDurability = expectedDurabilityByFortification;
        }

        return lastDurability;  
    }

    /** 
        @notice Get current max durability based on fortification
        @param tokenId: House NFT id
        @return max durability (With Precision)
    */
    function getCurrentMaxDurability(uint tokenId) public view returns (uint) {
        return 100 * PRECISION + getCountOfFortificationAtTimestamp(tokenId, block.timestamp) * 10 * PRECISION;
    }
    
    /** 
        @notice Calculate recent token reward
        @return Reward amount (with PRECISION)
    */
    function calculateTokenReward(uint depositedBalance, uint maxTokenReward, bool[12] memory hasAddon, bool isRare, bool hasTokenBoost, bool hasConcreteFoundation, uint[3] memory lastFortificationTime, uint[4] memory timeData, uint lastDurability) external view returns (uint) {
        /**
            timeData[0] - expire garden time
            timeData[1] - last firepit time 
            timeData[2] - last fertilized garden time 
            timeData[3] - last repair time 
        */

        uint sumOfDurabilityWithMultiplier;
        uint daysSinceRepair =  (block.timestamp - timeData[3]) / SECONDS_IN_TWO_DAY + 1;
        uint[4] memory settingData = setting.getDetailsForHelper(isRare, hasConcreteFoundation);

        if (daysSinceRepair == 1) {
            sumOfDurabilityWithMultiplier = (block.timestamp - timeData[3]) *
                    getDurabilityAtBreakpoint(timeData[3], settingData[3], lastFortificationTime, timeData, lastDurability) * 
                    getMultiplierAtBreakpoint(timeData[3], hasAddon, hasTokenBoost, lastFortificationTime, timeData, settingData);
        } else {
            uint durabilitySum;
            if (daysSinceRepair < (lastDurability / settingData[3] + 1)) {
                durabilitySum = (daysSinceRepair - 1) * lastDurability -  (daysSinceRepair - 1) * (daysSinceRepair - 2) * settingData[3] / 2;
            
                sumOfDurabilityWithMultiplier = durabilitySum * getMultiplierAtBreakpoint(block.timestamp, hasAddon, hasTokenBoost, lastFortificationTime, timeData, settingData) * SECONDS_IN_TWO_DAY +
                    (lastDurability - (daysSinceRepair - 1) * settingData[3]) * getMultiplierAtBreakpoint(block.timestamp, hasAddon, hasTokenBoost, lastFortificationTime, timeData, settingData) * (block.timestamp - timeData[3] - (daysSinceRepair -1) * SECONDS_IN_TWO_DAY);
            } else {
                daysSinceRepair = lastDurability / settingData[3] + 1;
                durabilitySum = (daysSinceRepair - 1) * lastDurability -  (daysSinceRepair - 1) * (daysSinceRepair - 2) * settingData[3] / 2;
                sumOfDurabilityWithMultiplier = durabilitySum * getMultiplierAtBreakpoint(block.timestamp, hasAddon, hasTokenBoost, lastFortificationTime, timeData, settingData) * SECONDS_IN_TWO_DAY;
            }
        }

        sumOfDurabilityWithMultiplier = depositedBalance * (sumOfDurabilityWithMultiplier / PRECISION / 100) / SECONDS_IN_A_YEAR;  // used as reward

        return maxTokenReward > sumOfDurabilityWithMultiplier ? sumOfDurabilityWithMultiplier : maxTokenReward;
    }

    /** 
        @notice Get resource amount to repair house with given percent
        @param tokenId: House NFT Id
        @param percent: Percent to repair (with PRECISION)
        @return Resource array (with PRECISION)
    */
    function getRepairCost(uint tokenId, uint percent) public view returns (uint[5] memory) {
        bool[12] memory hasAddon;
        uint activeToolshedType;
        (hasAddon, activeToolshedType) = house.getHasaddonAndToolshedType(tokenId);

        uint[5] memory repairCost = [10 * PRECISION, 0, 0, 0, 0];

        for (uint i = 0; i < 5; i++) {
            repairCost[i] = repairCost[i] * percent / 10 / PRECISION;
        }

        /// Calculate repair cost for base addons
        for(uint i = 0; i < 12; i++) {
            if (hasAddon[i]) {
                for (uint j = 1; j < 5; j++) {
                    if (baseAddonCost[i][j] > 0)
                        repairCost[j] += percent / 10;
                }                
            }
        }

        if (activeToolshedType > 0) { // Reduce repair cost based on toolshed level
            uint[5] memory discountPercent = setting.getToolshedDiscountPercent(activeToolshedType);
            
            for (uint i = 0; i < 5; i++) {
                if (discountPercent[i] > 0)
                    repairCost[i] = repairCost[i] * (100 - discountPercent[i]) / 100;
            }
        }

        return repairCost;
    }

    /** 
        @notice Get power amount required for havest
        @param harvestingReward: Trying to harvest resource reward or not, as array [token, lumber, brick, concrete, steel]
        @return power amount
    */
    function getHarvestCost(uint tokenId, bool[5] memory harvestingReward) external view returns (uint) {
        uint countItemsToHarvest;

        for (uint i = 0; i < 5; i++) {
            if (harvestingReward[i]) {
                countItemsToHarvest++;
            }
        }

        // Power cost - 10, harvester reduction radio - 50
        if (house.getHasHarvester(tokenId)) {
            return 5 * countItemsToHarvest * PRECISION;
        } 

        return 10 * countItemsToHarvest * PRECISION;
    }

    function getRepairData(uint tokenId, uint percent) external view returns(uint, uint, uint[5] memory) {
        return (
            getCurrentMaxDurability(tokenId),
            getDurabilityAtTimestamp(tokenId, block.timestamp),
            getRepairCost(tokenId, percent)
        );
    }

    /**
        @notice Return data for NFT detail page
        @param tokenId: House NFT id
    */
    function getHouseDetails(uint tokenId) external view returns (uint, uint, uint, uint[5] memory, uint, uint) {
        bool activated;
        ( , activated, ) = house.getOwnerAndStatus(tokenId);
        bool isRare;
        (isRare, , , , , , , , , , ) = house.getHelperDetails(tokenId);
        if (activated == false) {
            return (
                100 * PRECISION,
                100 * PRECISION,
                isRare ? setting.getRareMultiplier() : setting.getStandardMultiplier(),
                [uint(0), 0, 0, 0, 0],
                uint(0),
                uint(0)
            );
        }

        return (
            getDurabilityAtTimestamp(tokenId, block.timestamp),
            getCurrentMaxDurability(tokenId),
            getMultiplierAtTimestamp(tokenId, block.timestamp),
            house.getResourceReward(tokenId),
            house.getTokenReward(tokenId),
            setting.getHarvestLimit(isRare)
        );
    }
}
