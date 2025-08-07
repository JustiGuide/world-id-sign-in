// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface MobilityRightsProtocol {
    function updatePrice(string memory, string memory, int256) external;
}

contract MobilityPricingOracle {
    struct MarketData {
        uint256 talentDemand;
        uint256 talentSupply;
        uint256 averageSalary;
        uint256 economicImpact;
        uint256 lastUpdated;
    }

    mapping(string => mapping(string => MarketData)) public marketMetrics;
    mapping(string => mapping(string => int256)) public dynamicPrices;

    address public rightsContract;
    address public oracle;

    modifier onlyOracle() {
        require(msg.sender == oracle, "Not oracle");
        _;
    }

    constructor(address _rightsContract, address _oracle) {
        rightsContract = _rightsContract;
        oracle = _oracle;
    }

    function calculateExecutionPrice(
        string memory _country,
        string memory _rightType
    ) public view returns (int256) {
        MarketData memory data = marketMetrics[_country][_rightType];
        int256 price = 1000 * 10**18;
        if (data.talentDemand > data.talentSupply * 2) {
            price = -int256(data.averageSalary / 10);
        } else if (data.talentSupply > data.talentDemand * 2) {
            price = price * 3;
        }
        price = (price * int256(100 - data.economicImpact)) / 100;
        return price;
    }

    function updateMarketData(
        string memory _country,
        string memory _rightType,
        uint256 _demand,
        uint256 _supply,
        uint256 _avgSalary,
        uint256 _economicImpact
    ) external onlyOracle {
        marketMetrics[_country][_rightType] = MarketData({
            talentDemand: _demand,
            talentSupply: _supply,
            averageSalary: _avgSalary,
            economicImpact: _economicImpact,
            lastUpdated: block.timestamp
        });

        int256 newPrice = calculateExecutionPrice(_country, _rightType);
        dynamicPrices[_country][_rightType] = newPrice;
        MobilityRightsProtocol(rightsContract).updatePrice(
            _country,
            _rightType,
            newPrice
        );
    }

    function setEmergencyPricing(string memory _rightType, int256 _price) external onlyOracle {
        dynamicPrices["emergency"][_rightType] = _price;
    }
}
