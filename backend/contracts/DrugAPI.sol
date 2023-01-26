pragma solidity ^0.6.0;

import {ComponentBase} from "./ComponentBase.sol";

contract DrugAPI is ComponentBase {
    address public patentHolderAddress;

    constructor(
        address _fdaAddress,
        string memory _name,
        uint16 _lowerTempBound,
        uint16 _upperTempBound
    )
        public
        ComponentBase(_fdaAddress, _name, _lowerTempBound, _upperTempBound)
    {
        patentHolderAddress = msg.sender;
    }

    function isApproved() public view virtual override returns (bool) {
        return fda.checkApiApproval(address(this));
    }

    function getPatentExpiry() public view returns (uint256) {
        return fda.getApiPatentExpiry(address(this));
    }
}
