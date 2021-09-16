// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <0.9.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    
    // When the smart contract deploys, immediately set owner as the deployer of the contract
    constructor() public {
      owner = msg.sender;
    }
    
    // Method to fund the smart contract
    function fund() public payable {
      // We multiply the USD value by 10 and raise to the 18th for wei
      uint256 minimumUSD = 50 * 10 ** 18;
      
      // Require is a guard function that stops execution and reverts the transaction
      // User gets their money back and any unspent gas
      require(getConversionRate(msg.value) >= minimumUSD, "There is a minimum of $50 for this!");
      
      addressToAmountFunded[msg.sender] += msg.value;
      funders.push(msg.sender);
    }
    
    // Returns the Chainlink Aggregator version
    function getVersion() public view returns(uint256) {
      AggregatorV3Interface priceFeed = getEthUsd();
      return priceFeed.version();
    }
    
    // Returns the current price of ETHUSD from Chainlink
    function getPrice() public view returns(uint256) {
      AggregatorV3Interface priceFeed = getEthUsd();
      (, int256 answer,,,) = priceFeed.latestRoundData();
      return uint256(answer * 10000000000);
    }
    
    // 10000000000
    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
      uint256 ethPrice = getPrice();
      uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
      return ethAmountInUsd;
    }
    
    // Returns the ETHUSD aggregator
    function getEthUsd() public pure returns(AggregatorV3Interface) {
     return AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);   
    }
    
    // Modifier that runs a guard where only the contract owner satisfies the conditions
    modifier onlyOwner {
      // Only the owner of the contract (who deployed it) can withdraw
      require(msg.sender == owner, "Nice try");
      _;
    }
    
    // Withdraw all funds from the smart contract
    // Reset all funder contributions
    function withdraw() payable onlyOwner public {
      // "this" refers to the smart contract
      msg.sender.transfer(address(this).balance);
      
      // reset the funded balances of all the funders who participated
      for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
          address funder = funders[funderIndex];
          addressToAmountFunded[funder] = 0;
      }

      funders = new address[](0);   
    }
}
