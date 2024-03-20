import { ethers } from "hardhat";
import { expect } from "chai";
import {BaseContract, Contract, ContractFactory} from "ethers";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe("Router", function () {

  const EVENT_NAME_TAKE_LOAN = "TakeLoanCalledSuccessfully";
  const EVENT_NAME_REQUEST_CASH_OUT = "CashOutCalledSuccessfully";

  const BORROW_AMOUNT = 123;
  const CREDIT_LINE = "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2";
  const DURATION = 322;
  const TX_ID = ethers.encodeBytes32String("1337")

  let Lending: ContractFactory;
  let Pix: ContractFactory;
  let Router: ContractFactory;

  let LendingContract: BaseContract;
  let PixContract: BaseContract;
  let RouterContract: BaseContract;

  let borrower: HardhatEthersSigner;

  let lendingAddress: string;
  let pixAddress: string;

  beforeEach(async () => {
    [borrower] = await ethers.getSigners();
    Lending = await ethers.getContractFactory("Lending");
    Pix = await ethers.getContractFactory("Pix");
    Router = await ethers.getContractFactory("RouterTest");

    LendingContract = await Lending.deploy();
    PixContract = await Pix.deploy();

    lendingAddress = await LendingContract.getAddress();
    pixAddress = await  PixContract.getAddress();

    RouterContract = await Router.deploy(lendingAddress, pixAddress);

  });

  it("Executes takeLoan&requestCashOut successfully when using encodeWithSignature", async () => {
    expect((RouterContract.connect(borrower) as Contract)
      .takeLoanAndRequestCashOutAssemblyWithSignature(
        borrower.address,
        CREDIT_LINE,
        BORROW_AMOUNT,
        DURATION,
        TX_ID
      )).to.emit(
        LendingContract,
        EVENT_NAME_TAKE_LOAN
    ).withArgs(
      CREDIT_LINE,
      BORROW_AMOUNT,
      DURATION,
      borrower.address
    ).and.to.emit(
      PixContract,
      EVENT_NAME_REQUEST_CASH_OUT
    ).withArgs(
      borrower.address,
      BORROW_AMOUNT,
      TX_ID,
      await RouterContract.getAddress()
    );
  });

  it("Executes takeLoan&requestCashOut successfully when using encodeWithSelector", async () => {

    const takeLoanSelector = ethers.FunctionFragment.getSelector(
      "takeLoan", ["address", "uint256", "uint256"]
    );
    const requestCashOutSelector = ethers.FunctionFragment.getSelector(
      "requestCashOutFrom", ["address", "uint256", "bytes32"]
    );


    expect((RouterContract.connect(borrower) as Contract)
      .takeLoanAndRequestCashOutAssemblyWithSelector(
        borrower.address,
        CREDIT_LINE,
        BORROW_AMOUNT,
        DURATION,
        TX_ID,
        [takeLoanSelector, requestCashOutSelector]
      )).to.emit(
      LendingContract,
      EVENT_NAME_TAKE_LOAN
    ).withArgs(
      CREDIT_LINE,
      BORROW_AMOUNT,
      DURATION,
      borrower.address
    ).and.to.emit(
      PixContract,
      EVENT_NAME_REQUEST_CASH_OUT
    ).withArgs(
      borrower.address,
      BORROW_AMOUNT,
      TX_ID,
      await RouterContract.getAddress()
    );
  });

  it("Executes takeLoan&requestCashOut successfully when using encoded values", async () => {

    const takeLoanSelector = ethers.FunctionFragment.getSelector(
      "takeLoan", ["address", "uint256", "uint256"]
    );
    const requestCashOutSelector = ethers.FunctionFragment.getSelector(
      "requestCashOutFrom", ["address", "uint256", "bytes32"]
    );

    const abiCoder = ethers.AbiCoder.defaultAbiCoder();

    const takeLoanParameters = abiCoder.encode(
      ["address", "uint256", "uint256"],
      [CREDIT_LINE, BORROW_AMOUNT, DURATION]
    );

    const requestCashOutParameters = abiCoder.encode(
      ["address", "uint256", "bytes32"],
      [borrower.address, BORROW_AMOUNT, TX_ID]
    )


    expect((RouterContract.connect(borrower) as Contract)
      .takeLoanAndRequestCashOutAssemblyEncode(
        [takeLoanParameters, requestCashOutParameters],
        [takeLoanSelector, requestCashOutSelector]
      )).to.emit(
      LendingContract,
      EVENT_NAME_TAKE_LOAN
    ).withArgs(
      CREDIT_LINE,
      BORROW_AMOUNT,
      DURATION,
      borrower.address
    ).and.to.emit(
      PixContract,
      EVENT_NAME_REQUEST_CASH_OUT
    ).withArgs(
      borrower.address,
      BORROW_AMOUNT,
      TX_ID,
      await RouterContract.getAddress()
    );
  });

  it("Executes takeLoan&requestCashOut without yul successfully", async () => {
    expect((RouterContract.connect(borrower) as Contract)
      .takeLoanAndRequestCashOutSolidityWithSignature(
        borrower.address,
        CREDIT_LINE,
        BORROW_AMOUNT,
        DURATION,
        TX_ID
      )).to.emit(
      LendingContract,
      EVENT_NAME_TAKE_LOAN
    ).withArgs(
      CREDIT_LINE,
      BORROW_AMOUNT,
      DURATION,
      borrower.address
    ).and.to.emit(
      PixContract,
      EVENT_NAME_REQUEST_CASH_OUT
    ).withArgs(
      borrower.address,
      BORROW_AMOUNT,
      TX_ID,
      await RouterContract.getAddress()
    );
  });
});
