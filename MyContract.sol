pragma solidity ^0.6.0;

import "https://github.com/smartcontractkit/chainlink/evm-contracts/src/v0.6/ChainlinkClient.sol";

// Simple Contract that requests
contract MyContract is ChainlinkClient {
    // Stores the answer from the Chainlink oracle
    // These are public to be accessed by other contracts
    uint256 public currentPrice;
    address public owner;

    constructor() public {
        // Set the address for the LINK token for the network
        setPublicChainlinkToken();
        // Sets whoe the owsner of the contract
        owner = msg.sender;
    }

    function requestEthereumPrice(
        address _oracle,
        bytes32 _jobId,
        uint256 _payment
    ) public onlyOwner {
        // newRequest takes a JobID, a callback address, and callback function as input
        Chainlink.Request memory req = buildChainlinkRequest(
            _jobId,
            address(this),
            this.fulfill.selector
        );
        // Adds a URL with the key "get" to the request parameters
        req.add(
            "get",
            "https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD"
        );
        // Uses input param (dot-delimited string) as the "path" in the request parameters
        req.add("path", "USD");
        // Adds an integer with the key "times" to the request parameters
        req.addInt("times", 100);
        // Sends the request with the amount of payment specified to the oracle
        sendChainlinkRequestTo(_oracle, req, _payment);
    }

    // fulfill receives a uint256 data type
    function fulfill(bytes32 _requestId, uint256 _price)
        public
        // Use recordChainlinkFulfillment to ensure only the requesting oracle can fulfill
        recordChainlinkFulfillment(_requestId)
    {
        currentPrice = _price;
    }

    // cancelRequest allows the owner to cancel an unfulfilled request
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

    // withdrawLink allows the owner to withdraw any extra LINK on the contract
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    // Insures that the sender of the contract is the creator
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}
