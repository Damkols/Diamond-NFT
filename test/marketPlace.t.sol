// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Marketplace} from "contracts/facets/MarketPlace.sol";
import "contracts/facets/NftFacet.sol";
import "test/helpers/Signatures.sol";
import "contracts/interfaces/IDiamondCut.sol";
import "contracts/facets/DiamondCutFacet.sol";
import "contracts/facets/DiamondLoupeFacet.sol";
import "contracts/Diamond.sol";
import {Order} from "contracts/libraries/LibDiamond.sol";
import "./helpers/DiamondUtils.sol";

contract MarketPlaceTest is DiamondUtils, IDiamondCut,Helpers {
    //NFT contract instance
    NftFacet nftFacet;

    //Marketplace contract instance
    Marketplace marketplace;

    //Order Id intially starts at 0
    uint256 currentListingId;

    //public and private address of the users
    address publicAddress1;
    address publicAddress2;
    uint256 privateKey1;
    uint256 privateKey2;

    //Our Order template struct
    Order order;

    //signature used to authorise creation of lisiting
    bytes signature;

     Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;

    function setUp() public {
    //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet),"NFTFacet","NFT");
        dLoupe = new DiamondLoupeFacet();
     
        // Deploying the marketplace contract and storing it's returning object
        marketplace = new Marketplace();

        // Deploying the Alexia NFT contract and storing it's returning object
        nftFacet = new NftFacet();

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
                facetAddress: address(nftFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("NftFacet")
            })
        );

        cut[2] = (
            FacetCut({
                facetAddress: address(marketplace),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("Marketplace")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();

        //storing the key pairs from the addressPair function
        (publicAddress1, privateKey1) = addressPair("publicAddress1");
        (publicAddress2, privateKey2) = addressPair("publicAddress2");

        //Default Order object during setup
        order = Order({
            token: address(nftFacet),
            tokenId: 1,
            price: 1 ether,
            sig: bytes(""),
            deadline: 70 minutes,
            owner: publicAddress1,
            active: false
        });

        //storing the signature derived from the default order
        signature = constructSig(
            order.token,
            order.tokenId,
            order.price,
            order.deadline,
            order.owner,
            privateKey1
        );

        order.sig = signature;

        //minting to an address
        nftFacet.mint(publicAddress1, 1);
    }

    function testTokenName() public {
        assertEq(NftFacet(address(diamond)).name(), "NFTFacet");
    }

    function testValidSig() public {
        switchSigner(publicAddress1);
        bytes memory sig = constructSig(
            order.token,
            order.tokenId,
            order.price,
            order.deadline,
            order.owner,
            privateKey1
        );

        assertEq(sig, signature);
    }

    function testMinPriceTooLow() public {
        switchSigner(publicAddress1);
        nftFacet.setApprovalForAll(address(marketplace), true);
        order.price = 0;
        vm.expectRevert(Marketplace.MinPriceTooLow.selector);
        marketplace.createOrder(order);
    }

    function testNotOwner() public {
        switchSigner(publicAddress2);
        nftFacet.setApprovalForAll(address(marketplace), true);
        vm.expectRevert(Marketplace.NotOwner.selector);
        marketplace.createOrder(order);
    }

    function testNotApproved() public {
        switchSigner(publicAddress1);
        nftFacet.setApprovalForAll(address(0), true);
        vm.expectRevert(Marketplace.NotApproved.selector);
        marketplace.createOrder(order);
    }

    function testDeadlineTooSoon() public {
        switchSigner(publicAddress1);
        nftFacet.setApprovalForAll(address(marketplace), true);
        order.deadline = 0;
        vm.expectRevert(Marketplace.DeadlineTooSoon.selector);
        marketplace.createOrder(order);
    }

    function testMinDurationNotMet() public {
        switchSigner(publicAddress1);
        nftFacet.setApprovalForAll(address(marketplace), true);
        order.deadline = 15 minutes;
        vm.expectRevert(Marketplace.MinDurationNotMet.selector);
        marketplace.createOrder(order);
    }

    function testListingNotExistent() public {
        switchSigner(publicAddress1);
        vm.expectRevert(Marketplace.ListingNotExistent.selector);
        marketplace.executeOrder(2);
    }

    function testListingExpired() public {
        switchSigner(publicAddress1);
        nftFacet.setApprovalForAll(address(marketplace), true);
        uint id = marketplace.createOrder(order);
        vm.warp(order.deadline + 10 minutes);
        vm.expectRevert(Marketplace.ListingExpired.selector);
        marketplace.executeOrder(id);
    }

    function testListingNotActive() public {
        switchSigner(publicAddress1);
        nftFacet.setApprovalForAll(address(marketplace), true);
        uint id = marketplace.createOrder(order);
        marketplace.editOrder(id, order.price, false);
        vm.expectRevert(Marketplace.ListingNotActive.selector);
        marketplace.executeOrder{value:order.price}(id);
    }

    function testEditingListingNotExistent() public {
        vm.expectRevert(Marketplace.ListingNotExistent.selector);
        marketplace.editOrder(2, order.price, false);
    }

    function testEditingNotOwner() public {
        vm.startPrank(publicAddress1);
        nftFacet.setApprovalForAll(address(marketplace), true);
        uint id = marketplace.createOrder(order);
        vm.stopPrank();
        vm.prank(publicAddress2);
        vm.expectRevert(Marketplace.NotOwner.selector);
        marketplace.editOrder(id, order.price, true);
    }   

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {} 
}