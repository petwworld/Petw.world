// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CoinFlip {

    uint256 public GameID;
    address public PETW;

    mapping(address => uint256) public lastCallTime;

    event Result(uint256 gameID, uint256 _result, bytes32 _fullResult);
    event Save(uint256 gameID, bool gameStatus, uint256 blockNumber, address player, uint256 reward);

    function decode(bytes memory encodedABI) public pure returns (uint256, bytes32) {
        (uint256 ticketNumber, bytes32 _salt) = abi.decode(encodedABI, (uint256, bytes32));
        return (ticketNumber, _salt);
    }

    function getRandomNumber() public view returns (bytes32 fullResult, uint256 result){
        fullResult = keccak256(abi.encodePacked(blockhash(block.number), block.difficulty, block.timestamp, address(this), GameID));
        result = calculResult(fullResult);
    }

    function calculResult(bytes32 value) public pure returns (uint r) {
        uint256 _result;
        bytes memory result = new bytes(64);
        for (uint i = 0; i < 32; i++) {
            uint8 b = uint8(bytes1(value << (i * 8))); 
            bytes1 hi = bytes1(uint8(b / 16));
            bytes1 lo = bytes1(uint8(b - 16 * uint8(hi)));
            result[2 * i] = hexChar(hi);
            result[2 * i + 1] = hexChar(lo);            
        }
            
            for (uint i = result.length - 1; i > 0; i--) {
                if (uint8(result[i]) < 58) {
                    _result += (uint8(result[i]) - 48);
                }

            r = _result % 2;

            }
    }

    function hexChar(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function PlayCoinFlip(uint8 Choice, uint256 amount, uint256 noPlays) public {

        uint256 totalWins;

        require(Choice < 2, "Only ODD or EVEN");
        require(noPlays > 0, "Error");
        require(amount > 0, "Error");
        require(IERC20(PETW).balanceOf(msg.sender) >= amount * noPlays, "Not enough balance");
        require(IERC20(PETW).allowance(msg.sender, address(this)) >= amount * noPlays);  

        for (uint i = 0; i < noPlays; i ++) {
            (bytes32 fullResult, uint256 _result) = getRandomNumber();
            GameID ++;
            if (Choice == _result) totalWins += amount;
            emit Result(block.number, _result, fullResult);
        }

        totalWins > amount * noPlays ?  Win(msg.sender, totalWins - amount * noPlays) : Lose(msg.sender,  amount * noPlays - totalWins);

        
    }

    function Win(address user, uint256 amount) private  {

        IERC20(PETW).transfer(msg.sender, amount);

        emit Save(GameID, true,  block.number, user, amount);
    }
    function Lose(address user, uint256 amount) private {

        IERC20(PETW).transferFrom(user, address(this), amount);

        emit Save(GameID, false,  block.number, user, amount);

    }


}
