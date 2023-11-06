// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract TokenSender {
    enum PayFeesIn {
        NATIVE,
        LINK
    }

    address immutable router;
    address immutable link;
    uint16 immutable maxTokensLength;

    event MessageSent(bytes32 messageId);

    constructor(address _router, address _link) {
        router = _router;
        link = _link;
        maxTokensLength = 5;
    }

    receive() external payable {}

    function getSupportedTokens(
        uint64 chainSelector
    ) external view returns (address[] memory tokens) {
        tokens = IRouterClient(router).getSupportedTokens(chainSelector);
    }

    function sendToken(
        uint64 destinationChainSelector,
        address receiver,
        Client.EVMTokenAmount[] memory tokensToSendDetails,
        PayFeesIn payFeesIn
    ) external {
        uint256 length = tokensToSendDetails.length;
        require(
            length <= maxTokensLength,
            "Maximum 5 different tokens can be sent per CCIP Message"
        );

        for (uint256 i = 0; i < length; ) {
            // TODO: Approve ERC20 before
            IERC20(tokensToSendDetails[i].token).approve(
                address(this),
                tokensToSendDetails[i].amount
            );
            // --------------------------
            IERC20(tokensToSendDetails[i].token).transferFrom(
                msg.sender,
                address(this),
                tokensToSendDetails[i].amount
            );
            IERC20(tokensToSendDetails[i].token).approve(
                router,
                tokensToSendDetails[i].amount
            );
            unchecked {
                ++i;
            }
        }

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: "",
            tokenAmounts: tokensToSendDetails,
            extraArgs: "",
            feeToken: payFeesIn == PayFeesIn.LINK ? link : address(0)
        });

        uint256 fee = IRouterClient(router).getFee(
            destinationChainSelector,
            message
        );

        bytes32 messageId;

        if (payFeesIn == PayFeesIn.LINK) {
            IERC20(link).approve(router, fee);
            messageId = IRouterClient(router).ccipSend(
                destinationChainSelector,
                message
            );
        } else {
            messageId = IRouterClient(router).ccipSend{value: fee}(
                destinationChainSelector,
                message
            );
        }

        emit MessageSent(messageId);
    }
}
