// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FractionalOwnership {
    struct RealEstate {
        address owner;
        uint256 price;
        uint256 sharesTotal;
        uint256 sharesAvailable;
        mapping(address => uint256) sharesOwned;
    }

    struct Customer {
        bool exists;
        mapping(address => bool) authorizedAgents;
    }

    mapping(uint256 => RealEstate) private realEstates;
    mapping(address => Customer) private customers;
    uint256 private nextRealEstateId;

    event RealEstateCreated(uint256 indexed realEstateId, address indexed owner, uint256 price, uint256 sharesTotal);
    event SharesPurchased(uint256 indexed realEstateId, address indexed buyer, uint256 sharesAmount);
    event SharesTransferred(uint256 indexed realEstateId, address indexed from, address indexed to, uint256 sharesAmount);
    event AuthorizedAgentAdded(address indexed customer, address indexed agent);
    event AuthorizedAgentRemoved(address indexed customer, address indexed agent);

    modifier onlyRealEstateOwner(uint256 realEstateId) {
        require(realEstates[realEstateId].owner == msg.sender, "Not the real estate owner");
        _;
    }

    modifier onlyAuthorizedAgent(address customer) {
        require(customers[customer].authorizedAgents[msg.sender], "Not an authorized agent");
        _;
    }

    function createRealEstate(uint256 price, uint256 sharesTotal) external {
        require(price > 0, "Invalid price");
        require(sharesTotal > 0, "Invalid shares total");

        uint256 realEstateId = nextRealEstateId;
        nextRealEstateId++;

        realEstates[realEstateId] = RealEstate({
            owner: msg.sender,
            price: price,
            sharesTotal: sharesTotal,
            sharesAvailable: sharesTotal
        });

        emit RealEstateCreated(realEstateId, msg.sender, price, sharesTotal);
    }

    function purchaseShares(uint256 realEstateId, uint256 sharesAmount) external payable {
        require(realEstates[realEstateId].owner != address(0), "Real estate does not exist");
        require(sharesAmount > 0, "Invalid shares amount");
        require(sharesAmount <= realEstates[realEstateId].sharesAvailable, "Not enough shares available");
        require(msg.value == realEstates[realEstateId].price * sharesAmount, "Incorrect payment amount");

        realEstates[realEstateId].sharesOwned[msg.sender] += sharesAmount;
        realEstates[realEstateId].sharesAvailable -= sharesAmount;

        emit SharesPurchased(realEstateId, msg.sender, sharesAmount);
    }

    function transferShares(uint256 realEstateId, address to, uint256 sharesAmount) external {
        require(realEstates[realEstateId].owner != address(0), "Real estate does not exist");
        require(realEstates[realEstateId].sharesOwned[msg.sender] >= sharesAmount, "Insufficient shares owned");

        realEstates[realEstateId].sharesOwned[msg.sender] -= sharesAmount;
        realEstates[realEstateId].sharesOwned[to] += sharesAmount;

        emit SharesTransferred(realEstateId, msg.sender, to, sharesAmount);
    }

    function addAuthorizedAgent(address agent) external {
        require(customers[msg.sender].exists, "Customer does not exist");
        require(agent != address(0), "Invalid agent address");

        customers[msg.sender].authorizedAgents[agent] = true;

        emit AuthorizedAgentAdded(msg.sender, agent);
    }

    function removeAuthorizedAgent(address agent) external {
        require(customers[msg.sender].exists, "Customer does not exist");
        require(agent != address(0), "Invalid agent address");

        customers[msg.sender].authorizedAgents[agent] = false;

        emit AuthorizedAgentRemoved(msg.sender, agent);
    }

    function getRealEstateDetails(uint256 realEstateId) external view returns (address, uint256, uint256, uint256, uint256) {
        RealEstate memory realEstate = realEstates[realEstateId];
        return (
            realEstate.owner,
            realEstate.price,
            realEstate.sharesTotal,
            realEstate.sharesAvailable,
            realEstate.sharesOwned[msg.sender]
        );
    }
}
