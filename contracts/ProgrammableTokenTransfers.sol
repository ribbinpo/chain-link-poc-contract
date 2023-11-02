// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";

import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";

contract ProgrammableTokenTransfers is CCIPReceiver, OwnerIsCreator {
    bytes32[] public receivedMessages;
    mapping(bytes32 => Message) public messageDetail;
    error NoMessageReceived();
    error IndexOutOfBound(uint256 providedIndex, uint256 maxIndex);
    error MessageIdNotExist(bytes32 messageId);
    error NothingToWithdraw();
    error FailedToWithdrawEth(address owner, address target, uint256 value);

    struct Message {
        uint64 sourceChainSelector; // The chain selector of the source chain.
        address sender; // The address of the sender.
        string message; // The content of the message.
        address token; // received token.
        uint256 amount; // received amount.
    }

    event MessageSent(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        string message, // The message being sent.
        Client.EVMTokenAmount tokenAmount, // The token amount that was sent.
        uint256 fees // The fees paid for sending the message.
    );

    event MessageReceived(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed sourceChainSelector, // The chain selector of the source chain.
        address sender, // The address of the sender from the source chain.
        string message, // The message that was received.
        Client.EVMTokenAmount tokenAmount // The token amount that was received.
    );

    constructor(address router_) CCIPReceiver(router_) {}

    function sendMessage(
        uint64 _destinationChainSelector,
        address _receiver,
        string calldata _message,
        address _token,
        uint256 _amount
    ) external payable returns (bytes32 messageId) {
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount(
            _token,
            _amount
        );

        tokenAmounts[0] = tokenAmount;

        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: abi.encode(_message),
            tokenAmounts: tokenAmounts,
            // extraArgs: Client._argsToBytes(
            //     // Additional arguments, setting gas limit and non-strict sequencing mode
            //     Client.EVMExtraArgsV1({gasLimit: 200_000, strict: false})
            // ),
            extraArgs: "",
            feeToken: address(0)
        });

        IRouterClient router = IRouterClient(this.getRouter());

        IERC20(_token).approve(address(router), _amount);

        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);

        messageId = router.ccipSend{value: fees}(
            _destinationChainSelector,
            evm2AnyMessage
        );

        emit MessageSent(
            messageId,
            _destinationChainSelector,
            _receiver,
            _message,
            tokenAmount,
            fees
        );

        return messageId;
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal virtual override {
        bytes32 messageId = any2EvmMessage.messageId; // fetch the messageId
        uint64 sourceChainSelector = any2EvmMessage.sourceChainSelector; // fetch the source chain identifier (aka selector)
        address sender = abi.decode(any2EvmMessage.sender, (address)); // abi-decoding of the sender address
        Client.EVMTokenAmount[] memory tokenAmounts = any2EvmMessage
            .destTokenAmounts;
        address token = tokenAmounts[0].token; // we expect one token to be transfered at once but of course, you can transfer several tokens.
        uint256 amount = tokenAmounts[0].amount; // we expect one token to be transfered at once but of course, you can transfer several tokens.
        string memory message = abi.decode(any2EvmMessage.data, (string)); // abi-decoding of the sent string message
        receivedMessages.push(messageId);
        Message memory detail = Message(
            sourceChainSelector,
            sender,
            message,
            token,
            amount
        );
        messageDetail[messageId] = detail;

        emit MessageReceived(
            messageId,
            sourceChainSelector,
            sender,
            message,
            tokenAmounts[0]
        );
    }

    receive() external payable {}

    function withdraw(address beneficiary) public onlyOwner {
        // Retrieve the balance of this contract
        uint256 amount = address(this).balance;

        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();

        // Attempt to send the funds, capturing the success status and discarding any return data
        (bool sent, ) = beneficiary.call{value: amount}("");

        // Revert if the send failed, with information about the attempted transfer
        if (!sent) revert FailedToWithdrawEth(msg.sender, beneficiary, amount);
    }

    function withdrawToken(
        address beneficiary,
        address token
    ) public onlyOwner {
        // Retrieve the balance of this contract
        uint256 amount = IERC20(token).balanceOf(address(this));

        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();

        IERC20(token).transfer(beneficiary, amount);
    }
}
