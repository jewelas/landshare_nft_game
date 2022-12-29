//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/ISetting.sol";
import "../interface/IHelper.sol";
import "../interface/IWhitelist.sol";
import "../settings/constants.sol";

contract HouseNFT is ERC721, Ownable {
    ISetting setting;
    IHelper helper;
    IWhitelist whitelist;

    struct House {
        string name;
        string series;
        uint depositedBalance;
        uint tokenReward; // Pending amount of landtoken to harvest until `lastRepairTime`.
        uint[5] resourceReward; // Pending resources to harvest until `lastResourceRewardTime`
        uint[5] lastResourceRewardTime; // The time when updating `resourceReward`
        uint lastRepairTime;
        uint lastDurability;
        uint expireGardenTime;
        uint lastFertilizedGardenTime;
        uint[3] lastFortificationTime; // Last 3 fortification time in ascending order
        uint lastFirepitTime; // Last firepit expire time.
        uint lastHandymanHiredTime;
        uint totalHarvestedToken;
        uint deadTime;
        uint colorId;
        uint8 rareId;
        uint8 activeToolshedType;
        uint8[5] facilityLevel; // [power, lumber, brick, concrete, steel]
        bool isRare;  // true -> Rare NFT, false -> Standard NFT
        bool activated;
        bool[12] hasAddon;
        bool hasFireplace;
        bool hasHarvester;
        bool[5] hasToolshed;
        bool[5] hasBoost;
        bool hasConcreteFoundation;
        bool onSale;
    }

    mapping(uint => House) private houses;
    mapping(uint256 => string) private _tokenURIs;
    string private _baseURIextended;
    uint nextID = 0;
    uint nextRareID = 0;
    uint maxRare;
    uint deadTokenId = 1000000000;
    address private gameContractAddress;
    address private stakeContractAddress;

    constructor(
        string memory name,
        string memory symbol,
        uint _maxRare,
        address _settingAddress
    ) ERC721 (name, symbol) {
        setting = ISetting(_settingAddress);
        maxRare = _maxRare;
        _baseURIextended = "ipfs://";
    }

    /** 
        @notice Check msg.sender has permission to access houseNFT
    */
    modifier onlyHasPermission() {
        require (msg.sender == gameContractAddress || msg.sender == stakeContractAddress, "Permission denied");
        _;
    }

    /**
        @notice Set game conract address & stake contract address
        @param _settingAddress: Setting contract address
        @param _helperAddress: Helper contract address
        @param _gameAddress: Game contract address
        @param _stakeAddress: Stake contract address
    */
    function setContractAddress(address _settingAddress, address _helperAddress, address _gameAddress, address _stakeAddress, address _whitelistAddress) external onlyOwner {
        setting = ISetting(_settingAddress);
        helper = IHelper(_helperAddress);
        whitelist = IWhitelist(_whitelistAddress); 
        gameContractAddress = _gameAddress;
        stakeContractAddress = _stakeAddress;
    }

    function mint(address to, bool isRare, string memory tokenURI) public onlyOwner {
        if (isRare) {
            require(nextRareID < maxRare, "Limited to mint rare houses");
        }

        _safeMint(to, nextID);
        _setTokenURI(nextID, tokenURI);

        houses[nextID++] = House({
            isRare: isRare,
            rareId : uint8(nextRareID),
            name: "LSNF",
            series: "817 12th Ave N",
            depositedBalance: 0,
            tokenReward: 0,
            resourceReward: [uint(0), 0, 0, 0, 0],
            lastResourceRewardTime: [block.timestamp, block.timestamp, block.timestamp, block.timestamp, block.timestamp],
            lastRepairTime: block.timestamp,
            lastDurability: 100 * PRECISION,
            expireGardenTime: 0,
            lastFertilizedGardenTime: 0,
            hasAddon: [false, false, false, false, false, false, false, false, false, false, false, false],
            hasFireplace: false,
            hasHarvester: false,
            hasToolshed: [false, false, false, false, false],
            activated: false,
            activeToolshedType: 0,
            lastFortificationTime: [uint(0), 0, 0],
            lastFirepitTime: 0, 
            facilityLevel: [1, 0, 0, 0, 0], // levels of [power, lumber, brick, concrete, steel]
            hasConcreteFoundation: false,
            lastHandymanHiredTime: 0,
            hasBoost: [false, false, false, false, false],
            totalHarvestedToken: 0,
            colorId: 0,
            deadTime: 0,
            onSale: false
        });

        if (isRare) {
            nextRareID++;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint tokenId) internal override {
        House storage house = houses[tokenId];

        require(house.depositedBalance == 0, "Please unstake asset tokens");
        require(whitelist.isWhitelistedAddress(to) == true, "User not whitelisted"); 
        require(house.tokenReward == 0, "Please harvest token rewards");
        require(getActiveHouseByOwner(to) == deadTokenId, "User already has NFT");
        
        // Reset all resource when transfer      
        setHarvestByTransfer(tokenId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
		_baseURIextended = baseURI_;
	}

    function _setTokenURI(uint tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
		_tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseURIextended).length > 0 ? string(abi.encodePacked(_baseURIextended, _tokenURIs[tokenId])) : "";
    }

    /**
        @dev See {IERC721Enumerable-totalSupply}.
    */
    function totalSupply() public view returns (uint256) {
        return nextID;
    }

    /**
        @notice Get house detail information
    */
    function getHouse(uint tokenId) external view returns(House memory) {
        return houses[tokenId];
    }

    /**
        @notice Get houses id by owner
        @return All token ids that user has
    */
    function getHousesByOwner(address _owner) public view returns(uint[] memory) {
        uint counter;
        for (uint i = 0; i < totalSupply(); i++) {
            if (ownerOf(i) == _owner) {
               counter++;
            }
        }
        uint256[] memory result = new uint256[](counter);

        counter = 0;
        for (uint i = 0; i < totalSupply(); i++) {
            if (ownerOf(i) == _owner) {
               result[counter] = i;
               counter++;
            }
        }
        
        return result;
    }

    function getActiveHouseByOwner(address _owner) public view returns(uint) {
        for (uint i = 0; i < totalSupply(); i++) {
            if (ownerOf(i) == _owner && houses[i].deadTime == 0) {
               return i;
            }
        }

        return deadTokenId;
    }

    function setHouseName(uint tokenId, string memory _name) external {
        require(msg.sender == ownerOf(tokenId), "Set Name: PD");
        House storage house = houses[tokenId];
        house.name = _name;
    }

    /**
        @notice Get NFT owner address
        @return Owner of NFT
    */
    function getOwnerAndStatus(uint tokenId) public view returns(address, bool, uint) {
        return (ownerOf(tokenId), houses[tokenId].activated, houses[tokenId].deadTime);
    }

    /**
        @notice activate house and reset values
        @param tokenId: Id of house
    */
    function activate(uint tokenId) external onlyHasPermission {
        House storage house = houses[tokenId];

        house.activated = true;
        house.lastResourceRewardTime = [block.timestamp, block.timestamp, block.timestamp, block.timestamp, block.timestamp];
        house.lastRepairTime = block.timestamp;
    }

    function setDeadTime(uint tokenId) public onlyHasPermission {
        House storage house = houses[tokenId];
    
        uint maxTokenReward = setting.getHarvestLimit(house.isRare) - house.totalHarvestedToken - house.tokenReward;
        uint[4] memory timeData = [house.expireGardenTime, house.lastFirepitTime, house.lastFertilizedGardenTime, house.lastRepairTime];
        
        if (helper.calculateTokenReward(house.depositedBalance, maxTokenReward, house.hasAddon, house.isRare, house.hasBoost[0], house.hasConcreteFoundation, house.lastFortificationTime, timeData, house.lastDurability) == maxTokenReward) {
            house.deadTime = block.timestamp;
        }
    }

    /**
        @notice Get hasConcreteFoundation status
        @param tokenId: Id of house
        @return hasConcreteFoundation status
    */
    function getHasConcreteFoundation(uint tokenId) external view returns (bool) {
        return houses[tokenId].hasConcreteFoundation;
    }

    /**
        @notice Set house hasConcreteFoundation status
        @param tokenId: Id of house
        @param hasConcreteFoundation: status
    */
    function setHasConcreteFoundation(uint tokenId, bool hasConcreteFoundation) external onlyHasPermission {
        houses[tokenId].hasConcreteFoundation = hasConcreteFoundation;
    }

    /**
        @notice get Hire handy man hired time
        @param tokenId: houseNFT id
        @return lastHandymanHiredTime
    */
    function getHireHandymanHiredTime(uint tokenId) public view returns(uint) {
        return houses[tokenId].lastHandymanHiredTime;
    }

    /**
        @notice set Hire handy man hired time
        @param tokenId: houseNFT id 
    */
    function repairByHandyman(uint tokenId) external onlyHasPermission () {
        House storage house = houses[tokenId];

        house.tokenReward = getTokenReward(tokenId);
        house.lastDurability = helper.getCurrentMaxDurability(tokenId);
        house.lastRepairTime = block.timestamp;
        house.lastHandymanHiredTime = block.timestamp + setting.getHandymanLastDays();
    }

    /**
        @notice Get house deposited balance
        @param tokenId: NFT id
        @return House deposited balance
    */
    function getDepositedBalance(uint tokenId) external view returns (uint) {
        return houses[tokenId].depositedBalance;
    }

    /**
        @notice Add to house deposited balance
        @param tokenId: NFT id
        @param balance: Deposited balance
    */
    function deposit(uint tokenId, uint balance) external onlyHasPermission {
        updateTokenReward(tokenId);
        houses[tokenId].depositedBalance += balance;
    }

    /** 
        @notice Subtract to deposited balance
        @param tokenId: NFT id
        @param balance: Withdraw balance
    */
    function withdraw(uint tokenId, uint balance) external onlyHasPermission {
        updateTokenReward(tokenId);
        houses[tokenId].depositedBalance -= balance;
        setDeadTime(tokenId);
    }

    /**
        @notice Get house hasAddon
        @param tokenId: NFT id
        @param addonId: Id of addon
        @return House hasAddon
    */
    function getHasAddon(uint tokenId, uint addonId) external view returns (bool) {
        House storage house = houses[tokenId];
        
        return addonId == 2 ? house.hasAddon[addonId] && house.expireGardenTime > block.timestamp : house.hasAddon[addonId];
    }

    /**
        @notice Set house hasAddon
        @param tokenId: NFT id
        @param addon: House hasAddon
    */
    function setHasAddon(uint tokenId, bool addon, uint addonId) external onlyHasPermission {
        updateTokenReward(tokenId);
        House storage house = houses[tokenId];
        house.hasAddon[addonId] = addon;
        if (addon && addonId == 2) {
            house.expireGardenTime = block.timestamp + setting.getLastingGardenDays();
        }
        if (addon == false) {
            uint[] memory requiredAddons = setting.getRequiredAddons(addonId);
            for (uint i = 0; i < requiredAddons.length; i++) {
                house.hasAddon[requiredAddons[i]] = false;
            }
        }
    }

    /**
        @notice Get house hasAddon
        @param tokenId: NFT id
        @return House hasAddons in array
    */
    function getHasAddons(uint tokenId) external view returns (bool[12] memory) {
        return houses[tokenId].hasAddon;
    }

    /**
        @notice Get house hasFireplace
        @param tokenId: NFT id
        @return House hasFireplace
    */
    function getHasFireplace(uint tokenId) external view returns (bool) {
        return houses[tokenId].hasFireplace;
    }

    /**
        @notice Set house hasFireplace
        @param tokenId: NFT id
        @param hasFireplace: House hasFireplace
    */
    function setHasFireplace(uint tokenId, bool hasFireplace) external onlyHasPermission {
        houses[tokenId].hasFireplace = hasFireplace;
    }

    /**
        @notice Get house hasHarvester
        @param tokenId: NFT id
        @return House hasHarvester
    */
    function getHasHarvester(uint tokenId) external view returns (bool) {
        return houses[tokenId].hasHarvester;
    }

    /**
        @notice Set house hasHarvester
        @param tokenId: NFT id
        @param hasHarvester: House hasHarvester
    */
    function setHasHarvester(uint tokenId, bool hasHarvester) external onlyHasPermission {
        houses[tokenId].hasHarvester = hasHarvester;
    }

    /**
        @notice Get house toolshed
        @param tokenId: NFT id
        @return House toolshed in array
    */
    function getToolshed(uint tokenId) external view returns (bool[5] memory) {
        return houses[tokenId].hasToolshed;
    }

    /**
        @notice Set house toolshed 
        @param tokenId: NFT id
        @param _type: toolshed type
    */
    function setToolshed(uint tokenId, uint _type) external onlyHasPermission {
        houses[tokenId].hasToolshed[_type] = true;
        houses[tokenId].activeToolshedType = uint8(_type);
    }

    /**
        @notice Get house toolshed active type
        @param tokenId: NFT id
        @return House toolshed type
    */
    function getActiveToolshedType(uint tokenId) external view returns (uint) {
        return uint(houses[tokenId].activeToolshedType);
    }

    /**
        @notice Get house facility level
        @param tokenId: NFT id
        @return House facility level
    */
    function getFacilityLevel(uint tokenId, uint _type) external view returns (uint) {
        return uint(houses[tokenId].facilityLevel[_type]);
    }

    /**
        @notice Set house facility level
        @param tokenId: NFT id
        @param _type: House facility type
    */
    function setFacilityLevel(uint tokenId, uint _type) external onlyHasPermission {
        updateResourceReward(tokenId);

        houses[tokenId].facilityLevel[_type]++;
    }

    /**
        @notice Get house last fortification time
        @param tokenId: NFT id
        @return House last fortification time
    */
    function getLastFortificationTime(uint tokenId) external view returns (uint[3] memory) {
        return houses[tokenId].lastFortificationTime;
    }

    /**
        @notice Get Firepit remain days
        @param tokenId: NFT id
        @return remainDays
    */
    function getFirepitRemainDays(uint tokenId) public view returns (uint) {
        uint remainDays;
        House storage house = houses[tokenId];
        if (house.lastFirepitTime > block.timestamp) {
            remainDays =  (house.lastFirepitTime - block.timestamp) * PRECISION / SECONDS_IN_A_DAY;
        }
        return remainDays;
    }

    function setLastFirepitTime(uint tokenId, uint amount) external onlyHasPermission {
        updateTokenReward(tokenId);
        House storage house = houses[tokenId];

        if (house.lastFirepitTime <= block.timestamp) {
            house.lastFirepitTime = block.timestamp + amount * SECONDS_IN_A_DAY / PRECISION;
        } else {
            house.lastFirepitTime = house.lastFirepitTime + amount * SECONDS_IN_A_DAY / PRECISION;
        }
    }

    /**
        @notice Set house tokenReward, resourceReward/lastResourceRewardTime
        @param tokenId: NFT id
        @param harvestingReward: Trying to harvest resource reward or not, as array [token, lumber, brick, concrete, steel]
    */
    function setAfterHarvest(uint tokenId, bool[5] memory harvestingReward, uint harvestTokenAmount) external onlyHasPermission {
        House storage house = houses[tokenId];

        // If token reward is harvested, set amount to 0 and timestamp
        if (harvestingReward[0]) {
            house.totalHarvestedToken += harvestTokenAmount;
            house.tokenReward = 0;
            house.lastDurability = helper.getDurabilityAtBreakpoint(
                block.timestamp, 
                house.hasConcreteFoundation ? 18 * PRECISION : 20 * PRECISION,
                house.lastFortificationTime, 
                [house.expireGardenTime, house.lastFirepitTime, house.lastFertilizedGardenTime, house.lastRepairTime],
                house.lastDurability
            );
            house.lastRepairTime = block.timestamp;
        }
        // If resource reward is harvested, set amount to 0 and timestamp
        for (uint facilityType = 1; facilityType < 5; facilityType++) {
            if (harvestingReward[facilityType]) {
                house.resourceReward[facilityType] = 0;
                house.lastResourceRewardTime[facilityType] = block.timestamp;
            }
        }
    }

    function setHarvestByTransfer(uint tokenId) internal {
        House storage house = houses[tokenId];

        house.tokenReward = 0;
        house.lastRepairTime = block.timestamp;

        // If resource reward is harvested, set amount to 0 and timestamp
        house.resourceReward = [uint(0), 0, 0, 0, 0];
        house.lastResourceRewardTime = [block.timestamp, block.timestamp, block.timestamp, block.timestamp, block.timestamp];
    }

    /**
        @notice Set house fortification time, durability and repair time
        @param tokenId: NFT id
        @param _type: Fortification type: 0 => brick, 1 => concrete, 2 => steel
    */
    function setAfterFortify(uint tokenId, uint _type) external onlyHasPermission {
        House storage house = houses[tokenId];

        house.tokenReward = getTokenReward(tokenId);

        house.lastFortificationTime[_type] = block.timestamp + setting.getFortLastDays();
        house.lastDurability = helper.getDurabilityAtBreakpoint(
            block.timestamp, 
            house.hasConcreteFoundation ? 18 * PRECISION : 20 * PRECISION,
            house.lastFortificationTime, 
            [house.expireGardenTime, house.lastFirepitTime, house.lastFertilizedGardenTime, house.lastRepairTime],
            house.lastDurability
        ) + 10 * PRECISION;
        house.lastRepairTime = block.timestamp;
    }

    function setAfterRepair(uint tokenId, uint repairedDurability) external onlyHasPermission {
        House storage house = houses[tokenId];

        house.tokenReward = getTokenReward(tokenId);
        house.lastDurability = repairedDurability;
        house.lastRepairTime = block.timestamp;
    }

    /**
        @notice Set power reward time
        @param tokenId: NFT Id
    */
    function setPowerRewardTime(uint tokenId) external onlyHasPermission {
        if (tokenId != deadTokenId)
            houses[tokenId].lastResourceRewardTime[0] = block.timestamp;
    }

    /**
        @notice Calculate recent resource reward generated
        @param tokenId: House NFT Id
        @return reward amount in array
    */
    function getResourceReward(uint tokenId) public view returns (uint[5] memory) {
        House storage house = houses[tokenId];
        uint[5] memory resourceReward;
        
        if (house.deadTime != 0) {
            return house.resourceReward;
        }

        for (uint facilityType = 1; facilityType < 5; facilityType++) {
            if (house.facilityLevel[facilityType] == 0) continue;

            resourceReward[facilityType] = house.resourceReward[facilityType];

            uint generationAmount = setting.getResourceGenerationAmount(facilityType, house.facilityLevel[facilityType]);

            if (house.hasBoost[facilityType]) {
                resourceReward[facilityType] += generationAmount * (block.timestamp - house.lastResourceRewardTime[facilityType])  * 130 / 100 / SECONDS_IN_A_DAY;
            } else {
                resourceReward[facilityType] += generationAmount * (block.timestamp - house.lastResourceRewardTime[facilityType]) / SECONDS_IN_A_DAY;
            }
            
            // Limit for resource harvest
            if (resourceReward[facilityType] > 10 * PRECISION) {
                resourceReward[facilityType] = 10 * PRECISION;
            }
        }

        return resourceReward;
    }

    function calculateUserPower(uint tokenId, uint userPowerAmount) external view returns(uint) {
        uint powerLimit;
        uint powerReward;

        if (tokenId != deadTokenId) {
            if (houses[tokenId].activated == false) return 0;

            powerReward = setting.getResourceGenerationAmount(0, houses[tokenId].facilityLevel[0]) * (block.timestamp - houses[tokenId].lastResourceRewardTime[0]) / SECONDS_IN_A_DAY;
            powerLimit = setting.getPowerLimit(uint(houses[tokenId].facilityLevel[0]));
        }

        if (powerReward + userPowerAmount >= powerLimit) {
            return powerLimit;
        } else {
            return userPowerAmount + powerReward;
        }
    }

    /**
        @notice Calculate max power limit by user based on own houses
        @param tokenId: NFT Id
        @return max power limit
    */
    function calculateMaxPowerLimitByUser(uint tokenId) external view returns(uint) {
        uint powerLimit;

        if (tokenId != deadTokenId) {
            if (houses[tokenId].activated == false) return powerLimit;
            powerLimit = setting.getPowerLimit(uint(houses[tokenId].facilityLevel[0]));
        }

        return powerLimit;
    }

    /** 
        @notice Store recent token reward in house
        @param tokenId: House NFT Id
    */
    function updateTokenReward(uint tokenId) private onlyHasPermission {
        House storage house = houses[tokenId];

        house.tokenReward = getTokenReward(tokenId);
        house.lastDurability = helper.getDurabilityAtBreakpoint(
            block.timestamp, 
            house.hasConcreteFoundation ? 18 * PRECISION : 20 * PRECISION,
            house.lastFortificationTime, 
            [house.expireGardenTime, house.lastFirepitTime, house.lastFertilizedGardenTime, house.lastRepairTime],
            house.lastDurability
        );
        house.lastRepairTime = block.timestamp;
    }

    /**
        @notice Get house token reward
        @param tokenId: NFT id
        @return House token reward
    */
    function getTokenReward(uint tokenId) public view returns (uint) {
        House storage house = houses[tokenId];

        uint maxTokenReward = setting.getHarvestLimit(house.isRare) - house.totalHarvestedToken - house.tokenReward;
        
        return house.tokenReward + 
            helper.calculateTokenReward(
                house.depositedBalance, 
                maxTokenReward, 
                house.hasAddon, 
                house.isRare,
                house.hasBoost[0], 
                house.hasConcreteFoundation, 
                house.lastFortificationTime, 
                [house.expireGardenTime, house.lastFirepitTime, house.lastFertilizedGardenTime, house.lastRepairTime], 
                house.lastDurability
            );
    }

    /** 
        @notice Store recent house resource reward in house
        @param tokenId: House NFT Id
    */
    function updateResourceReward(uint tokenId) private onlyHasPermission {
        houses[tokenId].resourceReward = getResourceReward(tokenId);
        for (uint i = 1; i < 5; i++) {
            houses[tokenId].lastResourceRewardTime[i] = block.timestamp;
        }
    }

    /**
        @notice Check user has tree addon
        @param tokenId: NFT Id
    */
    function checkHavingTree(uint tokenId) external view returns (bool) {
        if (houses[tokenId].hasAddon[3]) return true;

        return false;
    }

    /**
        @notice Update token reward and update lastFertilizedGarden time
    */
    function fertilizeGarden(uint tokenId) external onlyHasPermission {
        updateTokenReward(tokenId);
        houses[tokenId].lastFertilizedGardenTime = block.timestamp + setting.getFertilizeGardenLastingDays();
    }

    /**
        @notice Activate overdrive for specific facility
        @param tokenId: House Id
        @param facilityType: 1 => lumber, 2 => brick, 3 => concrete, 4 => steel
     */
    function buyResourceOverdrive(uint tokenId, uint facilityType) external onlyHasPermission {
        updateResourceReward(tokenId);
        updateTokenReward(tokenId);
        houses[tokenId].hasBoost = [false, false, false, false, false];
        houses[tokenId].hasBoost[facilityType] = true;
    }

    /**
        @notice Activate overdrive for token
        @param tokenId: House Id
     */
    function buyTokenOverdrive(uint tokenId) external onlyHasPermission {
        updateTokenReward(tokenId);
        updateResourceReward(tokenId);
        houses[tokenId].hasBoost = [false, false, false, false, false];
        houses[tokenId].hasBoost[0] = true;
    }

    function canOverDrive(uint tokenId, uint boostType) external view returns(bool) {
        if (houses[tokenId].hasBoost[boostType]) 
            return false;
        
        return true;
    }

    /**
        @notice Set onsale
    */
    function setOnsale(uint tokenId, bool isSale) external onlyHasPermission {
        require(houses[tokenId].deadTime == 0, "House is dead");
        houses[tokenId].onSale = isSale;
    }

    /**
        @notice Get addon salvage and sell cost
        @param tokenId: NFT id
        @param addonId: Addon id
    */
    function getAddonSalvageCost(uint tokenId, uint addonId) external view returns(uint[5] memory, uint[5] memory) {
        return (setting.getSalvageCost(addonId, houses[tokenId].hasAddon));
    }

    function getBuyAddonDetails(uint tokenId) external view returns (address, bool, uint, bool[12] memory, uint, uint[3] memory) {
        House storage house = houses[tokenId];
        return (
            ownerOf(tokenId),
            house.activated,
            house.deadTime,
            house.hasAddon,
            house.expireGardenTime,
            house.lastFortificationTime
        );
    }

    /**
        @notice Get Helper details
        @param tokenId: houseNFT Id
    */
    function getHelperDetails(uint tokenId) external view returns (bool, bool, uint, uint, uint, uint, uint, uint, uint, bool, bool) {
        House storage house = houses[tokenId];

        return (
            house.isRare,
            house.hasBoost[0],
            house.expireGardenTime,
            house.lastFirepitTime,
            house.lastFertilizedGardenTime,
            house.lastRepairTime,
            house.lastRepairTime,
            house.lastDurability,
            house.activeToolshedType,
            house.hasConcreteFoundation,
            house.hasHarvester
        );
    }

    function getHasaddonAndToolshedType(uint tokenId) external view returns(bool[12] memory, uint) {
        return (
            houses[tokenId].hasAddon,
            houses[tokenId].activeToolshedType
        );
    }
    
}
