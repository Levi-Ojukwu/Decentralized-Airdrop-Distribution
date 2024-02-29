    // SPDX-License-Identifier: MIT

    pragma solidity ^0.8.20;

    import "./ERC20Token.sol";

    import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
    import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
    import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
    import "@openzeppelin/contracts/access/Ownable.sol";

    contract PriceDistrivbution is VRFConsumerBaseV2, Ownable {
        address public winner;
        address[] public participants;
        uint256 public priceAmount;
        uint256 public entryMultiplier = 1;
        uint256[]  randomWords;
        uint256 internal fee;
        uint256 public distributionStartTime;
        uint256 public minEntriesForDistribution;
        bool public isClaimed;
        bool private _isFulfillingRandomness = false;
        bytes32 internal keyHash;
        uint256 public prizePool;
        // bytes32 private _requestId;

        IERC20 public token;

        // Participant struct
        struct Participant {
            address participantAddress;
            uint256 entries;
        }

        struct RequestStatus {
        bool fulfilled; 
        bool exists;
        uint256[] randomWords;
    }
        

        // Enum of the participant level
        enum ParticipantionLevel {
            Beginner,
            Intermediate,
            Advanced
        }

        // Constructor
        constructor(
            address _vrfCoordinator, 
            address _linkToken, 
            bytes32 _keyHash, 
            uint256 _fee, 
            address _tokenAddress
        ) 
            VRFConsumerBaseV2(_vrfCoordinator)
            
        {
            keyHash = _keyHash;
            fee = _fee;
            token = IERC20(_tokenAddress);
        }


        // Mapping
        mapping(address => uint256) public participantEntries;
        mapping(address => ParticipantionLevel) public participantLevels;
        mapping(uint256 => RequestStatus) public s_requests;

        // Events
        event ParticipantRegisteredSuccessfully(address participant);
        event PrizeClaimedSuccessfully(address winner, uint amount);
        event EntryEarned(address participant, uint entries);
        event RequestFulfilled(uint256 requestId, uint256[] randomWords);
        event PrizeDistributionEvent(address[] winners, uint256[] rewards);
        event RequestSent(uint256 requestId, uint32 numWords);


        // This function registers a new participant
        function registerParticipant() external {
            require(!isParticipant(msg.sender), "Participant Already Registered");
            participants.push(msg.sender);
            // participantIndex[msg.sender] = participants.length;
            participantLevels[msg.sender] = ParticipatioLevel.Beginner;
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
        function gameParticipation(string memory _gameContent) external  {
            require(isParticipant(msg.sender), "Participant Not Registered");
            uint entriesEarned = calculateEntries(_gameContent);
            participantEntries[msg.sender] += entriesEarned;
            emit EntryEarned(msg.sender, entriesEarned);
        }

            // This function calculates the entry award based on the participant's level
        function calculateEntries(string memory _content) internal pure returns (uint) {
            ParticipantionLevel level = participantLevels[msg.sender];

            if (level == ParticipantionLevel.Beginner) {
                return 1;
            } else if (level == ParticipantionLevel.Intermediate) {
                return 2;
            } else {
                return 3;
            }
        }

        // This function is to update the participant's level, and only owner can perfom this function
        function updateParticipantLevel(address _participant, ParticipantionLevel  newLevel) external {
            require(msg.sender == owner, "Only Owner Can Update Participant Level");
            participantLevels[Participant] = newLevel;
        }

        // This is the callback function for chainlink VRF
        function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
            require(s_requests[_requestId].exists, "request not found");
            s_requests[_requestId].fulfilled = true;
            s_requests[_requestId].randomWords = _randomWords;
            emit RequestFulfilled(_requestId, _randomWords);
        }

        // This function selects the winner and distribute reward
        function selectWinnersAndDistribute(uint256 _randomNumber) internal {
            uint256 numberOfWinners = 1; 
            address[] memory winners = new address[](numberOfWinners);
            uint256[] memory rewards = new uint256[](numberOfWinners);

            for (uint256 i = 0; i < numberOfWinners && i < participants.length; i++) {
                uint256 winnerIndex = _randomNumber % participants.length;
                address winnerAddress = participants[winnerIndex].participantAddress;
                uint256 reward = calculateReward(participants[winnerIndex].entries);
                
                winners[i] = winnerAddress;
                rewards[i] = reward;
                delete participants[winnerIndex];
            }

            emit PrizeDistributionEvent(winners, rewards);

            for (uint256 i = 0; i < winners.length; i++) {
                distributeTokens(winners[i], rewards[i]);
            }
        }

        // This function gets the total entries
        function getTotalEntries() internal view returns (uint256) {
            uint256 totalEntries;
            for (uint256 i = 0; i < participants.length; i++) {
                totalEntries += participants[i].entries;
            }
            return totalEntries;
        }

        // This function calculates the reward or the participant
        function calculateReward(uint256 _entries) internal view returns (uint256) {
            return (prizePool * _entries) / getTotalEntries();
        }

        // This function distributes ERC20 tokens to as airdrop to th winner
        function distributeTokens(address _winner, uint256 _amount) internal {
            require(token.balanceOf(address(this)) >= _amount, "Insufficient balance in the contract");
            token.transfer(_winner, _amount);
        }
    }
    