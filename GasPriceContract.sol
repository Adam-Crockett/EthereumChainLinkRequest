pragma solidity ^0.6.0;

import "https://github.com/smartcontractkit/chainlink/evm-contracts/src/v0.6/ChainlinkClient.sol";

// Contract to request the current gas price using the Google BigQuery API
contract GasPriceContract is ChainlinkClient {
    uint256 oraclePayment;
    address public owner;
    int256 public gasPrice;

    constructor(uint256 _oraclePayment) public {
        setPublicChainlinkToken();
        oraclePayment = _oraclePayment;
    }

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
        req.add("action", "block");
        req.addUint("block", _block);
        req.add("copyPath", "gasPrice");
        sendChainlinkRequestTo(_oracle, req, oraclePayment);
    }

    function fulfillGasPrice(bytes32 _requestId, int256 _gasPrice)
        public
        recordChainlinkFulfillment(_requestId)
    {
        gasPrice = _gasPrice;
    }

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

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}
