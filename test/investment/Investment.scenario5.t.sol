// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {MCTest, MCDevKit, stdError} from "@mc-devkit/Flattened.sol";
import {console} from "forge-std/console.sol";

// investment
import {Storage} from "bundle/investment/storage/Storage.sol";
import {Schema} from "bundle/investment/storage/Schema.sol";
import {IInvestment} from "bundle/investment/interfaces/IInvestment.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";
import {InvestmentDeployer} from "script/deploy/InvestmentDeployer.sol";
import {CalculateYieldLib} from "bundle/investment/utils/CalculateYieldLib.sol";

// periphery
import {IAutomation} from "bundle/periphery/interfaces/IAutomation.sol";
import {Automation} from "bundle/periphery/Automation.sol";
import {IInvestmentNFT} from "bundle/periphery/interfaces/IInvestmentNFT.sol";
import {InvestmentNFT} from "bundle/periphery/InvestmentNFT.sol";

import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract InvestmentScenario5Test is MCTest {
    IInvestment public investment;
    MockInvestmentERC20 public usdt;
    Automation public automation;

    address safe;
    address admin1;
    address admin2;
    address[] admins;
    address forwarder;
    Schema.RegisterProductArgs registerProductArgs;

    uint256 constant PRODUCT_ID = 1;
    uint256 constant OFFERING_AMOUNT = 1_000_000_000_000; // 1_000_000USD(1USD = 150JPY: 150_000_000JPY)
    uint256 constant MIN_INVESTMENT = 250_000_000; // 250USD(1USD = 150JPY: 37_500JPY)
    uint256 constant OFFERING_END_DATE = 1737763200; // 2025-01-25 00:00:00 UTC
    uint256 constant MATURITY_DATE = 1767225600; // 2026-01-01 00:00:00 UTC
    uint256 constant EXPECTED_YIELD = 500; // 5%
    uint256 constant OPERATION_STARTDATE = 1738368000; // 2025-02-01 00:00:00 UTC
    uint256 constant DISTRIBUTION_START_DATE = 1748736000; // 2025-06-01 00:00:00 UTC
    uint256 constant TOTAL_DISTRIBUTION_COUNT = 3;
    uint256 constant DISTRIBUTION_INTERVAL = 3;

    string constant INITIAL_BASE_TOKEN_URI = "https://example.com/metadata/initial.json";
    string constant UPDATED_BASE_TOKEN_URI = "https://example.com/metadata/updated.json";

    function setUp() public {
        // make up address
        safe = makeAddr("safe");
        admin1 = makeAddr("admin1");
        admin2 = makeAddr("admin2");
        forwarder = makeAddr("forwarder");
        admins.push(admin1);

        // deploy
        usdt = new MockInvestmentERC20();
        vm.prank(safe);
        investment = IInvestment(InvestmentDeployer.deployInvestment(mc, admins, admins, address(usdt), safe));
        automation = new Automation(address(investment), forwarder);

        vm.prank(safe);
        investment.addAdmin(address(automation));
    }

    // To avoid stack too deep
    struct InvestorArgs {
        address investor1;
        address investor2;
        address investor3;
        address investor4;
    }

    struct InvestAmountArgs {
        uint256 investAmount1;
        uint256 investAmount2;
        uint256 investAmount3;
        uint256 investAmount4;
    }

    struct UnitCountArgs {
        uint256 unitCount1;
        uint256 unitCount2;
        uint256 unitCount3;
        uint256 unitCount4;
    }

    function test_scenario5_UpdateNFTURI() public {
        registerProductArgs = Schema.RegisterProductArgs({
            productId: PRODUCT_ID,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: MATURITY_DATE,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: DISTRIBUTION_START_DATE,
            totalDistributionCount: TOTAL_DISTRIBUTION_COUNT,
            distributionInterval: DISTRIBUTION_INTERVAL,
            baseTokenURI: INITIAL_BASE_TOKEN_URI,
            requiredTier: 0
        });

        InvestorArgs memory investorArgs = InvestorArgs({
            investor1: makeAddr("investor1"),
            investor2: makeAddr("investor2"),
            investor3: makeAddr("investor3"),
            investor4: makeAddr("investor4")
        });

        InvestAmountArgs memory investAmountArgs;
        UnitCountArgs memory unitCountArgs;

        // ----------------------------------------------------------
        //  No0. Set up time
        // ----------------------------------------------------------
        vm.warp(1735689600); // 2025-01-01 00:00:00 UTC

        // ----------------------------------------------------------
        //  No1. Add admin by Safe
        // ----------------------------------------------------------
        vm.prank(safe);
        investment.addAdmin(admin2);
        address[] memory adminList = investment.getAdminList();
        assertEq(adminList.length, 3, "No1: adminList.length is not equal");
        assertEq(adminList[2], admin2, "No1: adminList[2] is not equal");

        // ----------------------------------------------------------
        //  No2. RegisterProduct
        // ----------------------------------------------------------
        vm.prank(admin1);
        investment.registerProduct(registerProductArgs);

        // Assert product registration
        Schema.Product memory productForNo2 = investment.getProduct(registerProductArgs.productId);
        assertEq(productForNo2.productId, registerProductArgs.productId, "No2: productId is not equal");
        assertEq(productForNo2.offeringAmount, registerProductArgs.offeringAmount, "No2: offeringAmount is not equal");
        assertEq(productForNo2.minInvestment, registerProductArgs.minInvestment, "No2: minInvestment is not equal");
        assertEq(
            productForNo2.offeringEndDate, registerProductArgs.offeringEndDate, "No2: offeringEndDate is not equal"
        );
        assertEq(productForNo2.maturityDate, registerProductArgs.maturityDate, "No2: maturityDate is not equal");
        assertEq(productForNo2.expectedYield, registerProductArgs.expectedYield, "No2: expectedYield is not equal");
        assertEq(
            productForNo2.operationStartDate,
            registerProductArgs.operationStartDate,
            "No2: operationStartDate is not equal"
        );
        assertEq(
            productForNo2.distributionStartDate,
            registerProductArgs.distributionStartDate,
            "No2: distributionStartDate is not equal"
        );
        assertEq(
            productForNo2.totalDistributionCount,
            registerProductArgs.totalDistributionCount,
            "No2: totalDistributionCount is not equal"
        );
        assertEq(
            productForNo2.distributionInterval,
            registerProductArgs.distributionInterval,
            "No2: distributionInterval is not equal"
        );

        // Assert initial values
        assertEq(productForNo2.raisedAmount, 0, "No2: raisedAmount is not equal");
        assertEq(productForNo2.productPool, 0, "No2: productPool is not equal");
        assertEq(productForNo2.distributedCount, 0, "No2: distributedCount is not equal");
        assertEq(productForNo2.distributedYieldPerCount, 0, "No2: distributedYieldPerCount is not equal");
        assertEq(productForNo2.distributedTokenId, 0, "No2: distributedTokenId is not equal");
        assertEq(productForNo2.totalReturnedAmount, 0, "No2: totalReturnedAmount is not equal");
        assertEq(productForNo2.maturedTokenId, 0, "No2: maturedTokenId is not equal");
        assertFalse(productForNo2.isMaturity, "No2: isMaturity is not false");
        assertFalse(productForNo2.isInsufficientBalance, "No2: isInsufficientBalance is not false");

        // Assert NFT contract address is deployed
        assertTrue(productForNo2.nftContract != address(0), "No2: nftContract is not deployed");

        // ----------------------------------------------------------
        //  No3. Invest half of offering amount (JPY)
        //        Number of investors: 2
        // ----------------------------------------------------------
        uint256 halfOfferingAmount = registerProductArgs.offeringAmount / 2;
        uint256 amountPer2 = halfOfferingAmount / 2;
        investAmountArgs.investAmount1 = amountPer2;
        investAmountArgs.investAmount2 = amountPer2;
        unitCountArgs.unitCount1 = investAmountArgs.investAmount1 / registerProductArgs.minInvestment;
        unitCountArgs.unitCount2 = investAmountArgs.investAmount2 / registerProductArgs.minInvestment;

        vm.startPrank(admin1);
        investment.mintNFT(PRODUCT_ID, unitCountArgs.unitCount1, investorArgs.investor1);
        investment.mintNFT(PRODUCT_ID, unitCountArgs.unitCount2, investorArgs.investor2);
        vm.stopPrank();

        // Assert Product
        Schema.Product memory productForNo3 = investment.getProduct(PRODUCT_ID);
        assertEq(
            productForNo3.raisedAmount,
            investAmountArgs.investAmount1 + investAmountArgs.investAmount2,
            "No3: raisedAmount is not equal"
        );
        assertEq(productForNo3.productPool, 0, "No3: productPool is not equal");

        // Assert NFT
        assertEq(
            InvestmentNFT(productForNo3.nftContract).balanceOf(investorArgs.investor1),
            1,
            "No3: balanceOf(investor1) is not equal"
        );
        assertEq(
            InvestmentNFT(productForNo3.nftContract).balanceOf(investorArgs.investor2),
            1,
            "No3: balanceOf(investor2) is not equal"
        );
        assertEq(InvestmentNFT(productForNo3.nftContract).tokenIdCounter(), 2, "No3: tokenIdCounter is not equal");

        // ----------------------------------------------------------
        //  No4. Invest quarter of offering amount (USDT)
        //        Number of investors: 1
        // ----------------------------------------------------------
        investAmountArgs.investAmount3 = amountPer2; // 1/4 of offering amount
        unitCountArgs.unitCount3 = investAmountArgs.investAmount3 / registerProductArgs.minInvestment;

        usdt.mint(investorArgs.investor3, investAmountArgs.investAmount3);

        vm.startPrank(investorArgs.investor3);
        usdt.approve(address(investment), investAmountArgs.investAmount3);
        investment.invest(PRODUCT_ID, unitCountArgs.unitCount3);
        vm.stopPrank();

        // Assert Product
        Schema.Product memory productForNo4 = investment.getProduct(PRODUCT_ID);
        assertEq(
            productForNo4.raisedAmount,
            investAmountArgs.investAmount1 + investAmountArgs.investAmount2 + investAmountArgs.investAmount3,
            "No4: raisedAmount is not equal"
        );
        assertEq(productForNo4.productPool, investAmountArgs.investAmount3, "No4: productPool is not equal");

        // Assert NFT
        assertEq(
            InvestmentNFT(productForNo4.nftContract).balanceOf(investorArgs.investor3),
            1,
            "No4: balanceOf(investor3) is not equal"
        );
        assertEq(InvestmentNFT(productForNo4.nftContract).tokenIdCounter(), 3, "No4: tokenIdCounter is not equal");

        // ----------------------------------------------------------
        //  No5. Check NFT URI
        // ----------------------------------------------------------
        Schema.Product memory productForNo5 = investment.getProduct(PRODUCT_ID);
        InvestmentNFT nftContract = InvestmentNFT(productForNo5.nftContract);

        // Check URI of minted NFTs (tokenId 1, 2, 3)
        string memory tokenURI1 = nftContract.tokenURI(1);
        string memory tokenURI2 = nftContract.tokenURI(2);
        string memory tokenURI3 = nftContract.tokenURI(3);

        assertEq(tokenURI1, INITIAL_BASE_TOKEN_URI, "No5: tokenURI(1) is not equal");
        assertEq(tokenURI2, INITIAL_BASE_TOKEN_URI, "No5: tokenURI(2) is not equal");
        assertEq(tokenURI3, INITIAL_BASE_TOKEN_URI, "No5: tokenURI(3) is not equal");

        // ----------------------------------------------------------
        //  No6. Update NFT URI
        // ----------------------------------------------------------
        vm.prank(admin1);
        nftContract.setURI(UPDATED_BASE_TOKEN_URI);

        // Assert non-admin cannot set URI
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, investorArgs.investor1));
        vm.prank(investorArgs.investor1);
        nftContract.setURI(UPDATED_BASE_TOKEN_URI);

        // ----------------------------------------------------------
        //  No7. Check NFT URI
        // ----------------------------------------------------------
        string memory tokenURI1AfterUpdate = nftContract.tokenURI(1);
        string memory tokenURI2AfterUpdate = nftContract.tokenURI(2);
        string memory tokenURI3AfterUpdate = nftContract.tokenURI(3);

        assertEq(tokenURI1AfterUpdate, UPDATED_BASE_TOKEN_URI, "No7: tokenURI(1) is not equal");
        assertEq(tokenURI2AfterUpdate, UPDATED_BASE_TOKEN_URI, "No7: tokenURI(2) is not equal");
        assertEq(tokenURI3AfterUpdate, UPDATED_BASE_TOKEN_URI, "No7: tokenURI(3) is not equal");

        // ----------------------------------------------------------
        //  No8. Check URI of already minted NFTs
        // ----------------------------------------------------------
        // Verify that URIs of NFTs minted in No3 and No4 (tokenId 1, 2, 3) have been updated
        string memory existingTokenURI1 = nftContract.tokenURI(1);
        string memory existingTokenURI2 = nftContract.tokenURI(2);
        string memory existingTokenURI3 = nftContract.tokenURI(3);

        assertEq(existingTokenURI1, UPDATED_BASE_TOKEN_URI, "No8: existing tokenURI(1) is not equal");
        assertEq(existingTokenURI2, UPDATED_BASE_TOKEN_URI, "No8: existing tokenURI(2) is not equal");
        assertEq(existingTokenURI3, UPDATED_BASE_TOKEN_URI, "No8: existing tokenURI(3) is not equal");

        // ----------------------------------------------------------
        //  No9. Verify that newly minted NFT after setURI update returns updated URI
        // ----------------------------------------------------------
        // Invest remaining offering amount for investor4
        uint256 remainingAmount = registerProductArgs.offeringAmount - productForNo4.raisedAmount;
        investAmountArgs.investAmount4 = remainingAmount;
        unitCountArgs.unitCount4 = investAmountArgs.investAmount4 / registerProductArgs.minInvestment;

        usdt.mint(investorArgs.investor4, investAmountArgs.investAmount4);

        vm.startPrank(investorArgs.investor4);
        usdt.approve(address(investment), investAmountArgs.investAmount4);
        investment.invest(PRODUCT_ID, unitCountArgs.unitCount4);
        vm.stopPrank();

        // Assert Product
        Schema.Product memory productForNo9 = investment.getProduct(PRODUCT_ID);
        assertEq(productForNo9.raisedAmount, registerProductArgs.offeringAmount, "No9: raisedAmount is not equal");
        assertEq(
            productForNo9.productPool,
            investAmountArgs.investAmount3 + investAmountArgs.investAmount4,
            "No9: productPool is not equal"
        );

        // Assert NFT
        assertEq(
            InvestmentNFT(productForNo9.nftContract).balanceOf(investorArgs.investor4),
            1,
            "No9: balanceOf(investor4) is not equal"
        );
        assertEq(InvestmentNFT(productForNo9.nftContract).tokenIdCounter(), 4, "No9: tokenIdCounter is not equal");

        // Verify that newly minted NFT (tokenId 4) returns updated URI
        InvestmentNFT nftContractForNo9 = InvestmentNFT(productForNo9.nftContract);
        string memory newTokenURI4 = nftContractForNo9.tokenURI(4);
        assertEq(newTokenURI4, UPDATED_BASE_TOKEN_URI, "No9: new tokenURI(4) is not equal");
    }

    receive() external payable {}
}
