// SPDX-License-Identifier: MIT
// 麻省理工声明

pragma solidity ^0.8.0;

import "/IERC20.sol";
import "/IPAIR.sol";


//创建一个类
contract multiCall{

    uint point = 10;
    address WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    mapping (string => address[]) public quoteAsset ; //对标资产，usdt/eth/busd等
    //1.批量获取Token的合约信息
    function tokenInfo(address _token) public view returns(string memory name,string memory symbol,uint myBalance){
        name = IERC20(_token).name();
        symbol = IERC20(_token).symbol();
        //msg.sender传递调用者本人的参数
        myBalance = IERC20(_token).balanceOf(msg.sender);
    }

    //2.获取单个Token的价格
    function getPrice(address _token,address _pair)public view returns(uint price){
        //先判断基础货币,因为返回多数据不知道谁是token0，谁是tonken1
        uint tokenAmount;
        uint baseAmount;
        (address token0,uint reserve0,address token1,uint _reserve1) = _pairfordetal(_pair);
        if(token0 == _token){
            tokenAmount = reserve0;
            baseAmount = _reserve1;
        }else{
            tokenAmount = _reserve1;
            baseAmount = reserve0;
        }
        //价格等于货币对的数量相除，*(10**point)做小数位处理，防止溢出
        price = baseAmount *(10**point) /tokenAmount;
    }
    //写一个内部合约
    function _pairfordetal(address _pair) internal view returns(address token0,uint reserve0,address token1,uint reserve1){
        token0 = IPair(_pair).token0();
        token1 = IPair(_pair).token1();
        (reserve0,reserve1,) = IPair(_pair).getReserves();
    }

    //3.一次性获取多个Token的价格
    function multiPrice(address[] memory _tokens,address[] memory _pairs) public view returns(uint[] memory prices){
        uint len = _tokens.length;
        for(uint i;i<len;i++){
            prices[i] = getPrice(_tokens[i],_pairs[i]);
        }

    }

    //4.通过合约地址搜索Pair相关信息
    function searchPair(string memory _dex,address _token,address _factory)public view returns(address[] memory pairs,string[] memory baseName,uint[]memory pools){
        //定义数组长度
        uint len = quoteAsset[_dex].length;
        pairs  = new address[](len); 
        baseName = new string[](len);
        pools = new uint[](len);
        for(uint i;i<len;i++){
            address pair = IPair(_factory).getPair(_token,quoteAsset[_dex][i]);
            pairs[i] = pair;
            if(pair == address(0)){
                baseName[i] = "";
                pools[i] = 0;
            }else{
                (pools[i],baseName[i]) = _pairBasenamePool(pair,_token);
            }
        }
    }
    
    function _pairBasenamePool(address _pair,address _token) public view returns(uint pool,string memory symbol){
        (address token0,uint reserve0,address token1,uint reserve1) = _pairfordetal(_pair);
        uint8 decimals;
        if(token0 == _token){
            symbol = IERC20(token1).symbol();
            decimals = IERC20(token1).decimals();
            //流动池价值总和
            pool = reserve1 * 2 /(10**decimals);
            if(token1 == WETH){
                uint WETH_PRICE = getPrice(WETH,0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16);
                pool = pool * WETH_PRICE /(10 ** point);
            }
        }else{
            symbol = IERC20(token0).symbol();
            decimals = IERC20(token0).decimals();
            //流动池价值总和
            pool = reserve0 * 2 /(10**decimals);
            if(token0 == WETH){
                uint WETH_PRICE = getPrice(WETH,0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16);
                pool = pool * WETH_PRICE /(10 ** point);
            }
        }
    }

    constructor(){
        quoteAsset["PANCAKE"].push(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);//WBNB
        quoteAsset["PANCAKE"].push(0x55d398326f99059fF775485246999027B3197955);//USDT
        quoteAsset["PANCAKE"].push(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);//USDC
        quoteAsset["PANCAKE"].push(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);//BUSD

    }
}