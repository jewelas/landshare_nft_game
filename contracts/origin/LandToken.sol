pragma solidity ^0.6.0;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol';

contract LandToken is BEP20 {
   

    address public minter; 

    event MinterChanged(address indexed from, address to);

    constructor() public BEP20("Landshare Token", "LAND") {
        minter = msg.sender; 
       
       //inital token mint, covers presale tokens, team tokens and liqudity
       mint(msg.sender, 4000000000000000000000000); 
    }

    //passes minter role to contract on deployment
    function passMinterRole(address contractMint) public returns (bool) {
        require(contractMint != address(0));
        require(msg.sender == minter);
        minter = contractMint; 

        emit MinterChanged(msg.sender, contractMint);
        return true; 
    }

    function mint(address account, uint amount) public {
        require(totalSupply() + amount <= 10000000000000000000000000, "supply cap reached.");
        require(msg.sender == minter); 
        _mint(account, amount);
    }

    function burn(uint amount) public {
        _burn(msg.sender, amount); 
    }
    
    
   
}