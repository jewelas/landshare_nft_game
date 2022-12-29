//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Addon.sol";
import "../interface/IMarketplace.sol";
import "../settings/constants.sol";
// import "hardhat/console.sol";

contract Game is Addon {

    constructor(
        address _landToken,
        address _settingAddress,
        address _houseAddress,
        address _helperAddress,
        address _validatorAddress
    ) Addon(_settingAddress, _houseAddress, _helperAddress, _validatorAddress) {
        landToken = IERC20(_landToken);
    }

    IMarketplace marketplace;
    address private stakeContractAddress;

    /**
        @notice Set Stake conract address 
        @param _settingAddress: Setting contract address
        @param _houseAddress: House contract address
        @param _helperAddress: Helper contract address
        @param _stakeAddress: Stake contract address
        @param _validatorAddress: Validator contract address
    */
    function setContractAddress(
        address _settingAddress,
        address _houseAddress,
        address _helperAddress,
        address _stakeAddress,
        address _validatorAddress
    ) external onlyOwner {
        setting = ISetting(_settingAddress);
        house = IHouse(_houseAddress);
        helper = IHelper(_helperAddress);
        validator = IValidator(_validatorAddress);
        stakeContractAddress = _stakeAddress;
    }

    function setMarketplaceContract(address _marketplaceAddress) external onlyOwner {
        marketplace = IMarketplace(_marketplaceAddress);
    }

    /** 
        @notice Repair house with given percent
        @param tokenId: House NFT Id
        @param percent: Percent to repair (with PRECISION)
    */
    function repair(uint tokenId, uint percent) external {
        address user;
        bool activated;
        uint deadTime;
        (user, activated, deadTime) = house.getOwnerAndStatus(tokenId);
        require(deadTime == 0, "House is dead");
        require(activated, "Activation required");
        require(msg.sender == user, "Repair: PD");
        require(percent > 0, "Percent should above 0");
        
        uint maxDurability;
        uint curDurability;
        uint[5] memory repairCost;
        (maxDurability, curDurability, repairCost) = helper.getRepairData(tokenId, percent);
        
        require(curDurability + percent <= maxDurability, "Overflow maximium durability");
        if (maxDurability - curDurability >= 10 * PRECISION) {
            require(percent >= 10 * PRECISION, "Should repair at least 10%");
        } else {
            require(curDurability + percent == maxDurability, "Should repair to max durability");
        }

        subResource(msg.sender, tokenId, repairCost);
        house.setAfterRepair(tokenId, curDurability + percent);

        emit Repair(msg.sender, tokenId, percent);
    }

    /** 
        @notice Upgrade facility
        @param tokenId: House NFT Id
        @param facilityType: index of facility [power, lumber, brick, concrete, steel]
    */
    function upgradeFacility(uint tokenId, uint facilityType) external {
        if (!validator.canUpgradeFacility(tokenId, facilityType, msg.sender)) return;
        
        uint facilityLevel = house.getFacilityLevel(tokenId, facilityType);
        uint[5] memory cost = setting.getFacilityUpgradeCost(facilityType, facilityLevel + 1);

        subResource(msg.sender, tokenId, cost);

        // UpdateResourceReward called from setFacilityLevel
        house.setFacilityLevel(tokenId, facilityType);

        emit UpgradeFacility(msg.sender, tokenId, facilityType, facilityLevel + 1);
    }

    /** 
        @notice Harvest token and resource reward selectively
        @param tokenId: House NFT Id
        @param harvestingReward: Trying to harvest resource reward or not, as array [token, lumber, brick, concrete, steel]
    */
    function harvest(uint tokenId, bool[5] memory harvestingReward) external {
        bool isValid;
        uint deadTime;
        uint harvestTokenAmount;
        (isValid, harvestTokenAmount, deadTime) = validator.canHarvest(tokenId, harvestingReward, msg.sender);
        if (!isValid) return;

        uint powerCost = helper.getHarvestCost(tokenId, harvestingReward);
        uint[5] memory harvestedAmount;
        uint[5] memory resourceReward = house.getResourceReward(tokenId);

        if (deadTime == 0) {
            subResource(msg.sender, tokenId, [powerCost, 0, 0, 0, 0]);
        }

        house.setAfterHarvest(tokenId, harvestingReward, harvestTokenAmount);

        if (harvestingReward[1] || harvestingReward[2] || harvestingReward[3] || harvestingReward[4]) {
        
            for (uint facilityType = 1; facilityType < 5; facilityType++) {
                if (harvestingReward[facilityType]) {
                    harvestedAmount[facilityType] = resourceReward[facilityType];
                }
            }

            addResource(msg.sender, harvestedAmount);
        }

        if (harvestingReward[0]) {
            landToken.transfer(msg.sender, harvestTokenAmount);
        }

        emit Harvest(msg.sender, tokenId, harvestedAmount);
    }

    /** 
        @notice Buy power using landtoken
        @param amount: landtoken amount
    */
    function buyPowerWithLandtoken(uint amount, uint tokenId) external payable {
        bool isValid;
        uint powerAmount;
        (isValid, powerAmount) = validator.canBuyPowerWithLandtoken(tokenId, amount, house.calculateUserPower(tokenId, userResources[msg.sender][0]), msg.sender);
        if (!isValid) return;

        /// auto harvest power before buy power using landtoken
        landToken.transferFrom(msg.sender, address(this), amount);
        autoPowerHarvest(msg.sender, tokenId);
        addResource(msg.sender, [powerAmount, 0, 0, 0, 0]);

        emit BuyPower(msg.sender, amount, powerAmount);
    }

    /**
        @notice Gather lumber using power
        @param amount: amount to gather
    */
    function gatherLumberWithPower(uint amount, uint tokenId) external {
        if (!validator.canGatherLumberWithPower(tokenId, amount, getLastGatherLumberTime(), msg.sender)) return;

        uint powerAmount = setting.getPowerPerLumber() * amount;
        uint[5] memory cost = [powerAmount * PRECISION, 0, 0, 0, 0];
        subResource(msg.sender, tokenId, cost);
        setGatherLumberTime(amount);
        addResource(msg.sender, [0, amount * PRECISION, 0, 0, 0]);
        

        emit GatherLumber(msg.sender, amount, powerAmount);
    }

    /**
        @notice Fortify and repare (Fixed 10%)
        @param tokenId: House NFT Id
        @param _type: 0 => brick, 1 => concrete, 2 => steel
    */
    function fortify(uint tokenId, uint _type) external {
        address user;
        bool activated;
        uint deadTime;
        (user, activated, deadTime) = house.getOwnerAndStatus(tokenId);
        require(deadTime == 0, "House is dead");
        require(activated, "Activation required");
        require (msg.sender == user, "Fortify: PD");
        require(_type < 3, "Invalid fortification type");

        uint[5] memory cost = setting.getFortifyCost(_type);
        subResource(user, tokenId, cost);
        house.setAfterFortify(tokenId, _type);

        emit Fortify(user, tokenId, _type);
    }

    /**
        @notice Activate house
        @param tokenId: House NFT Id
    */
    function activateHouse(uint tokenId) external {
        address user;
        bool activated;
        uint deadTime;
        (user, activated, deadTime) = house.getOwnerAndStatus(tokenId);
        require(msg.sender == user, "Activate: PD");
        require(activated == false, "Already activated");

        autoPowerHarvest(user, tokenId);
        house.activate(tokenId);

        emit Activate(user, tokenId);
    }

    /**
        @notice Withdraw landtoken from contract
        @param amount: amount to withdraw
    */
    function withdrawLandToken(uint amount) external onlyOwner {
        require(landToken.balanceOf(address(this)) >= amount, "Not enough of token balance");
        landToken.transfer(msg.sender, amount);
    }

    /**
        @notice frontload lumbers to firepit
        @param tokenId: Id of house
        @param lumberAmount : lumber amount with precision
    */
    function frontLoadFirepit(uint tokenId, uint lumberAmount) external {
        if (!validator.canFrontloadFirepit(tokenId, lumberAmount, msg.sender)) return;

        uint[5] memory cost = [uint(0), lumberAmount, 0, 0, 0];

        subResource(msg.sender, tokenId, cost);
        house.setLastFirepitTime(tokenId, lumberAmount);

        emit FrontloadFirepit(msg.sender, tokenId, lumberAmount);
    }

    /**
        @notice Buy Overdrive
        @param tokenId: Id of house
        @param facilityType: type of facility to overdrive
    */
    function buyResourceOverdrive(uint tokenId, uint facilityType) external {
        if (!validator.canBuyResourceOverdrive(tokenId, facilityType, msg.sender)) return;
        
        subResource(msg.sender, tokenId, [15 * PRECISION, 0, 0, 0, 0]);
        house.buyResourceOverdrive(tokenId, facilityType);

        emit BuyResourceOverdrive(msg.sender, tokenId, facilityType);
    }

    function buyTokenOverdrive(uint tokenId) external {
        if (!validator.canBuyTokenOverdrive(tokenId, msg.sender)) return;

        subResource(msg.sender, tokenId, [15 * PRECISION, 0, 0, 0, 0]);
        house.buyTokenOverdrive(tokenId);

        emit BuyTokenOverdrive(msg.sender, tokenId);
    }

    function onSale(uint tokenId, uint amount) external {
        address user;
        uint deadTime;
        (user, , deadTime) = house.getOwnerAndStatus(tokenId);
        require(deadTime == 0, "House is dead");
        require(msg.sender == user, "OnSale: PD");
        require(house.getDepositedBalance(tokenId) == 0, "Shoud unstake all");
        require(house.getTokenReward(tokenId) == 0, "Shoud harvest all");

        house.setOnsale(tokenId, true);
        marketplace.addItem(tokenId, amount);
        
        emit OnSale(msg.sender, tokenId, amount);
    }

    function offSale(uint tokenId) external {
        address user;
        (user, , ) = house.getOwnerAndStatus(tokenId);
        require(msg.sender == user, "OffSale: PD");
        
        house.setOnsale(tokenId, false);
        marketplace.removeItem(tokenId);

        emit OffSale(msg.sender, tokenId);
    }
}

