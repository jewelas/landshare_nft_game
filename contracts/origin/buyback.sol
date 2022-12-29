pragma solidity ^0.6.0;


import './LandTokenStake.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol'; 
import './stake.sol';

contract buyback {
    
    uint256 MAX_INT = 2**256 - 1; 
    LandToken public token;
    LandTokenStake public LS;
    address[] public paths;
    address owner; 
    IBEP20 stablecoin = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
 
    constructor(LandToken _token, LandTokenStake _LS) public {
        token = _token;
        LS = _LS; 
        paths = [0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56, 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c, address(_token)]; 
        owner = msg.sender; 
    }


    

    IUniswapV2Router02 router = IUniswapV2Router02(0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7);


    function approveTokens() public {
        require(msg.sender==owner);
        token.approve(address(LS), MAX_INT);
        stablecoin.approve(0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7, MAX_INT);
    }

    function approveNewToken(address newTokenAddy, address newRouter) public {
        require(msg.sender==owner);
        IBEP20 newToken = IBEP20(newTokenAddy);
        newToken.approve(newRouter, MAX_INT); 
    }

    function modifyPath1(address x) public {
        require(msg.sender==owner);
        delete paths; 
        paths = [x, address(token)];
    }
    
    function modifyPath2(address first, address second) public {
        require(msg.sender==owner);
        delete paths; 
        paths = [first, second, address(token)];
    }

    function changeRouter(address x) public {
        require(msg.sender==owner);
        router = IUniswapV2Router02(x);
    }

    function getMoney(address x) public {
        require(msg.sender==owner); 
        stake pv = stake(x);

        //calculates the daily buyback based on the idea of 25% vault value buyback annually
        uint amount = pv.totalVaultAmount() / 1460;
        pv.adminWithdraw(amount); 
    }
    
    function swapperV2 (uint amountIn, uint min, uint time) public {
        require(msg.sender==owner);
        router.swapExactTokensForTokens(amountIn, min, paths, address(this), time);
    }

    function sendBuyBack(uint x) public {
        require(msg.sender==owner);
        LS.addToRewardPool(x); 
    }
}
