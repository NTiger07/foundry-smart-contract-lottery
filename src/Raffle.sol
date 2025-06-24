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
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title Raffle
 * @author 0xFreddie
 * @notice This contract is for creating a raffle contract.
 * @dev Implements Chainlink VRF.
 */
contract Raffle is VRFConsumerBaseV2Plus {
    // ERRORS
    error Raffle__NotEnoughEthSent();
    error Raffle__NotEnoughTimePassed();

    // STATE VARIABLES
    uint256 immutable i_entranceFee;
    uint256 immutable i_interval; // @dev The time interval between raffle draws in seconds.
    address payable[] private s_players;
    uint256 private immutable s_lastTimeStamp;

    // Chainlink VRF variables
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    // EVENTS
    event RaffleEntered(address indexed player, uint256 amount);

    constructor(
        uint256 _entryFee,
        uint256 _interval,
        address vrfCoordinator,
        bytes32 keyHash,
        uint256 subscriptionId,
        uint32 callbackGasLimit,
        uint32 numWords
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = _entryFee;
        i_interval = _interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        numWords = numWords;
    }

    function enterRaffle() external payable {
        if (msg.value <= i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender, msg.value);
    }

    // get a random number from Chainlink VRF
    // pick winner with random number
    // be automated
    function pickWinner() external {
        if ((block.timestamp - s_lastTimeStamp) >= i_interval) {
            revert Raffle__NotEnoughTimePassed();
        }

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS, 
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: false
                    })
                )
            });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);

    }

    function withdraw() public {}

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {}
}
