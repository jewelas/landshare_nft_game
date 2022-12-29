//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract ISetting {
    function getDetailsForMultiplierCalc(bool isRare) external view virtual returns(uint, uint, uint);
    function getDetailsForHelper(bool isRare, bool hasConcreteFoundation) external view virtual returns(uint[4] memory);
    function getFacilitySetting() external view virtual returns(uint[5][5][5] memory, uint[5][5] memory);
    function getStandardMultiplier() external view virtual returns(uint);
    function getRareMultiplier() external view virtual returns(uint);

    function getFacilityUpgradeCost(uint _type, uint _level) public view virtual returns (uint[5] memory);
    function getResourceGenerationAmount(uint _type, uint _level) public view virtual returns (uint);
    function getPowerLimit(uint level) public view virtual returns (uint);
    function getPowerAmountForHarvest() public view virtual returns (uint);
    function getRepairBaselineCost() public view virtual returns (uint[5] memory);

    function getBaseAddonCost() external view virtual returns (uint[5][12] memory);
    function getBaseAddonCostById(uint id) public view virtual returns (uint[5] memory);
    function getBaseAddonMultiplier() public view virtual returns (uint[12] memory);
    function getBaseAddonDependency(uint id) public view virtual returns (uint[] memory);
    function getBaseAddonFortDependency(uint id) public view virtual returns (uint);
    function getBaseAddonSalvagePercent() external view virtual returns (uint);

    function getDurabilitySetting() external view virtual returns(uint, uint, uint);
    function getDurabilityReductionPercent(bool hasConcreteFoundation) public view virtual returns(uint);
    function getFortLastDays() public view virtual returns (uint);
    function getFortifyCost(uint _type) public view virtual returns (uint[5] memory);

    function getToolshedSetting() external view virtual returns(uint[5][4] memory, uint[5] memory, uint[5][4] memory);
    function getSpecialAddonSetting() external view virtual returns(uint[5] memory, uint, uint[5] memory, uint, uint, uint[5] memory, uint, uint, uint, uint);
    function getToolshedBuildCost(uint _type) public view virtual returns (uint[5] memory);
    function getToolshedSwitchCost() public view virtual returns (uint[5] memory);
    function getToolshedDiscountPercent(uint _type) public view virtual returns (uint[5] memory);
    function getFireplaceCost() public view virtual returns (uint[5] memory);
    function getFireplaceBurnRatio() public view virtual returns (uint);
    function getHarvesterCost() public view virtual returns (uint[5] memory);
    function getHarvesterReductionRatio() public view virtual returns (uint);
    function getPowerPerLandtoken() public view virtual returns (uint);
    function getPowerPerLumber() external view virtual returns (uint);
    function getLastingGardenDays() external view virtual returns (uint);
    function getRequiredAddons(uint id) external view virtual returns (uint[] memory);
    function getSalvageCost(uint id, bool[12] memory hasAddon) external view virtual returns (uint[5] memory, uint[5] memory);
    function getFertilizeGardenCost() external view virtual returns (uint[5] memory);
    function getFertilizeGardenLastingDays() external view virtual returns (uint);
    function getDurabilityDiscountPercent() external view virtual returns(uint);
    function getDurabilityDiscountCost() external view virtual returns(uint[5] memory);
    function getHandymanLastDays() external view virtual returns(uint);
    function getHandymanLandCost() external view virtual returns(uint);

    function getFertilizedGardenMultiplier() external view virtual returns (uint);
    function getOverdrivePowerCost() external view virtual returns(uint);
    function getOverdriveDays() external view virtual returns(uint);
    function getResourceOverdrivePercent() external view virtual returns(uint);
    function getTokenOverdrivePercent() external view virtual returns(uint);
    function getHarvestLimit(bool isRare) external view virtual returns (uint);
    function getResourceGenerationLimit() external view virtual returns(uint);
}
