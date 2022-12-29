// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FakeLandToken is ERC20 {
    constructor() ERC20("FakeLand", "FL") {
        _mint(msg.sender, 1000 ether);
    }
}
