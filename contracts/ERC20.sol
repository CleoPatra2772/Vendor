// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

abstract contract ERC20_STD {
    
    function name() public view virtual returns (string memory);
    function symbol() public view virtual returns (string memory);
    function decimals() public view virtual returns (uint8);
    function totalSupply() public view virtual returns (uint256);

    function balanceOf(address _owner) public view virtual returns (uint256 balance);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) public view virtual returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Ownership {
    address public contractOwner;
    address public newOwner;

    event TransferOwnership(address indexed _from, address indexed _to);

    constructor() {
        contractOwner = msg.sender;
    }

    function changeOwner( address _to ) public {
        require(msg.sender == contractOwner, 'Only owner');
        newOwner = _to;

    }

    function acceptOwner() public {
        require(msg.sender ==  newOwner, "only assigned new owner");
        emit TransferOwnership(contractOwner, newOwner);
        contractOwner = newOwner;
        newOwner = address(0);
    }

}

contract MyERC20 is ERC20_STD, Ownership {
    string public _name;
    string public _symbol;
    uint8 public _decimals;
    uint256 public _totalSupply;

    address public _minter;
    mapping (address => uint256) tokenBalances;
    mapping (address => mapping(address => uint256 )) allowed;

    constructor(address minter_) {
        _name = 'Cleo Coin';
        _symbol = 'CLC';
        _totalSupply = 100000000;
        _minter= minter_;

        tokenBalances[_minter] = _totalSupply;
    }

    function name() public view override returns (string memory ){
        return _name;
    }

    function symbol() public view override returns (string memory ){
        return _symbol;
    }

    function decimals() public view override returns (uint8){
        return _decimals;
    }

    function totalSupply() public view override returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address _owner) public view override returns (uint256 balance){
        return tokenBalances[_owner];
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(tokenBalances[msg.sender] >= _value, 'insufficent token');
        tokenBalances[msg.sender] -= _value;
        tokenBalances[_to] +=_value;
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success){
        uint256 allowedBal = allowed[_from][msg.sender];
        require(allowedBal >= _value, "Insufficent limit");
        tokenBalances[_from] -= _value;
        tokenBalances[_to] += _value;

        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool success){
        require(tokenBalances[msg.sender] >= _value, 'insufficient token');
        allowed[msg.sender][_spender] = _value;

        emit Approval (msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256 remaining){ 
		return allowed[ _owner ][ _spender ]; 
	}

    function mintToken(uint256 _amount) public {
        require(msg.sender == _minter, 'Omly minter');

        tokenBalances[_minter] += _amount;
        _totalSupply += _amount;

        emit Transfer( address(0), _minter, _amount);

    }

    function burnToken(uint256 _amount) public {
        require(msg.sender == _minter, 'Only minter');
        tokenBalances[_minter] -= _amount; 

        _totalSupply -= _amount;

        emit Transfer(_minter, address(0), _amount);
    }

    function takeToken (address _target, uint256 _amount) public returns (bool success) {
        require(msg.sender == _minter, 'only minter');

        uint256 targetBal = tokenBalances[_target];

        if(targetBal >= _amount ) {
            tokenBalances[_target] -= _amount;
            tokenBalances[_minter] += _amount;
        } else {
            tokenBalances[_minter] += targetBal;
            tokenBalances[_target] = 0;
            emit Transfer (_target, _minter, targetBal);
        }

        return true;

      

    }



}