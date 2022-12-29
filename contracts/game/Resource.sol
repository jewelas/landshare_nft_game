//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IGameEvents.sol";
import "../interface/ISetting.sol";
import "../interface/IHouse.sol";
import "../interface/IHelper.sol";
import "../settings/constants.sol";

contract Resource is Ownable, IGameEvents {
    ISetting setting;
    IHouse house;
    IHelper helper;

    mapping(address => uint[5]) public userResources;
    mapping(address => uint[3]) private lastGatherLumberTime;

    constructor(
        address _settingAddress,
        address _houseAddress,
        address _helperAddress
    ) {
        setting = ISetting(_settingAddress);
        house = IHouse(_houseAddress);
        helper = IHelper(_helperAddress);
    }

    /** 
        @notice Add resources to user's resource balance
        @param user : receiving user address, resource : resource value
    */
    function addResource(address user, uint[5] memory resource) internal {
        for (uint i = 0; i < 5; i++) {
            if(resource[i] > 0) {
                userResources[user][i] += resource[i];
            }
        }

        emit UpdateResource(user, userResources[user]);
    }

    /** 
        @notice Sub resources from user's resource balance
        @param user : user address, resource : resource value
    */
    function subResource(address user, uint tokenId, uint[5] memory resource) internal {
        require (house.calculateUserPower(tokenId, userResources[user][0]) >= resource[0], "Insufficient power");
        require (userResources[user][1] >= resource[1], "Insufficient lumber");
        require (userResources[user][2] >= resource[2], "Insufficient brick");
        require (userResources[user][3] >= resource[3], "Insufficient concrete");
        require (userResources[user][4] >= resource[4], "Insufficient steel");

        /// Before subtract, auto harvest power 
        autoPowerHarvest(user, tokenId);

        for (uint i = 0; i < 5; i++) {
            if(resource[i] > 0) {
                userResources[user][i] -= resource[i];
            }
        }

        emit UpdateResource(user, userResources[user]);
    }

    /**
        @notice Get user resources
        @return User resources
    */
    function getResource(address user, uint tokenId) public view returns (uint[5] memory) {
        uint[5] memory resource;
        resource = userResources[user];
        resource[0] = house.calculateUserPower(tokenId, userResources[user][0]);
        return resource;
    }

    /** 
        @notice Add resources to user's resource by admin
        @param user : receiving user address, resource : resource value
    */
    function addResourceByAdmin(address user, uint[5] memory resource) public onlyOwner {
        for (uint i = 0; i < 5; i++) {
            userResources[user][i] += resource[i] * PRECISION;
        }
    }

    /**
        @notice Auto harvest power when user update/repair/harvest/fortify etc
        @param user: User
    */
    function autoPowerHarvest(address user, uint tokenId) internal {
        userResources[user][0] = house.calculateUserPower(tokenId, userResources[user][0]);
        house.setPowerRewardTime(tokenId);
    }

    /**
        @notice Get last timestamp of gathering lumber
        @return timestamp
    */
    function getLastGatherLumberTime() public view returns (uint[3] memory) {
        return lastGatherLumberTime[msg.sender];
    }

    /**
        @notice Track last 2 timestamps of gathering lumber
        @param amount: amount to gather
    */
    function setGatherLumberTime(uint amount) internal {
        address user = msg.sender;

        uint nonZeroCount;
        uint i;
        for (i = 0; i < 3; i++)
            if (lastGatherLumberTime[user][i] != 0) nonZeroCount++;
        
        if (amount + nonZeroCount > 3) {
            uint overlapCount = amount + nonZeroCount - 3;
            for (i = 0; i + overlapCount < 3; i++) lastGatherLumberTime[user][i] = lastGatherLumberTime[user][i + overlapCount];
            for ( ; i < 3; i++) lastGatherLumberTime[user][i] = block.timestamp;
        } else {
            for (i = 0; i < amount; i++) lastGatherLumberTime[user][i + nonZeroCount] = block.timestamp;
        }
    }
}
