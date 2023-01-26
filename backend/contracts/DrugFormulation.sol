pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {ComponentBase} from "./ComponentBase.sol";

contract DrugFormulation is ComponentBase {
    constructor(
        address _fdaAddress,
        string memory _name,
        uint16 _lowerTempBound,
        uint16 _upperTempBound,
        Formula[] memory _apiList,
        Formula[] memory _excipientList
    )
        public
        ComponentBase(_fdaAddress, _name, _lowerTempBound, _upperTempBound)
    {
        arrayToMapping(_apiList, apiFormulaMapping);
        arrayToMapping(_excipientList, excipientFormulaMapping);
    }

    function arrayToMapping(
        Formula[] memory arr,
        mapping(address => string) storage map
    ) private {
        for (uint256 index = 0; index < arr.length; index++) {
            map[arr[index].ingAddress] = arr[index].quantityMg;
        }
    }

    // Properties

    struct Formula {
        address ingAddress;
        // Quantity is stored as a string since Solidity does not support floating points.
        string quantityMg;
    }

    mapping(address => string) apiFormulaMapping;
    mapping(address => string) excipientFormulaMapping;

    // functions
    function isApproved() public view virtual override returns (bool) {
        return fda.checkDrugFormulationApproval(address(this));
    }
}
