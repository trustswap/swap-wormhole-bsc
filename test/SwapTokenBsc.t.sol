// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SwapToken} from "../src/SwapTokenBsc.sol";

import "wormhole-solidity-sdk/testing/WormholeRelayerTest.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract SwapTokenBscTest is WormholeRelayerBasicTest {
    SwapToken public swapSource;
    SwapToken public swapTarget;

    ERC20Mock public token;

    function setUpGeneral() public override {
        setMainnetForkChains(2, 4);
    }

    function setUpSource() public override {
        swapSource = new SwapToken(
            address(relayerSource),
            address(tokenBridgeSource),
            address(wormholeSource)
        );

        token = createAndAttestToken(sourceChain);
    }

    function setUpTarget() public override {
        swapTarget = new SwapToken(
            address(relayerTarget),
            address(tokenBridgeTarget),
            address(wormholeTarget)
        );
    }

    function testRemoteDeposit() public {
        uint256 amount = 19e17;
        token.approve(address(swapSource), amount);

        console.log("a");
        vm.selectFork(targetFork);
        address recipient = 0x1234567890123456789012345678901234567890;

        vm.selectFork(sourceFork);
        uint256 cost = swapSource.quoteCrossChainDeposit(targetChain);
        console.log("b");

        vm.recordLogs();
        swapSource.sendCrossChainDeposit{value: cost}(
            targetChain,
            address(swapTarget),
            recipient,
            amount,
            address(token)
        );
        console.log("c");

        performDelivery();
        console.log("d");

        vm.selectFork(targetFork);
        address wormholeWrappedToken = tokenBridgeTarget.wrappedAsset(
            sourceChain,
            toWormholeFormat(address(token))
        );
        console.log("e");

        assertEq(IERC20(wormholeWrappedToken).balanceOf(recipient), amount);
    }
}
