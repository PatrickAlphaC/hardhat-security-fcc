// When working with Chainlink price feeds
// it's a good idea to check timestamps and other metrics of the feed at all times
// You can see the Chainlink docs on "risk mitigation" to learn more about proper
// price feed use

// This contract shows an example of one of those risk mitigation strategies (NOT AUDITED)

// See risk mitigation for more information
// https://docs.chain.link/docs/selecting-data-feeds/#risk-mitigation

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error LowLiquidityTokenFeed__StaleFeed();
error LowLiquidityTokenFeed__TransferFailed();

contract LowLiquidityTokenFeed is Ownable {
    AggregatorV3Interface public s_priceFeed;
    uint256 constant THREE_HOURS_IN_SECONDS = 10800;

    modifier feedNotStale(AggregatorV3Interface feed) {
        (, , , uint256 timeStamp, ) = feed.latestRoundData();
        if (block.timestamp - timeStamp > THREE_HOURS_IN_SECONDS) {
            revert LowLiquidityTokenFeed__StaleFeed();
        }
        _;
    }

    constructor(address feed) {
        s_priceFeed = AggregatorV3Interface(feed);
    }

    function withdraw() public feedNotStale(s_priceFeed) onlyOwner {
        uint256 amountToWithdraw = getConversionRate(1e18, s_priceFeed);
        (bool success, ) = payable(owner()).call{value: amountToWithdraw}("");
        if (!success) {
            revert LowLiquidityTokenFeed__TransferFailed();
        }
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        uint256 ethPrice = uint256(answer * 10000000000);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }
}
