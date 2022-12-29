//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract IMarketplace {
    function addItem(uint tokenId, uint price) public view virtual returns (uint);
    function removeItem(uint tokenId) public view virtual returns (uint);
}
