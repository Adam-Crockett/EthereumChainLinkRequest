pragma solidity ^0.6.0;

// Used this import statement while working within Remix
import "https://github.com/smartcontractkit/chainlink/evm-contracts/src/v0.6/ChainlinkClient.sol";

// Contract to request the current gas price using the Google BigQuery API.
contract GasPriceContract is ChainlinkClient {
    uint256 oraclePayment;
    address public owner;
    int256 public gasPrice;

    // Create the public LINK token for the network
    constructor(uint256 _oraclePayment) public {
        setPublicChainlinkToken();
        oraclePayment = _oraclePayment;
    }

    // Build and send Chainlink Request
    function requestGasPriceByBlock(
        address _oracle,
        bytes32 _jobId,
        uint256 _block
    ) public onlyOwner {
        Chainlink.Request memory req = buildChainlinkRequest(
            _jobId,
            address(this),
            this.fulfillGasPrice.selector
        );
        // Parameters for request
        req.add("action", "block");
        req.addUint("block", _block);
        req.add("copyPath", "gasPrice");

        sendChainlinkRequestTo(_oracle, req, oraclePayment);
    }

    // Sets the gasPrice from the response fulfillment
    function fulfillGasPrice(bytes32 _requestId, int256 _gasPrice)
        public
        recordChainlinkFulfillment(_requestId)
    {
        gasPrice = _gasPrice;
    }

    // Cancel Contract if it is not fullfilled
    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    ) public onlyOwner {
        cancelChainlinkRequest(
            _requestId,
            _payment,
            _callbackFunctionId,
            _expiration
        );
    }

    // Withdaw the contract if there are extra LINKS on contract
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    // Ensure that the sender of the contract is the owner.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}
