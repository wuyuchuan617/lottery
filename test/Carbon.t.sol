// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Carbon} from "../src/Carbon.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

contract CarbonTest is Test {
    Carbon public carbon;
    address admin;
    address seller;
    address buyer;
    address public constant WETH = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;
    // address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function setUp() public {
        // Fork Ethereum mainnet at block 15_941_703
        string memory rpc = vm.envString("MAINNET_RPC_URL");
        vm.createSelectFork(rpc, 15_941_703);

        admin = makeAddr("admin");
        seller = makeAddr("seller");
        buyer = makeAddr("buyer");

        vm.startPrank(admin);
        carbon = new Carbon("Carbon", "CBN");
        vm.stopPrank();
    }

    function testRegister() public {
        // 1. seller claim to mint NFT
        vm.startPrank(seller);
        carbon.register(2);
        assertEq(carbon.balanceOf(seller), 2 * 10 ** 18);
        vm.stopPrank();

        // 2.  claim emmision
        uint256 claimAmount = 1 * 10 ** 18;

        vm.startPrank(seller);
        carbon.claimEmmision(claimAmount);
        assertEq(carbon.emission(seller), claimAmount);
        vm.stopPrank();

        vm.startPrank(buyer);
        carbon.claimEmmision(claimAmount);
        assertEq(carbon.emission(buyer), claimAmount);
        vm.stopPrank();

        // 3. buyer buy carbon token via ETH
        vm.startPrank(buyer);
        uint256 buyAmount = 1000;

        // 3-1. Calculate Fee
        (uint256 feeAmount, uint256 protocalFeeAmount) = carbon.calulateFee(buyAmount);
        uint256 totalAmount = buyAmount + feeAmount + protocalFeeAmount;
        uint256 orgSellerbalance = carbon.balanceOf(seller);

        // 3-2. Give buyer ETH -> WETH
        deal(address(buyer), 10000 ether);
        carbon.buy{value: totalAmount}(seller, buyAmount, feeAmount, protocalFeeAmount);

        assertEq(carbon.balanceOf(seller), orgSellerbalance - buyAmount);
        assertEq(carbon.balanceOf(buyer), buyAmount); // 1000
        assertEq(IERC20(WETH).balanceOf(seller), buyAmount + feeAmount); // 1020
        assertEq(IERC20(WETH).balanceOf(buyer), 0); // 0
        assertEq(IERC20(WETH).balanceOf(address(carbon)), protocalFeeAmount); // 10

        vm.stopPrank();

        // 4. Offset
        orgSellerbalance = carbon.balanceOf(seller);
        uint256 orgSellerEmmision = carbon.emission(seller);

        vm.startPrank(seller);
        uint256[] memory burnTokenIds = carbon.offset(1);

        assertEq(carbon.balanceOf(seller), orgSellerbalance - 1 * 10 ** 18); // 0
        assertEq(carbon.emission(seller), orgSellerEmmision - 1 * 10 ** 18); // 0
        console.log(burnTokenIds[0]); //  11

        vm.stopPrank();
    }
}
