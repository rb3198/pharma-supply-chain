pragma solidity ^0.6.0;

import {Fda} from "./Fda.sol";

abstract contract ComponentBase {
    // Properties
    Fda internal fda;
    string public name;
    uint16[2] public temperatureBounds;
    string public clinicalDataIpfsHash;

    constructor(
        address _fdaAddress,
        string memory _name,
        uint16 _lowerTempBound,
        uint16 _upperTempBound
    ) public {
        fda = Fda(_fdaAddress);
        name = _name;
        temperatureBounds = [_lowerTempBound, _upperTempBound];
    }

    // events
    event ClinicalTrialDataAdded(
        address drugAddress,
        string clinicalDataIpfsHash
    );

    // Functions

    function addClinicalData(string memory _clinicalDataIpfsHash) public {
        clinicalDataIpfsHash = _clinicalDataIpfsHash;
        emit ClinicalTrialDataAdded(address(this), _clinicalDataIpfsHash);
    }

    function isApproved() public view virtual returns (bool) {}
}
