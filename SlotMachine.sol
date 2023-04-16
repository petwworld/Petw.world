// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SlotMachine {
    
    address public PETW;
    uint8[] public Doge = [0 ,8];
    uint8[] public Floki = [1, 9];
    uint8[] public PepeTheFrog = [2, 10];
    uint8[] public AKITA = [3, 11];
    uint8[] public zkSyncEra = [4, 12];
    uint8[] public SHIB = [5, 13];
    uint8[] public BABYDOGE = [6, 14];
    uint8[] public KISHU = [7, 15];
    uint256 public GameID;

    event Result(uint256 gameID, bytes32 _fullResult, uint256[3] _result);
    event Save(uint256 gameID, bool gameStatus, uint256 blockNumber, address player, uint256 reward);

    function calculReward(uint256[3] memory result) public pure returns (uint256 ratio) {
        uint256 r = 1;
        for (uint i = 0; i < result.length - 1; i ++) {
            result[i] == result[i + 1] ? r = r : r = r + 1;
        }
        if (r==3) ratio = 15625;
        if (r==2) ratio = 328125;

    }

    function getRandomNumber() public view returns (bytes32 fullResult, uint256[3] memory result){
        fullResult = keccak256(abi.encodePacked(blockhash(block.number), block.difficulty, block.timestamp, address(this), GameID));
        result = calculResult(fullResult);
    }

    function calculResult(bytes32 value) public pure returns (uint256[3] memory _result) {
        bytes memory result = new bytes(64);
        for (uint i = 0; i < 32; i++) {
            uint8 b = uint8(bytes1(value << (i * 8))); 
            bytes1 hi = bytes1(uint8(b / 16));
            bytes1 lo = bytes1(uint8(b - 16 * uint8(hi)));
            result[2 * i] = hexChar(hi);
            result[2 * i + 1] = hexChar(lo);            
        }
            uint r = 0;
            for (uint i = result.length - 1; i > 0 && r < 3 ; i--) {
                (uint8(result[i]) < 58) ? _result[r] =  (uint8(result[i]) - 48) : _result[r] =  (uint8(result[i]) - 58);
                }
                r ++;
            }
    

    function hexChar(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function spin(uint256 amount, uint256 noPlays) public {
        uint256 totalWins;
        require(noPlays > 0, "Error");
        require(amount > 0, "Error");
        require(IERC20(PETW).balanceOf(msg.sender) >= amount * noPlays, "Not enough balance");
        require(IERC20(PETW).allowance(msg.sender, address(this)) >= amount * noPlays);   
        for (uint i = 0; i < noPlays; i ++){
            (bytes32 fullResult, uint256[3] memory _result) = getRandomNumber();
            uint256 reward = (10 ** 6 - calculReward(_result)) * amount / 10 ** 6;
            if (calculReward(_result) > 0) totalWins += reward;
            GameID ++;
            emit Result(block.number, fullResult, _result);
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
