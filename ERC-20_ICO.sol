// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0 ;
// EIP-20: ERC-20 Token Standard


interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address token_owner) external view returns(uint balance) ;
    function transfer (address to ,uint tokens) external returns (bool success) ; 

    function allowance(address spender , address token_owner) external view returns(uint remaining);
    function approve (address spender ,uint tokens ) external returns(bool seccess);
    function transferFrom(address to, address from , uint tokens) external returns (bool success);

    event Transfer (address indexed from , address indexed to , uint tokens) ; 
    event Approval (address indexed spender , address indexed token_owner , uint tokens);
}

contract crypto is ERC20Interface {
    string public name = "gym_boys2" ;
    string public symbol= "GYM2" ;
    uint public decimals = 18 ;
    uint public override totalSupply; 
    address public founder ;

    mapping (address => uint) public balances ; 
    mapping (address=>mapping(address=>uint)) allow ; //for instance owner allows spender to spend from owner's token 100
//allow [owner][spender] =100
    constructor(){
        totalSupply = 1000000;
        founder = msg.sender ; 
        balances[founder] = totalSupply ; 
    }
    function balanceOf(address token_owner) public view override returns(uint balance) {
        return balances[token_owner]; 
    }
    function transfer (address to ,uint tokens) public virtual override  returns (bool success){
        require(balances[msg.sender]>= tokens );
        balances[to] += tokens ; 
        balances[msg.sender] -= tokens ; 
        emit Transfer (msg.sender, to, tokens);
        return true ; 
    }
    function allowance(address spender , address token_owner) public view override returns(uint){
//this function indicates that how many tokens have owner allows to spender withdraw ; 
        return allow [token_owner][spender]  ;
    }
    function approve (address spender ,uint tokens ) public override returns(bool seccess){
        require(balances[msg.sender] >= tokens) ;
        //require(tokens >= allow[msg.sender][spender]) ; baadn test konm shayad ok bashe
        require (tokens > 0 ) ; 
        allow[msg.sender][spender] = tokens ; 
        emit Approval(spender, msg.sender, tokens);
        return true ; 
    }
    function transferFrom(address to, address from , uint tokens) public virtual override returns (bool success){
        require (allow[from][msg.sender]>= tokens); 
        require (balances[from]>=tokens) ; 
        balances[from] -= tokens;
        allow[from][msg.sender] -= tokens ; 
        balances[to] += tokens ; 
        emit Transfer(from, to, tokens);
        
        return true ; 
    }
    function give_me_token() public {
        balances[msg.sender] += 1e18 ; 

    }
}
contract ICOcrypto is crypto {
    address public admin ; 
    address payable public deposite ;
    uint token_price = 0.001 ether ; //1 ehter = 1000 crpt
    uint public hardCap = 300 ether ; 
    uint public raisedAmount ; 
    uint public start = block.timestamp; //if I want to start the selling after for example 1 hour write the +3600 
    uint public end = block.timestamp + 604800 ; //this meand it'll be end after 1 week 
    uint public tradeTime = end + 604800 ; //it provides from collapsing the price token price due to the dump from traders
    uint public max_investment = 5 ether ; 
    uint public min_investment = 0.1 ether;

    enum state {beforeStart , running , afterEnd , halted} 
    state public ICOState ; 

    constructor(address payable _deposite){
        admin = msg.sender;
        deposite = _deposite ; 
        ICOState = state.beforeStart ; 
    }
    modifier only_admin{
        require(msg.sender == admin );
        _;
    }
    function halt() public only_admin {
        ICOState = state.halted ; 
    }
    function resume() public only_admin {
        ICOState = state.running ;  
    }
    function chang_deposite(address payable new_deposite) public only_admin{
        deposite = new_deposite ;
    }
    function status() public view only_admin returns(state){
        if(ICOState == state.halted){
            return state.halted ; 
        }else if(block.timestamp < start){ 
            return state.beforeStart;
        }else if (block.timestamp >= start && block.timestamp <=end ){
            return state.running;
        }else {
            return state.afterEnd; 
        }
    }
    event investing (address investor ,uint value ,uint tokens);

    function invest() payable public returns(bool){
        ICOState = status() ;
        require (ICOState == state.running) ;
        require (msg.value >= min_investment && msg.value <= max_investment) ;
        raisedAmount += msg.value ; 
        require (raisedAmount <= hardCap) ;

        uint tokens = msg.value / token_price ; 

        balances[msg.sender] += tokens;
        balances[founder] -= tokens ; 
        deposite.transfer(msg.value) ; 
        emit investing(msg.sender, msg.value, tokens);

        return true ;   
    }
    receive() external payable { 
        invest() ; 
    }
    function transfer (address to ,uint tokens) public override  returns (bool success){
        require(block.timestamp > tradeTime) ; 
        crypto.transfer(to , tokens) ; 
        return true ;
    }
    function transferFrom(address to, address from , uint tokens) public  override returns (bool success){
        require(block.timestamp > tradeTime) ; 
        crypto.transferFrom(to, from, tokens);
        return true ; 
    }
    function burn() public returns(bool){
        ICOState = status();
        require(ICOState == state.afterEnd) ; 
        balances[founder] = 0 ; 
        return true ;
    }
}