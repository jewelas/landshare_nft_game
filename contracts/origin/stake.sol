pragma solidity ^0.6.0;

import "./LandToken.sol";
import './buyback.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';

contract stake {
    
    using SafeMath for uint256; 
    using SafeBEP20 for IBEP20;

    address owner;
    LandToken private token;
    IBEP20 private busd; 
    uint public totalVaultAmount; 
    uint private amountOut; 
    uint public yieldFarm; 
    uint public totalVaultCapacity = 346000000000000000000000; 
    uint public landRatio = 8; 
    uint public lastBuyBack = 0; 
    address public buyback; 
    address[] private stakers; 
    
    mapping(address => uint) public balanceOf; //percentage of total vault capacity in wei 
    mapping(address => uint) public depositStart; 
    mapping(address => uint) public initialDepositStart;
    mapping(address => bool) public isDeposited; 
    // mapping(address => uint) public harvestAmountBUSD;
    // mapping(address => uint) public harvestAmountLand;
    mapping(address => bool) public hasStaked; 

    mapping(address => uint) public bankedHarvestLand;
    mapping(address => uint) public bankedHarvestBUSD;  

    uint currentAPR = 7714333082402223; //stable coin apr, for conversion see below
    uint landAPR = 12535791258903612;  // land token apr (relative to a $1 land token, mulitply by land token price for actual apr), for conversion see below 

    // 1002863300712289 / desiredAPR = contract adjusted APR 
    // 1002863300712289 / 0.1 = approx 1e16 
    // 1002863300712289 / 0.2 = approx 5e15
    // 0.25 = 4e15
    // 0.3 = 33e14
    // 1 = 1e15
   

   
    
    constructor(LandToken _token, address _buyback, address _owner, address _busd) public {
        owner = _owner; 
        token = _token; 
        buyback = _buyback;
        busd = IBEP20(_busd);
    }
    
    //changes vault capacity, to be used when new properties obtained or liquidated 
    function changeVaultCapacity(uint newCapacity) public {
        require(msg.sender==owner, 'only contract owner'); 
        totalVaultCapacity = newCapacity; 
    }

    function changeLandRatio(uint newRatio) public {
        require(msg.sender==owner, 'only owner'); 
        landRatio = newRatio; 
    }

    function setCurrentAPR(uint newAPR) public {
        require(msg.sender==owner);
        require(newAPR <= 12535791258903612 && newAPR >= 3342877669040963, "APR must be between 8 and 30 percent");
        currentAPR = newAPR; 
    }
    
    function setLandAPR(uint newAPR) public {
        require(msg.sender==owner);
        require(newAPR <= 12535791258903612 && newAPR >= 3342877669040963, "APR must be between 8 and 30 percent");
        landAPR = newAPR; 

    }


    function deposit(uint amountSpend) public {
        require(totalVaultAmount + amountSpend <= totalVaultCapacity, 'Vault is full'); 
        require(SafeMath.div(SafeMath.add(amountSpend, balanceOf[msg.sender]), landRatio) <= token.balanceOf(msg.sender), "insufficient LAND token holdings.");

        

        if (isDeposited[msg.sender] != true) {
            initialDepositStart[msg.sender] = block.timestamp;
            depositStart[msg.sender] = initialDepositStart[msg.sender]; 
        }
        else {
            storeHarvest(msg.sender);
            depositStart[msg.sender] = block.timestamp; 
        }
        
    
        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender); 
        }
        
        isDeposited[msg.sender] = true;  
        hasStaked[msg.sender] = true;
       
        totalVaultAmount = totalVaultAmount + amountSpend; 
        balanceOf[msg.sender] = SafeMath.add(balanceOf[msg.sender], amountSpend);

        busd.safeTransferFrom(msg.sender, address(this), amountSpend);

        
    }
    function withdraw(uint amount) public {
        require(isDeposited[msg.sender]==true, "Error, no previous deposit");
        require(amount <= balanceOf[msg.sender], "Can't withdraw more than your deposit"); 
        require(SafeMath.div(balanceOf[msg.sender], landRatio) <= token.balanceOf(msg.sender), "insufficient LAND token holdings.");
        harvest(); 

        //reset deposit data
        totalVaultAmount = SafeMath.sub(totalVaultAmount, amount); 
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], amount);
        if(balanceOf[msg.sender]==0){
            isDeposited[msg.sender] = false; 
        }
        
        //send back their balance
        busd.safeTransfer(msg.sender, amount);

        
    }
    function harvest() public {
        require(isDeposited[msg.sender]==true, "Error, no previous deposit");
        require(depositStart[msg.sender] > 0, "no harvest yet"); 
        require(SafeMath.div(balanceOf[msg.sender], landRatio) <= token.balanceOf(msg.sender), "insufficient LAND token holdings.");
        
        //interest calc BUSD
        uint _harvestAmountBUSD = getHarvestAmountBUSD();
        
        
        //interest calc LAND 
        uint _harvestAmountLand = getHarvestAmountLand();
        
        //reset harvest amount and deposit start time 
        bankedHarvestBUSD[msg.sender] = 0;
        bankedHarvestLand[msg.sender] = 0; 
        depositStart[msg.sender] = block.timestamp;

        busd.safeTransfer(msg.sender, _harvestAmountBUSD);
        token.mint(msg.sender, _harvestAmountLand); 

       
    }

 
    function getHarvestAmountBUSD() public view returns (uint) {
        uint depositTime = SafeMath.sub(block.timestamp, depositStart[msg.sender]); 
        uint interestPerSecond = SafeMath.div(SafeMath.mul(31668017, balanceOf[msg.sender]), currentAPR);
        uint harvestAmount = SafeMath.add(SafeMath.mul(interestPerSecond, depositTime), bankedHarvestBUSD[msg.sender]);  
        return harvestAmount;
    }
    
    function getHarvestAmountLand() public view returns (uint) {
        uint depositTime = SafeMath.sub(block.timestamp, depositStart[msg.sender]); 
        uint interestPerSecond = SafeMath.div(SafeMath.mul(31668017, balanceOf[msg.sender]), landAPR);
        uint harvestAmount = SafeMath.add(SafeMath.mul(interestPerSecond, depositTime), bankedHarvestLand[msg.sender]);  
        return harvestAmount;
    }

    //allows buyback contract to withdraw up to 25% of vault funds for buybacks
    function adminWithdraw(uint amount) public {
        require(msg.sender==buyback); 
        require(SafeMath.add(amount, amountOut) < SafeMath.div(totalVaultAmount, 4), "can't withdraw more than 25% of vault before paying back");
        require(amount <= SafeMath.div(totalVaultAmount, 1460), "cannot withdraw more than established buyback amount");
        require(block.timestamp > SafeMath.add(lastBuyBack, 86000), "only one buyback per 24 hours");
    
       lastBuyBack = block.timestamp; 
        amountOut = SafeMath.add(amountOut, amount); 
         busd.safeTransfer(buyback, amount); 
    }

    function yieldFarming(uint amount) public {
        require(msg.sender==owner);
        require(SafeMath.add(amount, amountOut) < SafeMath.div(totalVaultAmount, 4), "can't withdraw more than 25% of vault before paying back");
        require(SafeMath.add(yieldFarm, amount) < SafeMath.div(totalVaultAmount, 5), "can't withdraw more than 20% of vault for yield farm");
        amountOut = SafeMath.add(amount, amountOut); 
        yieldFarm = SafeMath.add(amount, yieldFarm);
        busd.safeTransfer(owner, amount); 
    }

    //this is how admins put the money back into the vault after withdrawing. 
    function adminDeposit(uint amount) public {
        require(msg.sender==owner); 
        require(amount <= amountOut);
        amountOut = SafeMath.sub(amountOut, amount); 
        busd.safeTransferFrom(msg.sender, address(this), amount); 
        
    }
    
    function yieldFarmDeposit(uint amount) public {
        require(msg.sender==owner); 
        require(amount <= amountOut);
        require(amount <= yieldFarm);
        amountOut = SafeMath.sub(amountOut, amount); 
        yieldFarm = SafeMath.sub(yieldFarm, amount); 
        busd.safeTransferFrom(msg.sender, address(this), amount); 
        
    }
    

    //function to invoke a harvest banking, used when APR values need to be changed but existing harvest value must be retained.
    //also called when additonal deposit is made
    
    function storeHarvest(address x) public {
     
                //bank BUSD harvest calc
                uint depositTime = SafeMath.sub(block.timestamp, depositStart[x]); 
                uint interestPerSecondBUSD = SafeMath.div(SafeMath.mul(31668017, balanceOf[x]), currentAPR);
                
              
                //bank Land Harvest calc
                uint interestPerSecondLand = SafeMath.div(SafeMath.mul(31668017, balanceOf[x]), landAPR);
                
               
                //reset deposit start time 
                depositStart[x] = block.timestamp;

                //set banked harvest 
                bankedHarvestBUSD[x] = SafeMath.add(SafeMath.mul(interestPerSecondBUSD, depositTime), bankedHarvestBUSD[x]); 
                bankedHarvestLand[x] = SafeMath.add(SafeMath.mul(interestPerSecondLand, depositTime), bankedHarvestLand[x]);  
                
    }

 
    function getAmountWithdrawn() public view returns (uint){
        return amountOut; 
    }
    function getStakers() public view returns (address[] memory ) {
        return stakers; 
    }
  
}
