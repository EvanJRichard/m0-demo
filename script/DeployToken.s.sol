// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {ExampleToken} from "../src/ExampleToken.sol";
import {AddConsumer, CreateSubscription, FundSubscription} from "./Interactions.s.sol";

contract DeployExampleToken is Script {
    function run() external returns (ExampleToken, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        AddConsumer addConsumer = new AddConsumer();
        (
            uint64 subscriptionId,
            bytes32 gasLane,
            uint256 automationUpdateInterval,
            uint256 raffleEntranceFee,
            uint256 initialDenomination,
            uint32 callbackGasLimit,
            address vrfCoordinatorV2,
            address link,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(
                vrfCoordinatorV2,
                deployerKey
            );

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                vrfCoordinatorV2,
                subscriptionId,
                link,
                deployerKey
            );
        }

        vm.startBroadcast(deployerKey);
        ExampleToken exampleToken = new ExampleToken(
            subscriptionId,
            gasLane,
            automationUpdateInterval,
            raffleEntranceFee,
            initialDenomination,
            callbackGasLimit,
            vrfCoordinatorV2
        );
        vm.stopBroadcast();

        // We already have a broadcast in here
        addConsumer.addConsumer(
            address(exampleToken),
            vrfCoordinatorV2,
            subscriptionId,
            deployerKey
        );
        return (exampleToken, helperConfig);
    }
}
