//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract IWhitelist {
    function isWhitelistedAddress(address _address) external view virtual returns (bool);
}