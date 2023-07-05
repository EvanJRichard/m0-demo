// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

/**@title An example written for interview with M0
 * @author Evan Richard
 * @notice This contract is for creating a sample token, the token representing interest in a basket of assets
 * @dev This uses Chainlink VRF Version 2.
 * @dev This contract is not intended to be used in production, and indeed cannot be compiled, it is a demo interface to show design
 */
contract ExampleToken is VRFConsumerBaseV2, AutomationCompatibleInterface {
    //  is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable,
    // ERC20SnapshotUpgradeable, AccessControlUpgradeable, PausableUpgradeable
    // Rebaseable
    /* Errors */
    error ExampleToken__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numHolders,
        uint256 tokenState
    );
    error ExampleToken__TransferFailed();
    error ExampleToken__RebaseFailed();
    error ExampleToken__ContractInactive();

    /* Type declarations */
    enum ContractState {
        // cruft from old demo
        OPEN,
        CALCULATING
    }

    /* State variables */
    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Rebase Variables
    uint256 private immutable i_interval;
    uint256 private immutable i_fee;
    uint256 private s_lastTimeStamp;
    uint256 private s_denomination;
    address payable[] private s_holders;
    ContractState private s_contractState; // ignore

    /* Events */
    event PerformedRebase(uint256 indexed requestId);
    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed player);

    /* Functions */
    constructor(
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint256 entranceFee,
        uint256 initialDenomination,
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_fee = entranceFee;
        s_contractState = ContractState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;
        s_denomination = initialDenomination;
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between rebase runs.
     * 2. The contact is open.
     * 3. Implicity, subscription is funded with LINK.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = ContractState.OPEN == s_contractState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        upkeepNeeded = (timePassed && isOpen);
        return (upkeepNeeded, "0x0");
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to perform the rebase
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert ExampleToken__UpkeepNotNeeded(
                address(this).balance,
                s_holders.length,
                uint256(s_contractState)
            );
        }
        uint256 newDenomination = rebase();
        s_denomination = newDenomination;
        emit PerformedRebase(newDenomination);
    }

    function rebase() private returns (uint256) {
        uint256 newDenomination = 1;
        // do some math and get a new scaling factor
        // this varied over time from "accept scaling factor directly as an input"
        // to "look at other updated asset contracts on chain and user stablecoin flows"
        // to "actually never calculate a new scaling factor, don't rebase at all,
        // just call mint() and burn() off chain because number of users is very small"
        return newDenomination;
    }

    /** Getter Functions */

    function getContractState() public view returns (ContractState) {
        return s_contractState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_holders[index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getFee() public view returns (uint256) {
        return i_fee;
    }

    function getNumberOfHolders() public view returns (uint256) {
        return s_holders.length;
    }

    // we don't use this anymore but for sake of time we are keeping an old interface
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal virtual override {}
}
