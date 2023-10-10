// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721Facet} from "./ERC721.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";


contract NftFacet is ERC721Facet {
    function name() public view virtual returns(string memory){
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds._name;
    }
    function tokenURI(
        uint256 id
    ) public view virtual override returns (string memory) {
        return "Scam";
    }

    function mint(address recipient, uint256 tokenId) public payable {
        _mint(recipient, tokenId);
    }
}