// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./ERC20Token.sol";

import {VRFCoordinatorV2Interface} from "@chainlink/contracts@0.8.0/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts@0.8.0/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {ConfirmedOwner} from "@chainlink/contracts@0.8.0/src/v0.8/shared/access/ConfirmedOwner.sol";

contract PriceDistrivbution is VRFConsumerBaseV2 {
    address public owner;
    address public winner;
    address[] public participants;
    uint public priceAmount;
    uint public entryMultiplier = 1;
    uint public randomResult;
    uint internal fee;
    uint public distributionStartTime;
    uint public minEntriesForDistribution;
    bool public isClaimed;
    bool private _isFulfillingRandomness = false;
    bytes32 internal keyHash;
    

    // Enum of the participant level
    enum ParticipationLevel {
        Beginner,
        Intermediate,
        Advanced
    }

    // Constructor
    constructor(address _vrfCoordinator, address _linkToken, bytes32 _keyHash, uint256 _fee, address _tokenAddress) 
        Ownable(msg.sender)
        VRFConsumerBase(_vrfCoordinator, _linkToken)
    {
        keyHash = _keyHash;
        fee = _fee;
        token = IERC20(_tokenAddress);
    }
    // Mapping
    mapping(address => uint256) public participantEntries;
    mapping(address => ParticipationLevel) public participantLevels;

    // Events
    event ParticipantRegisteredSuccessfully(address participant);
    event PrizeClaimedSuccessfully(address winner, uint amount);
    event EntryEarned(address participant, uint entries);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner Can Call This Functions");
        _;
    }

    modifier notwner() {
        require(msg.sender != owner, "Owners Cannot Call This function");
        _;
    }

    // This function registers a new participant
    function registerParticipant() external notwner{
        require(!isParticipant(msg.sender), "Participant Already Registered");
        participants.push(msg.sender);
        participantIndex[msg.sender] = participants.length;
        participantLevels[msg.sender] = ParticipationLevel.Beginner;
        emit ParticipantRegisteredSuccessfully(msg.sender);
    }

    // This function checks if the address is already registered as a participant
    function isParticipant(address _address) public view returns (bool) {
        for (uint i = 0; i < participants.length; i++) {
            if (participants[i] == _address) {
                return true;
            }
        }
        return false;
    }

    // This function allows the participant to engage in the game to earn entry
    function gameParticipation(string memory _gameContect) external notwner {
        require(isParticipant(msg.sender), "Participant Not Registered");
        uint entriesEarned = calculateEntries(_gameContent);
        participantEntries[msg.sender] += entriesEarned;
        emit EntryEarned(msg.sender, entriesEarned);
    }

        // This function calculates the entry award based on the participant's level
    function calculateEntries(string memory _content) internal pure returns (uint) {
        ParticipationLevel level = participantLevels[msg.sender];

        if (level == ParticipationLevel.Beginner) {
            return 1;
        } else if (level == ParticipationLevel.Intermediate) {
            return 2;
        } else {
            return 3;
        }
    }

    // This function is to update the participant's level, and only owner can perfom this function
    function updateParticipantLevel(address _participant, ParticipationLevel = newLevel) external onlyOwner {
        require(msg.sender == owner, "Only Owner Can Update Participant Level");
        participantLevels[participant] = newLevel;
    }

    // This is the callback function for chainlink VRF
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(requestId == _requestId, "Invalid request ID");
        require(!_isFulfillingRandomness, "Function is already being executed");
        _isFulfillingRandomness = true;
        randomResult = randomness;
        selectWinnersAndDistribute(randomResult);
        _isFulfillingRandomness = false;
    }
}