// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20{
    constructor() ERC20("TestToken", "token"){
        _mint(msg.sender, 21000000 * 10 ** decimals());
        
    }

    function mint(address to , uint256 amount) public {
        _mint(to, amount);
    }
}
