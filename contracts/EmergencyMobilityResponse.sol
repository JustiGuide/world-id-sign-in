// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface MobilityRightsProtocol {
    function issueRight(bytes32, string memory, uint8, uint256, bytes32) external;
}

interface MobilityPricingOracle {
    function setEmergencyPricing(string memory, int256) external;
}

contract EmergencyMobilityResponse {
    struct EmergencyEvent {
        string eventType;
        string[] affectedRegions;
        uint256 severity;
        uint256 startTime;
        bool active;
    }

    mapping(bytes32 => EmergencyEvent) public emergencies;

    address public rightsContract;
    address public pricingOracle;
    address public authorized;

    modifier onlyAuthorized() {
        require(msg.sender == authorized, "Not authorized");
        _;
    }

    constructor(address _rightsContract, address _pricingOracle, address _auth) {
        rightsContract = _rightsContract;
        pricingOracle = _pricingOracle;
        authorized = _auth;
    }

    function declareEmergency(
        string memory _eventType,
        string[] memory _affectedRegions,
        uint256 _severity
    ) external onlyAuthorized {
        bytes32 emergencyId = keccak256(
            abi.encodePacked(_eventType, block.timestamp)
        );

        emergencies[emergencyId] = EmergencyEvent({
            eventType: _eventType,
            affectedRegions: _affectedRegions,
            severity: _severity,
            startTime: block.timestamp,
            active: true
        });

        for (uint256 i = 0; i < _affectedRegions.length; i++) {
            MobilityPricingOracle(pricingOracle).setEmergencyPricing(
                _affectedRegions[i],
                -10000 * 10**18
            );
        }
    }

    function emergencyVerification(
        bytes32 _userDID,
        string memory _originRegion,
        bytes32 _emergencyId
    ) external {
        EmergencyEvent memory emergency = emergencies[_emergencyId];
        require(emergency.active, "No active emergency");
        MobilityRightsProtocol(rightsContract).issueRight(
            _userDID,
            "temporary_protection",
            10,
            180 days,
            _emergencyId
        );
    }
}
