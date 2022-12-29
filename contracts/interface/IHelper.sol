//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract IHelper {
    function getCountOfFortificationAtTimestamp(uint tokenId, uint timestamp) public view virtual returns (uint);
    function getMultiplierAtTimestamp(uint tokenId, uint timestamp) public view virtual returns (uint);
    function getDurabilityAtTimestamp(uint tokenId, uint timestamp) public view virtual returns (uint);
    function getDurabilityAtBreakpoint(uint timestamp, uint durabilityReductionPercent, uint[3] memory lastFortificationTime, uint[4] memory timeData, uint lastDurability) public pure virtual returns (uint);
    function getCurrentMaxDurability(uint tokenId) public view virtual returns (uint);
    function getSumOfDurabilityWithMultiplier(uint tokenId) public view virtual returns (uint);
    function getRepairCost(uint tokenId, uint percent) external view virtual returns (uint[5] memory);
    function getHarvestCost(uint tokenId, bool[5] memory harvestingReward) external view virtual returns (uint);
    function calculateTokenReward(uint depositedBalance, uint maxTokenReward, bool[12] memory hasAddon, bool isRare, bool hasTokenBoost, bool hasConcreteFoundation, uint[3] memory lastFortificationTime, uint[4] memory timeData, uint lastDurability) external view virtual returns (uint);
    function getRepairData(uint tokenId, uint percent) external view virtual returns(uint, uint, uint[5] memory);
    function getHouseDetails(uint tokenId) public view virtual returns (uint, uint, uint, uint[5] memory, uint, uint);
}
