// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/NftFacet.sol";
// import "contracts/facets/MarketPlace.sol";
import "../contracts/Diamond.sol";
// ERC721Facet

import "./helpers/DiamondUtils.sol";

contract DiamondDeployer is DiamondUtils, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    NftFacet nftF;
    // MarketPlaceFacet marketPlaceF;

    function testDeployDiamond() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(
            address(this),
            address(dCutFacet),
            "NFTFacet",
            "NFT"
        );
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        nftF = new NftFacet();
        // marketPlaceF = new MarketPlaceFacet();

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](3);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );

        cut[2] = (
            FacetCut({
                facetAddress: address(nftF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("NftFacet")
            })
        );

        // cut[3] = (
        //     FacetCut({
        //         facetAddress: address(tokenF),
        //         action: FacetCutAction.Add,
        //         functionSelectors: generateSelectors("MarketPlaceFacet")
        //     })
        // );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();
    }

    function testName() public {
        // assertEq(TokenFacet(address(diamond)).name, "Blessed");
    }

    // function testTransfer() public {
    //     vm.startPrank(address(0x1111));
    //     tokenF(address(diamond)).mint(address);
    // }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
