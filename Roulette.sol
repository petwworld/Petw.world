// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Roulette {

    bytes4 public constant T_ST_O = 0xbee4e6f1; // 2to1 (0, 1 - 34)
    bytes4 public constant T_ND_O = 0xed9287ba; // 2to1 (0, 2 - 35)
    bytes4 public constant T_RD_O = 0xb01060fb; // 2to1 (0, 3 - 36)
    bytes4 public constant O_ST_T = 0x601d1c3b; // 1st12
    bytes4 public constant T_ND_T = 0x88542287; // 2nd12
    bytes4 public constant T_RD_T = 0x62db1cdb; // 3rd12
    bytes4 public constant O_E = 0x1cb05b88; // 1-18
    bytes4 public constant N_T = 0xc7832ddb; // 19-36
    bytes4 public constant EVEN = 0xd6a1baa7;
    bytes4 public constant ODD = 0x195302f6;
    bytes4 public constant RED = 0xe81b7fb1;
    bytes4 public constant BLACK = 0x88319a14;
    uint256 public GameID;



    mapping (bytes4 => uint256[]) public prize;
    // mapping (bytes4 => checkPrize) public check;

    function initialize() public {
        prize[T_ST_O] = [0,1,4,7,10,13,16,19,22,25,28,31,34];
        prize[T_ND_O] = [0,2,5,8,11,14,17,20,23,26,29,32,35];
        prize[T_RD_O] = [0,3,6,9,12,15,18,21,24,27,30,33,36];
        prize[O_ST_T] = [1,2,3,4,5,6,7,8,9,10,11,12];
        prize[T_ND_T] = [13,14,15,16,17,18,19,20,21,22,23,24];
        prize[T_RD_T] = [25,26,27,28,29,30,31,32,33,34,35,36];
        prize[O_E] = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18];
        prize[N_T] = [19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36];
        prize[EVEN] = [0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34,36];
        prize[ODD] = [1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35];
        prize[RED] = [1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36];
        prize[BLACK] = [2,4,6,8,10,11,13,15,17,20,22,24,26,28,29,31,33,35];

    }
    
    address public PETW;
    mapping(address => uint256) public lastCallTime;

    event Result(uint256 gameID, uint256 _result, bytes32 _fullResult);
    event Save(uint256 gameID, bool gameStatus, uint256 blockNumber, address player, uint256 reward);


    function getRandomNumber() public view returns (bytes32 fullResult, uint256 result){
        fullResult = keccak256(abi.encodePacked(blockhash(block.number), block.difficulty, block.timestamp, address(this)));
        result = calculResult(fullResult);
    }

    function decode(bytes memory encodedbetPlaces) public pure returns (bytes4[] memory, bytes32) {
        (bytes4[] memory betPlaces, bytes32 _salt) = abi.decode(encodedbetPlaces, (bytes4[], bytes32));
        return (betPlaces, _salt);
    }

    function calculResult(bytes32 value) public pure returns (uint256 _result) {
        bytes memory result = new bytes(64);
        for (uint i = 0; i < 32; i++) {
            uint8 b = uint8(bytes1(value << (i * 8))); 
            bytes1 hi = bytes1(uint8(b / 16));
            bytes1 lo = bytes1(uint8(b - 16 * uint8(hi)));
            result[2 * i] = hexChar(hi);
            result[2 * i + 1] = hexChar(lo);            
        }
            uint r = 0;
            for (uint i = result.length - 1; i > 0 && r < 4 ; i--) {
                if (uint8(result[i]) < 58) {
                    _result =  _result + (uint8(result[i]) - 48);
                    r ++;
                }
            }
    }

    function hexChar(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function isIn(uint256 number, uint256[] memory listNumber) public pure returns (bool) {
        for (uint i = 0; i < listNumber.length; i++) {
            if (listNumber[i] == number) {
                return true;
            }
        }
        return false;
    }

    function checkResult(bytes4 betPlace) public view returns (uint8 reward) {

        (, uint256 _result) = getRandomNumber();

        if (uint32(betPlace) == _result) reward = 35;

        if (isIn(_result, prize[betPlace])) {
            if (betPlace == T_ST_O 
            || betPlace == T_ND_O 
            || betPlace == T_RD_O 
            || betPlace == O_ST_T 
            || betPlace == T_ND_T 
            || betPlace == T_RD_T ) reward = 2;
            else reward = 1;
        }

        reward = 0;

        }

    function PlayWheel(bytes memory encodeBetPlace, bytes32 _salt, uint256[] memory amount) public {
        GameID ++;
        uint256 totalAmount;
        uint256 totalReward;
        
        (bytes4[] memory betPlaces, bytes32 salt) = decode(encodeBetPlace);
        require(betPlaces.length == amount.length && _salt == salt , "Mismatch");

        for (uint i = 0; i < amount.length; i ++) {
            totalAmount += amount[i];
        }
        require(totalAmount > 0, "Error");
        require(IERC20(PETW).balanceOf(msg.sender) >= totalAmount, "Not enough balance");
        require(IERC20(PETW).allowance(msg.sender, address(this)) >= totalAmount);
        (bytes32 fullResult, uint256 _result) = getRandomNumber();
        for (uint i=0; i < encodeBetPlace.length; i ++) {
            totalReward += checkResult(betPlaces[i]) * amount[i];
        }

        (totalReward > totalAmount) ? Win(msg.sender, totalReward - totalAmount) : Lose(msg.sender, totalAmount - totalReward);

        emit Result(block.number, _result, fullResult);

    }

    function calculRate(uint256 ticketNumber) public pure returns (uint256) {
        return 100 + (100 - ticketNumber);
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
