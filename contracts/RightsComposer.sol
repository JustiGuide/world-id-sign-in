// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface MobilityRightsProtocol {
    function issueRight(bytes32, string memory, uint8, uint256, bytes32) external;
}

contract RightsComposer {
    address public rightsContract;

    constructor(address _rightsContract) {
        rightsContract = _rightsContract;
    }

    function composeRights(bytes32 _userDID, string[] memory _rightTypes)
        external
        returns (string memory composedRight)
    {
        if (_rightTypes.length == 2) {
            composedRight = string.concat(_rightTypes[0], "_", _rightTypes[1]);
            uint8 level = 5;
            MobilityRightsProtocol(rightsContract).issueRight(
                _userDID,
                composedRight,
                level,
                365 days * 5,
                keccak256(abi.encode(_rightTypes))
            );
        }
    }

    function delegateRight(
        bytes32 _fromDID,
        bytes32 _toDID,
        string memory _rightType,
        uint256 _duration,
        bytes32 _relationshipProof
    ) external {
        uint8 delegatedLevel = 1;
        MobilityRightsProtocol(rightsContract).issueRight(
            _toDID,
            string.concat(_rightType, "_delegated"),
            delegatedLevel,
            _duration,
            _relationshipProof
        );
    }
}
