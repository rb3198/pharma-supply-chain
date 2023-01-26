pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {DrugAPI} from "./DrugAPI.sol";
import {DrugFormulation} from "./DrugFormulation.sol";
import {Fda} from "./Fda.sol";

contract DrugLot {
    enum ManufacturingStatus {
        UNSTARTED,
        STARTED,
        COMPLETED
    }
    // properties
    address payable public ownerId;
    string public lotName;
    uint32 public numBoxes;
    uint128 public lotPrice;
    uint128 public boxPrice;
    uint256 public manufacturingDate;
    uint256 public expiryDate;
    ManufacturingStatus public manufacturingStatus;
    mapping(address => uint256) public boxesPatient; //Mapping the purchased boxes to their corresonding patient ID
    DrugFormulation public drugFormulation;
    Fda private fda;
    uint16[] public temperatureListings;
    mapping(address => bool) public authorizedManufacturers;
    mapping(address => bool) public authorizedDistributors;
    mapping(address => bool) public authorizedPharmacies;

    constructor(address _fdaAddress, address _drugFormulationAddress) public {
        fda = Fda(_fdaAddress);
        drugFormulation = DrugFormulation(_drugFormulationAddress);
    }

    // modifiers
    modifier onlyOwner() {
        require(
            msg.sender == ownerId,
            "Only the owner should be able to do this action"
        );
        _;
    }

    modifier onlyManufacturer() {
        require(authorizedManufacturers[msg.sender]);
        _;
    }

    modifier onlyDistributor() {
        require(authorizedDistributors[msg.sender]);
        _;
    }

    modifier manufacturerOrDistributor() {
        require(
            authorizedDistributors[msg.sender] ||
                authorizedManufacturers[msg.sender]
        );
        _;
    }

    modifier distributorOrPharmacy() {
        require(
            authorizedDistributors[msg.sender] ||
                authorizedPharmacies[msg.sender]
        );
        _;
    }

    modifier onlyPharmacy() {
        require(authorizedPharmacies[msg.sender]);
        _;
    }

    // events
    event lotManufacturingStarted(
        address manufacturer,
        string lotName,
        uint32 numBoxes
    );
    event lotManufactured(
        address indexed manufacturer,
        uint32 numBoxes,
        uint128 lotPrice,
        uint128 boxPrice,
        uint256 manufacturingDate
    );
    event lotOpenForSale(
        address indexed seller,
        string lotName,
        uint32 numBoxes,
        uint256 lotPrice,
        uint128 boxPrice
    );

    event lotSold(address indexed newOwnerId);
    event boxesSold(uint256 soldBoxes, address newownerID);

    //Authoorization functions
    function manufacturerAddress(address user) public onlyOwner {
        authorizedManufacturers[user] = true;
    }

    function distributorAddress(address user) public onlyOwner {
        authorizedDistributors[user] = true;
    }

    function pharmacyAddress(address user) public onlyOwner {
        authorizedPharmacies[user] = true;
    }

    // functions

    function startManufacturing(
        string memory _lotName,
        uint32 _numBoxes,
        uint128 _lotPrice,
        uint128 _boxPrice
    ) public onlyManufacturer {
        require(
            manufacturingStatus == ManufacturingStatus.UNSTARTED,
            "Manufacturing must not be started already"
        );
        require(
            fda.checkDrugFormulationApproval(address(drugFormulation)),
            "Require formulation of the drug to be approved before starting to manufacture it"
        );
        lotName = _lotName;
        numBoxes = _numBoxes;
        lotPrice = _lotPrice;
        boxPrice = _boxPrice;
        emit lotManufacturingStarted(msg.sender, _lotName, _numBoxes);
    }

    function completeManufacturing(
        uint256 _manufacturingDate,
        uint256 _expiryDate
    ) public onlyManufacturer {
        require(
            manufacturingStatus == ManufacturingStatus.STARTED,
            "Manufacturing status must be started in order to mark it complete"
        );
        manufacturingDate = _manufacturingDate;
        expiryDate = _expiryDate;
        manufacturingStatus = ManufacturingStatus.COMPLETED;
        emit lotManufactured(
            msg.sender,
            numBoxes,
            lotPrice,
            boxPrice,
            _manufacturingDate
        );
    }

    function grantSale() public onlyOwner manufacturerOrDistributor {
        require(
            manufacturingStatus == ManufacturingStatus.COMPLETED,
            "Lot must be manufactured before it can be sold"
        );
        emit lotOpenForSale(ownerId, lotName, numBoxes, lotPrice, boxPrice);
    }

    function buyLot() public payable distributorOrPharmacy {
        address payable buyer = msg.sender;
        require(buyer != ownerId, "Owner cannot buy the lot himself");
        require(msg.value >= lotPrice, "Insufficient payment");
        uint256 refundAmount = msg.value - lotPrice;
        if (refundAmount > 0) {
            buyer.transfer(refundAmount);
        }
        ownerId.transfer(lotPrice);
        emit lotSold(buyer);
    }

    function buyBox(uint32 _numBoxesToBuy) public payable {
        address payable buyer = msg.sender;
        address payable seller = ownerId;
        require(
            _numBoxesToBuy <= numBoxes,
            "The specified amount exceeds the limit"
        );
        require(msg.value >= boxPrice * _numBoxesToBuy, "insufficient payment");
        uint256 refundAmount = msg.value - (boxPrice * _numBoxesToBuy);
        if (refundAmount > 0) {
            msg.sender.transfer(refundAmount);
        }

        seller.transfer(boxPrice * _numBoxesToBuy); //Transfering ether to the seller
        boxesPatient[buyer] = _numBoxesToBuy;
        numBoxes -= _numBoxesToBuy;

        emit boxesSold(_numBoxesToBuy, ownerId);
    }

    function viewLot()
        public
        view
        returns (
            string memory _lotName,
            uint256 _lotPrice,
            uint256 _numBoxes,
            uint256 _boxPrice,
            uint256 _manufacturingDate,
            uint256 _expiryDate,
            address _ownerId
        )
    {
        return (
            lotName,
            lotPrice,
            numBoxes,
            boxPrice,
            manufacturingDate,
            expiryDate,
            ownerId
        );
    }
}
