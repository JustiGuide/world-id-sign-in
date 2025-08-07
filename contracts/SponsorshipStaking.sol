// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface MobilityRightsProtocol {
    function issueRight(bytes32, string memory, uint8, uint256, bytes32) external;
    function revokeRight(bytes32, string memory) external;
}

interface IEmploymentVerifier {
    function verifyEmployment(bytes32, bytes32) external returns (bool);
}

interface IPayrollOracle {
    function verifySalary(bytes32, uint256) external returns (bool);
}

contract SponsorshipStaking {
    struct SponsorshipConditions {
        uint256 minimumSalary;
        string requiredRole;
        bytes32 employmentContractHash;
        uint256 performanceThreshold;
    }

    struct Sponsorship {
        address sponsor;
        bytes32 beneficiaryDID;
        uint256 stakeAmount;
        string rightType;
        uint256 startTime;
        uint256 duration;
        bool active;
        SponsorshipConditions conditions;
    }

    mapping(bytes32 => Sponsorship) public sponsorships;
    mapping(address => uint256) public sponsorReputation;

    uint256 public constant MIN_STAKE = 10000 * 10**18;
    uint256 public constant REPUTATION_SLASH_PERCENTAGE = 20;

    address public rightsContract;
    address public employmentVerifier;
    address public payrollOracle;

    constructor(address _rightsContract) {
        rightsContract = _rightsContract;
    }

    function sponsorMobility(
        bytes32 _beneficiaryDID,
        string memory _rightType,
        uint256 _duration,
        SponsorshipConditions memory _conditions
    ) external payable {
        require(msg.value >= MIN_STAKE, "Insufficient stake");
        require(sponsorReputation[msg.sender] >= 100, "Insufficient reputation");

        bytes32 sponsorshipId = keccak256(
            abi.encodePacked(msg.sender, _beneficiaryDID, block.timestamp)
        );

        sponsorships[sponsorshipId] = Sponsorship({
            sponsor: msg.sender,
            beneficiaryDID: _beneficiaryDID,
            stakeAmount: msg.value,
            rightType: _rightType,
            startTime: block.timestamp,
            duration: _duration,
            active: true,
            conditions: _conditions
        });

        MobilityRightsProtocol(rightsContract).issueRight(
            _beneficiaryDID,
            _rightType,
            5,
            _duration,
            keccak256(abi.encode(_conditions))
        );
    }

    function verifyConditions(bytes32 _sponsorshipId) external {
        Sponsorship storage sponsorship = sponsorships[_sponsorshipId];
        require(sponsorship.active, "Sponsorship inactive");

        bool employed = IEmploymentVerifier(employmentVerifier).verifyEmployment(
            sponsorship.beneficiaryDID,
            sponsorship.conditions.employmentContractHash
        );

        bool salaryMet = IPayrollOracle(payrollOracle).verifySalary(
            sponsorship.beneficiaryDID,
            sponsorship.conditions.minimumSalary
        );

        if (!employed || !salaryMet) {
            uint256 slashAmount =
                (sponsorship.stakeAmount * REPUTATION_SLASH_PERCENTAGE) / 100;
            sponsorReputation[sponsorship.sponsor] -= 50;
            sponsorship.active = false;
            MobilityRightsProtocol(rightsContract).revokeRight(
                sponsorship.beneficiaryDID,
                sponsorship.rightType
            );
        }
    }
}
