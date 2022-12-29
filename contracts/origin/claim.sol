pragma solidity ^0.6.0;

import "./LandToken.sol";


contract claim {
    
    using SafeMath for uint256; 

    LandToken public LAND;
    address [] public participants; 
    mapping (address => uint) public blocksClaimed;
    mapping (address => uint ) public blockAmount; 
    mapping (address => bool) public isParticipant;

    uint public startTime = 1630506600;

    address public owner; 

    constructor (address [] memory _participants, uint [] memory _blockAmounts, address _owner, address _LAND) public {
        participants = _participants; 
        owner = _owner;  
        LAND = LandToken(_LAND);

        for(uint i; i < participants.length; i++) {
            isParticipant[participants[i]] = true; 
            blockAmount[participants[i]] += _blockAmounts[i]; 
        }
    }



    function fundOut(uint amountOut) public {
        require(msg.sender==owner, "only owner");
        LAND.transfer(msg.sender, amountOut);
      
    }
    
    function clearParticipantsList() public {
        require(msg.sender==owner, "only owner");
         for(uint i; i < participants.length; i++) {
            isParticipant[participants[i]] = false; 
            blockAmount[participants[i]] = 0; 
        }
        delete participants; 
    }
    
    function newParticipantsList (address [] memory _participants, uint[] memory _blockAmounts) public {
        require(msg.sender==owner, "only owner");
        participants = _participants;
        for(uint i; i < participants.length; i++) {
            isParticipant[participants[i]] = true; 
            blockAmount[participants[i]] += _blockAmounts[i]; 
        }
    }
    

    function getWithdrawableBlocks(address x) public view returns(uint) {
        require(isParticipant[x] == true, "not a participant");

         if (block.timestamp < startTime) {
            return 0; 
        }        

        uint eligibleBlocks = (block.timestamp.sub(startTime)).div(259200) + 1; 

        if (eligibleBlocks > 95) {
            eligibleBlocks = 95; 
        }

        uint withdrawableBlocks = eligibleBlocks.sub(blocksClaimed[x]);

        return (withdrawableBlocks);
    }

    function getWithdrawAmount(address x) public view returns(uint) {
        require(isParticipant[x] == true, "not a participant");


        uint claimableAmt = getWithdrawableBlocks(x).mul(blockAmount[x]);

        return (claimableAmt); 


    }

    function withdraw() public {
        require(isParticipant[msg.sender] == true, "participants only");
        require(getWithdrawAmount(msg.sender) > 0, "nothing to claim");


        //set amount out
        uint amountOut = getWithdrawAmount(msg.sender);

        //set blocks withdrawn
        blocksClaimed[msg.sender] += getWithdrawableBlocks(msg.sender); 


        LAND.transfer(msg.sender, amountOut);

    }
}

