// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RouterTest {
    // !NB Three examples with using assembler, one more with regular Solidity functionality for comparing

    // For convenience only, parameters of functions can be used
    address public lending;
    address public pix;

    constructor(address _lending, address _pix) {
        lending = _lending;
        pix = _pix;
    }

    // The most explicit way
    function takeLoanAndRequestCashOutAssemblyWithSignature(
        address account,
        address creditLine,
        uint256 amount,
        uint256 durationInPeriods,
        bytes32 txId
    ) external {
        // create data payload
        bytes memory takeLoanEncoded = abi.encodeWithSignature(
            "takeLoan(address,uint256,uint256)",
            creditLine,
            amount,
            durationInPeriods
        );

        bytes memory requestCashOutEncoded = abi.encodeWithSignature(
            "requestCashOutFrom(address,uint256,bytes32)",
            account,
            amount,
            txId
        );

        assembly {
            // load contract addresses
            // not necessary, function parameters can be used instead
            let lendingAddr := sload(lending.slot)
            let pixAddr := sload(pix.slot)

            // delegate call first, so the msg.sender is a borrower

            // gas() returns the amount gas still available to execution
            // lendingAddr stands for the address of the contract to delegate the call to
            // after that we are constructing call data array
            let takeLoanResult := delegatecall(gas(), lendingAddr, add(takeLoanEncoded, 0x20), mload(takeLoanEncoded), 0, 0)

            if eq(takeLoanResult, 0) {
                revert(0, returndatasize())
            }

            // regular call, so the msg.sender is a router (configured as cashier)
            let requestCashOutResult := call(gas(), pixAddr, 0, add(requestCashOutEncoded, 0x20), mload(requestCashOutEncoded), mload(0x40), 0)

            if eq(requestCashOutResult, 0) {
                revert(0, returndatasize())
            }
        }
    }

    // Way without hardcoding function names, selectors are created on the back end side
    function takeLoanAndRequestCashOutAssemblyWithSelector(
        address account,
        address creditLine,
        uint256 amount,
        uint256 durationInPeriods,
        bytes32 txId,
        bytes4[] memory selectors
    ) external {
        bytes memory takeLoanEncoded = abi.encodeWithSelector(
            selectors[0],
            creditLine,
            amount,
            durationInPeriods
        );

        bytes memory requestCashOutEncoded = abi.encodeWithSelector(
            selectors[1],
            account,
            amount,
            txId
        );

        assembly {
            let lendingAddr := sload(lending.slot)
            let pixAddr := sload(pix.slot)

            let takeLoanResult := delegatecall(gas(), lendingAddr, add(takeLoanEncoded, 0x20), mload(takeLoanEncoded), 0, 0)

            if eq(takeLoanResult, 0) {
                revert(0, returndatasize())
            }

            let requestCashOutResult := call(gas(), pixAddr, 0, add(requestCashOutEncoded, 0x20), mload(requestCashOutEncoded), mload(0x40), 0)

            if eq(requestCashOutResult, 0) {
                revert(0, returndatasize())
            }
        }
    }

    // Most flexible way
    function takeLoanAndRequestCashOutAssemblyEncode(
        bytes4[] memory selectors,
        bytes[] memory parameters
    ) external {
        bytes memory takeLoanEncoded = abi.encodePacked(
            selectors[0],
            parameters[0]
        );

        bytes memory requestCashOutEncoded = abi.encodePacked(
            selectors[1],
            parameters[1]
        );

        assembly {
            let lendingAddr := sload(lending.slot)
            let pixAddr := sload(pix.slot)

            let takeLoanResult := delegatecall(gas(), lendingAddr, add(takeLoanEncoded, 0x20), mload(takeLoanEncoded), 0, 0)

            if eq(takeLoanResult, 0) {
                revert(0, returndatasize())
            }

            let requestCashOutResult := call(gas(), pixAddr, 0, add(requestCashOutEncoded, 0x20), mload(requestCashOutEncoded), mload(0x40), 0)

            if eq(requestCashOutResult, 0) {
                revert(0, returndatasize())
            }
        }
    }

    // Same, but without Yul
    function takeLoanAndRequestCashOutSolidityWithSignature(
        address account,
        address creditLine,
        uint256 amount,
        uint256 durationInPeriods,
        bytes32 txId
    ) external {
        bytes memory takeLoanEncoded = abi.encodeWithSignature(
            "takeLoan(address,uint256,uint256)",
            creditLine,
            amount,
            durationInPeriods
        );

        bytes memory requestCashOutEncoded = abi.encodeWithSignature(
            "requestCashOutFrom(address,uint256,bytes32)",
            account,
            amount,
            txId
        );

        (bool success, bytes memory data) = lending.call{
                value: 0,
                gas: 50000000
            }(takeLoanEncoded);
        if (!success) {
            revert();
        }

        (success, data) = pix.delegatecall(requestCashOutEncoded);
        if (!success) {
            revert();
        }
    }
}

// ----------------------- Test contracts to check call results ----------------------------

contract Lending {
    event TakeLoanCalledSuccessfully(
        address creditLine,
        uint256 borrowAmount,
        uint256 durationInPeriods,
        address caller
    );

    function takeLoan(
        address creditLine,
        uint256 borrowAmount,
        uint256 durationInPeriods
    ) external returns (uint256) {
        emit TakeLoanCalledSuccessfully(creditLine, borrowAmount, durationInPeriods, msg.sender);
        return 1;
    }
}

contract Pix {
    event CashOutCalledSuccessfully(address account, uint256 amount, bytes32 txId, address caller);

    function requestCashOutFrom(
        address account,
        uint256 amount,
        bytes32 txId
    ) external returns (uint256) {
        emit CashOutCalledSuccessfully(account, amount, txId, msg.sender);
        return 1;
    }
}