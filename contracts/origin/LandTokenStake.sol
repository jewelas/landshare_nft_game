pragma solidity ^0.6.0;

import "./LandToken.sol";

    


contract LandTokenStake {
    
   
    using SafeMath for uint256;

    address owner;
    LandToken private token; 
    uint public tokensStaked;
    uint public rewardPool; 
    uint public rewardPerToken = 0; 
    address [] public stakers; 
    uint thing = 10000000000000000000000;
    mapping(address => uint) public amountStaked;  
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaked; 
    mapping(address => uint) public rewardTally; 

    constructor(LandToken _token, address _owner) public {
        owner = _owner; 
        token = _token; 
    }


    function deposit(uint amount) public {
         
        
        uint amountGoingInAdjusted = SafeMath.div(SafeMath.mul(thing, amount), 10101010101010101010101);
                                                                              
        
        amountStaked[msg.sender] = SafeMath.add(amountGoingInAdjusted, amountStaked[msg.sender]); 
        rewardTally[msg.sender] = SafeMath.add(rewardTally[msg.sender], SafeMath.div(SafeMath.mul(rewardPerToken, amountGoingInAdjusted), thing));
        tokensStaked = SafeMath.add(tokensStaked, amountGoingInAdjusted);
        rewardPool = SafeMath.add(rewardPool, SafeMath.sub(amount, amountGoingInAdjusted));

        
        //add to stakers
        if (hasStaked[msg.sender] != true) {
            stakers.push(msg.sender); 
        }

        //verify has and is staked
        hasStaked[msg.sender] = true;
        isStaked[msg.sender] = true; 

        token.transferFrom(msg.sender, address(this), amount);

    }

    function distribute(uint r) public {
        require(msg.sender==owner);
        require(tokensStaked > 0, "no tokens staked");
        require(r <= rewardPool, "distribution larger than pool");
        rewardPerToken = SafeMath.add(rewardPerToken, SafeMath.div(SafeMath.mul(r, thing), tokensStaked)); 
        rewardPool = SafeMath.sub(rewardPool, r);

    }

    function computeReward(address x) public view returns(uint reward) {
        if (rewardTally[x] > SafeMath.div(SafeMath.mul(amountStaked[x], rewardPerToken), thing)) {
            return 0;
        }
        else {
        return SafeMath.sub(SafeMath.div(SafeMath.mul(amountStaked[x], rewardPerToken), thing), rewardTally[x]); 
        }
    }

    function withdrawReward() public  {
        require (computeReward(msg.sender) > 0, "no reward found"); 
        uint rewardAmt = computeReward(msg.sender);
        rewardTally[msg.sender] = SafeMath.div(SafeMath.mul(amountStaked[msg.sender], rewardPerToken), thing);
        token.transfer(msg.sender, rewardAmt);
    }

    function withdraw(uint withdrawAmt) public {
        
        require(isStaked[msg.sender] == true, "No deposit found");
        require(amountStaked[msg.sender] >= withdrawAmt, "Can't withdraw more than your deposit");
     
        
        if (computeReward(msg.sender) > 0) {
            withdrawReward();
        }
        
        if (rewardTally[msg.sender] < SafeMath.div(SafeMath.mul(rewardPerToken, withdrawAmt), thing)) {
            rewardTally[msg.sender] = 0;
        }
        else {
            rewardTally[msg.sender] = SafeMath.sub(rewardTally[msg.sender], SafeMath.div(SafeMath.mul(rewardPerToken, withdrawAmt), thing));
        }
        amountStaked[msg.sender] = SafeMath.sub(amountStaked[msg.sender], withdrawAmt); 
       
        tokensStaked = SafeMath.sub(tokensStaked, withdrawAmt); 
        

        if (amountStaked[msg.sender] == 0) {    
         isStaked[msg.sender] == false; 
        }

        token.transfer(msg.sender, withdrawAmt);
    }

    function addToRewardPool(uint x) public {
        require(token.allowance(msg.sender, address(this)) > x, "insufficient allowance" );
        rewardPool = SafeMath.add(rewardPool, x); 
        
        token.transferFrom(msg.sender, address(this), x);
    }



}
