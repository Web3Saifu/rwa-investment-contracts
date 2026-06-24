// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {MCTest} from "@mc-devkit/Flattened.sol";

import {Schema} from "bundle/investment/storage/Schema.sol";
import {IInvestment} from "bundle/investment/interfaces/IInvestment.sol";
import {IInvestmentFunctions} from "bundle/investment/interfaces/IInvestmentFunctions.sol";
import {InvestmentDeployer} from "script/deploy/InvestmentDeployer.sol";
import {IInvestmentNFT} from "bundle/periphery/interfaces/IInvestmentNFT.sol";
import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract OODAReentrantReceiver is IERC721Receiver {
    IInvestment internal investment;
    MockInvestmentERC20 internal usdt;
    address internal destination;
    bytes internal nestedCall;

    bool public nestedSuccess;
    bytes4 public nestedError;
    uint256 public observedAmountDuringCallback;

    constructor(MockInvestmentERC20 usdt_, address destination_) {
        usdt = usdt_;
        destination = destination_;
    }

    function setInvestment(IInvestment investment_) external {
        investment = investment_;
    }

    function setNestedCall(bytes calldata data) external {
        nestedCall = data;
        nestedSuccess = false;
        nestedError = bytes4(0);
    }

    function approveInvestment(uint256 amount) external {
        usdt.approve(address(investment), amount);
    }

    function startInvest(uint256 productId, uint256 units) external {
        investment.invest(productId, units);
    }

    function startMint(uint256 productId, uint256 units) external {
        investment.mintNFT(productId, units, address(this));
    }

    function onERC721Received(address, address, uint256 tokenId, bytes calldata) external returns (bytes4) {
        observedAmountDuringCallback = IInvestmentNFT(msg.sender).getInvestmentAmount(tokenId);

        // Ownership can move during safeMint, then the callback probes another proxy facet.
        IERC721(msg.sender).transferFrom(address(this), destination, tokenId);
        bytes memory result;
        (nestedSuccess, result) = address(investment).call(nestedCall);
        if (!nestedSuccess && result.length >= 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(result, 32))
            }
            nestedError = selector;
        }
        return IERC721Receiver.onERC721Received.selector;
    }
}

contract OODACallbackSequencesTest is MCTest {
    IInvestment internal investment;
    MockInvestmentERC20 internal usdt;
    OODAReentrantReceiver internal receiver;
    IInvestmentNFT internal nft;

    address internal safe;
    address internal admin;
    address internal bob;

    uint256 internal constant UNIT = 100_000_000;
    bytes4 internal constant REENTRANCY_ERROR = bytes4(keccak256("ReentrancyGuardReentrantCall()"));

    function setUp() public {
        safe = makeAddr("safe");
        admin = makeAddr("admin");
        bob = makeAddr("bob");
        usdt = new MockInvestmentERC20();
        receiver = new OODAReentrantReceiver(usdt, bob);

        address[] memory admins = new address[](1);
        admins[0] = admin;
        address[] memory minters = new address[](1);
        minters[0] = address(receiver);
        vm.prank(safe);
        investment = IInvestment(InvestmentDeployer.deployInvestment(mc, admins, minters, address(usdt), safe));
        receiver.setInvestment(investment);

        Schema.RegisterProductArgs memory args = Schema.RegisterProductArgs({
            productId: 1,
            offeringAmount: 20 * UNIT,
            minInvestment: UNIT,
            offeringEndDate: 1_737_763_200,
            maturityDate: 1_767_225_600,
            expectedYield: 500,
            operationStartDate: 1_738_368_000,
            distributionStartDate: 1_748_736_000,
            totalDistributionCount: 1,
            distributionInterval: 0,
            baseTokenURI: "",
            requiredTier: 0
        });
        vm.prank(admin);
        investment.registerProduct(args);
        nft = IInvestmentNFT(investment.getProduct(1).nftContract);
    }

    // Sequence 10: all facets delegatecall into one proxy, so slot 0 is one effective guard.
    function test_10_investCallbackTransferThenCrossFacetMintIsBlocked() public {
        usdt.mint(address(receiver), UNIT);
        receiver.approveInvestment(UNIT);
        receiver.setNestedCall(abi.encodeCall(IInvestmentFunctions.mintNFT, (1, 1, address(receiver))));

        receiver.startInvest(1, 1);

        assertFalse(receiver.nestedSuccess(), "cross-facet nested mint must fail");
        assertEq(receiver.nestedError(), REENTRANCY_ERROR);
        assertEq(nft.ownerOf(1), bob, "callback transfer itself is valid");
        assertEq(nft.getInvestmentAmount(1), UNIT, "amount is committed after callback");
        Schema.Product memory product = investment.getProduct(1);
        assertEq(product.raisedAmount, UNIT);
        assertEq(product.productPool, UNIT);
        assertEq(nft.tokenIdCounter(), 1, "nested mint created no second token");
    }

    // Sequence 11: mintNFT callback sees a temporary zero amount, but nested write paths cannot exploit it.
    function test_11_mintCallbackCannotReenterInvestMintOrClaim() public {
        usdt.mint(address(receiver), UNIT);
        receiver.approveInvestment(UNIT);

        bytes[] memory probes = new bytes[](3);
        probes[0] = abi.encodeCall(IInvestmentFunctions.invest, (1, 1));
        probes[1] = abi.encodeCall(IInvestmentFunctions.mintNFT, (1, 1, address(receiver)));
        probes[2] = abi.encodeCall(IInvestmentFunctions.claimYield, (1, 1, 1));

        for (uint256 i; i < probes.length; ++i) {
            receiver.setNestedCall(probes[i]);
            receiver.startMint(1, 1);
            assertEq(receiver.observedAmountDuringCallback(), 0, "safeMint callback precedes amount write");
            assertFalse(receiver.nestedSuccess(), "nested state-changing call must fail");
            assertEq(receiver.nestedError(), REENTRANCY_ERROR);
            assertEq(nft.ownerOf(i + 1), bob);
            assertEq(nft.getInvestmentAmount(i + 1), UNIT, "amount is correct after callback returns");
        }

        Schema.Product memory product = investment.getProduct(1);
        assertEq(product.raisedAmount, 3 * UNIT, "only the three outer mints changed accounting");
        assertEq(product.productPool, 0, "off-chain mint path did not pull ERC20");
        assertEq(nft.tokenIdCounter(), 3, "nested calls minted no extra NFTs");
    }
}
