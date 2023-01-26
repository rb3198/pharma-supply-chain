pragma solidity ^0.6.0;

import {ComponentBase} from "./ComponentBase.sol";

contract DrugExcipient is ComponentBase {
    constructor(
        address _fdaAddress,
        string memory _name,
        uint16 _lowerTempBound,
        uint16 _upperTempBound
    )
        public
        ComponentBase(_fdaAddress, _name, _lowerTempBound, _upperTempBound)
    {}

    function isApproved() public view virtual override returns (bool) {
        return fda.checkExcipientApproval(address(this));
    }
}
