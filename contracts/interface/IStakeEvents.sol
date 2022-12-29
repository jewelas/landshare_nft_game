//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract IStakeEvents {
    event Stake(address indexed user, uint indexed tokenId, uint amount);
    event Unstake(address indexed user, uint indexed tokenId, uint amount);
}