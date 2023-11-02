// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MessagePassing is CCIPReceiver {
    enum PayFeesIn {
        NATIVE,
        LINK
    }

    address immutable router;
    address immutable link;

    event MessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        string text
    );
    event MessageReceived(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address sender,
        string message
    );

    constructor(address router_, address link_) CCIPReceiver(router_) {
        router = router_;
        link = link_;
    }

    receive() external payable {}

    function sendMessage(
        uint64 _destinationChainSelector,
        address _receiver,
        string calldata _messageText,
        PayFeesIn _payFeesIn
    ) external payable returns (uint256, bytes32) {
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            _receiver,
            _messageText,
            // address(0),
            // 0,
            _payFeesIn == PayFeesIn.LINK ? link : address(0)
        );

        uint256 fee = getCCIPMessageFee(
            _destinationChainSelector,
            evm2AnyMessage
        );

        bytes32 messageId;
        if (_payFeesIn == PayFeesIn.LINK) {
            IERC20(link).approve(router, fee);
            messageId = IRouterClient(router).ccipSend(
                _destinationChainSelector,
                evm2AnyMessage
            );
        } else {
            messageId = IRouterClient(router).ccipSend{value: fee}(
                _destinationChainSelector,
                evm2AnyMessage
            );
        }

        emit MessageSent(
            messageId,
            _destinationChainSelector,
            _receiver,
            _messageText
        );

        return (fee, messageId);
    }

    // generate a CCIP message
    function _buildCCIPMessage(
        address _receiver,
        string calldata _text,
        // address _token,
        // uint256 _amount,
        address _feeTokenAddress
    ) internal pure returns (Client.EVM2AnyMessage memory) {
        // Set Token Amount
        // Client.EVMTokenAmount[]
        //     memory tokenAmounts = new Client.EVMTokenAmount[](1);
        // tokenAmounts[0] = Client.EVMTokenAmount({
        //     token: _token,
        //     amount: _amount
        // });

        // Create an EVM2EVM message
        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(_receiver),
                data: abi.encode(_text),
                tokenAmounts: new Client.EVMTokenAmount[](0),
                // extraArgs: Client._argsToBytes(
                //     // Additional arguments, setting gas limit and non-strict sequencing mode
                //     Client.EVMExtraArgsV1({gasLimit: 200_000, strict: false})
                // ),
                extraArgs: "",
                feeToken: _feeTokenAddress
            });
    }

    // get the fee for a CCIP message
    function getCCIPMessageFee(
        uint64 _destinationChainSelector,
        Client.EVM2AnyMessage memory _ccipMessage
    ) public view returns (uint256) {
        return
            IRouterClient(router).getFee(
                _destinationChainSelector,
                _ccipMessage
            );
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {
        emit MessageReceived(
            message.messageId,
            message.sourceChainSelector,
            abi.decode(message.sender, (address)),
            abi.decode(message.data, (string))
        );
    }
}
