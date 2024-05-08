// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "forge-std/Test.sol";

import "./ERC404.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SafeMath.sol";

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
    function approve(address spender, uint256 amount) external returns (bool);
}

contract Carbon is ERC404 {
    using SafeMath for uint256;

    address weth = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;
    // address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    mapping(address => uint256) public emission;

    constructor(string memory _name, string memory _symbol) ERC404(_name, _symbol, 18, 100, msg.sender) {}

    function tokenURI(uint256 id_) public pure override returns (string memory) {
        return
            string.concat("https://ipfs.io/ipfs/QmXPXhtK2Vdxr6eYz4avcZXiS5fcHdp3qWpa2trmZKm7Sr/", Strings.toString(id_));
    }

    function register(uint256 amount) public {
        balanceOf[msg.sender] += amount * 10 ** 18;
        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender);
        }
    }

    function claimEmmision(uint256 amount) public {
        emission[msg.sender] += amount;
    }

    function calulateFee(uint256 amount) public pure returns (uint256 fee, uint256 protocalFee) {
        fee = (amount * 2) / 100;
        protocalFee = (amount * 1) / 100;
    }

    function buy(address sellerAddr, uint256 amount, uint256 fee, uint256 protocalFee) public payable {
        allowance[sellerAddr][msg.sender] = amount;

        require(allowance[sellerAddr][msg.sender] >= amount, "Insufficient allowance");
        require(balanceOf[sellerAddr] >= amount, "Insufficient balance");

        uint256 totalCost = amount.add(fee).add(protocalFee);
        require(msg.value >= totalCost, "Insufficient ETH sent");
        IWETH(weth).deposit{value: msg.value}();
        IWETH(weth).transfer(address(this), msg.value);

        IERC20(weth).transferFrom(address(this), address(this), protocalFee);
        IERC20(weth).transferFrom(address(this), sellerAddr, amount + fee);

        transferFrom(sellerAddr, msg.sender, amount);
    }

    function offset(uint256 amount) public returns (uint256[] memory burnTokenIds) {
        require(balanceOf[msg.sender] >= amount * 10 ** 18, "Insufficient balance");
        
        burnTokenIds = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            emission[msg.sender] -= 10 ** 18;
            uint256 lastTokenId = _owned[msg.sender][_owned[msg.sender].length - 1];
            burnTokenIds[i] = lastTokenId;
            transferFrom(msg.sender, address(0), lastTokenId);
        }
    }
}
